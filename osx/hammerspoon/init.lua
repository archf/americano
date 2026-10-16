---@diagnostic disable: undefined-global

-- Enables the `hs` command-line tool.
require("hs.ipc")

-- -------------------------
-- Automatic config reload.
-- -------------------------
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
--
-- Entries are an application name, or { name = ..., bundle_id = ... }.
-- The bundle ID avoids fuzzy name matching when finding and launching apps.
-- Overriden in osx/hammerspoon/run-or-raise-aerospace.lua
APPS = {
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

local aerospaceBundleID = "bobko.aerospace"

local function aerospaceIsRunning()
  return #hs.application.applicationsForBundleID(aerospaceBundleID) > 0
end

if aerospaceIsRunning() then
  require("run-or-raise-aerospace")
else
  require("run-or-raise")
end

local aerospaceWatcher = hs.application.watcher.new(function(_, event, app)
  if not app or app:bundleID() ~= aerospaceBundleID then
    return
  end

  if event == hs.application.watcher.launched
      or event == hs.application.watcher.terminated then
    hs.reload()
  end
end)

aerospaceWatcher:start()

require("dictation-router")
-- require("paperwm-setup").start(hyper)
-- require("focus-follow-mouse")
