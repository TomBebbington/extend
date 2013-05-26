package ext;
import js.*;
class Storage {
	static inline var ID = "data";
	public static var data:Map<String, Dynamic>;
	public static function __init__() {
		data = new Map<String, Dynamic>();
		#if userscript
			data = untyped GM_getValue(ID, data);
		#elseif chrome
			untyped chrome.storage.sync.get(ID, function(d) data = cast d);
		#else
			var i = Browser.getLocalStorage().getItem(ID);
			if(i != null)
				data = cast haxe.Unserializer.run(i);
		#end
	}
	public static function flush() {
		#if userscript
			untyped GM_setValue(ID, data);
		#elseif chrome
			untyped chrome.storage.sync.set(ID, function(d) data = cast d);
		#else
			Browser.getLocalStorage().setItem(ID, haxe.Serializer.run(data));
		#end
	}
}