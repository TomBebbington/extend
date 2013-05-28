package ext;

typedef Extension = {
	name: Name,
	author: Author,
	description: Null<String>,
	url: Null<String>,
	version: String,
	icons:Dynamic<String>,
	sites: Null<Array<String>>,
	permissions: Null<Array<String>>,
	license:Null<String>,
	resources:Array<String>,
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