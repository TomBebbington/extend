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
	#if chrome
	static var nid = 0;
	#end
	public static function notify(n:ext.Notification) {
		#if chrome
			var opt = {
				type: "basic",
				title: n.title,
				message: n.message,
				iconUrl: n.icon
			};
			try {
				untyped chrome.notifications.create(Std.string(nid++), opt, function(id:String){});
			}
			catch(e:Dynamic) {
		#end
			if(window.notifications != null) {
				if(window.notifications.checkPermission() != 0)
					window.notifications.requestPermission(function() {
						window.notifications.createNotification(null, n.title, n.message);
						return true;
					});
				else
					window.notifications.createNotification(null, n.title, n.message);
			} else
				trace("No notifications object found");
		#if chrome
		}
		#end
	}
}