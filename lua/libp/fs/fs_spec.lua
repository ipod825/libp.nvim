require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local pathfn = require("libp.utils.pathfn")
local fs = require("libp.fs")
local uv = require("libp.fs.uv")
local reflection = require("libp.debug.reflection")

assert:register("assertion", "fs_succ", function(state, arguments)
    local res, err = arguments[1], arguments[2]
    state.failure_message = ([[
    Expect fs operation success
    Passed in:
    %s, %s
    Expected:
    nil, non-nil
    ]]):format(res, err)
    return res and (err == nil)
end, "pos", "neg")

assert:register("assertion", "fs_fail", function(state, arguments)
    local res, err = arguments[1], arguments[2]
    state.failure_message = ([[
    Expect fs operation fail
    Passed in:
    %s, %s
    Expected:
    nil, non-nil
    ]]):format(res, err)
    return res == nil and err
end, "pos", "neg")

local function itsa(description, fn)
    it(description .. " in sync context", fn)
    a.it(description .. " in async context", fn)
end

local function create_file(...)
    local name
    if select("#", ...) > 0 then
        name = pathfn.join(...)
    else
        name = vim.fn.tempname()
    end
    vim.fn.system("touch " .. name)
    return name
end

local function create_dir(...)
    local name
    if select("#", ...) > 0 then
        name = pathfn.join(...)
    else
        name = vim.fn.tempname()
    end
    vim.fn.mkdir(name, "p")
    return name
end

describe("stat_mode_num", function()
    itsa("Returns number version of file mode", function()
        assert.are.same(52, fs.stat_mode_num(64))
        assert.are.same(493, fs.stat_mode_num(755))
    end)
end)

describe("chmod", function()
    it("Change modes using human representation", function()
        local tmp = create_file()
        fs.chmod(tmp, 123)
        assert.are.same(123, fs.get_mode(tmp))
        fs.chmod(tmp, 456)
        assert.are.same(456, fs.get_mode(tmp))
        fs.chmod(tmp, 0)
        assert.are.same(0, fs.get_mode(tmp))
    end)
end)

describe("is_direcory", function()
    itsa("Returns false if directory does not exist", function()
        assert.is_false(fs.is_directory("no_such_dir"))
    end)

    itsa("Returns true if directory exist", function()
        assert.is_true(fs.is_directory(reflection.script_dir()))
    end)
end)

describe("is_executable", function()
    itsa("Returns false if file does not exist", function()
        assert.is_false(fs.is_executable("no_such_file"))
    end)

    itsa("Returns false if file is not executable", function()
        local tmp = create_file()
        assert.is_false(fs.is_executable(tmp))
    end)

    it("Returns false if target path is a directory", function()
        assert.is_false(fs.is_executable(reflection.script_dir()))
    end)

    itsa("Returns true if file is executable", function()
        local tmp = create_file()
        fs.chmod(tmp, 700)
        assert.is_true(fs.is_executable(tmp))
        fs.chmod(tmp, 300)
        assert.is_true(fs.is_executable(tmp))
        fs.chmod(tmp, 100)
        assert.is_true(fs.is_executable(tmp))
        fs.chmod(tmp, 000)
        assert.is_false(fs.is_executable(tmp))
    end)
end)

describe("is_readable", function()
    itsa("Returns true if file/directory is readable", function()
        assert.is_true(fs.is_readable(reflection.script_path()))
        assert.is_true(fs.is_readable(reflection.script_dir()))
    end)

    itsa("Returns false if file/directory does not exist", function()
        assert.is_false(fs.is_readable("no_such_file"))
        assert.is_false(fs.is_readable("no_such_directory"))
    end)

    itsa("Returns false if file/directory exists but not readable", function()
        local tmp = create_file()

        fs.chmod(tmp, 0)
        assert.is_false(fs.is_readable(tmp))
    end)

    -- TODO: Test file exists but not readable.
end)

describe("get_mode", function()
    itsa("Returns fail if file does not exist", function()
        assert.is.fs_fail(fs.get_mode("no_such_file"))
    end)

    itsa("Get the mode", function()
        local tmp = create_file()
        vim.fn.system("chmod 755 " .. tmp)
        assert.are.same(755, fs.get_mode(tmp))
        vim.fn.system("chmod 644 " .. tmp)
        assert.are.same(644, fs.get_mode(tmp))
    end)
end)

describe("touch", function()
    itsa("Returns fail on permission error", function()
        assert.is.fs_fail(fs.touch("/no_write_access"))
    end)

    itsa("Creates a file with mode 640", function()
        local tmp = vim.fn.tempname()
        assert.is.fs_succ(fs.touch(tmp))
        assert.is.fs_succ(fs.is_readable(tmp))
        assert.are.same(640, fs.get_mode(tmp))
    end)
end)

