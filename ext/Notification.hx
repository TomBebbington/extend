package ext;
typedef Notification = {
	/** The title of the notification **/
	title: String,
	/** The message of the notification **/
	message: String,
	/** The URL of the icon to display in the notification **/
	?icon: String,
	/** Called when, and only when, the notification is clicked **/
	?onclick: Void -> Void,
	/** How long it should take to dissappear in seconds **/
	?timeout: Float
}