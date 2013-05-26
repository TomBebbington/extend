Extend is a Haxe-based framework for development of Web Browser plugins akin to UserScripts, just with a more generalised API.
Developing a plugin
-------------------
Just call ext.Builder.build with your plugin information (defined in ext.Extension)!
For example:
    ext.Builder.build({
    	name: "Useless plugin",
    	author: {
    		name: "Tom Bebbington",
    		username: "TopHattedCoder"
    	},
    	description: "A very very useless plugin. Upping your productivity since tomorrow!",
    	version: "0.1",
    	sites: [
    		"*.haxe.org/*"
    	]
    })
And use a -D flag to choose what you want to target. Currently supported are:
+ Firefox (you'll need the Add-on SDK to build it)
+ Chrome
+ Userscripts (GreaseMonkey/TamperMonkey)