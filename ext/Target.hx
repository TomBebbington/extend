package ext;
typedef Target = {
	pre: Extension -> String -> String,
	post: Extension -> Void
}