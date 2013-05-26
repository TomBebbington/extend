import ext.*;
class Test {
	static function main() {
		ext.Builder.build({
			name: {
				short: "useless",
				full: "Useless plugin"
			},
			author: {
				name: "Tom Bebbington",
				username: "TopHattedCoder"
			},
			description: "A very very useless plugin. Upping your productivity since tomorrow!",
			version: "0.1",
			sites: [
				"*.haxe.org/*"
			]
		});
		trace(Http.requestUrl("http://www.reddit.com/r/funny/about.json"));
	}
}