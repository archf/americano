-- Automatic config reload.
function reloadConfig(files)
  doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon config loaded")

-- if you want to use a different keyboard combo, define it here.
-- local hyper = {"cmd", "alt"}
-- Remove ctrl to avoid triggering ctrl+w in neovim
local hyper = { "cmd", "alt" }

-- I: Internet, IRC
-- M: Mail, Messages, Music
-- S: Signal, Slack
-- C: Calendar, Google Chrome
-- F: File Explorer
-- V: VideoCall
-- G: Gitx
--
-- NOTE:
--
-- Apps:
--  - [E] Gmail
--  - [C] Calculator
--  - [A] Calendar | Agenda ? | Audio
--  - [L] File Explorer | Library
--  - [P] QtPass
--  - [S] Slack
--  - [G] Google Chrome
--  - [ ] Messages for Web | Web messages | sms
--  - [ ] Signal
--  - [T] Terminal
--  - [J] Rhythmbox | VLC  [Music | Jukebox  ]
--  - [V] Zoom | or other videcocall app
--  - [I] Firefox [Internet  Browser]
--  - [ ] Gitk | Gitx [Git log viewer] - maybe not useful enough
--  - [B] Calibre  [books]
--
--
-- Free: L I O R E D W U
-- Behaviors:
--  F: Toggle Fullscreen -> set in OS
--  A: Toggle all workspaces -> to disable
--  Q: Close Window -> Set in OS only if multiple mappings are allowed
--
--  Left/Right arrow -> snap left/right (configure in rectangle or in Window
--  Manager settings)
--
-- define your own shortcut list here
local windows = {
  J = "VLC",           -- [J]ukebox
  A = "VLC",           -- [A]udio
  -- M = "Messages", --
  C = "Calculator",    -- [C]alculator
  E = "Gmail",         -- [E]mail
  G = "Google Chrome", -- [G]oogle Chrome
  I = "Firefox",       -- [I]nternet
  L = "Finder",        -- [l]s
  P = "QtPass",        -- [P]Assword
  S = "Slack",         -- [S]lack
  T = "Alacritty",     -- Terminal
  V = "Zoom",          -- VideoCall
  O = "Settings",      -- Options // Settings
  Z = "Zoom",
  K = "Karabiner-Elements",
  -- ['\\'] = "Hammerspoon", -- opens the Hammerspoon console. useful
}

-- if the app has to be launched by a different name
-- than the one the windows are found by, this list
-- will take precedence when opening the app.
local windowLaunchNames = {
  -- currently just VS Code
  -- V = "Visual Studio Code",
}

local lastKey = ''
local lastKeyTime = 0
local lastWindowIndex = 1
local appWindows = nil
local doubleKeyThreshold = 1.2
-- set up the binding for each key combo
for key, appName in pairs(windows) do
  hs.hotkey.bind(hyper, key, function()
    local keyTime = hs.timer.secondsSinceEpoch()
    -- for a repeated key press, cycle through windows
    if key == lastKey and keyTime - lastKeyTime < doubleKeyThreshold then
      if appWindows == nil then
        -- find the switchable windows
        local app = hs.application.find(appName)
        if app then
          appWindows = hs.fnutils.filter(app:allWindows(), function(w)
            return w:isStandard()
          end)
        end
      end

      if appWindows and #appWindows > 0 then
        -- increment and loop
        lastWindowIndex = lastWindowIndex % #appWindows + 1

        -- focus the window (will switch to its space)
        appWindows[lastWindowIndex]:focus()
      end
    else
      -- switch to window
      appWindows = nil
      lastWindowIndex = 1

      local app = hs.application.get(appName)
      if app then
        -- get the main window and focus it (will switch to its space)
        -- This allows effectively switching back to the previous space. If
        -- not, it would go only focus the window appname on the single
        -- space 2nd monitor
        -- app:activate(false)

        local mainWindow = app:mainWindow()
        if mainWindow then
          mainWindow:focus()
        else
          app:activate(false)
        end

      else
        local launchName = windowLaunchNames[key] or appName
        hs.application.launchOrFocus(launchName)
      end
    end

    lastKey = key
    lastKeyTime = keyTime
  end)
