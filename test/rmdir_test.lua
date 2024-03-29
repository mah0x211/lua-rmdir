require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local mkdir = require('mkdir')
local fstat = require('fstat')
local rmdir = require('rmdir')

function testcase.before_each()
    assert(mkdir('./testdir/foo/bar/baz/qux', nil, true))
    local f = assert(io.open('./testdir/hello', 'w'))
    f:write('world')
    f:close()
end

function testcase.after_each()
    os.remove('./testdir/hello')
    local list = {
        'testdir',
        'foo',
        'bar',
        'baz',
        'qux',
    }
    for i = #list, 1, -1 do
        local pathname = './' .. table.concat(list, '/', 1, i)
        os.remove(pathname)
    end
end

function testcase.rmdir()
    -- test that remove directory
    assert(rmdir('./testdir/foo/bar/baz/qux'))
    local stat = fstat('./testdir/foo/bar/baz/qux')
    assert(stat == nil, './testdir/foo/bar/baz/qux is exist')

    -- test that return an error if not exist
    local ok, err = rmdir('./testdir/foo/bar/baz/qux')
    assert.is_false(ok)
    assert.match(err, 'fstat()')

    -- test that return an error if not empty
    ok, err = rmdir('./testdir')
    assert.is_false(ok)
    assert.match(err, 'not empty')

    -- test that return an error if not directory
    ok, err = rmdir('./testdir/hello')
    assert.is_false(ok)
    assert.match(err, 'ENOTDIR')

    -- test that throws an error if pathname argument is invalid
    err = assert.throws(rmdir, {})
    assert.match(err, 'pathname must be string')

    -- test that throws an error if recursive argumnet is invalid
    err = assert.throws(rmdir, './testdir', {})
    assert.match(err, 'recursive must be boolean')

    -- test that throws an error if follow_symlink argumnet is invalid
    err = assert.throws(rmdir, './testdir', nil, {})
    assert.match(err, 'follow_symlink must be boolean')

    -- test that throws an error if approver argumnet is invalid
    err = assert.throws(rmdir, './testdir', nil, nil, {})
    assert.match(err, 'approver must be function')
end

function testcase.rmdir_recursive()
    -- test that remove directory
    assert(rmdir('./testdir', true))
    local stat = fstat('./testdir')
    assert(stat == nil, './testdir is exist')
end

function testcase.rmdir_approve()
    local entries = {
        ['./testdir/foo/bar/baz/qux'] = true,
        ['./testdir/foo/bar/baz'] = true,
        ['./testdir/foo/bar'] = true,
        ['./testdir/foo'] = true,
        ['./testdir/hello'] = false,
        ['./testdir'] = true,
    }
    -- test that calls the approver function and not remove entries
    local ok, err = rmdir('./testdir', true, nil, function(entry, isdir)
        assert.equal(isdir, entries[entry])
        entries[entry] = nil
    end)
    assert.is_false(ok)
    assert.is_nil(err)
    assert.empty(entries)
    local stat = fstat('./testdir')
    assert(stat ~= nil, './testdir is not exist')

    -- test that remove entries if approver return true
    assert(rmdir('./testdir', true, nil, function()
        return true
    end))
    stat = fstat('./testdir')
    assert(stat == nil, './testdir is exist')
end

