---
-- Context-aware dictation router
--
-- Karabiner generates the OpenWhisper shortcut configured in KEYBIND:
--
--     trigger DOWN
--          ... held ...
--     trigger UP
--
-- Hammerspoon observes that event:
--
--   ChatGPT
--     -> consume trigger
--     -> emit Ctrl+Shift+D according to the route's mode
--
--   Gemini
--     -> consume trigger
--     -> emit Cmd+Shift+D according to the route's mode
--
--   everything else
--     -> do NOT consume anything
--     -> original trigger reaches OpenWhisper untouched
--
-- Both routes apply in Google Chrome and Firefox. The ChatGPT shortcut has
-- to be configured in ChatGPT settings once per browser profile; Gemini's
-- shortcut is the same in both.
--
-- The trigger key and the emitted shortcuts are configured in KEYBIND and
-- ROUTES below.
--

---@diagnostic disable: undefined-global

local CHROME = "com.google.Chrome"
local FIREFOX = "org.mozilla.firefox"

local BROWSER_NAMES = {
  [CHROME] = "Chrome",
  [FIREFOX] = "Firefox",
}

----------------------------------------------------------------------
-- Configuration
----------------------------------------------------------------------

-- Input shortcut produced by Karabiner. Modifiers must match exactly:
-- use {} for no modifiers or { "cmd" } for Cmd only.
-- macOS adds an Fn flag to function keys; it is ignored unless listed.
-- Supported modifiers: cmd, ctrl, alt, shift, fn.
-- Karabiner maps physical Left Ctrl to F15 with a simple modification,
-- then wraps F15 with a held Cmd in a complex modification. Caps Lock's
-- Left Ctrl output never matches that F15-only wrapper.
local KEYBIND = {
  key = "f15",
  mods = { "cmd" }, -- Cmd+F15, held until physical Left Ctrl is released
}

local DEBUG = false -- Enable one decision log per input press, not repeats.

-- Dictation shortcut emitted per routed target.
--
--   domains: active tab URL matches one of these domains
--   titles:  window title contains one of these strings, used only when the
--            URL is unavailable or has no parseable domain
--   key:     key to emit, with the modifiers in `flags`
--   mode:    "hold" sends a stroke on press and release, for shortcuts
--            that toggle recording; "toggle" sends a stroke only on press;
--            "keyhold" holds the emitted key until the input is released,
--            for shortcuts that natively support hold-to-record
--
-- OpenWhisper always receives the original held input unchanged. Its
-- hold/toggle preference is configured in OpenWhisper, not these routes.
local ROUTES = {
  {
    -- Configured in ChatGPT keyboard settings. Cmd+Shift+D would conflict
    -- with the browser's "bookmark all tabs" shortcut.
    target = "ChatGPT",
    mode = "hold",
    domains = { "chatgpt.com", "chat.openai.com" },
    titles = { "chatgpt" },
    key = "d",
    flags = { ctrl = true, shift = true },
  },
  {
    target = "Gemini",
    mode = "hold",
    domains = { "gemini.google.com" },
    titles = { "google gemini" },
    key = "d",
    flags = { cmd = true, shift = true },
  },
}

for _, route in ipairs(ROUTES) do
  assert(route.mode == "hold" or route.mode == "toggle" or route.mode == "keyhold",
    "dictation-router: unknown mode for " .. route.target .. ": " .. tostring(route.mode))
end

local activePress = nil

local function log(message)
  if DEBUG then
    print("[dictation] " .. message)
  end
end

----------------------------------------------------------------------
-- URL helpers
----------------------------------------------------------------------

local function normalizeURL(value)
  if value == nil then
    return nil
  end

  local stringValue = tostring(value)
  return stringValue:match("(https?://[^%s]+)") or stringValue
end

local function getDomainFromURL(url)
  if not url then
    return nil
  end

  local domain = url:match("^https?://([^/:?#]+)")
  return domain and domain:lower() or nil
end

local function matchDomain(domain, expected)
  if not domain then
    return false
  end

  domain = domain:lower()
  expected = expected:lower()

  return domain == expected
      or domain:sub(-(expected:len() + 1)) == "." .. expected
end

