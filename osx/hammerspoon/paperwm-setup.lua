---
-- PaperWM tiling window manager with ActiveSpace, WarpMouse and Swipe add-ons.
--
-- Spoons are installed in ./Spoons by `make hammerspoon-spoons`.
--
-- NOTE: this file must not be named paperwm.lua. macOS is case-insensitive, so
-- require("PaperWM") inside hs.loadSpoon would resolve to this file instead of
-- Spoons/PaperWM.spoon.
--
-- Requires, in System Settings > Desktop & Dock > Mission Control:
--   - "Automatically rearrange Spaces based on most recent use" off
--   - "Displays have separate Spaces" on
-- WarpMouse expects displays arranged vertically.
--

---@diagnostic disable: undefined-global

local M = {}

local function load(name)
  local ok, result = pcall(hs.loadSpoon, name)
  if not ok or not result then
    hs.alert.show(name .. ".spoon missing: run `make hammerspoon-spoons`")
    return nil
  end
  return result
end

-- Actions.actions() in Spoons/PaperWM.spoon/actions.lua.
-- https://github.com/mogenson/PaperWM.spoon/blob/82f5dde20d40cf1bdef18ab92b2b847f16f368a3/config.lua#L7
local function bindings(hyper)
  local hyperShift = { "cmd", "alt", "shift" }
  local hyperCtrl = { "ctrl", "cmd", "alt" }
  -- local hyperCtrlShift = { "ctrl", "cmd", "alt", "shift" }

  return {
    -- Lifecycle
    -- start_events = unbound (PaperWM:start() is called below)
    -- stop_events = { hyperShift, "q" },  -- default; unbound to avoid stopping by accident
    -- dump_state = { hyperShift, "d" },  -- default; debugging only
    -- -- refresh/retile windows (forcedly)
    refresh_windows = { hyperShift, "w" }, -- default; shift+r is cycle_height
    refresh_windows_forcedly = { hyperShift, "t" },

    -- Floating
    -- toggle_floating = { hyperShift, "escape" },
    -- move the focused window into / out of the tiling layer
    toggle_floating = { hyperShift, "f" },
    -- raise all floating windows on top of tiled windows
    -- focus_floating = { hyperShift, "f" },

    -- Focus adjacent window
    focus_left = { hyper, "left" },
    focus_right = { hyper, "right" },
    -- focus_up = { hyper, "up" },
    -- focus_down = { hyper, "down" },

    -- switch windows by cycling forward/backward
    -- (forward = down or right, backward = up or left)
    -- focus_prev = unbound (hyper+k)
    -- focus_next = unbound (hyper+j is the VLC launcher)
    -- focus_prev = { hyper, "up" },
    -- focus_next = { hyper, "down" },

    -- Focus window by position in the current space
    focus_window_first = { hyper, "home" },
    focus_window_last = { hyper, "end" },

    -- Swap window with adjacent window
    swap_left = { hyperShift, "left" },
    swap_right = { hyperShift, "right" },
    -- swap_up = { hyperShift, "up" },
    -- swap_down = { hyperShift, "down" },

    -- Move focused window to another screen
    -- move_window_l = { hyperShift, "left" },
    -- move_window_r = { hyperShift, "right" },
    move_window_u = { hyperShift, "up" },
    move_window_d = { hyperShift, "down" },

    -- Position and resize
    center_window = { hyperShift, "m" }, -- default hyper+c is the Calculator launcher
    anchor_window_left = { hyper, "[" },
    anchor_window_right = { hyper, "]" },
    full_width = { hyper, "z" }, -- default hyper+f
    cycle_width = { hyper, "r" },
    cycle_height = { hyperShift, "r" },
    reverse_cycle_width = { hyperCtrl, "r" },
    -- reverse_cycle_height = { hyperCtrlShift, "r" },
    increase_width = { hyper, "=" },
    decrease_width = { hyper, "-" },
    -- increase_height = unbound
    -- decrease_height = unbound

    -- Columns stack/unstack
    slurp_in = { hyperShift, "[" }, -- default hyper+i is the Firefox launcher
    barf_out = { hyperShift, "]" }, -- default hyper+o
    toggle_stack = { hyperShift, "s" },
    -- split_screen = unbound (default hyper+s is the Slack launcher)

    -- focus_window_1..9 = unbound (default cmd+shift+N clashes with screenshots)

    -- this is buggy, better to use the native shortcut
    -- -- Switch Mission Control space
    -- switch_recent_space = { hyper, "`" }, -- default ctrl+hyper+6
    -- switch_space_l = { hyper, "," },
    -- switch_space_r = { hyper, "." },
    -- switch_space_1 = { hyper, "1" },
    -- switch_space_2 = { hyper, "2" },
    -- switch_space_3 = { hyper, "3" },
    -- switch_space_4 = { hyper, "4" },
    -- switch_space_5 = { hyper, "5" },
    -- switch_space_6 = { hyper, "6" },
    -- switch_space_7 = { hyper, "7" },
    -- switch_space_8 = { hyper, "8" },
    -- switch_space_9 = { hyper, "9" },

    -- -- This won't work because of a bug
    -- Move focused window to another space
    -- move_window_1 = { hyperShift, "1" },
    -- move_window_2 = { hyperShift, "2" },
    -- move_window_3 = { hyperShift, "3" },
    -- move_window_4 = { hyperShift, "4" },
    -- move_window_5 = { hyperShift, "5" },
    -- move_window_6 = { hyperShift, "6" },
    -- move_window_7 = { hyperShift, "7" },
    -- move_window_8 = { hyperShift, "8" },
    -- move_window_9 = { hyperShift, "9" },
  }