describe("mkdir", function()
    itsa("Returns fail on permission error", function()
        assert.is.fs_fail(fs.mkdir("/no_write_access"))
    end)

    itsa("Creates a directory with default mode 750", function()
        local tmp = vim.fn.tempname()
        assert.is.fs_succ(fs.mkdir(tmp))
        assert.is.fs_succ(fs.is_readable(tmp))
        assert.are.same(750, fs.get_mode(tmp))
    end)

    itsa("Accepts an optional mode", function()
        local tmp = vim.fn.tempname()
        assert.is.fs_succ(fs.mkdir(tmp, 640))
        assert.is.fs_succ(fs.is_readable(tmp))
        assert.are.same(640, fs.get_mode(tmp))
    end)
end)

a.describe("rm", function()
    itsa("Returns fail if the path does not exist", function()
        assert.is_fs_fail(fs.rm("no_such_dir"))
        assert.is_fs_fail(fs.rm("no_such_file"))
    end)

    itsa("Removes directory", function()
        local tmp = create_dir()
        fs.rm(tmp)
        assert.are.same(0, vim.fn.isdirectory(tmp))
    end)

    itsa("Removes file", function()
        local afile = create_file("a")
        fs.rm(afile)
        assert.are.same(0, vim.fn.filereadable(afile))
    end)
end)

a.describe("rmdir", function()
    itsa("Returns fail if the path is not a directory", function()
        assert.is_fs_fail(fs.rmdir("no_such_dir"))
        local tmp = create_file()
        assert.are.same(0, vim.fn.isdirectory(tmp))
        assert.is_fs_fail(fs.rmdir(tmp))
    end)

    itsa("Returns fail if the path is not readable", function()
        local tmp = create_dir()
        fs.chmod(tmp, 000)
        assert.is_fs_fail(fs.rmdir(tmp))
    end)

    it("Fails on non-readable directory but removes other file/directories", function()
        local root = create_dir()
        local dir1 = create_dir(root, "dir1")
        fs.chmod(dir1, 000)
        local dir2 = create_dir(root, "dir2")
        local file1 = create_dir(root, "file1")
        assert.is_fs_fail(fs.rmdir(root))
        assert.are.same(1, vim.fn.isdirectory(root))
        assert.are.same(1, vim.fn.isdirectory(dir1))
        assert.are.same(0, vim.fn.isdirectory(dir2))
        assert.are.same(0, vim.fn.filereadable(file1))
    end)
end)

a.describe("list_dir", function()
    itsa("Returns fail if directory does not exist", function()
        assert.is_fs_fail(fs.list_dir("no_such_dir"))
    end)

    itsa("Lists the directories", function()
        local dir = create_dir()
        create_file(dir, "a")
        create_dir(dir, "b")
        local res = fs.list_dir(dir)
        assert.is_truthy(res)
        if res and res[1].name ~= "a" then
            res[1], res[2] = res[2], res[1]
        end
        assert.are.same({ { name = "a", type = "file" }, { name = "b", type = "directory" } }, res)
    end)
end)

a.describe("copy", function()
    itsa("Returns true when src equals dst", function()
        local tmp = create_file()
        assert.is_true(fs.copy(tmp, tmp))

        local dir = create_dir()
        assert.is_true(fs.copy(dir, dir))
    end)

    itsa("Returns fail if src does not exist", function()
        assert.is.fs_fail(fs.copy("no_such_file", "./dst"))
    end)

    itsa("Copies file", function()
        local tmp = create_file()
        assert.is_true(fs.copy(tmp, tmp .. "copy"))
        assert.is_true(fs.is_readable(tmp .. "copy"))
    end)

    itsa("Returns fail if src is not readble", function()
        local tmp = create_file()
        fs.chmod(tmp, 0)
        assert.is.fs_fail(fs.copy(tmp, "./dst"))
    end)

    itsa("Returns fail if src directory is not readble", function()
        local dir = create_dir()
        fs.chmod(dir, 0)
        assert.is.fs_fail(fs.copy(dir, "./dst"))
    end)

    itsa("Returns success by default if dst directory already exists", function()
        local src_dir = create_dir()
        local dst_dir = create_dir()
        assert.is_true(fs.copy(src_dir, dst_dir))
    end)

    itsa("Returns fail if dst directory already exists and excl is true", function()
        local src_dir = create_dir()
        local dst_dir = create_dir()
        assert.is.fs_fail(fs.copy(src_dir, dst_dir, { excl = true }))
    end)

    itsa("Recursively copies directory", function()
        local src_dir = create_dir()
        local dst_dir = src_dir .. "copy"
        create_file(src_dir, "a")
        assert.is_true(fs.copy(src_dir, dst_dir))
        assert.is_true(fs.is_readable(dst_dir))
        assert.is_true(fs.is_readable(pathfn.join(dst_dir, "a")))
    end)
end)