end

-- Bind hyper+q to close the current window/app
hs.hotkey.bind(hyper, "q", function()
  local win = hs.window.focusedWindow()
  if win then
    local app = win:application()
    if app then
      -- Close the window
      win:close()
      -- Alternative: Quit the entire application instead
      -- app:kill()
    end
  end
end)

-- hs.hotkey.bind(hyper, "f", function()
--   local win = hs.window.focusedWindow()
--   if win then
--     -- Toggles the window between zoomed/maximized state and original size
--     win:toggleFullScreen()
--   end
-- end
-- )
-- -- -- Load the MouseFollowsFocus Spoon
-- -- hs.loadSpoon("MouseFollowsFocus")
-- -- -- Start the Spoon
-- -- spoon.MouseFollowsFocus:start()

-- -- Optional: Define a hotkey to quickly stop/start the feature
-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "z", function()
--     if spoon.MouseFollowsFocus:isRunning() then
--         spoon.MouseFollowsFocus:stop()
--         hs.notify.show("MouseFollowsFocus", "Status", "Stopped")
--     else
--         spoon.MouseFollowsFocus:start()
--         hs.notify.show("MouseFollowsFocus", "Status", "Started")
--     end
-- end)

-- -- Load Hammerspoon Spoon installer
-- hs.loadSpoon("SpoonInstall")
-- -- Install and configure MouseFollowsFocus
-- spoon.SpoonInstall:andUse("MouseFollowsFocus", {
--     start = true,
--     config = {
--         followMouse = true
--     }
-- })

---
-- Context-aware dictation router
--
-- Karabiner always generates the real OpenWhisper shortcut:
--
--     Cmd+F15 DOWN
--          ... held ...
--     Cmd+F15 UP
--
-- Hammerspoon observes that event:
--
--   ChatGPT
--     -> consume Cmd+F15
--     -> emit Ctrl+Shift+D once
--
--   Gemini
--     -> consume Cmd+F15
--     -> emit Cmd+Shift+D once
--
--   everything else
--     -> do NOT consume anything
--     -> original Cmd+F15 reaches OpenWhisper untouched
--

local CHROME = "com.google.Chrome"
local FIREFOX = "org.mozilla.firefox"

local interceptedTarget = nil

local function dictationLog(message)
    print("[dictation] " .. message)
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

local function domainFromURL(url)
    if not url then
        return nil
    end

    local domain = url:match("^https?://([^/:?#]+)")

    return domain and domain:lower() or nil
end

local function domainMatches(domain, expected)
    if not domain then
        return false
    end

    domain = domain:lower()
    expected = expected:lower()

    return domain == expected
        or domain:sub(-(expected:len() + 1)) == "." .. expected
end

----------------------------------------------------------------------
-- Chrome URL
----------------------------------------------------------------------

