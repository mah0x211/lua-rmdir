# lua-rmdir

[![test](https://github.com/mah0x211/lua-rmdir/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-rmdir/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-rmdir/branch/master/graph/badge.svg?token=NC0N3888PV)](https://codecov.io/gh/mah0x211/lua-rmdir)

remove a directory file.


## Installation

```
luarocks install rmdir
```

## ok, err = rmdir( pathname [, recursive [, follow_symlink [, approver]]] )

remove a directory.

**Parameters**

- `pathname:string`: path of the directory.
- `recursive:boolean`: remove directories and their contents recursively. (default `false`)
- `follow_symlink:boolean`: follow symbolic links. (default `false`)
- `approver:function`: callback function to be called before removing each entry. (default `nil`)
    ```
    -- Specification of the compiler function
    ok [, err] = approver( entry, isdir )

    -- arguments
    - `entry:string`: path of the entry.
    - `isdir:boolean`: true on entry is directory.

    -- returns
    - `ok:boolean`: return true if the entry can be removed.
    - `err:any`: return any error if the removing process must be aborted immediately.
    ```

**Returns**

- `ok:boolean`: `true` on success.
- `err:any`: error message.

