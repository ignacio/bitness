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

The module exports a single function that when called will return 32, 64 or throw an error if it can't determine the bitness.

## Where does it work? #
Automated tests are run with Lua 5.1, 5,2 and 5.3 and LuaJIT 2.0.4, 2.1 on both x86 and x64 platforms.

It won't work on your [ZX Spectrum](https://en.wikipedia.org/wiki/ZX_Spectrum)or your old trusty [80286](https://en.wikipedia.org/wiki/Intel_80286). Tests probably won't run out of the box on ARM. Patches welcome.

## License #
**bitness** is available under the MIT license.

