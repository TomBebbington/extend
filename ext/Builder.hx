package ext;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.*;
import ext.target.*;
using StringTools;
import haxe.io.Path;
#if(macro||sys)
using sys.FileSystem;
using sys.io.File;
#end
class Builder {
	public macro static function meta(e:Expr):Expr {
		var data = haxe.Unserializer.run("plugin/info".getContent());
		return switch(e.expr) {
			case EField({expr: EConst(CIdent("this")), pos: _},name):
				Context.makeExpr(Reflect.field(data, name), Context.currentPos());
			default: throw 'Unknown expression $e';
		}
	}
	public macro static function build(e:ExprOf<Map<String, Dynamic>>):Expr {
		var m:Extension = resolve(e);
		if(m.sites == null)
			m.sites = [];
		if(m.permissions == null)
			m.permissions = [];
		if(m.license == null)
			m.license = "None";
		if(m.resources == null)
			m.resources = [];
		if(!"plugin".exists())
			"plugin".createDirectory();
		var aor = Sys.getCwd().fullPath();
		Sys.setCwd("plugin");
		if(Sys.getCwd().indexOf("plugin") == -1)
			throw "Could not chdir into plugin directory";
		var orig = Sys.getCwd();
		for(t in targets.keys()) {
			if(!Context.defined(t))
				continue;
			if(t.exists())
				delete(t);
			t.createDirectory();
			var at:Target = targets.get(t);
			m.target = t;
			if(at.copyTo != null) {
				if(at.copyTo.length > 0)
					at.copyTo = Path.addTrailingSlash(at.copyTo);
				Sys.setCwd(aor);
				var nr = [];
				for(r in m.resources)
					nr = nr.concat(copy(r, Path.addTrailingSlash('plugin/$t/'.fullPath())+at.copyTo+r));
				m.resources = nr;
				Sys.setCwd("plugin");
			}
			Sys.setCwd(t);
			if(at.iconDir != null && m.icons != null) {
				at.iconDir.createDirectory();
				at.iconDir = Path.addTrailingSlash(at.iconDir);
				var nicons = {};
				for(is in Reflect.fields(m.icons)) {
					var ip:haxe.io.Path = new Path(Reflect.field(m.icons, is)), newloc = '${at.iconDir}${ip.file}.${ip.ext}';
					copy(Path.addTrailingSlash(aor) + ip, newloc);
					Reflect.setField(nicons, is, newloc);
				}
				m.icons = nicons;
				Reflect.setField(m, "icons", nicons);
			}
			var o:String = at.pre(m, aor);
			o.saveContent("");
			o = o.fullPath();
			Compiler.setOutput(o);
			m.output = o;
			Sys.setCwd(orig);
		}
		if(m.skip_compile == null)
			m.skip_compile = Context.defined("skip-closure");
		"info".saveContent(haxe.Serializer.run(m));
		Sys.setCwd(aor);
		return Context.makeExpr(true, Context.currentPos());
	}
	#if(macro||sys)
	static function delete(path:String) {
		if(path.exists() && path.isDirectory()) {
			path = Path.addTrailingSlash(path);
			for(f in path.readDirectory())
				delete(path+f);
		} else if(path.exists())
			path.deleteFile();
	}
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
	/** Copies the file/directory [path] as [to], and returns all the file's paths (no folders) **/
	static function copy(path:String, to:String):Array<String> {
		var a = [];
		if(!path.exists())
			throw 'Path "$path" does not exist in ${Sys.getCwd()}';
		if(path.isDirectory()) {
			path = Path.addTrailingSlash(path);
			to = Path.addTrailingSlash(to);
			if(!to.exists())
				to.createDirectory();
			for(f in path.readDirectory())
				a = a.concat(copy('$path$f', '$to$f'));
		} else {
			'$to'.saveContent(path.getContent());
			a.push(path);
		}
		return a;
	}
	public static var targets:Map<String, Target> = [
		"chrome" => {
			pre: function(e, r) {
				var data:Dynamic = {
					name: e.name.full,
					version: e.version,
					manifest_version: 2,
					description: e.description,
					content_scripts: [{
						matches: e.sites.map(match),
						js: ['${e.name.short}.js']
					}],
					icons: e.icons,
					permissions: ["storage", "notifications"].concat(e.permissions.concat(e.sites).map(match))
				};
				if(e.resources.length > 0)
					data.web_accessible_resources = e.resources;
				"manifest.json".saveContent(haxe.Json.stringify(data));
				return '${e.name.short}.js';
			},
			post: function(e) {
			},
			copyTo: "",
			iconDir: "icons"
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
				var iconSizes = Reflect.fields(e.icons);
				iconSizes.sort(function(a, b) return Std.parseInt(b) - Std.parseInt(a));
				if(iconSizes.length >= 1) {
					var main = iconSizes[0];
					iconSizes = iconSizes.slice(1);
					data.icon = Reflect.field(e.icons, main);
				}
				for(is in iconSizes) {
					var iss:Int = Std.parseInt(is);
					var ip = Reflect.field(e.icons, is);
					Reflect.setField(data, 'icon$is', ip);
				}
				"package.json".saveContent(haxe.Json.stringify(data));
				"data".createDirectory();
				"doc".createDirectory();
				"lib".createDirectory();
				var main = "var data = require(\"self\").data;\nvar pageMod = require(\"page-mod\");\n";
				main += 'pageMod.PageMod({\n\tinclude: ${haxe.Json.stringify(e.sites.map(domain))},\n\tcontentScriptWhen: \'ready\',\n\tcontentScriptFile: data.url("${e.name.short}.js")\n});';
				"lib/main.js".saveContent(main);
				"README.md".saveContent(e.description);
				return 'data/${e.name.short}.js';
			},
			post: function(e) {

			},
			copyTo: "data",
			iconDir: "icons"
		},
		"userscript" => {
			pre: function(e, r) {
				return '${e.name.short}.user.js';
			},
			post: function(e) {
				var includes = [for(s in e.sites) '// @include\t$s'].join("\n"), ns = e.url != null ? '@namespace\t\t${e.url}':"";
				var old = e.output.getContent();
				e.output.saveContent('// ==UserScript==\n// @name\t${e.name.short}\n$ns\n// @description\t${e.description}\n$includes\n// @version\t${e.version}\n// @grant\tGM_xmlhttpRequest\n// @grant\tGM_getValue\n// @grant\tGM_setValue\n// ==/UserScript==\n$old');
			}
		},
		"opera" => {
			pre: function(e, r) {
				if(!"includes".exists())
					"includes".createDirectory();
				var authorref = e.author.url == null ? "" :  ' href="${e.author.url}"';
				var iconxml = "";
				var iconSizes = Reflect.fields(e.icons);
				for(is in Reflect.fields(e.icons)) {
					var ip = Reflect.field(e.icons, is);
					iconxml += '<icon width="$is" height="$is">ip</icon>';
				}
				"config.xml".saveContent('<?xml version="1.0" encoding="utf-8"?>\n<widget xmlns="http://www.w3.org/ns/widgets">\n\t<name>${e.name.full}</name>\n\t<description>${e.description}</description>\n\t<author${authorref}>${e.author.name} (${e.author.username})</author>\n\t$iconxml\n</widget>');
				"index.html".saveContent("");
				return 'includes/${e.name.short}.js';
			},
			post: function(e) {
				var includes = [for(s in e.sites) '// @include\t${match(s)}'].join("\n");
				var old = e.output.getContent();
				e.output.saveContent('// ==UserScript==\n$includes\n// ==/UserScript==\n$old');
				var zip = '../${e.name.short}.oex';
				zip.deleteFile();
				Sys.command('zip -r $zip .');
			},
			copyTo: "",
			iconDir: "icons"
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
			case EConst(CIdent("true")): return true;
			case EConst(CIdent("false")): return false;
			case EObjectDecl(fs):
				var o = {};
				for(f in fs)
					Reflect.setField(o, f.field, resolve(f.expr));
				return o;
			default: trace(e.expr); return null;
		}
	}
	public static function main() {
		Sys.setCwd(Sys.args()[0]);
		if(!"plugin".exists())
			throw "Plugin folder does not exist. Cannot complete extension compilation";
		var old = Sys.getCwd();
		Sys.setCwd("plugin");
		var m:Extension = cast haxe.Unserializer.run("info".getContent());
		var func = function(o) {
			m.output.saveContent(o);
			var t:String = m.target;
			if(!t.exists())
				throw "Unexistant target directory '$t'!";
			Sys.setCwd(t);
			var at:Target = targets.get(t);
			at.post(m);
			Sys.setCwd(old);
		};
		if(m.output.exists()) {
			var output = m.output.getContent();
			if(m.skip_compile)
				func(output);
			else
				Closure.compile(output, func);
		} else throw '${m.output} does not exist in ${Sys.getCwd()}!';
	}
	#end
}