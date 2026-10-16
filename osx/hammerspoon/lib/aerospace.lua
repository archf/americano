---@diagnostic disable: undefined-global

-- Asynchronous AeroSpace client.
--
-- Never call AeroSpace synchronously from Hammerspoon: the server queries
-- every application through the accessibility API before answering, including
-- Hammerspoon. A blocked Hammerspoon main thread cannot reply, so each call
-- waits for the accessibility timeout (~4.5s instead of ~50ms).
--
-- The socket protocol is not usable directly: hs.socket crashes on Unix
-- socket connect, and hs.task drops output that is not valid UTF-8, which
-- includes the binary length prefixes. Commands therefore run through the
-- CLI with hs.task, one at a time, and events stream from `aerospace
-- subscribe`, whose output is JSON lines.

local M = {}

local command_timeout = 2
local subscribe_restart_delay = 2

local function find_aerospace()
  -- AEROSPACE_BIN may be unset; a nil first element would stop ipairs.
  local candidates = {
    os.getenv("AEROSPACE_BIN") or false,
    "/opt/homebrew/bin/aerospace",
    "/usr/local/bin/aerospace",
  }

  for _, path in ipairs(candidates) do
    if path and hs.fs.attributes(path, "mode") == "file" then
      return path
    end
  end

  return nil
end

local aerospace = find_aerospace()

function M.available()
  return aerospace ~= nil
end

local queue = {}
local running = nil

local function pump()
  if running or #queue == 0 then
    return
  end

  local job = table.remove(queue, 1)
  running = job

  job.task = hs.task.new(aerospace, function(rc, stdout, stderr)
    job.timer:stop()
    running = nil
    pump()

    if rc == 0 then
      job.callback(stdout or "")
    else
      job.callback(nil, string.format(
        "aerospace %s exited with %s: %s",
        job.args[1],
        tostring(rc),
        stderr or ""
      ))
    end
  end, job.args)

  job.timer = hs.timer.doAfter(command_timeout, function()
    if job.task:isRunning() then
      job.task:terminate()
    end
  end)

  if not job.task:start() then
    job.timer:stop()
    running = nil
    pump()
    job.callback(nil, "could not start aerospace")
  end
end

-- Queues an AeroSpace command; callback(output) or callback(nil, err).
--
-- opts.replace: a queued, not yet started command with the same key is
-- replaced, so bursts of the same command collapse into the latest one.
function M.run(args, callback, opts)
  callback = callback or function(_, err)
    if err then
      print(err)
    end
  end

  if not aerospace then
    callback(nil, "aerospace executable not found")
    return
  end

  local job = {
    args = args,
    callback = callback,
    replace = opts and opts.replace,
  }

  if job.replace then
    for index, queued in ipairs(queue) do
      if queued.replace == job.replace then
        queue[index] = job
        return
      end
    end
  end

  table.insert(queue, job)
  pump()
end

-- Lists every window of the application, visible or not; callback receives
--   { id, workspace, focused, visible, title }
-- where focused/visible describe the window's workspace, or nil, err.
--
-- opts:
--   bundle_id or pid => application filter
function M.list_windows(opts, callback)
  local args = { "list-windows", "--monitor", "all" }

  if opts.bundle_id then
    table.insert(args, "--app-bundle-id")
    table.insert(args, opts.bundle_id)
  elseif opts.pid then
    table.insert(args, "--pid")
    table.insert(args, tostring(opts.pid))
  end

  table.insert(args, "--json")
  table.insert(args, "--format")
  table.insert(
    args,
    "%{window-id} %{workspace} %{workspace-is-focused} %{workspace-is-visible} %{window-title}"
  )

  M.run(args, function(output, err)
    if not output then
      callback(nil, err)
      return
    end

    local ok, decoded = pcall(hs.json.decode, output)
    if not ok or type(decoded) ~= "table" then
      callback(nil, "could not decode list-windows output: " .. output)
      return
    end

    local windows = {}

    for _, entry in ipairs(decoded) do
      table.insert(windows, {
        id = entry["window-id"],
        workspace = entry["workspace"],
        focused = entry["workspace-is-focused"] == true,
        visible = entry["workspace-is-visible"] == true,
        title = entry["window-title"] or "",
      })
    end

    callback(windows)
  end)
end

-- Bursts of focus requests collapse into the latest one.
function M.focus_window(window_id, callback)
  M.run(
    { "focus", "--window-id", tostring(window_id) },
    callback,
    { replace = "focus" }
  )
end

-- Streams AeroSpace events (e.g. "focus-changed") to on_event(event).
-- The current state is sent first. Restarts when AeroSpace goes away.
-- Returns a handle with :stop().
function M.subscribe(events, on_event)
  local subscription = { stopped = false }

  if not aerospace then
    function subscription.stop() end
    return subscription
  end

  local args = { "subscribe" }

  for _, event in ipairs(events) do
    table.insert(args, event)
  end

  local function start()
    local buffer = ""

    subscription.task = hs.task.new(aerospace, function(rc, _, stderr)
      if subscription.stopped then
        return
      end

      print("aerospace subscribe exited with " .. tostring(rc) .. ": " .. (stderr or ""))
      subscription.timer = hs.timer.doAfter(subscribe_restart_delay, start)
    end, function(_, stdout)
      buffer = buffer .. (stdout or "")

      while true do
        local newline = buffer:find("\n", 1, true)
        if not newline then
          break
        end

        local line = buffer:sub(1, newline - 1)
        buffer = buffer:sub(newline + 1)

        local ok, event = pcall(hs.json.decode, line)
        if ok and type(event) == "table" then
          on_event(event)
        end
      end

      return true
    end, args)

    subscription.task:start()
  end

  function subscription.stop()
    subscription.stopped = true

    if subscription.timer then
      subscription.timer:stop()
    end

    if subscription.task and subscription.task:isRunning() then
      subscription.task:terminate()
    end
  end

  start()

  return subscription
end

return M
