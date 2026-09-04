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
