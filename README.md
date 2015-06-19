# bitness #

[![Build Status](https://travis-ci.org/ignacio/bitness.png?branch=master)](https://travis-ci.org/ignacio/bitness)

Determines the bitness of Lua.

Ever wanted to answer the question _"Is this Lua installation I'm running on 32 or 64 bits?"_. Well, **bitness** gives you the answer.

````lua
local arch = require("bitness")()
print("Lua has been compiled as "..arch.." bits")
````

## How it works? #
Under **PUC Lua**, it inspects the bytecode to get the size of `size_t`. On **LuaJIT** it calls _ffi.abi_ to get the architecture.

## Where does it work? #
Automated tests are run on Lua 5.1, 5,2 and 5.3 and on LuaJIT 2.0.4 and 2.1.

## License #
**bitness** is available under the MIT license.