----------------------------------------------------------------------
-- Routing table lookup
----------------------------------------------------------------------

local function getRoute(context)
  for _, route in ipairs(ROUTES) do
    for _, domain in ipairs(route.domains or {}) do
      if matchDomain(context.domain, domain) then
        return route, "domain"
      end
    end

    if context.domain == nil then
      local title = context.title:lower()

      for _, expected in ipairs(route.titles or {}) do
        if title:find(expected:lower(), 1, true) then
          return route, "title"
        end
      end
    end
  end

  return nil
end

----------------------------------------------------------------------
-- Chrome URL
----------------------------------------------------------------------

local function getChromeURL()
  local ok, result = hs.osascript.applescript([[
        tell application "Google Chrome"
            if (count of windows) = 0 then
                return ""
            end if

            try
                return URL of active tab of front window
            on error
                return ""
            end try
        end tell
    ]])

  if ok and result and result ~= "" then
    return tostring(result)
  end

  return nil
end

----------------------------------------------------------------------
-- Firefox URL
----------------------------------------------------------------------

local function getAXAttribute(element, attribute)
  if not element then
    return nil
  end

  local ok, value = pcall(function()
    return element:attributeValue(attribute)
  end)

  return ok and value or nil
end

local function getFirefoxURLFromFocusedElement(axApp)
  local element = getAXAttribute(axApp, "AXFocusedUIElement")

  for _ = 1, 40 do
    if not element then
      break
    end

    if getAXAttribute(element, "AXRole") == "AXWebArea" then
      local url = getAXAttribute(element, "AXURL")
      if url then
        return normalizeURL(url)
      end
    end

    element = getAXAttribute(element, "AXParent")
  end

  return nil
end

