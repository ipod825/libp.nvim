--- Module: **libp.Job**
--
-- Run shell commands asynchronously. Note that `Job` supports plenary async
-- context seamlessly. For example, the following non-async context usage
--
--    local job = Job({ cmd = "ls" })
--    job:start(function(exit_code)
--    	print(vim.inspect(job:stdoutput()))
--    end)
-- is written as the following in plenary async context.
--    require("plenary.async").void(function()
--    	local job = Job({ cmd = "ls" })
--    	local exit_code = job:start()
--    	print(vim.inspect(job:stdoutput()))
--    end)()
-- For convenience, in non-async context, instead of specifying callback in
-- @{Job:start}, one could chain the APIs like:
--    Job({cmd="ls"}):start():wait():stdoutput()
-- One caveat is that the chain `:start():wait()` won't work in async context as
-- @{Job:start} returns exit code instead of the job itself in async context.
-- Given that inconsistency and since most of the time we just want to run the
-- command and get the output, @{Job:stdoutput} and @{Job:stdoutputstr} performs
-- the `start` and `wait` automatically:
--    Job({cmd="ls"}):stdoutput()
--
-- Inherits: @{Class}
-- @classmod Job
require("libp.utils.string_extension")
local M
M = require("libp.datatype.Class")
    :EXTEND({
        __index = function(_, key)
            if key == "start" then
                return coroutine.running() and rawget(M, "_start_async") or rawget(M, "start")
            else
                return rawget(M, key) or getmetatable(M)[key]
            end
        end,
    })
    :SET_CLASS_METHOD_INDEX(function(ori_index)
        return function(_, key)
            if key == "start_all" then
                return coroutine.running() and rawget(M, "_start_all_async") or rawget(M, "_start_all_non_async")
            else
                return rawget(ori_index, key)
            end
        end
    end)

local KVIter = require("libp.datatype.KVIter")
local a = require("plenary.async")
local vimfn = require("libp.utils.vimfn")
local List = require("libp.datatype.List")
local tokenizer = require("libp.argparse.tokenizer")

local function close_pipe(pipe)
    if not pipe then
        return
    end

    if not pipe:is_closing() then
        pipe:close()
    end
end

local function transform_env(env)
    vim.validate({ env = { env, "t", true } })
    if not env then
        return
    end

    local res = {}
    for k, v in pairs(env) do
        if type(k) == "number" then
            table.insert(res, v)
        elseif type(k) == "string" then
            table.insert(res, k .. "=" .. tostring(v))
        end
    end
    return res
end

local State = { NOT_STARTED = 1, RUNNING = 2, FINISHED = 3 }

--- StderrDumpLevel
M.StderrDumpLevel = {
    SILENT = 1, -- Never show stderr output.
    ON_ERROR = 2, -- Show stderr output only when the process exits with non-zero code.
    ALWAYS = 3, -- Always show stderr error. Useful for program that use stderr for normal message.
}

