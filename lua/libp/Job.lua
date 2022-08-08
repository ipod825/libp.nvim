--- Module: **libp.Job**
--
-- Run shell commands asynchronously.
--
-- Inherits: @{Class}
-- @classmod Job
require("libp.utils.string_extension")
local M = require("libp.datatype.Class"):EXTEND()
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
-- @{tokenizer.tokenize}. Otherwise, the user should tokenize the cmd into an
-- array. One benefit of passing an array directly is that the arguments do not
-- need to be quoted even if they contain white space.
-- @tparam[opt] function opts.on_stdout The handler to process command output
-- (stdout). If not provided, the default behavior is to store the outputs which
-- can be retrieved by @{Job:stdoutput}.
-- @tparam[opt=5000] number opts.on_stdout_buffer_size The internal buffer size
-- for `on_stdout`, which will be called when the internal buffer reaches
-- this number of lines. This is an optimization technique to reduce number of
-- function calls. Note that on job finish, `on_stdout` will be called
-- regardless the number of lines in the buffer (as long as it contains >0
-- line).
-- @tparam[opt=StderrDumpLevel.SILENT] StderrDumpLevel opts.stderr_dump_level
-- Whether to notify the user with the stderr output. See @{StderrDumpLevel} for
-- details.
-- @tparam[opt] string opts.cwd The working directory to exectue the command
-- @tparam[opt] table|{string} opts.env Environment variables when invoking the
-- command. If `env` is of table type, each key is the variable name and each
-- value is the variable value (converted to string type). If `env` is of string
-- array type, each must be of the form `name=value`
-- @tparam[opt=false] boolean opts.detached Whether to detach the job, i.e. to keep the job running after vim exists.
-- @usage
-- require("plenary.async").void(function()
--     assert.are.same({ "a", "b" }, Job({ cmd = 'echo "a\nb"' }):stdoutput())
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
        detached = { opts.detached, "boolean", true },
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
-- @function M:start
-- @usage
-- require("plenary.async").void(function()
--     local job = Job({ cmd = 'echo "a\nb"' })
--     job:start()
--     assert.are.same({ "a", "b" }, job:stdoutput())
-- end)()
M.start = a.wrap(function(self, callback)
    assert(self.state == State.NOT_STARTED)
    self.state = State.RUNNING

    local opts = self.opts

    self.stdin = vim.loop.new_pipe(false)
    self.stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)
    self.done = a.control.Condvar.new()

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
                vimfn.error(("Error message from\n%s\n\n%s"):format(opts.cmd, stderr_lines))
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
        self.done:notify_all()
        self.state = State.FINISHED
    end

    self.process, self.pid = vim.loop.spawn(cmd, {
        stdio = { self.stdin, self.stdout, stderr },
        args = args,
        cwd = opts.cwd,
        detached = opts.detached,
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
end, 2)

--- Retrieves the cached stdoutput.
-- If the job hasn't started (@{Job:start}), it will start automatically.
-- @treturn {string}
-- @usage
-- require("plenary.async").void(function()
--     assert.are.same({ "a", "b" }, Job({ cmd = 'echo "a\nb"' }):stdoutput())
-- end)()
function M:stdoutput()
    if self.state == State.NOT_STARTED then
        self:start()
    end
    return self.stdout_lines
end

--- Retrieves the cached stdoutput as a single string.
-- If the job hasn't started (@{Job:start}), it will start automatically.
-- @treturn string
-- @usage
-- require("plenary.async").void(function()
--     assert.are.same("a\nb", Job({ cmd = 'echo "a\nb"' }):stdoutputstr())
-- end)()
function M:stdoutputstr()
    return table.concat(self:stdoutput(), "\n")
end

--- Sends a string to the stdin of the job.
-- Thie is useful if the job expects user input. One might need to shutdown the
-- job explicitly if the job don't finish on user inputs (see usage below).
-- @treturn nil
-- @usage
-- local job = Job({
--     cmd = "cat",
--     on_stdout_buffer_size = sz,
-- })
-- require("plenary.async").void(function()
--     job:start()
-- end)()
-- require("plenary.async").void(function()
--     job:send("hello\n")
--     job:send("world\n")
--     job:shutdown()
--     assert.are.same({ "hello", "world" }, job:stdoutput())
-- end)()
function M:send(data)
    assert(self.state == State.RUNNING)
    self.stdin:write(data)
end

--- Kills the job.
-- Useful to cancel a job whose output is no longer needed anymore. If accessing
-- the available output is desired, one should use @{Job:shutdown}
-- instead as it not guaranteed the @{Job.start} coroutine finished when `kill`
-- returns.
-- @tparam[opt=15] number signal The kill signal to sent to the job.
-- @see Job.shutdown
function M:kill(signal)
    assert(self.state ~= State.NOT_STARTED)
    if self.state == State.FINISHED then
        return
    end
    signal = signal or 15
    self.process:kill(signal)
    self.was_killed = true
end

-- Wait until the job finished. This is only useful for @{Job:shutdown} which is
-- almost always invoked in a separate coroutine than @{Job:start}. Returning
-- from shutdown thus does not guarantee finish of the @{Job:start} coroutine
-- and thus explicit wait is necessary.
function M:_wait()
    assert(self.state ~= State.NOT_STARTED)
    if self.state == State.FINISHED then
        return
    end
    self.done:wait()
end

--- Shuts down the job.
-- Useful to cancel a job. It's guaranteed that the job has already finished on
-- `shutdown` return. Hence @{Job:stdoutput} will returns the available outputs
-- before the job shutdown.
-- @see Job.send
-- @see Job.kill
function M:shutdown()
    assert(self.state ~= State.NOT_STARTED)
    if self.state == State.FINISHED then
        return
    end
    vim.wait(10, function()
        return not vim.loop.is_active(self.stdout)
    end)
    self.process:kill(15)
    self:_wait()
end

M.start_all = a.wrap(function(cmds, opts, callback)
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
