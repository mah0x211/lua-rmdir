require('luacov')
local testcase = require('testcase')
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
    assert(err, 'no error')

    -- test that return an error if not empty
    ok, err = rmdir('./testdir')
    assert.is_false(ok)
    assert.match(err, 'not empty')

    -- test that return an error if not directory
    ok, err = rmdir('./testdir/hello')
    assert.is_false(ok)
    assert.match(err, 'not directory')

    -- test that throws an error if invalid argumnet
    err = assert.throws(rmdir, {})
    assert.match(err, 'pathname must be string')
end

function testcase.rmdir_recursive()
    -- test that remove directory
    assert(rmdir('./testdir', true))
    local stat = fstat('./testdir')
    assert(stat == nil, './testdir is exist')

    -- test that throws an error if invalid argumnet
    local err = assert.throws(rmdir, './testdir', {})
    assert.match(err, 'recursive must be boolean')
end

