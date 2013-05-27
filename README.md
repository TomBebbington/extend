Extend is a Haxe-based framework for development of Web Browser plugins akin to UserScripts, just with a more generalised API.
Developing a plugin
-------------------
Just call ext.Builder.build with your plugin information.

For example:

    ext.Builder.build({
    	name: {
            short: "useless",
            full: "Useless plugin"
        },
    	author: {
    		name: "Stevey McStevenson",
    		username: "steve"
    	},
    	description: "A very very useless plugin. Upping your productivity since tomorrow!",
    	version: "0.1",
    	sites: [
    		"*.haxe.org/*"
    	]
    })

And use a -D flag to choose what you want to target. Currently supported are:
+ Firefox (you'll need the Add-on SDK to build it)
+ Chrome (it will be unpacked; you still need to zip & publish it on the Chrome Web Store)
+ Greasemonkey

Then add the following in your hxml file:

    -cmd haxelib run extend

