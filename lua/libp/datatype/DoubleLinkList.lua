local M = require("libp.datatype.Class"):EXTEND()
local values = require("libp.iter").values

local Node = require("libp.datatype.Class"):EXTEND()
function Node:init(val)
    self.val = val
    self.right = nil
    self.left = nil
end

function Node:link_right(that)
    assert(self ~= that)
    self.right = that
    if that then
        that.left = self
    end
end

function Node:link_left(that)
    assert(self ~= that)
    self.left = that
    if that then
        that.right = self
    end
end

function M:init(head, tail)
    self.head = head
    self.tail = tail
end

function M:_set_head_if_no_left(new_head)
    if new_head and new_head.left == nil then
        self.head = new_head
    end
end

function M:_set_tail_if_no_right(new_tail)
    if new_tail and new_tail.right == nil then
        self.tail = new_tail
    end
end

function M:_ensure_head_tail_correct()
    if self.head then
        self.head.left = nil
    end
    if self.tail then
        self.tail.right = nil
    end

    if self.head == nil then
        self.tail = nil
    elseif self.tail == nil then
        self.head = nil
    end
end

function M:insert(a, val)
    assert(a and a:IS(Node) and val)

    local b = Node(val)

    local ori_right = a.right
    a:link_right(b)
    b:link_right(ori_right)

    self:_set_tail_if_no_right(b)
    return b
end

function M.from_list(lst)
    if not lst or #lst < 1 then
        return
    end

    local head = Node(lst[1])
    local current = head

    for v in values(vim.list_slice(lst, 2)) do
        current:link_right(Node(v))
        current = current.right
    end
    return M(head, current)
end

function M:to_list()
    if not self.head then
        return {}
    end

    local current = self.head
    local res = {}
    while current do
        table.insert(res, current.val)
        current = current.right
    end
    return res
end

function M:to_reverse_list()
    if not self.tail then
        return {}
    end

    local current = self.tail
    local res = {}
    while current do
        table.insert(res, current.val)
        current = current.left
    end
    return res
end

function M:push_front(val)
    local n = Node(val)
    n:link_right(self.head)
    self.head = n
    self:_set_tail_if_no_right(n)
    return n
end

function M:push_back(val)
    local n = Node(val)
    n:link_left(self.tail)
    self:_set_head_if_no_left(n)
    self.tail = n
    return n
end

function M:pop_front()
    local res = self.head
    self.head = self.head and self.head.right or nil
    self:_ensure_head_tail_correct()
    return res
end

function M:pop_back()
    local res = self.tail
    self.tail = self.tail and self.tail.left or nil
    self:_ensure_head_tail_correct()
    return res
end

function M:remove(node)
    if not node then
        return
    end

    if node.left then
        node.left:link_right(node.right)
        self:_set_tail_if_no_right(node.left)
    end
    if node.right then
        node.right:link_left(node.left)
        self:_set_head_if_no_left(node.right)
    end

    if node == self.head then
        self.head = node.right
    elseif node == self.tail then
        self.tail = node.left
    end
    self:_ensure_head_tail_correct()
end

function M:splice_same(paste_before, slice_beg, slice_end)
    -- We cut slice_end and then paste to paste_before. If they are the same, we
    -- will paste to an invalid node.
    if paste_before == slice_end then
        paste_before = slice_end and slice_end.right
    end

    local cut_left_tail = slice_beg and slice_beg.left
    local cut_right_head = slice_end and slice_end.right

    if cut_left_tail then
        cut_left_tail:link_right(cut_right_head)
    end
    if cut_right_head then
        cut_right_head:link_left(cut_left_tail)
    end

    local paste_left_tail
    local paste_right_head
    if paste_before then
        paste_left_tail = paste_before.left
        paste_right_head = paste_before
    else
        -- This is the special case when we cut the tail and then paste to the
        -- tail. In this case, the paste_before was modified above.
        paste_left_tail = slice_beg.left
    end

    if slice_beg then
        slice_beg:link_left(paste_left_tail)
    end
    if slice_end then
        slice_end:link_right(paste_right_head)
    end

    self:_set_head_if_no_left(cut_right_head)
    self:_set_tail_if_no_right(cut_left_tail)
    self:_set_head_if_no_left(slice_beg)
    self:_set_tail_if_no_right(slice_end)
    self:_ensure_head_tail_correct()
end

-- See https://en.cppreference.com/w/cpp/container/list/splice
function M:splice(paste_before, that, slice_beg, slice_end)
    assert(that and that:IS(M))

    if not slice_beg then
        if not slice_end then
            slice_beg = that.head
            slice_end = that.tail
        end
    elseif not slice_end then
        slice_end = slice_beg
    end

    if self == that then
        return self:splice_same(paste_before, slice_beg, slice_end)
    end

    local cut_left_tail = slice_beg and slice_beg.left
    local cut_right_head = slice_end and slice_end.right

    if cut_left_tail then
        cut_left_tail:link_right(cut_right_head)
    end
    if cut_right_head then
        cut_right_head:link_left(cut_left_tail)
    end

    if slice_beg == that.head then
        that.head = cut_right_head
    end
    if slice_end == that.tail then
        that.tail = cut_left_tail
    end
    that:_ensure_head_tail_correct()

    local paste_left_tail
    local paste_right_head
    paste_left_tail = paste_before and paste_before.left
    paste_right_head = paste_before

    if slice_beg then
        slice_beg:link_left(paste_left_tail)
    end
    if slice_end then
        slice_end:link_right(paste_right_head)
    end

    self:_set_head_if_no_left(slice_beg)
    self:_set_tail_if_no_right(slice_end)
    self:_ensure_head_tail_correct()
end

return M
