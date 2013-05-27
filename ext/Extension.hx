package ext;

typedef Extension = {
	name: Name,
	author: Author,
	description: Null<String>,
	url: Null<String>,
	version: String,
	icons:Map<Int, String>,
	sites: Null<Array<String>>,
	permissions: Null<Array<String>>,
	license:Null<String>,
	target:String,
	output:String,
	skip_compile:Bool
}
typedef Name = {
	short:String,
	full:String
}
typedef Author = {
	name: String,
	username: String,
	?url:String
}