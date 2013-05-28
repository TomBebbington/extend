package ext;
#if macro
import sys.*;
import sys.io.*;
import haxe.macro.*;
#end
using haxe.crypto.BaseCode;
class Resource {
	static var b64:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
	static var cssfile:EReg = ~/file\(('|")([^'"]*)\1\)/;
	static function encode(str:String):String {
		var r = str.encode(b64);//also does utf-8 encoding
		//add padding:
		switch(r.length%4) {
			case 2: r += '==';
			case 3:  r += '=';
		}
		return r;
	}
	#if macro
	static function getN(path:String, mime:String=""):String {
		if(!FileSystem.exists(path))
			throw '$path does not exist';
		var p = new haxe.io.Path(path);
		if(mime.length == 0 && p.ext != null && p.ext.length > 0)
			mime = switch(p.ext.toLowerCase()) {
				case "jpg", "png", "jpeg", "gif", "webp", "bmp": 'image/${p.ext}';
				case "css": "text/css";
				case "txt": "text/plain";
				case "html": "text/html";
				default: "";
			}
		var cont = File.getContent(path);
		if(mime == "text/css") {
			while(cssfile.match(cont)) {
				var path = cssfile.matched(2);
				var pcont = getN(path);
				cont = cssfile.replace(cont, 'url("$pcont")');
			}
		}
		var encoded:String = encode(cont);
		var final = 'data:$mime;base64,$encoded';
		return final;
	}
	#end
	/** Returns a URL suitable for embedding in a webpage of the resource **/
	#if chrome
	public static function get(path:String, callb:String->Void):Void {
		callb(untyped chrome.extension.getURL(path));
	}
	#elseif opera
	public static function get(path:String, callb:String->Void):Void {
		var file = untyped opera.extension.getFile('/$path');
		if(file != null) {
			var fr = new js.html.FileReader();
			fr.onload = function(_) callb(fr.result);
			fr.readAsDataURL(file);
		}
	}
	#else
	public static macro function get(path:String, callb:Expr.ExprOf<String->Void>):Expr {
		var v = Context.makeExpr(getN(path), Context.currentPos());
		return macro $callb($v);
	}
	#end
}