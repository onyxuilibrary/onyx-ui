// Runs the Onyx test suite inside fengari (Lua VM in JS) against the mocked Roblox runtime.
const fs = require("fs");
const path = require("path");
const luaparse = require("luaparse");
const { lua, lauxlib, lualib, to_luastring } = require("fengari");

const sourcePath = path.join(__dirname, "..", "source.lua");
const source = fs.readFileSync(sourcePath, "utf8");

// 1. Syntax: Lua 5.1 grammar is a strict subset of Luau, so passing here means Luau will parse it.
try {
	luaparse.parse(source, { luaVersion: "5.1", comments: false });
	console.log("syntax  ok (Lua 5.1 / Luau compatible)");
} catch (err) {
	console.error("syntax  FAILED:", err.message);
	process.exit(1);
}

// 2. Runtime: load mock, library, then each test file.
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function setGlobalString(name, value) {
	lua.lua_pushstring(L, to_luastring(value));
	lua.lua_setglobal(L, to_luastring(name));
}

setGlobalString("__MOCK_SRC", fs.readFileSync(path.join(__dirname, "mock.lua"), "utf8"));
setGlobalString("__ONYX_SRC", source);
const tests = process.argv.slice(2).length ? process.argv.slice(2) : ["test.lua"];
setGlobalString("__TEST_SRC", tests.map((t) => fs.readFileSync(path.join(__dirname, t), "utf8")).join("\n"));

const driver = `
local function run(src, name)
	local fn, err = load(src, "@" .. name)
	if not fn then error(err, 0) end
	return fn()
end
local ok, err = xpcall(function()
	run(__MOCK_SRC, "mock.lua")
	Onyx = run(__ONYX_SRC, "source.lua")
	run(__TEST_SRC, "test.lua")
end, debug.traceback)
if not ok then
	print("FATAL: " .. tostring(err))
	return 1
end
return __FAILURES or 0
`;

if (lauxlib.luaL_loadstring(L, to_luastring(driver)) !== lua.LUA_OK) {
	console.error(lua.lua_tojsstring(L, -1));
	process.exit(1);
}
if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) {
	console.error(lua.lua_tojsstring(L, -1));
	process.exit(1);
}
const failures = lua.lua_tointeger(L, -1);
process.exit(failures === 0 ? 0 : 1);
