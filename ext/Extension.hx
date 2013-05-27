package ext;

typedef Extension = {
	var name: Name;
	var author: Author;
	var description: Null<String>;
	var url: Null<String>;
	var version: String;
	var icons:Map<Int, String>;
	var sites: Null<Array<String>>;
	var permissions: Null<Array<String>>;
	var license:Null<String>;
	var target:String;
	var output:String;
}
typedef Name = {
	var short:String;
	var full:String;
}
typedef Author = {
	var name: String;
	var username: String;
}