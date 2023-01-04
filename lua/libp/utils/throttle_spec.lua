require("plenary.async").tests.add_to_env()
local throttle = require("libp.utils.throttle")

describe("max_per_second", function()
    it("Allows max 1 count per second", function()
        local t = throttle.max_per_second(1)
        local actions_performed = 0

        -- Perform 10 actions in a loop
        for _ = 1, 10 do
            if t() then
                actions_performed = actions_performed + 1
            end
        end
        assert.are.same(1, actions_performed)
    end)

    it("Allows max 5 count per second", function()
        local t = throttle.max_per_second(5)
        local actions_performed = 0

        for _ = 1, 10 do
            if t() then
                actions_performed = actions_performed + 1
            end
        end
        assert.are.same(5, actions_performed)
    end)

    it("Takes optional function and returns values", function()
        local i = 0
        local function inc()
            i = i + 1
            return i
        end
        local throttled = throttle.max_per_second(5, inc)

        local res = {}
        for _ = 1, 10 do
            local ran, i = throttled()
            if ran then
                table.insert(res, i)
            end
        end
        assert.are.same({ 1, 2, 3, 4, 5 }, res)
    end)
end)

describe("delay_call_last", function()
    a.it("Only calls the last", function()
        local res = {}
        local d = throttle.delay_call_last(50, function(i)
            table.insert(res, i)
        end)

        for i = 1, 10 do
            d(i)
        end
        a.util.sleep(50)
        assert.are.same({ 10 }, res)
    end)

    a.it("Calls the two last in two time span", function()
        local res = {}
        local d = throttle.delay_call_last(50, function(i)
            table.insert(res, i)
        end)

        for i = 1, 5 do
            d(i)
        end
        a.util.sleep(50)

        for i = 6, 10 do
            d(i)
        end
        a.util.sleep(50)
        assert.are.same({ 5, 10 }, res)
    end)
end)
