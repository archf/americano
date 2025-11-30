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
  L = "Finder",        -- ls
  P = "QtPass",        --[P]Assword
  S = "Slack",
  T = "Alacritty",     -- Terminal
  V = "Zoom",          -- VideoCall
  O = "Settings",      -- Options // Settings
  Z = "Zoom",
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
