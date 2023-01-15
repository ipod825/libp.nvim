require("plenary.async").tests.add_to_env()
local Job = require("libp.Job")
local a = require("plenary.async")
local Set = require("libp.datatype.Set")
local spy = require("luassert.spy")
local reflection = require("libp.debug.reflection")

describe("start", function()
    local function test_buffer_size(sz)
        describe("Works with buffer size " .. sz, function()
            local job
            before_each(function()
                job = Job({
                    cmd = "cat",
                    on_stdout_buffer_size = sz,
                })
                a.void(function()
                    job:start()
                end)()
            end)

            a.it("Handles simple newline cases", function()
                job:send("hello\n")
                job:send("world\n")
                job:shutdown(nil, 30)
                assert.are.same({ "hello", "world" }, job:stdoutput())
            end)

            a.it("Handles empty line with newline", function()
                job:send("hello\n")
                job:send("\n")
                job:send("world\n")
                job:send("\n")
                job:shutdown(nil, 30)
                assert.are.same({ "hello", "", "world", "" }, job:stdoutput())
            end)

            a.it("Handles partial line", function()
                job:send("hello\nwor")
                job:send("ld\n")
                job:shutdown(nil, 30)
                assert.are.same({ "hello", "world" }, job:stdoutput())
            end)

            a.it("Handles no newline at eof", function()
                job:send("hello\nwor")
                job:send("ld")
                job:shutdown(nil, 30)
                assert.are.same({ "hello", "world" }, job:stdoutput())
            end)
        end)
    end
    test_buffer_size(1)
    test_buffer_size(2)
    test_buffer_size(3)
    test_buffer_size(4)
    test_buffer_size(100)

    local function test_env(env, expect)
        a.it("Works with env " .. vim.inspect(env):gsub("\n", ""), function()
            local job
            job = Job({
                cmd = "env",
                env = env,
            })
            job:start()
            assert.are.same(Set(expect), Set.intersection(Set(expect), Set(job:stdoutput())))
        end)
    end

    test_env({ A = 100 }, { "A=100" })
    test_env({ A = 100, B = "test" }, { "A=100", "B=test" })
    test_env({ A = "This is a long env var" }, { "A=This is a long env var" })
    test_env({ ["A"] = 100, ["B"] = "test" }, { "A=100", "B=test" })

    a.it("Respects cwd", function()
        local job
        job = Job({
            cmd = "pwd",
            cwd = "/tmp",
        })
        job:start()
        assert.are.same({ "/tmp" }, job:stdoutput())
    end)

    describe("stderr_dump_level", function()
        local notify
        before_each(function()
            notify = spy.on(vim, "notify")
        end)
        after_each(function()
            notify:clear()
        end)

        a.it("No stderr output with no error", function()
            Job({
                cmd = "ls",
            }):start()
            assert.spy(notify).was_not_called()
        end)

        a.it("Output to stderr on error", function()
            Job({
                cmd = "ls no_such_file",
            }):start()
            assert.spy(notify).was_called()
        end)

        a.it("Does not output to stderr on error when silent", function()
            Job({
                cmd = "ls no_such_file",
                stderr_dump_level = Job.StderrDumpLevel.SILENT,
            }):start()
            assert.spy(notify).was_not_called()
        end)

        a.it("Always outputs stderr is stderr_dump_level is ALWAYS", function()
            Job({
                cmd = "echoerr",
                stderr_dump_level = Job.StderrDumpLevel.ALWAYS,
                env = {
                    PATH = ("%s:%s/scripts"):format(os.getenv("PATH"), reflection.git_project_root()),
                },
            }):start()
            assert.spy(notify).was_called()
        end)
    end)

    a.it("Takes customized on_stdout", function()
        local results
        local job
        results = {}
        job = Job({
            cmd = 'echo "a\nb"',
            on_stdout = function(lines)
                vim.list_extend(results, lines)
            end,
        })
        job:start()
        assert.are.same({ "a", "b" }, results)
        assert.are.same(nil, job:stdoutput())
    end)

    a.describe("Works with Quote", function()
        a.it("Work with double quotes", function()
            assert.are.same({ "a", "b" }, Job({ cmd = 'echo "a\nb"' }):stdoutput())
        end)
        a.it("Work with single quotes", function()
            assert.are.same({ "a", "b" }, Job({ cmd = "echo 'a\nb'" }):stdoutput())
        end)
        a.it("Honors escaped quotes", function()
            assert.are.same({ [["a]], [[b"]] }, Job({ cmd = 'echo "\\"a\nb\\""' }):stdoutput())
        end)
    end)

    a.describe("Takes array as cmd", function()
        a.it("Work with double quotes", function()
            assert.are.same({ "a", "b" }, Job({ cmd = { "echo", '"a\nb"' } }):stdoutput())
        end)
        a.it("Work with single quotes", function()
            assert.are.same({ "a", "b" }, Job({ cmd = { "echo", "'a\nb'" } }):stdoutput())
        end)
        a.it("Honors escape mark", function()
            assert.are.same({ [["a]], [[b"]] }, Job({ cmd = { "echo", [["\"a\nb\""]] } }):stdoutput())
        end)
    end)
end)

a.describe("stdoutputstr", function()
    a.it("Returns stdout as a single string", function()
        assert.are.same("a\nb", Job({ cmd = 'echo "a\nb"' }):stdoutputstr())
    end)
end)

describe("non-async context", function()
    it("Works", function()
        assert.are.same({ "a", "b" }, Job({ cmd = 'echo "a\nb"' }):start():wait():stdoutput())
        assert.are.same(
            { "hello", "world" },
            Job({
                    cmd = "cat",
                })
                :start()
                :send("hello\n")
                :send("world\n")
                :shutdown()
                :stdoutput()
        )
    end)
end)

describe("start_all", function()
    a.it("Returns all exiting code", function()
        assert.are.same({ { 0 }, { 2 } }, Job.start_all({ "ls", "ls no_such_file" }))
    end)

    it("non-async: Returns all exiting code", function()
        Job.start_all({ "ls", "ls no_such_file" }, {}, function(exit_codes)
            assert.are.same({ { 0 }, { 2 } }, exit_codes)
        end)
    end)
end)