--- Constructor.
-- @tparam table opts
-- @tparam string|array opts.cmd The command to execute along with the
-- arguments. If cmd is a string, it will be tokenize into a list by
-- @{libp.argparse.tokenizer.tokenize}. Otherwise, the user should tokenize the
-- cmd into an array. One benefit of passing an array directly is that the
-- arguments do not need to be quoted even if they contain white space.
-- @tparam[opt] function({string})->nil opts.on_stdout The handler to process
-- command output
-- (stdout). If not provided, the default behavior is to store the outputs which
-- can be retrieved by @{Job:stdoutput}.
-- @tparam[opt=5000] number opts.on_stdout_buffer_size The internal buffer size
-- for `on_stdout`, which will be called when the internal buffer reaches
-- this number of lines. This is an optimization technique to reduce number of
-- function calls. Note that on job finish, `on_stdout` will be called the last
-- time with the remaining lines in the buffer.
-- @tparam[opt=StderrDumpLevel.ON_ERROR] StderrDumpLevel opts.stderr_dump_level
-- Whether to notify (`vim.notify`) the user with the stderr output. See
-- @{StderrDumpLevel} for details.
-- @tparam[opt] string opts.cwd The working directory to exectue the command
-- @tparam[opt] table|{string} opts.env Environment variables when invoking the
-- command. If `env` is of table type, each key is the variable name and each
-- value is the variable value (converted to string type). If `env` is of string
-- array type, each must be of the form `name=value`
-- @tparam[opt=false] boolean opts.detach Whether to detach the job, i.e. to keep the job running after vim exists.
-- @treturn Job The new job
-- @usage
-- local res = {}
-- local job = Job({ cmd = {"echo", "a\nb"})
-- job:start(function(lines)
--     vim.list_extend(res, lines)
-- end):wait()
-- assert.are.same({ "a", "b" }, res)
-- @usage
-- assert.are.same({ "a", "b" },
--  Job({ cmd = 'echo "a\nb"' }):start():wait():stdoutput())
-- @usage
-- require("plenary.async").void(function()
--     assert.are.same(
--         { "A=100" },
--         Job({
--             cmd = "env",
--             env = { A = 100 },
--         }):stdoutput()
--     )
-- end)()
function M:init(opts)
    vim.validate({
        cmd = { opts.cmd, { "s", "t" } },
        on_stdout = { opts.on_stdout, "f", true },
        on_stdout_buffer_size = { opts.on_stdout_buffer_size, "n", true },
        stderr_dump_level = { opts.stderr_dump_level, "n", true },
        cwd = { opts.cwd, "s", true },
        env = { opts.env, "table", true },
        detach = { opts.detach, "boolean", true },
    })

    self.state = State.NOT_STARTED

    -- Default stdout handler that just caches the output.
    if not opts.on_stdout then
        self.stdout_lines = {}
        opts.on_stdout = function(lines)
            vim.list_extend(self.stdout_lines, lines)
        end
    end

    -- Only invokes on_stdout once a while.
    opts.on_stdout_buffer_size = opts.on_stdout_buffer_size or 5000

    opts.stderr_dump_level = opts.stderr_dump_level or M.StderrDumpLevel.ON_ERROR
    self.opts = opts
end

--- Executes the command asynchronously.
-- See @{Job.init} for configuration.
-- @tparam[opt=nil] function(number)->nil callback The function invoked on job
-- finish. The argument is the job exit code. In async context, the exit code is
-- the return value of `start` and the callback should never be passed
-- explicitly.
-- @return
-- non-async: (@{Job}) The job
--
-- async: (number) The exit code
-- @see Job:init
function M:start(callback)
    assert(self.state == State.NOT_STARTED)
    self.state = State.RUNNING

    local opts = self.opts

    self.stdin = vim.loop.new_pipe(false)
    self.stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)

    local cmd_tokens
    if type(opts.cmd) == "string" then
        cmd_tokens = tokenizer.tokenize(opts.cmd)
    else
        cmd_tokens = vim.deepcopy(opts.cmd)
    end
    local cmd, args = cmd_tokens[1], vim.list_slice(cmd_tokens, 2, #cmd_tokens)
    -- Remove quotes as spawn will quote each args. Also need to replace '\"'
    -- with '"' as spawn adds the escape back.
    for i, arg in ipairs(args) do
        args[i] = arg:gsub('^"(.*)"$', "%1"):gsub('="(.*)"$', "=%1"):gsub('\\"', '"')
        if #args[i] == #arg then
            args[i] = arg:gsub("^'(.*)'$", "%1"):gsub("='(.*)'$", "=%1"):gsub("\\'", "'")
        end
    end

    local stdout_lines = { "" }
    local stderr_lines = ""
    local eof_has_new_line = false
    local on_stdout = function(_, data)
        if data == nil then
            return
        end

        eof_has_new_line = data:find("\n$")

        -- The last line in stdout_lines is always a "partial line":
        -- 1. At initialization, we initialized it to "".
        -- 2. For a real partial line (data not ending with "\n"), lines[-1] would be non-empty.
        -- 3. For a complete line (data ending with "\n"), lines[-1] would be "".
        local lines = data:split("\n")
        stdout_lines[#stdout_lines] = stdout_lines[#stdout_lines] .. lines[1]
        vim.list_extend(stdout_lines, lines, 2)

        if #stdout_lines >= opts.on_stdout_buffer_size then
            local partial_line = table.remove(stdout_lines)
            opts.on_stdout(stdout_lines)
            stdout_lines = { partial_line }
        end
    end

    local on_stderr = function(_, data)
        if data then
            stderr_lines = stderr_lines .. data
        end
    end

    local on_exit = function(exit_code, _)
        self.stdout:read_stop()
        stderr:read_stop()

        close_pipe(self.stdin)
        close_pipe(self.stdout)
        close_pipe(stderr)

        if exit_code ~= 0 then
            if opts.stderr_dump_level ~= M.StderrDumpLevel.SILENT and not self.was_killed then
                local cmd = type(opts.cmd) == "string" and opts.cmd or table.concat(opts.cmd, " ")
                vimfn.error(("Error message from\n%s\n\n%s"):format(cmd, stderr_lines))
            end
        end

        -- It's tempting to not handle stdout on error. However, it's useful in
        -- case when the user wants to read stdout result while expecting the
        -- command to fail.
        if opts.on_stdout then
            stdout_lines = eof_has_new_line and vim.list_slice(stdout_lines, 1, #stdout_lines - 1) or stdout_lines
            if #stdout_lines > 0 then
                opts.on_stdout(stdout_lines)
            end

            if opts.stderr_dump_level == M.StderrDumpLevel.ALWAYS and #stderr_lines > 0 then
                vimfn.warn(stderr_lines)
            end
        end

        if callback then
            callback(exit_code)
        end
        self.state = State.FINISHED
    end
    self.process, self.pid = vim.loop.spawn(cmd, {
        stdio = { self.stdin, self.stdout, stderr },
        args = args,
        cwd = opts.cwd,
        detach = opts.detach,
        env = transform_env(opts.env),
    }, vim.schedule_wrap(on_exit))

    if type(self.pid) == "string" then
        stderr_lines = stderr_lines .. ("Command not found: %s"):format(cmd)
        vimfn.error(stderr_lines)
        return -1
    else
        self.stdout:read_start(vim.schedule_wrap(on_stdout))
        stderr:read_start(vim.schedule_wrap(on_stderr))
    end
    return self
end

M._start_async = a.wrap(M.start, 2)

--- Retrieves the cached stdoutput.
-- If the job hasn't started/finished, it will start automatically and wait
-- until it finished.
-- @treturn {string}
function M:stdoutput()
    if self.state == State.NOT_STARTED then
        self:start()
    end
    self:wait()
    return self.stdout_lines
end

--- Retrieves the cached stdoutput as a single string.
-- If the job hasn't started/finished, it will start automatically and wait
-- until it finished.
-- @treturn string
function M:stdoutputstr()
    return table.concat(self:stdoutput(), "\n")
end

--- Sends a string to the stdin of the job.
-- This is useful if the job expects user input. One might need to shutdown the
-- job explicitly if the job don't finish on user inputs (see usage below).
-- @tparam string data The string to be sent to the job stdin
-- @treturn Job The job
-- @usage
-- assert.are.same(
--     { "hello", "world" },
--     Job({
--             cmd = "cat",
--         })
--         :start()
--         :send("hello\n")
--         :send("world\n")
--         :shutdown()
--         :stdoutput()
-- )
function M:send(data)
    assert(self.state == State.RUNNING)
    self.stdin:write(data)
    return self
end

--- Kills the job.
-- Useful to cancel a job whose output is no longer needed anymore. If accessing
-- the available output is desired, one should chain @{Job:wait} or use @{Job:shutdown}
-- instead as it not guaranteed the @{Job:start} coroutine finished when `kill`
-- returns.
-- @tparam[opt=15] number signal The kill signal to sent to the job.
-- @treturn Job The job
-- @see Job.shutdown
function M:kill(signal)
    assert(self.state ~= State.NOT_STARTED)
    if self.state == State.FINISHED then
        return
    end
    signal = signal or 15
    self.process:kill(signal)
    self.was_killed = true
    return self
end

--- Waits until the job finishes.
-- @tparam[opt=10] number interval_ms Number of milliseconds to wait between polls.
-- @treturn Job The job
function M:wait(interval_ms)
    vim.validate({ interval_ms = { interval_ms, "n", true } })
    interval_ms = interval_ms or 10
    if self.state ~= State.FINISHED then
        vim.wait(interval_ms, function()
            return self.state == State.FINISHED
        end, interval_ms)
    end
    return self
end

--- Shuts down the job.
-- Useful to cancel a job. It's guaranteed that the job has already finished on
-- `shutdown` return. Hence @{Job:stdoutput} will returns the available outputs
-- before the job shutdown.
-- @tparam[opt=15] number signal The kill signal to sent to the job.
-- @tparam[opt=10] number grace_period Grace period in ms before sending the
-- signal. Probably only useful for unit test of this module.
-- @see Job.send
-- @see Job.kill
function M:shutdown(signal, grace_period)
    vim.validate({ signal = { signal, "n", true }, grace_period = { grace_period, "n", true } })

    assert(self.state ~= State.NOT_STARTED)
    if self.state == State.FINISHED then
        return
    end

    signal = signal or 15
    grace_period = grace_period or 10
    vim.wait(grace_period, function()
        return not vim.loop.is_active(self.stdout)
    end)
    self.process:kill(signal)

    -- Wait until on_exit returns.
    self:wait()
    return self
end

--- Executes the commands asynchronously and simultaneously.
-- This is beneficial when all commands are i/o bounded. Note that we don't
-- allow per-command configuration, all the commands will share the same option.
-- @static
-- @tparam {string}|{array} cmds The commands for each job.
-- @tparam[opts={}] table opts All jobs' common options. See @{Job:init} for configuration.
-- @tparam[opts=nil] function({number})->nil callback The function invoked on
-- job finish. The argument is an array of the jobs' exit codes. In async
-- context, the exit codes is the return value of `start_all` and the callback
-- should not be passed explicitly.
-- @return
-- non-async: ({@{Job}}) The array of all jobs
--
-- async: ({{number}}) The exit codes
-- @see Job:init
-- @usage
-- Job.start_all({ "ls", "ls no_such_file" }, {}, function(exit_codes)
--     assert.are.same({ { 0 }, { 2 } }, exit_codes)
-- end)
-- @usage
-- require("plenary.async").void(function()
--     assert.are.same({ { 0 }, { 2 } }, Job.start_all({ "ls", "ls no_such_file" }))
-- end)()
function M._start_all_non_async(cmds, opts, callback)
    vim.validate({ cmds = { cmds, "t" }, opts = { opts, "t", true }, callback = { callback, "f", true } })
    local num_jobs = #cmds
    local exit_codes = {}
    return KVIter(List(cmds)):mapkv(function(i, cmd)
        return M(vim.tbl_extend("keep", { cmd = cmd }, opts or {})):start(function(exit_code)
            if callback then
                exit_codes[i] = { exit_code }
                num_jobs = num_jobs - 1
                if num_jobs == 0 then
                    callback(exit_codes)
                end
            end
        end)
    end):collect()
end

M._start_all_async = a.wrap(function(cmds, opts, callback)
    local res_code = {}
    a.run(function()
        res_code = a.util.join(List(cmds):map(function(e)
            return a.wrap(function(cb)
                M(vim.tbl_extend("keep", { cmd = e }, opts or {})):start(cb)
            end, 1)
        end))
    end, function()
        callback(res_code)
    end)
end, 3)

return M
