package ext;
class Storage {
	static inline var ID = "data";
	public static var data:Map<String, Dynamic>;
	public static function __init__() {
		data = new Map<String, Dynamic>();
		#if userscript
			var tdata = untyped GM_getValue(ID, null);
			if(tdata != null)
				data = haxe.Unserializer.run(tdata);
		#elseif chrome
			untyped chrome.storage.sync.get(ID, function(d:Dynamic) if(d != null && d.data != null) {
					data = cast haxe.Unserializer.run(d.data);
				#if debug
					trace('${data.toString()} loaded');
				#end
			} #if debug else {
				trace('Incompatible value given by Chrome:');
				trace(d);
			} #end);
		#else
			var i = Browser.window.localStorage.getItem(ID);
			if(i != null)
				data = cast haxe.Unserializer.run(i);
		#end
	}
	public static function flush() {
		var adata = haxe.Serializer.run(data);
		#if debug
			trace('Saving: ${data.toString()}');
		#end
		#if userscript
			untyped GM_setValue(ID, adata);
		#elseif chrome
			untyped chrome.storage.sync.set({data: adata}, function() {
				#if debug
					trace("Extension storage saved");
				#end
			});
		#else
			Browser.window.localStorage.setItem(ID, adata);
		#end
	}
}