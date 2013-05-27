package ext;
class Closure {
	public static function compile(code:String, cb:String->Void):Void {
		var h = new haxe.Http("http://closure-compiler.appspot.com/compile");
		h.setParameter("compilation_level", "SIMPLE_OPTIMIZATIONS");
		h.setParameter("output_format", "text");
		h.setParameter("output_info", "compiled_code");
		h.setParameter("js_code", code);
		h.onData = function(d:String) {
			trace(d);
			cb(d);
		}
		h.request(true);
	}
}