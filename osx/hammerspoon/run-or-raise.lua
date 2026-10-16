---@diagnostic disable: undefined-global

-- Remove ctrl to avoid triggering ctrl+w in neovim
local hyper = { "cmd", "alt" }

-- if the app has to be launched by a different name
-- than the one the windows are found by, this list
-- will take precedence when opening the app.
local windowLaunchNames = {
  -- currently just VS Code
  -- V = "Visual Studio Code",
}

local window_cycle = require("lib.window-cycle")

-- APPS entries are either an application name or
-- { name = "...", bundle_id = "..." }.
local function normalize(def)
  if type(def) == "string" then
    return { name = def }
  end

  return def
end

local function getApplication(def)
  if def.bundle_id then
    return hs.application.get(def.bundle_id)
  end

  return hs.application.get(def.name) or hs.application.find(def.name)
end

-- Front-to-back window IDs from the window server. This is the private helper
-- behind hs.window.orderedWindows(), which is ~200x slower because it also
-- builds a window object for every window of every application.
local function zOrder()
  local rank = {}

  if hs.window._orderedwinids then
    for index, id in ipairs(hs.window._orderedwinids()) do
      rank[id] = index
    end
  end

  return rank
end

-- Hyper+key cycles through the application's windows; see
-- lib/window-cycle.lua. Without AeroSpace the z-order is already
-- most-recently-used, so no focus tracking is needed. Windows on other Spaces
-- or minimized have no z-order and come last.
local cycle = window_cycle.new({
  modifiers = hyper,
  presorted = true,

  focused_id = function()
    local focusedWindow = hs.window.focusedWindow()
    return focusedWindow and focusedWindow:id()
  end,

  resolve = function(def, done)
    local app = getApplication(def)

    if not app then
      done({})
      return
    end

    local rank = zOrder()
    local windows = {}

    for _, w in ipairs(app:allWindows()) do
      if w:isStandard() then
        table.insert(windows, {
          id = w:id(),
          window = w,
          rank = rank[w:id()] or math.huge,
        })
      end
    end

    table.sort(windows, function(a, b)
      if a.rank ~= b.rank then
        return a.rank < b.rank
      end

      return a.id < b.id
    end)

    if #windows == 0 then
      app:activate(false)
    end

    done(windows)
  end,

  -- Focusing a window switches to its Space.
  focus = function(window)
    window.window:focus()
  end,
})

-- set up the binding for each key combo
for key, def in pairs(APPS) do
  def = normalize(def)

  hs.hotkey.bind(hyper, key, function()
    if getApplication(def) then
      cycle.press(key, def)
      return
    end

    cycle.release()

    local launchName = windowLaunchNames[key]
    if launchName then
      hs.application.launchOrFocus(launchName)
    elseif def.bundle_id then
      hs.application.launchOrFocusByBundleID(def.bundle_id)
    else
      hs.application.launchOrFocus(def.name)
    end
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

-- local hyperShift = { "cmd", "alt", "shift" }
-- local spaces = hs.spaces
--
-- -- Treat Spaces as one global numbered sequence across all displays.
-- local function getSpace(i)
--     local layout, err = spaces.allSpaces()
--     if not layout then
--         return nil, err
--     end
--
--     for _, screen in ipairs(hs.screen.allScreens()) do
--         local screenSpaces = layout[screen:getUUID()]
--
--         if screenSpaces then
--             if i <= #screenSpaces then
--                 return screenSpaces[i]
--             end
--
--             i = i - #screenSpaces
--         end
--     end
--
--     return nil, "Space does not exist"
-- end
--
-- local function moveFocusedWindowToSpace(i)
--     local win = hs.window.focusedWindow()
--     if not win then
--         return
--     end
--
--     local targetSpace, err = getSpace(i)
--     if not targetSpace then
--         hs.alert.show(err)
--         return
--     end
--
--     print(
--         "moving",
--         win:id(),
--         "from",
--         hs.inspect(spaces.windowSpaces(win)),
--         "to",
--         targetSpace,
--         "display",
--         spaces.spaceDisplay(targetSpace)
--     )
--
--     local ok, moveErr = spaces.moveWindowToSpace(win, targetSpace)
--
--     print("moveWindowToSpace:", ok, moveErr)
--
--     hs.timer.doAfter(0.25, function()
--         print("window now on:", hs.inspect(spaces.windowSpaces(win)))
--     end)
-- end
--
-- for i = 1, 9 do
--     hs.hotkey.bind(hyperShift, tostring(i), function()
--         moveFocusedWindowToSpace(i)
--     end)
-- end
