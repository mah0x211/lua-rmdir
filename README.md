# lua-rmdir

[![test](https://github.com/mah0x211/lua-rmdir/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-rmdir/actions/workflows/test.yml)
[![Coverage Status](https://coveralls.io/repos/github/mah0x211/lua-rmdir/badge.svg?branch=master)](https://coveralls.io/github/mah0x211/lua-rmdir?branch=master)

remove a directory file.


## Installation

```
luarocks install rmdir
```

## ok, err = rmdir( pathname [, recursive] )

remove a directory.

**Parameters**

- `pathname:string`: path of the directory.
- `recursive:boolean`: remove directories and their contents recursively. (default `false`)

**Returns**

- `ok:boolean`: `true` on success.
- `err:string`: error message.

