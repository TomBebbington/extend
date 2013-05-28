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
		#if(firefox||chrome)
			HTML5Notification.requestPermission(function(g:String) {
				switch(g.toLowerCase()) {
					case "granted":
						var f = new HTML5Notification(n.title, {
							body: n.message
						});
						f.onshow = function(_) if(n.timeout != null) untyped setTimeout(f.close, n.timeout * 1000);
						f.onclose = function(_) if(n.onclick != null) n.onclick();
					default: trace('Permission $g granted or not?'); throw g;
				}
			});
		#else
			var not:js.html.NotificationCenter = #if chrome untyped window.webkitNotifications #else window.notifications #end;
			if(not != null) {
				if(not.checkPermission() != 0)
					not.requestPermission(function() {
						not.createNotification(null, n.title, n.message);
						return true;
					});
				else
					not.createNotification(null, n.title, n.message);
			} else
				trace("No notifications object found");
		#end
	}
}

#if(firefox||chrome)
@:native("Notification") extern class HTML5Notification {
	public function new(title:String, info:{?dir:String, ?lang:String, ?body:String, ?tag:String}) {}
	public var onclose:Dynamic->Void;
	public var onshow:Dynamic->Void;
	public var onerror:Dynamic->Void;
	public function close():Void;
	public static function requestPermission(ongrant:String->Void):Void {}
}
#end