package ext;
import js.html.*;
class Browser {
	public static inline var EXTENSION_TYPE = #if userscript "Userscript" #elseif chrome "Chrome extension" #elseif firefox "Firefox extension" #elseif opera "Opera extension" #else "Unknown" #end;
	public static var window(get, never):DOMWindow;
	static inline function get_window() {
		#if userscript
			return untyped unsafeWindow;
		#else
			return untyped __js__("window");
		#end
	}
	public static var document(get, never):Document;
	static inline function get_document() {
		return untyped __js__("document");
	}
	public static var navigator(get, never):Navigator;
	static inline function get_navigator() {
		return untyped __js__("navigator");
	}
	public static var location(get, never):Location;
	static inline function get_location() {
		return untyped __js__("location");
	}
	public static function onload(cb:Void->Void) {
		switch(document.readyState) {
			case "complete": cb();
			default: untyped window.onload = function(_) cb();
		}
	}
}