local function getFirefoxURLFromWindow(axApp)
  local root = getAXAttribute(axApp, "AXFocusedWindow")
  if not root then
    return nil
  end

  local queue = { root }
  local position = 1
  local inspected = 0
  local maxElements = 1500

  while position <= #queue and inspected < maxElements do
    local element = queue[position]
    position = position + 1
    inspected = inspected + 1

    if getAXAttribute(element, "AXRole") == "AXWebArea" then
      local url = getAXAttribute(element, "AXURL")
      if url then
        return normalizeURL(url)
      end
    end

    local children = getAXAttribute(element, "AXChildren")
    if type(children) == "table" then
      for _, child in ipairs(children) do
        queue[#queue + 1] = child
      end
    end
  end

  return nil
end

local function getFirefoxURL(app)
  local axApp = hs.axuielement.applicationElement(app)

  if not axApp then
    return nil
  end

  return getFirefoxURLFromFocusedElement(axApp)
      or getFirefoxURLFromWindow(axApp)
end

----------------------------------------------------------------------
-- Current browser context
----------------------------------------------------------------------

local function getBrowserContext()
  local app = hs.application.frontmostApplication()

  if not app then
    return nil
  end

  local bundle = app:bundleID()

  if bundle ~= CHROME and bundle ~= FIREFOX then
    return nil
  end

  local window = hs.window.frontmostWindow()
  local title = window and window:title() or ""
  local url

  if bundle == CHROME then
    url = getChromeURL()
  elseif bundle == FIREFOX then
    url = getFirefoxURL(app)
  end

  return {
    app = app,
    bundle = bundle,
    title = title,
    url = url,
    domain = getDomainFromURL(url)
  }
end

----------------------------------------------------------------------
-- Emit browser shortcut
--
-- setFlags() is intentional. The trigger modifiers are still held by
-- Karabiner, so we explicitly define the modifiers attached to the key.
----------------------------------------------------------------------

local function postExactKeyEvent(key, flags, isDown, app)
  local event = hs.eventtap.event.newKeyEvent({}, key, isDown)
  event:setFlags(flags)
  event:post(app)
end

-- Serialize strokes so a quick release cannot post a second keyDown before
-- the first stroke's keyUp. Each queued stroke retains its destination app.
local shortcutQueue = {}
local shortcutInFlight = false

local function postNextShortcut()
  if shortcutInFlight or #shortcutQueue == 0 then
    return
  end

  local shortcut = table.remove(shortcutQueue, 1)
  shortcutInFlight = true
  postExactKeyEvent(shortcut.key, shortcut.flags, true, shortcut.app)

  hs.timer.doAfter(0.02, function()
    postExactKeyEvent(shortcut.key, shortcut.flags, false, shortcut.app)
    shortcutInFlight = false
    postNextShortcut()
  end)
end

local function postExactKeyStroke(key, flags, app)
  shortcutQueue[#shortcutQueue + 1] = { key = key, flags = flags, app = app }
  postNextShortcut()
end

----------------------------------------------------------------------
-- Shortcut helpers
----------------------------------------------------------------------

local MODIFIER_ORDER = { "cmd", "ctrl", "alt", "shift", "fn" }
local MODIFIER_LABELS = {
  cmd = "Cmd",
  ctrl = "Ctrl",
  alt = "Alt",
  shift = "Shift",
  fn = "Fn",
}

local function formatShortcutLabel(key, flags)
  local parts = {}

  for _, name in ipairs(MODIFIER_ORDER) do
    if flags[name] then
      parts[#parts + 1] = MODIFIER_LABELS[name]
    end
  end

  parts[#parts + 1] = key:upper()
  return table.concat(parts, "+")
end

----------------------------------------------------------------------
-- Trigger interception
----------------------------------------------------------------------

local eventTypes = hs.eventtap.event.types
local eventProperties = hs.eventtap.event.properties
local triggerKeyCode = assert(
  hs.keycodes.map[KEYBIND.key],
  "dictation-router: unknown trigger key: " .. tostring(KEYBIND.key)
)
local triggerFlags = {}
for _, modifier in ipairs(KEYBIND.mods) do
  triggerFlags[modifier] = true
end
local triggerLabel = formatShortcutLabel(KEYBIND.key, triggerFlags)
local ignoreImplicitFn = KEYBIND.key:match("^f%d+$") ~= nil and not triggerFlags.fn

---@diagnostic disable-next-line: lowercase-global
dictationEventTap = hs.eventtap.new({
  eventTypes.keyDown,
  eventTypes.keyUp
}, function(event)
  if event:getKeyCode() ~= triggerKeyCode then
    return false
  end

  local eventType = event:getType()
  local flags = event:getFlags()
  local isRepeat =
      event:getProperty(eventProperties.keyboardEventAutorepeat) ~= 0

  if eventType == eventTypes.keyUp then
    local press = activePress
    activePress = nil
    if not press then
      return false
    end

    local route = press.route
    if route.mode == "hold" then
      postExactKeyStroke(route.key, route.flags, press.app)
    elseif route.mode == "keyhold" then
      postExactKeyEvent(route.key, route.flags, false, press.app)
    end
    return true
  end

  -- Latch the selected route for the entire press. Repeats and duplicate
  -- downs must not restart recording or change the release destination.
  if isRepeat or activePress then
    return activePress ~= nil
  end

  -- getFlags() returns a separate Lua table; removing Fn here does not
  -- change the original event delivered to OpenWhisper.
  if ignoreImplicitFn then
    flags.fn = nil
  end

  if not flags:containExactly(KEYBIND.mods) then
    log("input rejected | expected " .. triggerLabel
      .. " | received " .. formatShortcutLabel(KEYBIND.key, flags))
    return false
  end

  local context = getBrowserContext()
  local route, matchKind = nil, nil

  if context then
    route, matchKind = getRoute(context)
  end

  if not route then
    log("route -> OpenWhisper | passing original "
      .. triggerLabel .. " through")
    return false
  end

  activePress = { route = route, app = context.app }
  log(string.format(
    "route -> %s%s | browser=%s | domain=%s | mode=%s | swallow %s | emit %s",
    route.target,
    matchKind == "title" and " (title fallback)" or "",
    BROWSER_NAMES[context.bundle] or context.bundle,
    context.domain or "<none>",
    route.mode,
    triggerLabel,
    formatShortcutLabel(route.key, route.flags)
  ))
  if route.mode == "keyhold" then
    postExactKeyEvent(route.key, route.flags, true, context.app)
  else
    postExactKeyStroke(route.key, route.flags, context.app)
  end
  return true
end):start()
