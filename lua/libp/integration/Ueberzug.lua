local M = require("libp.datatype.Class"):EXTEND()
local osfn = require("libp.utils.osfn")
local vimfn = require("libp.utils.vimfn")
local args = require("libp.args")
local path = require("libp.path")
local Job = require("libp.Job")
local fs = require("libp.fs")
local VIter = require("libp.datatype.VIter")
local functional = require("libp.functional")
local LruDict = require("libp.datatype.LruDict")
local mime = require("libp.mime")
local itt = require("libp.itertools")

local cache = LruDict(100)

function M:init(opts)
    if not osfn.is_in_path("ueberzug") then
        vimfn.warn("Command not found: ueberzug. Please install it for image preview.")
        return
    end
    opts = opts or {}

    vim.validate({
        win_id = { opts.win_id, "n" },
        kill_on_win_close = { opts.kill_on_win_close, { "b", "t" }, true },
        kill_on_tab_leave = { opts.kill_on_tab_leave, "b", true },
    })

    if args.get_default(opts.kill_on_win_close, true) then
        local win_ids
        if type(opts.kill_on_win_close) == "boolean" then
            win_ids = { opts.win_id }
        else
            win_ids = opts.kill_on_win_close
        end

        for win_id in itt.values(win_ids) do
            vim.api.nvim_create_autocmd("WinClosed", {
                pattern = tostring(win_id),
                once = true,
                callback = function()
                    self:kill()
                end,
            })
        end
    end

    if args.get_default(opts.kill_on_tab_leave, true) then
        vim.api.nvim_create_autocmd("TabLeave", {
            once = true,
            callback = function()
                self:kill()
            end,
        })
    end

    self.buf_id = vim.api.nvim_win_get_buf(opts.win_id)
    self.identifier = vim.fn.tempname()
    self.channel = vim.fn.jobstart("ueberzug layer --parser json")
end

function M:kill()
    if self.channel then
        vim.fn.jobstop(self.channel)
        self.channel = nil
    end
end

function M:remove(opts)
    if not self.identifier then
        return
    end
    opts = opts or {}
    vim.validate({
        draw = { opts.draw, "boolean", true },
    })
    self:send(vim.tbl_extend("force", opts, { action = "remove", identifier = self.identifier }))
end

function M:send(opts)
    if self.channel then
        vim.api.nvim_chan_send(self.channel, vim.fn.json_encode(opts) .. "\r\n")
    end
end

function M:get_or_gen_preview(file_path, msg, gen_preview)
    vim.validate({ file_path = { file_path, "s" }, msg = { msg, "s" }, gen_preview = { gen_preview, "f" } })
    if not cache[file_path] then
        local _, err = fs.mkdir(self.identifier)
        if err then
            vimfn.error(err)
        else
            local ori_modifiable = vimfn.buf_get_option_and_set(self.buf_id, "modifiable", true)
            vim.api.nvim_buf_set_lines(self.buf_id, 0, -1, true, { ("Loading %s preview..."):format(msg) })
            gen_preview(self.identifier)
            vimfn.buf_get_option_and_set(self.buf_id, "modifiable", ori_modifiable)

            cache[file_path] = fs.list_dir(self.identifier)
                :map(function(e)
                    return path.join(self.identifier, e.name)
                end)
                :sort()
                :unbox_if_one()
        end
    end
    return cache[file_path]
end

function M:add(opts)
    if not self.identifier then
        return
    end
    vim.validate({
        x = { opts.x, "n" },
        y = { opts.y, "n" },
        path = { opts.path, "s" },
        width = { opts.width, "n", true },
        height = { opts.height, "n", true },
        draw = { opts.draw, "boolean", true },
        synchronously_draw = { opts.synchronously_draw, "boolean", true },
        scaler = {
            opts.scaler,
            function(e)
                return not e
                    or e == "crop"
                    or e == "distort"
                    or e == "fit_contain"
                    or e == "contain"
                    or e == "forced_cover"
                    or e == "cover"
            end,
        },
        scaling_position_x = { opts.scaling_position_x, "number", true },
        scaling_position_y = { opts.scaling_position_y, "number", true },
    })
    opts.action = "add"
    opts.identifier = self.identifier

    local mime_str = mime.info(opts.path)
    if mime_str:match("gif") then
        if not osfn.is_in_path("convert") then
            return false
        end

        local images = self:get_or_gen_preview(opts.path, "gif", function(dst_dir)
            Job({ cmd = ('convert -deconstruct "%s" "%s/a.png"'):format(opts.path, dst_dir) }):start()
        end)
        images = VIter(images):cycle()

        functional.debounce({
            body = function()
                self:remove()
                self:send(vim.tbl_extend("force", opts, { path = images:next() }))
                return self.channel
            end,
            wait_ms = 100,
        })
    elseif mime_str:match("video/") then
        if not osfn.is_in_path("ffmpegthumbnailer") then
            return false
        end

        local images = self:get_or_gen_preview(opts.path, "video", function(dst_dir)
            for i = 1, 5 do
                Job({
                    cmd = ('ffmpegthumbnailer -i "%s" -o "%s/%d.png" -s 0 -q 10 -t %d%%'):format(
                        opts.path,
                        dst_dir,
                        i,
                        i * 20
                    ),
                }):start()
            end
        end)
        images = VIter(images):cycle()

        functional.debounce({
            body = function()
                self:remove()
                self:send(vim.tbl_extend("force", opts, { path = images:next() }))
                return self.channel
            end,
            wait_ms = 600,
        })
    elseif mime_str:match("application/pdf") then
        local image = self:get_or_gen_preview(opts.path, "pdf", function(dst_dir)
            Job({ cmd = ("pdftoppm -png -singlefile %s %s/a.png"):format(opts.path, dst_dir) }):start()
        end)
        self:send(vim.tbl_extend("force", opts, { path = image }))
    else
        self:send(opts)
    end

    return true
end

return M
