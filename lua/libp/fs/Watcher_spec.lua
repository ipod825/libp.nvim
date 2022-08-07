require("plenary.async").tests.add_to_env()
local Watcher = require("libp.fs.Watcher")
local a = require("plenary.async")

a.describe("Watcher", function()
    a.it("Watches the file until terminate", function()
        local dir = vim.fn.tempname()
        local fs_event_done = a.control.Condvar.new()

        vim.fn.mkdir(dir, "p")
        local callback_count = 0
        Watcher(dir, function(watcher)
            callback_count = callback_count + 1
            if callback_count > 2 then
                fs_event_done:notify_all()
                watcher:stop()
            end
        end)

        vim.fn.system(("touch %s/a"):format(dir))
        vim.fn.system(("rename %s/a %s/b"):format(dir, dir))
        vim.fn.system(("touch %s/a"):format(dir))
        fs_event_done:wait()
        assert.are.same(3, callback_count)
    end)
end)
