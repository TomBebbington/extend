package ext;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.*;
import ext.target.*;
using StringTools;
#if macro
using sys.FileSystem;
using sys.io.File;
#end
class Builder {
	public macro static function build(e:ExprOf<Map<String, Dynamic>>):Expr {
		var m:Extension = resolve(e);
		if(m.sites == null)
			m.sites = [];
		if(m.permissions == null)
			m.permissions = [];
		if(m.license == null)
			m.license = "None";
		if(!"plugin".exists())
			"plugin".createDirectory();
		var aor = Sys.getCwd().fullPath();
		Sys.setCwd("plugin");
		"info".saveContent(haxe.Json.stringify(m));
		var orig = Sys.getCwd();
		for(t in targets.keys()) {
			if(!Context.defined(t))
				continue;
			if(!t.exists())
				t.createDirectory();
			Sys.setCwd(t);
			var at:Target = targets.get(t);
			at.pre(m, aor);
			Sys.setCwd(orig);
		}
		Sys.setCwd(aor);
		return Context.makeExpr(true, Context.currentPos());
	}
	#if macro
	static function fullURL(url:String) {
		if(url.indexOf(".") == url.lastIndexOf("."))
			url = 'www.$url';
		if(!url.startsWith("http://") && !url.startsWith("https://"))
			url = 'http://$url';
		return url;
	}
	static function domain(url:String) {
		if(url.startsWith("http://"))
			url = url.substr(7);
		else if(url.startsWith("https://"))
			url = url.substr(8);
		if(url.indexOf("/") != -1)
			url = url.substr(0, url.indexOf("/"));
		if(url.indexOf(".") == url.lastIndexOf("."))
			url = 'www.$url';
		return url;
	}
	static function match(url:String) {
		var secure = url.startsWith("https://");
		url = domain(url);
		url = (secure ? "https" : "http") + "://"+url;
		return '$url/*';
	}
	public static var targets:Map<String, Target> = [
		"chrome" => {
			pre: function(e, r) {
				var values = {
					name: e.name.full,
					version: e.version,
					manifest_version: 2,
					description: e.description,
					content_scripts: [{
						matches: e.sites.map(match),
						js: ['${e.name.short}.js']
					}],
					permissions: ["storage", "notifications"].concat(e.permissions.concat(e.sites).map(match))
				};
				if(e.icons != null) {
					Reflect.setField(values, "icons", e.icons);
					for(is in Reflect.fields(e.icons)) {
						var ip:String = Reflect.field(e.icons, is);
						var old = Sys.getCwd();
						Sys.setCwd(r);
						var b:Null<haxe.io.Bytes> = ip.exists() ? ip.getBytes() : null;
						Sys.setCwd(old);
						if(b != null)
							ip.saveBytes(b);
					}
				}
				"manifest.json".saveContent(haxe.Json.stringify(values));
				var target = '${e.name.short}.js';
				target.saveContent("");
				Compiler.setOutput(target.fullPath());
			},
			post: function(e) {
			}
		},
		"firefox" => {
			pre: function(e, r) {
				var id = e.url != null ? '${e.name.short}@${e.url}' : '${e.name.short}@${e.author.username}';
				var data:Dynamic = {
					name: e.name.short,
					fullName: e.name.full,
					id: id,
					description: e.description,
					author: e.author.name,
					license: e.license,
					version: e.version
				};
				if(e.icons != null)
					for(i in Reflect.fields(e.icons)) {
						var ip = Reflect.field(e.icons, i);
						if(data.icon == null)
							data.icon = ip;
						else
							Reflect.setField(data, 'icon$i', ip);
						var old = Sys.getCwd();
						Sys.setCwd(r);
						trace('ip: $ip, i: $i');
						var b:Null<haxe.io.Bytes> = ip.exists() ? ip.getBytes() : null;
						Sys.setCwd(old);
						if(b != null)
							ip.saveBytes(b);
					}
				"package.json".saveContent(haxe.Json.stringify(data));
				"data".createDirectory();
				"doc".createDirectory();
				"lib".createDirectory();
				var main = "var data = require(\"self\").data;\nvar pageMod = require(\"page-mod\");\n";
				main += 'pageMod.PageMod({\n\tinclude: ${haxe.Json.stringify(e.sites.map(domain))},\n\tcontentScriptWhen: \'ready\',\n\tcontentScriptFile: data.url("${e.name.short}.js")\n});';
				"lib/main.js".saveContent(main);
				"README.md".saveContent(e.description);
				var out = 'data/${e.name.short}.js';
				out.saveContent("");
				out = out.fullPath();
				Compiler.setOutput(out);
			},
			post: function(e) {

			}
		},
		"userscript" => {
			pre: function(e, r) {
				var includes = [for(s in e.sites) '// @include\t\t\t$s'].join("\n"), ns = e.url != null ? '@namespace\t\t${e.url}':"";
	'${e.name.short}.user.info.js'.saveContent('// ==UserScript==
// @name			${e.name.short}
$ns
// @description		${e.description}
$includes
// @version			${e.version}
// @grant			GM_xmlhttpRequest
// @grant			GM_getValue
// @grant			GM_setValue
// ==/UserScript==');
				'${e.name.short}.user.js'.saveContent("");
				Compiler.setOutput('${e.name.short}.user.js'.fullPath());
			},
			post: function(e) {

			}
		}
	];
	static function resolve(e:Expr):Dynamic {
		switch(e.expr) {
			case EArrayDecl(vs) if(vs.length == 0 || switch(vs[0].expr) {case EBinop(Binop.OpArrow, _, _): false; default: true;}):
				return [for(v in vs) resolve(v)];
			case EArrayDecl(vs):
				var o = {};
				for(v in vs)
					switch(v.expr) {
						case EBinop(OpArrow, a, b):
							Reflect.setField(o, Std.string(resolve(a)), resolve(b));
						default: 
					}
				return o;
			case EConst(CString(s)): return s;
			case EConst(CInt(s)): return Std.parseInt(s);
			case EConst(CFloat(s)): return Std.parseFloat(s);
			case EObjectDecl(fs):
				var o = {};
				for(f in fs)
					Reflect.setField(o, f.field, resolve(f.expr));
				return o;
			default: trace(e.expr); return null;
		}
	}
	public static function generate() {
		Compiler.define("dce", "full");
		/*var m:Extension = cast haxe.Unserializer.run("temp".getContent());
		//"temp".deleteFile();
		var aor = Sys.getCwd();
		Sys.setCwd("plugin");
		var orig = Sys.getCwd();
		for(t in targets.keys()) {
			if(!Context.defined(t))
				continue;
			if(!t.exists())
				t.createDirectory();
			Sys.setCwd(t);
			var at:Target = targets.get(t);
			trace('Building for $t');
			at.post(m);
			Sys.setCwd(orig);
		}
		Sys.setCwd(aor);*/
	}
	#end
}