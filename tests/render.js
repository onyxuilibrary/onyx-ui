// Renders a scene from render.lua to static HTML (used for the screenshots in docs/images).
// usage: node render.js <scene> <out.html> [viewW viewH cssScale]
// scenes: main, sidebar, settings, keysystem, changelog, mobile, crowded, discord (mobile uses 993 459 0.85)
// then screenshot the page at its size, e.g. with headless Chrome/Edge:
//   msedge --headless --window-size=1280,720 --virtual-time-budget=6000 --screenshot=main.png http://localhost/main.html
// (serve it over http so the Inconsolata web font loads)
const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring } = require("fengari");

const [scene = "main", out = "preview.html", vw = "1280", vh = "720", css = "1"] = process.argv.slice(2);
const viewW = Number(vw), viewH = Number(vh), cssScale = Number(css);

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
const setStr = (n, v) => { lua.lua_pushstring(L, to_luastring(v)); lua.lua_setglobal(L, to_luastring(n)); };
const setNum = (n, v) => { lua.lua_pushnumber(L, v); lua.lua_setglobal(L, to_luastring(n)); };
setStr("__MOCK_SRC", fs.readFileSync(path.join(__dirname, "mock.lua"), "utf8"));
setStr("__ONYX_SRC", fs.readFileSync(path.join(__dirname, "..", "source.lua"), "utf8"));
setStr("__RENDER_SRC", fs.readFileSync(path.join(__dirname, "render.lua"), "utf8"));
setStr("__SCENE", scene);
setNum("__VW", viewW);
setNum("__VH", viewH);

const driver = `
local ok, err = xpcall(function()
	load(__MOCK_SRC, "@mock.lua")()
	__mock.setViewport(Vector2.new(__VW, __VH))
	Onyx = load(__ONYX_SRC, "@source.lua")()
	load(__RENDER_SRC, "@render.lua")()
end, debug.traceback)
if not ok then error(err, 0) end
if #__mock.errors > 0 then error(__mock.errors[1], 0) end
return __RENDER_JSON`;
lauxlib.luaL_loadstring(L, to_luastring(driver));
if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) { console.error(lua.lua_tojsstring(L, -1)); process.exit(1); }
const nodes = JSON.parse(lua.lua_tojsstring(L, -1));

const rgba = (c) => `rgba(${c[0]},${c[1]},${c[2]},${c[3].toFixed(3)})`;
const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
let html = "";
for (const n of nodes) {
	let style = `left:${n.x}px;top:${n.y}px;width:${Math.max(0, n.w)}px;height:${Math.max(0, n.h)}px;`;
	if (n.bg[3] > 0) {
		if (n.grad && n.grad.stops.length) {
			const stops = n.grad.stops.map(([t, c]) => {
				const mixed = [Math.round((c[0] * n.bg[0]) / 255), Math.round((c[1] * n.bg[1]) / 255), Math.round((c[2] * n.bg[2]) / 255), n.bg[3]];
				return `${rgba(mixed)} ${(t * 100).toFixed(1)}%`;
			});
			style += `background:linear-gradient(${n.grad.rot + 90}deg, ${stops.join(",")});`;
		} else {
			style += `background:${rgba(n.bg)};`;
		}
		if (n.grad && n.grad.t0 !== undefined && n.grad.t0 !== null) {
			style += `-webkit-mask-image:linear-gradient(${n.grad.rot + 90}deg, rgba(0,0,0,${1 - n.grad.t0}), rgba(0,0,0,${1 - n.grad.t1}));`;
		}
	}
	if (n.stroke) style += `outline:1px solid ${rgba(n.stroke)};`;
	if (n.clip) style += `clip-path:inset(${n.clip[1] - n.y}px ${n.x + n.w - n.clip[2]}px ${n.y + n.h - n.clip[3]}px ${n.clip[0] - n.x}px);`;
	let inner = "";
	if (n.text !== undefined) {
		const just = n.xa === "Center" ? "center" : n.xa === "Right" ? "flex-end" : "flex-start";
		const align = n.ya === "Top" ? "flex-start" : n.ya === "Bottom" ? "flex-end" : "center";
		style += `display:flex;justify-content:${just};align-items:${align};color:${rgba(n.tc)};font-size:${n.ts}px;line-height:${n.ts}px;padding:${n.pad[0]}px ${n.pad[1]}px ${n.pad[2]}px ${n.pad[3]}px;box-sizing:border-box;white-space:${n.wrap ? "pre-wrap" : "pre"};overflow:hidden;`;
		inner = `<span style="text-align:${n.xa.toLowerCase()}">${esc(n.text)}</span>`;
	}
	if (n.img === "avatar") style += "background:linear-gradient(160deg,#c9a27a,#8a6a4c);";
	html += `<div style="${style}">${inner}</div>\n`;
}

const pageW = Math.round(viewW * cssScale), pageH = Math.round(viewH * cssScale);
fs.writeFileSync(out, `<!doctype html><meta charset="utf-8"><title>Onyx preview</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inconsolata:wght@400;500&display=block" rel="stylesheet">
<style>
html,body{margin:0;width:${pageW}px;height:${pageH}px;overflow:hidden;background:#0b0f14}
#bg{position:absolute;inset:0;background:
 radial-gradient(1200px 500px at 20% 110%, #1d3b2a 0%, transparent 60%),
 radial-gradient(900px 600px at 90% -10%, #22324a 0%, transparent 55%),
 linear-gradient(180deg,#1a2230 0%,#10151c 55%,#0c1015 100%)}
#bg:after{content:"";position:absolute;inset:0;background:repeating-linear-gradient(90deg,rgba(255,255,255,.015) 0 1px,transparent 1px 64px),repeating-linear-gradient(0deg,rgba(255,255,255,.015) 0 1px,transparent 1px 64px)}
#ui{position:absolute;left:0;top:0;width:${viewW}px;height:${viewH}px;transform:scale(${cssScale});transform-origin:0 0;font-family:Inconsolata,Consolas,monospace;-webkit-font-smoothing:antialiased}
#ui div{position:absolute}
</style>
<div id="bg"></div><div id="ui">
${html}</div>`);
console.log(`wrote ${out} (${nodes.length} nodes, ${pageW}x${pageH})`);
