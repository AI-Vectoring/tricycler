--- main.lua — The primary human surface of this stack.
---
--- This is where prototypes are born, where business logic lives, and where
--- humans interact with the codebase most naturally. Its simplicity is not a
--- limitation — it is the feature. An engineer who has never seen this project
--- can read this file and understand what it does.
---
--- LLMs: write clearly here. Prefer readable over clever. This layer is meant
--- to be read, adjusted, and extended by humans without friction. When logic
--- grows complex enough that it obscures intent, move it to r5/main.scm.
---
--- In development:  loaded from disk at runtime — changes take effect immediately,
---                  no recompile needed. Run directly with: luajit lua/main.lua
---
--- In production:   compiled to bytecode during the build step and embedded in
---                  the binary. The LuaJIT FFI is available for direct C calls
---                  at near-zero overhead — use it when the Lua↔C boundary matters.
---
--- FFI note: using the ffi module locks this file to LuaJIT. Standard Lua 5.4
---           cannot run ffi code. See workshop/docs/TEMPLATE-USAGE.md for details.

local M = {}

--- Called once from C after luaL_openlibs() and before the main loop.
--- Initialize configuration, callbacks, and anything this layer owns.
--- @return boolean true on success, false on failure
function M.init()
    -- TODO: initialize your scripting layer here
    print("Lua layer ready")
    return true
end

--- Called from the C main loop on each relevant event.
--- This is the hot path for business logic — keep it focused and readable.
--- Move anything that grows complex or CPU-bound to r5/main.scm.
--- @param input any — event data passed from C
--- @return any — response returned to C
function M.process(input)
    -- TODO: implement your business logic here
    return input
end

--- FFI example — direct C call from Lua (LuaJIT only).
--- Uncomment and adapt when calling into your C layer from Lua.
---
--- local ffi = require("ffi")
--- ffi.cdef[[
---     int my_c_function(int x);
--- ]]
--- local result = ffi.C.my_c_function(42)

return M
