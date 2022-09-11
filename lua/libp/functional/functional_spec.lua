require("plenary.async").tests.add_to_env()
local functional = require("libp.functional")

describe("nop", function()
    it("Does nothing", function()
        functional.nop()
    end)
end)

describe("identity", function()
    it("Returns the argument", function()
        assert.are.same(1, functional.identity(1))
        assert.are.same(10, functional.identity(10))
    end)
end)

describe("oneshot", function()
    it("Returns a function that will be called only once", function()
        local var = 0
        local inc = functional.oneshot(function()
            var = var + 1
            return var
        end)
        assert.are.same(1, inc())
        assert.is_nil(inc())
        assert.are.same(1, var)
    end)
    it("Accepts parameter to control which time the call happens", function()
        local var = 0
        local inc = functional.oneshot(function()
            var = var + 1
            return var
        end, 2)
        assert.is_nil(inc())
        assert.are.same(1, inc())
        assert.is_nil(inc())
        assert.are.same(1, var)
    end)
end)

describe("oneshot_if", function()
    it("Returns a function that will be called only once when condition holds", function()
        local should_run = false
        local var = 0
        local inc = functional.oneshot_if(function()
            var = var + 1
            return var
        end, function()
            return should_run
        end)
        assert.is_nil(inc())
        should_run = true
        assert.are.same(1, inc())
        assert.is_nil(inc())
        assert.are.same(1, var)
    end)
end)

describe("head_tail", function()
    it("Returns the argument", function()
        local arr = { 1, 2, 3 }
        local head, tail = functional.head_tail(arr)
        assert.are.same(1, head)
        assert.are.same({ 2, 3 }, tail)
    end)
end)

describe("bind", function()
    local function f1(a)
        return a
    end

    local function f2(a, b)
        return a + b
    end

    local function nil_to_str(a, b, c)
        return tostring(a), tostring(b), tostring(c)
    end

    it("Failed on zero args", function()
        assert.has.errors(function()
            functional.bind(f1)
        end)
    end)

    it("Binds one arg", function()
        assert.are.same(1, functional.bind(f1, 1)())
        assert.are.same(3, functional.bind(f2, 1)(2))
    end)
    it("Binds two args", function()
        assert.are.same(3, functional.bind(f2, 1, 2)())
    end)
    it("Accepts nil", function()
        local f = functional.bind(nil_to_str, nil)
        assert.are.same({ "nil", "1", "2" }, { f(1, 2) })
        assert.are.same({ "nil", "nil", "2" }, { f(nil, 2) })
        assert.are.same({ "nil", "nil", "nil" }, { f(nil, nil) })
    end)
end)

describe("binary_op", function()
    it("Works", function()
        local op = functional.binary_op
        assert.are.same(3, op.add(1, 2))
        assert.are.same(-1, op.sub(1, 2))
        assert.are.same(6, op.mult(2, 3))
        assert.are.same(0.5, op.div(1, 2))
        assert.are.same(1, op.first(1, 2))
        assert.are.same(2, op.second(1, 2))
    end)
end)

describe("debounce", function()
    a.it("Works", function()
        local count = 0
        functional.debounce({
            body = function()
                count = count + 1
                return count <= 1
            end,
            wait_ms = 10,
            first_wait_ms = 1,
        })
        assert.are.same(0, count)
        a.util.sleep(5)
        assert.are.same(1, count)
        a.util.sleep(10)
        assert.are.same(2, count)
    end)
end)
