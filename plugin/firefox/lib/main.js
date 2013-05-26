var data = require("self").data;
var pageMod = require("page-mod");
pageMod.PageMod({
	include: ["*.haxe.org"],
	contentScriptWhen: 'ready',
	contentScriptFile: data.url("useless.js")
});