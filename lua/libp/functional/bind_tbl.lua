return {

    function(fn, A1)
        return function(...)
            return fn(A1, ...)
        end
    end,

    function(fn, A1, A2)
        return function(...)
            return fn(A1, A2, ...)
        end
    end,

    function(fn, A1, A2, A3)
        return function(...)
            return fn(A1, A2, A3, ...)
        end
    end,

    function(fn, A1, A2, A3, A4)
        return function(...)
            return fn(A1, A2, A3, A4, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5)
        return function(...)
            return fn(A1, A2, A3, A4, A5, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, ...)
        end
    end,

    function(fn, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15)
        return function(...)
            return fn(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, ...)
        end
    end,
}
