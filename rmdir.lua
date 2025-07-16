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
local type = type
local fstat = require('fstat')
local opendir = require('opendir')
local errorf = require('error').format
local ENOTDIR = require('errno').ENOTDIR
local remove = require('os.remove')
-- constants
local IGNORE_FILES = {
    ['.'] = true,
    ['..'] = true,
}

--- DEFAULT_APPROVER
--- @param entry string
--- @param isdir boolean
--- @return boolean ok
--- @return any err
local function DEFAULT_APPROVER(entry, isdir)
    -- luachek: ignore entry, isdir
    return true
end

--- check if a directory exists and is a directory
--- @param path string
--- @param follow_symlink boolean
--- @return boolean isdir
--- @return any err
local function isdir(path, follow_symlink)
    -- check type of entry
    local stat, ferr = fstat(path, follow_symlink)
    if not stat then
        return false, errorf('failed to fstat()', ferr)
    end
    return stat.type == 'directory'
end

--- remove specified entry
--- @param path string
--- @param approver function
--- @param is_dir boolean
--- @return boolean ok
--- @return any err
local function rment(path, approver, is_dir)
    local ok, err = approver(path, is_dir)
    if err ~= nil then
        return false, errorf('failed to approver()', err)
    elseif ok then
        return remove(path)
    end
    return true
end

--- removedir
--- @param path string
--- @param recursive boolean
--- @param follow_symlink boolean
--- @param approver function
--- @return boolean ok
--- @return any err
local function removedir(path, recursive, follow_symlink, approver)
    if recursive then
        local dir, err = opendir(path)
        if not dir then
            return false, err
        end

        -- remove all entries in the directory
        local entry
        entry, err = dir:readdir()
        while entry do
            if not IGNORE_FILES[entry] then
                local target = gsub(path .. '/' .. entry, '/+', '/')

                -- check if target is a directory
                local ok
                ok, err = isdir(target, follow_symlink)
                if err then
                    return false, err
                elseif ok then
                    -- if target is a directory, recursively remove it
                    ok, err = removedir(target, recursive, follow_symlink,
                                        approver)
                else
                    ok, err = rment(target, approver, false)
                end

                -- if there was an error removing the entry, return it
                if not ok and err then
                    return false, errorf('failed to remove %s', target, err)
                end
            end

            -- read next entry
            entry, err = dir:readdir()
        end

        if err then
            return false, err
        end
    end

    -- finally, remove the directory itself
    return rment(path, approver, true)
end

--- rmdir
--- @param pathname string
--- @param recursive boolean?
--- @param follow_symlink boolean?
--- @param approver function?
--- @return boolean ok true if all entries were removed
--- @return any err
local function rmdir(pathname, recursive, follow_symlink, approver)
    if type(pathname) ~= 'string' then
        error('pathname must be string')
    elseif recursive ~= nil and type(recursive) ~= 'boolean' then
        error('recursive must be boolean')
    elseif follow_symlink ~= nil and type(follow_symlink) ~= 'boolean' then
        error('follow_symlink must be boolean')
    elseif approver == nil then
        approver = DEFAULT_APPROVER
    elseif type(approver) ~= 'function' then
        error('approver must be function')
    end

    recursive = recursive == true
    follow_symlink = follow_symlink == true

    -- confirm that pathname is a directory
    local path = gsub(pathname, '/+', '/')
    local ok, err = isdir(path, follow_symlink)
    if not ok then
        return false, err or ENOTDIR:new(format('%q', pathname))
    end

    local approved = true
    ok, err = removedir(path, recursive, follow_symlink, function(...)
        ok, err = approver(...)
        if not ok then
            approved = false
            if err then
                return false, errorf('failed to approver()', err)
            end
            return false
        end
        return true
    end)

    return approved and ok, err
end

return rmdir
