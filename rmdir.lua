--
-- Copyright (C) 2022 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- modules
local error = error
local format = string.format
local gsub = string.gsub
local remove = os.remove
local type = type
local fstat = require('fstat')
local opendir = require('opendir')
-- constants
local IGNORE_FILES = {
    ['.'] = true,
    ['..'] = true,
}

--- removedir
--- @param path string
--- @param recursive boolean
--- @param follow_symlink boolean
--- @return boolean ok
--- @return string err
local function removedir(path, recursive, follow_symlink)
    if recursive then
        local dir, err, errno = opendir(path)
        if not dir then
            return false, err, errno
        end

        -- remove contents
        local entry
        entry, err, errno = dir:readdir()
        while entry do
            if not IGNORE_FILES[entry] then
                local target = gsub(path .. '/' .. entry, '/+', '/')
                local stat

                -- check type of entry
                stat, err, errno = fstat(target, follow_symlink)
                if not stat then
                    return false, err, errno
                end

                local ok
                if stat.type ~= 'directory' then
                    ok, err = remove(target)
                else
                    ok, err, errno =
                        removedir(target, recursive, follow_symlink)
                end

                if not ok then
                    return false, err, errno
                end
            end

            entry, err, errno = dir:readdir()
        end

        if err then
            return false, err, errno
        end
    end

    local ok, err = remove(path)
    if not ok then
        return false, err
    end
    return true
end

--- rmdir
--- @param pathname string
--- @param recursive boolean
--- @param follow_symlink boolean
--- @return boolean ok
--- @return string err
local function rmdir(pathname, recursive, follow_symlink)
    if type(pathname) ~= 'string' then
        error('pathname must be string')
    elseif recursive ~= nil and type(recursive) ~= 'boolean' then
        error('recursive must be boolean')
    elseif follow_symlink ~= nil and type(follow_symlink) ~= 'boolean' then
        error('follow_symlink must be boolean')
    end

    local path = gsub(pathname, '/+', '/')
    -- check type of entry
    local stat, err, errno = fstat(path, follow_symlink == true)
    if not stat then
        return false, err, errno
    elseif stat.type ~= 'directory' then
        return false, format('%s is not directory', pathname)
    end

    return removedir(path, recursive, follow_symlink == true)
end

return rmdir
