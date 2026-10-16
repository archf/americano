---@diagnostic disable: undefined-global

print("Enabling AeroSpace run-or-raise")

-- Remove ctrl to avoid triggering ctrl+w in Neovim.
local hyper = { "cmd", "alt" }

local aerospace = require("lib.aerospace")
local window_cycle = require("lib.window-cycle")

-- Application shortcuts.
--
-- Hyper+key cycles through the application's windows in most-recently-used
-- order; see lib/window-cycle.lua. A tap toggles between the two most recent
-- windows; holding Hyper and pressing the key again steps further.
--
-- Windows already visible in AeroSpace come first, then hidden ones. This
-- matters on a multi-monitor setup: focusing a window on a hidden workspace
-- makes AeroSpace show that workspace on its monitor, replacing the one
-- displayed there, so a tap never does that while a visible window exists.

-- APPS entries are either an application name or
-- { name = "...", bundle_id = "..." }.
--
local APPS = {
  J = { name = "VLC", bundle_id = "org.videolan.vlc" },                                         -- [J]ukebox
  A = { name = "VLC", bundle_id = "org.videolan.vlc" },                                         -- [A]udio
  -- M = "Messages", --
  C = { name = "Calculator", bundle_id = "com.apple.calculator" },                              -- [C]alculator
  E = { name = "Gmail", bundle_id = "com.google.Chrome.app.fmgjjmmmlfnkbppncabfkddbjimcfncm" }, -- [E]mail
  G = { name = "Google Chrome", bundle_id = "com.google.Chrome" },                              -- [G]oogle Chrome
  I = { name = "Firefox", bundle_id = "org.mozilla.firefox" },                                  -- [I]nternet
  L = { name = "Finder", bundle_id = "com.apple.finder" },                                      -- [l]s
  -- P = { name = "QtPass", bundle_id = "org.qtpass" },                                            -- [P]Assword
  S = { name = "Slack", bundle_id = "com.tinyspeck.slackmacgap" },                              -- [S]lack
  T = { name = "Alacritty", bundle_id = "org.alacritty" },                                      -- Terminal
  V = { name = "Zoom", bundle_id = "us.zoom.xos" },                                             -- VideoCall
  -- O = "Settings",      -- Options // Settings
  -- Z = "Zoom",
  -- K = "Karabiner-Elements",
  -- ['\\'] = "Hammerspoon", -- opens the Hammerspoon console. useful
}

local function normalize(def)
  if type(def) == "string" then
    return { name = def }
  end

  return def
end

local function get_application(def)
  if def.bundle_id then
    return hs.application.get(def.bundle_id)
  end

  return hs.application.get(def.name) or hs.application.find(def.name)
end

local function launch(def)
  if def.bundle_id then
    hs.application.launchOrFocusByBundleID(def.bundle_id)
  else
    hs.application.launchOrFocus(def.name)
  end
end

local cycle = window_cycle.new({
  modifiers = hyper,

  group = function(window)
    return window.visible and 0 or 1
  end,

  resolve = function(def, done)
    local app = get_application(def)

    if not app then
      done({})
      return
    end

    local opts = {}
    local bundle_id = def.bundle_id or app:bundleID()

    if bundle_id then
      opts.bundle_id = bundle_id
    else
      opts.pid = app:pid()
    end

    aerospace.list_windows(opts, function(windows, err)
      if not windows then
        print("AeroSpace window query failed:", err)
      elseif #windows == 0 then
        -- Running application with no AeroSpace window yet.
        app:activate(false)
      end

      done(windows)
    end)
  end,

  focus = function(window, def)
    aerospace.focus_window(window.id, function(_, err)
      if err then
        hs.alert.show("Could not focus " .. def.name)
        print(err)
      end
    end)
  end,
})

-- Keep a reference so the event stream is not garbage collected.
local focus_events = aerospace.subscribe({ "focus-changed" }, function(event)
  if event._event == "focus-changed" then
    cycle.observe_focus(event.windowId)
  end
end)

-- Stop the subscribe process on reload, or every reload leaks one.
hs.shutdownCallback = function()
  focus_events.stop()
end

for key, def in pairs(APPS) do
  def = normalize(def)

  hs.hotkey.bind(hyper, key, function()
    if not aerospace.available() then
      local app = get_application(def)

      if app then
        app:activate(false)
      else
        launch(def)
      end

      return
    end

    if not get_application(def) then
      cycle.release()
      launch(def)
      return
    end

    cycle.press(key, def)
  end)
end

-- Close the focused window without quitting the whole application.
hs.hotkey.bind(hyper, "q", function()
  local window = hs.window.focusedWindow()

  if window then
    window:close()
  end
end)

return true
