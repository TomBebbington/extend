package ext;
import haxe.ds.*;
#if userscript
class Http {
	public var url:String;
	public var responseData(default, null):Null<String>;
	public var async:Bool;
	var postData:String;
	var headers:StringMap<String>;
	var params:StringMap<String>;
	public function new(url:String) {
		this.url = url;
		headers = new haxe.ds.StringMap();
		params = new haxe.ds.StringMap();
		async = true;
	}
	public function setHeader(header:String, value:String):Http {
		headers.set(header, value);
		return this;
	}
	public function setParameter(param:String, value:String):Http {
		params.set(param, value);
		return this;
	}
	public function setPostData(data:String):Http {
		postData = data;
		return this;
	}
	public function request(post:Bool = false) {
		var r:Dynamic = {
			synchronous: !this.async,
			method: post ? "POST" : "GET",
			url: this.url
		};
		if(this.headers.iterator().hasNext())
			r.headers = toObject(this.headers);
		if(this.postData != null)
			r.data = this.postData;
		var r:js.html.XMLHttpRequest = untyped GM_xmlhttpRequest(r);
		var onreadystatechange = function(_) {
			if(r.readyState != 4)
				return;
			var s = try r.status catch(e : Dynamic) null;
			if(s == untyped __js__("undefined"))
				s = null;
			if(s != null)
				this.onStatus(s);
			if(s != null && s >= 200 && s < 400)
				this.onData(this.responseData = r.responseText);
			else if (s == null)
				this.onError("Failed to connect or resolve host")
			else switch(s) {
			case 12029:
				this.onError("Failed to connect to host");
			case 12007:
				this.onError("Unknown host");
			default:
				this.responseData = r.responseText;
				this.onError("Http Error #"+r.status);
			}
		}
		if(async)
			r.onreadystatechange = onreadystatechange;
		else
			onreadystatechange(null);
	}
	public dynamic function onData(data:String) {
	}
	public dynamic function onError(msg:String) {
	}
	public dynamic function onStatus(status:Int) {
	}
	public static function requestUrl(url:String):String {
		var h = new Http(url);
		h.async = false;
		var r = null;
		h.onData = function(d) r = d;
		h.onError = function(e) throw e;
		h.request(false);
		return r;
	}
	static function toObject(m:StringMap<Dynamic>):Dynamic {
		var o:Dynamic = {};
		for(k in m.keys())
			Reflect.setField(o, k, Reflect.field(o, k));
		return o;
	}
}
#else typedef Http = haxe.Http #end