local function chromeURL()
    local ok, result = hs.osascript.applescript([[
        tell application "Google Chrome"
            if (count of windows) = 0 then
                return ""
            end if

            return URL of active tab of front window
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

local function axAttribute(element, attribute)
    if not element then
        return nil
    end

    local ok, value = pcall(function()
        return element:attributeValue(attribute)
    end)

    return ok and value or nil
end

local function firefoxURLFromFocusedElement(axApp)
    local element = axAttribute(axApp, "AXFocusedUIElement")

    for _ = 1, 40 do
        if not element then
            break
        end

        if axAttribute(element, "AXRole") == "AXWebArea" then
            local url = axAttribute(element, "AXURL")
            if url then
                return normalizeURL(url)
            end
        end

        element = axAttribute(element, "AXParent")
    end

    return nil
end

local function firefoxURLFromWindow(axApp)
    local root = axAttribute(axApp, "AXFocusedWindow")
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

        if axAttribute(element, "AXRole") == "AXWebArea" then
            local url = axAttribute(element, "AXURL")
            if url then
                return normalizeURL(url)
            end
        end

        local children = axAttribute(element, "AXChildren")
        if type(children) == "table" then
            for _, child in ipairs(children) do
                queue[#queue + 1] = child
            end
        end
    end

    return nil
end

local function firefoxURL(app)
    local axApp = hs.axuielement.applicationElement(app)

    if not axApp then
        return nil
    end

    return firefoxURLFromFocusedElement(axApp)
        or firefoxURLFromWindow(axApp)
end

----------------------------------------------------------------------
-- Current browser context
----------------------------------------------------------------------

local function currentBrowserContext()
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
        url = chromeURL()
    elseif bundle == FIREFOX then
        url = firefoxURL(app)
    end

    return {
        bundle = bundle,
        title = title,
        url = url,
        domain = domainFromURL(url)
    }
end

----------------------------------------------------------------------
-- Emit browser shortcut
--
-- setFlags() is intentional. Cmd is still held by Karabiner as part
-- of Cmd+F15, so we explicitly define the modifiers attached to D.
----------------------------------------------------------------------

local function exactKeyStroke(key, flags)
    local down = hs.eventtap.event.newKeyEvent({}, key, true)
    down:setFlags(flags)
    down:post()

    hs.timer.doAfter(0.02, function()
        local up = hs.eventtap.event.newKeyEvent({}, key, false)
        up:setFlags(flags)
        up:post()
    end)
end

----------------------------------------------------------------------
-- Cmd+F15 interception
----------------------------------------------------------------------

local eventTypes = hs.eventtap.event.types
local eventProperties = hs.eventtap.event.properties
local f15KeyCode = hs.keycodes.map.f15

dictationEventTap = hs.eventtap.new({
    eventTypes.keyDown,
    eventTypes.keyUp
}, function(event)
    if event:getKeyCode() ~= f15KeyCode then
        return false
    end

    local eventType = event:getType()

    if eventType == eventTypes.keyUp then
        if interceptedTarget then
            dictationLog("Cmd+F15 UP swallowed | target=" .. interceptedTarget)
            interceptedTarget = nil
            return true
        end
        return false
    end

    local flags = event:getFlags()
    if not flags.cmd then
        return false
    end

    if interceptedTarget then
        return true
    end

    local isRepeat = event:getProperty(eventProperties.keyboardEventAutorepeat) == 1
    if isRepeat then
        return false
    end

    local context = currentBrowserContext()
    if not context then
        return false
    end

    dictationLog(string.format(
        'Cmd+F15 DOWN | bundle="%s" | domain="%s" | url="%s" | title="%s"',
        context.bundle,
        context.domain or "<none>",
        context.url or "<none>",
        context.title or "<none>"
    ))

    if domainMatches(context.domain, "chatgpt.com") or
       domainMatches(context.domain, "chat.openai.com") then
        interceptedTarget = "chatgpt"
        dictationLog("route -> ChatGPT | swallow Cmd+F15 | emit Ctrl+Shift+D")
        exactKeyStroke("d", {ctrl = true, shift = true})
        return true
    end

    if domainMatches(context.domain, "gemini.google.com") then
        interceptedTarget = "gemini"
        dictationLog("route -> Gemini | swallow Cmd+F15 | emit Cmd+Shift+D")
        exactKeyStroke("d", {cmd = true, shift = true})
        return true
    end

    if context.bundle == FIREFOX and
       context.title:lower():find("google gemini", 1, true) then
        interceptedTarget = "gemini"
        dictationLog("route -> Gemini (title fallback) | swallow Cmd+F15 | emit Cmd+Shift+D")
        exactKeyStroke("d", {cmd = true, shift = true})
        return true
    end

    dictationLog("route -> OpenWhisper | passing original Cmd+F15 through")
    return false
end):start()