end

-- Floating apps and windows, ported from the paneru configuration.
local function configureFilter(filter)
  for _, app in ipairs({
    "Calculator",
    "System Settings",
    "Activity Monitor",
    "Keychain Access",
    "Passwords",
    "Karabiner-Elements",
    "Karabiner-EventViewer",
    "Hammerspoon",
    "QtPass",
    "zoom.us",
  }) do
    filter:rejectApp(app)
  end

  local pip = { "^[Pp]icture[- ][Ii]n[- ][Pp]icture$" }
  filter:setAppFilter("Google Chrome", { rejectTitles = pip })
  filter:setAppFilter("Firefox", { rejectTitles = pip })

  filter:setAppFilter("Finder", {
    rejectTitles = {
      "^Info$",
      " Info$",
      "^Inspector$",
      "^Copy",
      "^Move",
      "^Connect to Server$",
      "^Go to Folder$",
    },
  })
end

-- tileSpace anchors on the focused window even when window_filter rejects it
-- (e.g. the Hammerspoon console), then logs "anchor index not found" and skips
-- tiling. Anchor on the first visible tiled window in that case.
local function anchorOnTrackedWindow(paperwm)
  local tileSpace = paperwm.tiling.tileSpace

  paperwm.tiling.tileSpace = function(space, anchor_window)
    if not anchor_window then
      local focused = hs.window.focusedWindow()
      if focused and not paperwm.state.windowIndex(focused) and not paperwm.floating.isFloating(focused) then
        local screen = hs.screen(hs.spaces.spaceDisplay(space))
        if screen then
          anchor_window = paperwm.windows.getFirstVisibleWindow(space, screen:frame())
        end
      end
    end
    return tileSpace(space, anchor_window)
  end
end

-- Windows tiled on a portrait screen take its full width.
local function fullWidthOnPortrait(paperwm)
  local getAppDefaultWidth = paperwm.windows.getAppDefaultWidth

  paperwm.windows.getAppDefaultWidth = function(window)
    local screen = window:screen()
    if screen then
      local frame = screen:frame()
      if frame.h > frame.w then
        return paperwm.windows.getCanvas(screen).w
      end
    end
    return getAppDefaultWidth(window)
  end
end

-- Focus adjacent window with a three-finger swipe, using natural scrolling.
local function startSwipe(actions)
  local swipe = load("Swipe")
  if not swipe then
    return
  end

  local current_id, threshold
  swipe:start(3, function(direction, distance, id)
    if id == current_id then
      if distance > threshold then
        threshold = math.huge -- trigger once per swipe

        if direction == "left" then
          actions.focus_right()
        elseif direction == "right" then
          actions.focus_left()
        elseif direction == "up" then
          actions.focus_down()
        elseif direction == "down" then
          actions.focus_up()
        end
      end
    else
      current_id = id
      threshold = 0.2 -- swipe distance > 20% of trackpad size
    end
  end)
end

function M.start(hyper)
  local paperwm = load("PaperWM")
  if not paperwm then
    return
  end

  paperwm.window_gap = { top = 2, bottom = 2, left = 4, right = 4 }
  paperwm.window_ratios = { 0.25, 0.33, 0.50, 0.66, 0.75 }
  paperwm.center_mouse = true
  -- Four-finger swipe scrolls the strip; three fingers are used by Swipe.spoon.
  paperwm.swipe_fingers = 4
  paperwm.drag_window = hyper

  configureFilter(paperwm.window_filter)
  -- anchorOnTrackedWindow(paperwm)
  fullWidthOnPortrait(paperwm)
  paperwm:bindHotkeys(bindings(hyper))
  paperwm:start()

  local activeSpace = load("ActiveSpace")
  if activeSpace then
    activeSpace:start()
  end

  local warpMouse = load("WarpMouse")
  if warpMouse then
    warpMouse:start()
  end

  startSwipe(paperwm.actions.actions())
end

return M
