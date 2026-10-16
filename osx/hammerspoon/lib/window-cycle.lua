---@diagnostic disable: undefined-global

-- Hold-to-cycle window switching in most-recently-used (MRU) order.
--
-- A press starts a session: the application's windows are snapshotted in MRU
-- order and the window after the focused one is focused, so a tap toggles
-- between the two most recent windows. Further presses while the modifiers
-- stay held step through the same snapshot. Releasing the modifiers ends the
-- session and moves only the final window to the front of the MRU list, so
-- the windows passed through keep their order.

local M = {}

local mru_limit = 200
-- Ignore late focus events for windows passed through during a session.
local settle_seconds = 1
-- Safety net in case a modifier release is never observed.
local idle_seconds = 5

local function remove_value(list, value)
  for index, item in ipairs(list) do
    if item == value then
      table.remove(list, index)
      return
    end
  end
end

-- opts:
--   modifiers  => hotkey modifiers; releasing any of them ends the session
--   resolve    => fn(def, done): calls done(windows) with the candidate
--                 windows, tables with an `id` field; may be asynchronous.
--                 Unranked windows keep the given order.
--   focus      => fn(window, def)
--   group      => optional fn(window) -> number; lower groups come first,
--                 MRU order applies within a group
--   focused_id => optional fn() -> id of the focused window; defaults to the
--                 last id passed to observe_focus
--   presorted  => resolve already returns MRU order (e.g. z-order); skip
--                 the internal MRU list and grouping
function M.new(opts)
  local self = {}

  local mru = {}
  local current_id = nil
  -- Session that receives presses.
  local session = nil
  -- Sessions not committed yet; MRU updates are paused while any exists.
  local open_sessions = 0
  local settle = nil
  local release_tap
  local idle_timer

  local function promote(id)
    remove_value(mru, id)
    table.insert(mru, 1, id)

    if #mru > mru_limit then
      table.remove(mru)
    end
  end

  -- Feed every focus change; id is nil when nothing is focused.
  function self.observe_focus(id)
    current_id = id

    if not id or open_sessions > 0 then
      return
    end

    if settle then
      if hs.timer.secondsSinceEpoch() > settle.deadline then
        settle = nil
      elseif settle.ids[id] then
        return
      end
    end

    promote(id)
  end

  local function order(windows)
    if opts.presorted then
      return windows
    end

    local rank = {}

    for index, id in ipairs(mru) do
      rank[id] = index
    end

    local items = {}

    for index, window in ipairs(windows) do
      items[index] = {
        window = window,
        group = opts.group and opts.group(window) or 0,
        rank = rank[window.id] or math.huge,
        position = index,
      }
    end

    table.sort(items, function(a, b)
      if a.group ~= b.group then
        return a.group < b.group
      end

      if a.rank ~= b.rank then
        return a.rank < b.rank
      end

      return a.position < b.position
    end)

    local ordered = {}

    for index, item in ipairs(items) do
      ordered[index] = item.window
    end

    return ordered
  end

  local function commit(s)
    if s.committed or not (s.ended and s.windows) then
      return
    end

    s.committed = true
    open_sessions = open_sessions - 1

    if s.target_id then
      s.visited[s.target_id] = nil
      settle = {
        ids = s.visited,
        deadline = hs.timer.secondsSinceEpoch() + settle_seconds,
      }
      promote(s.target_id)
    end
  end

  local function advance(s, steps)
    local count = #s.windows

    if count == 0 or steps == 0 then
      return
    end

    s.index = (s.index + steps - 1) % count + 1

    local window = s.windows[s.index]

    if window.id == (s.target_id or s.start_id) then
      return
    end

    s.target_id = window.id
    s.visited[window.id] = true
    opts.focus(window, s.def)
  end

  local function release()
    local s = session

    if not s then
      return
    end

    session = nil
    release_tap:stop()
    idle_timer:stop()
    s.ended = true
    commit(s)
  end

  self.release = release

  local function modifiers_held(flags)
    for _, modifier in ipairs(opts.modifiers) do
      if not flags[modifier] then
        return false
      end
    end

    return true
  end

  release_tap = hs.eventtap.new(
    { hs.eventtap.event.types.flagsChanged },
    function(event)
      if not modifiers_held(event:getFlags()) then
        release()
      end

      return false
    end
  )

  idle_timer = hs.timer.delayed.new(idle_seconds, release)

  function self.press(key, def)
    if session and session.key ~= key then
      release()
    end

    if session then
      idle_timer:start()

      if session.windows then
        advance(session, 1)
      else
        session.steps = session.steps + 1
      end

      return
    end

    local s = {
      key = key,
      def = def,
      steps = 1,
      index = 0,
      visited = {},
      start_id = opts.focused_id and opts.focused_id() or current_id,
    }

    session = s
    open_sessions = open_sessions + 1
    release_tap:start()
    idle_timer:start()

    -- The modifiers may already be up when the tap starts.
    if not modifiers_held(hs.eventtap.checkKeyboardModifiers()) then
      release()
    end

    opts.resolve(def, function(windows)
      s.windows = order(windows or {})

      for index, window in ipairs(s.windows) do
        if window.id == s.start_id then
          s.index = index
          break
        end
      end

      advance(s, s.steps)
      s.steps = 0
      commit(s)
    end)
  end

  return self
end

return M
