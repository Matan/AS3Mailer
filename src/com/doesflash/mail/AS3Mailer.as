package com.doesflash.mail
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;

	/**
	 * Dispatches once the server script has returned with positive results.
	 */
	[Event(name="complete", type="flash.events.Event")]
	/**
	 * Dispatches if an error has occured.
	 */
	[Event(name="error", type="flash.events.ErrorEvent")]

	/**
	 * AS3Mailer sends emails from Flash using either a server script or a mailto link.
	 * 
	 * @author Matan Uberstein
	 */
	public class AS3Mailer extends EventDispatcher
	{
		/**
		 * URL to the server script that sends the email.
		 */
		public var scriptURL : String;

		/**
		 * The mimeVersion, this get's included in the email's header.
		 * 
		 * @default "1.0"
		 */
		public var mimeVersion : String = "1.0";

		/**
		 * The email type. Options are: "text/html" or "text/plain".
		 * 
		 * @default "text/html"
		 * 
		 * @see #TEXT_HTML
		 * @see #TEXT_PLAIN
		 */
		public var type : String = "text/html";

		/**
		 * The email characher set, only applies if email is of type "text/html".
		 * 
		 * @default "utf-8"
		 */
		public var charset : String = "utf-8";

		/**
		 * The sender's address.
		 */
		public var from : String;
		/**
		 * The email's subject.
		 */
		public var subject : String;
		/**
		 * The email's message.
		 */
		public var message : String;
		/**
		 * The URL to the message.
		 */
		public var messageURL : String;

		/**
		 * Constant for HTML email types.
		 * 
		 * @see #type
		 */
		public static const TEXT_HTML : String = "text/html";

		/**
		 * Constant for PLAIN email types.
		 * 
		 * @see #type
		 */
		public static const TEXT_PLAIN : String = "text/plain";

		/**
		 * Constant for TO recipient list.
		 * 
		 * @see #getRecipientList()
		 */
		public static const TO : String = "to";
		/**
		 * Constant for CC recipient list.
		 * 
		 * @see #getRecipientList()
		 */
		public static const CC : String = "cc";
		/**
		 * Constant for BCC recipient list.
		 * 
		 * @see #getRecipientList()
		 */
		public static const BCC : String = "bcc";

		/**
		 * Constant for clearing all recipient list.
		 * 
		 * @see #clearRecipients()
		 */
		public static const ALL : String = "all";

		/**
		 * @private
		 */
		protected var _to : Array = [];
		/**
		 * @private
		 */
		protected var _cc : Array = [];
		/**
		 * @private
		 */
		protected var _bcc : Array = [];

		public function AS3Mailer(scriptURL : String = null)
		{
			this.scriptURL = scriptURL;
		}

		/**
		 * Sets the proper "From" address.
		 * 
		 * @param address The sender's email address. E.g. "no-reply&#38;doesflash.com"
		 * @param name The sender's name.
		 * 
		 * @see #from
		 * @see #getFullAddress()
		 */
		public function setFrom(address : String, name : String = null) : void
		{
			from = getFullAddress(address, name);
		}

		/**
		 * Add a recipient, either to "To", "Cc" or "Bcc" field of the email.
		 * 
		 * @param address The recipient's email address.
		 * @param name The recipient's name.
		 * @param type The corresponding recipient list to add to. Options are "to", "cc" or "bcc".
		 * 
		 * @see #getFullAddress()
		 * @see #getRecipientList()
		 * @see #TO
		 * @see #CC
		 * @see #BCC
		 * 
		 * @return The index where the recipient was added.
		 */
		public function addRecipient(address : String, name : String = null, type : String = "to") : int
		{
			var list : Array = getRecipientList(type);
			list.push(getFullAddress(address, name));
			return list.length - 1;
		}

		/**
		 * Removes a recipient at index given, from the list specified.
		 * 
		 * @param index The index where the recipient should be removed.
		 * @param type The corresponding recipient list to add to. Options are "to", "cc" or "bcc".
		 * 
		 * @see #addRecipient()
		 * @see #getRecipientList() 
		 */
		public function removeRecipientAt(index : int, type : String = "to") : String
		{
			return getRecipientList(type).splice(index, 1)[0];
		}

		/**
		 * Clears the recipient list of your choice or all of them.
		 * 
		 * @param type The corresponding recipient list to clear. Options are "to", "cc", "bcc" or "all".
		 */
		public function clearRecipients(type : String = "all") : void
		{
			switch(type)
			{
				case ALL:
					clearRecipients(TO);
					clearRecipients(CC);
					clearRecipients(BCC);
					break;
				case TO:
					_to = [];
					break;
				case CC:
					_cc = [];
					break;
				case BCC:
					_bcc = [];
					break;
				default:
					throw new ArgumentError("Argument 'type' not recognized! Options are: 'to', 'cc', 'bcc' or 'all'.");
			}
		}

		/**
		 * Sends the email, either by using the server script or by invoking a "mailto" hyper link.
		 * <p>
		 * <strong>Types of execution:</strong>
		 * <ul>
		 * 	<li>If "scriptURL" present: Post information to server script, server sends email.</li>
		 * 	<li>If "scriptURL" NOT present: Format "mailto" link, invoke mailto.</li>
		 * </ul>
		 * <strong>Note:</strong> There are two ways of passing the email body (aka message), setting directly
		 * via "message" or setting the "messageURL". "message" will alway take preferance over "messageURL", thus
		 * if "message" is set, the "messageURL" will not be loaded.
		 * Also, if the "scriptURL" is set, the server will load the message, NOT Flash, but if not set, Flash will load
		 * the message and attach it to the mailto link.
		 * </p>
		 * <p>
		 * <strong>Note:</strong> Any parameter passed will overwrite any existing values. E.g. Passing parameter "from" will
		 * overwrite the sender's address set via the "mailer.setFrom();" function and the "mailer.from" setter.
		 * </p>
		 * 
		 * @param from Quick access for the sender's email address.
		 * @param to Quick access for the recipient. Can also be a comma separated list of recipients. E.g. myRecipients.toString();
		 * @param subject Quick access for email subject.
		 * @param message Quick access for email message.
		 * 
		 * @see @scriptURL
		 * @see @message
		 * @see @messageURL
		 */
		public function send(from : String = null, to : String = null, subject : String = null, message : String = null) : void
		{
			this.from ||= from;
			if(to)
				_to = to.split(",");
			this.subject ||= subject;
			this.message ||= message;

			if(scriptURL)
				sendViaScript();
			else if(this.message)
				sendViaClient();
			else if(this.messageURL)
				loadMessage(this.messageURL);

		}

		/**
		 * Formats address and name into a proper full email address format.
		 * 
		 * @param address The email's address. e.g. "matan&#38;example.com"
		 * @param name The email's name prefix. e.g. "Matan Uberstein"
		 * @param braces What braces to use around the email address. The first characher represents the opening brace and the second characher represents the closing brace.
		 * 
		 * @return Formated email address String. e.g. "Matan Uberstein &lt;matan&#38;example.com&gt;"
		 */
		public function getFullAddress(address : String, name : String = null, braces : String = "<>") : String
		{
			return (name ? name + " " + braces.charAt(0) : "") + address + (name ? braces.charAt(1) : "");
		}

		/**
		 * Validates email address.
		 * 
		 * return Whether it is valid or not.
		 */
		public function isValidEmail(address : String) : Boolean
		{
			var exp : RegExp = /\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b/i;
			return exp.test(address);
		}

		/**
		 * Gets the recipients list according to type passed.
		 * 
		 * @param type The corresponding recipient list to add to. Options are "to", "cc" or "bcc".
		 */
		public function getRecipientList(type : String) : Array
		{
			var list : Array;
			switch(type)
			{
				case TO:
					list = _to;
					break;
				case CC:
					list = _cc;
					break;
				case BCC:
					list = _bcc;
					break;
				default:
					throw new ArgumentError("Argument 'type' not recognized! Options are: 'to', 'cc' or 'bcc'.");
			}
			return list;
		}

		// --------------------------------------------------------------------------------------------------------------------------------//
		// PROTECTED
		// --------------------------------------------------------------------------------------------------------------------------------//
		/**
		 * @private
		 */
		protected function sendViaScript() : void
		{
			var vrs : URLVariables = new URLVariables();
			if(from) vrs.from = from;
			if(_to.length > 0)
				vrs.to = _to.join(", ");
			if(_cc.length > 0)
				vrs.cc = _cc.join(", ");
			if(_bcc.length > 0)
				vrs.bcc = _bcc.join(", ");
			if(mimeVersion) vrs.mimeVersion = mimeVersion;
			if(type) vrs.type = type;
			if(charset) vrs.charset = charset;
			if(subject) vrs.subject = subject;
			if(message) vrs.message = message;
			if(messageURL) vrs.messageURL = messageURL;

			var req : URLRequest = new URLRequest(scriptURL);
			req.contentType = "application/x-www-form-urlencoded";
			req.method = URLRequestMethod.POST;
			req.data = vrs;

			var loader : URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			addScriptListeners(loader);
			loader.load(req);
		}

		/**
		 * @private
		 */
		protected function sendViaClient() : void
		{
			var mailTo : String = "mailto:" + _to.join("; ");

			var vrs : URLVariables = new URLVariables();
			if(_cc.length > 0)
				vrs.cc = _cc.join("; ");
			if(_bcc.length > 0)
				vrs.bcc = _bcc.join("; ");
			if(subject) vrs.subject = subject;
			if(message) vrs.body = message;

			mailTo += "?" + vrs;

			navigateToURL(new URLRequest(mailTo));
		}

		/**
		 * @private
		 */
		protected function loadMessage(url : String) : void
		{
			var loader : URLLoader = new URLLoader();
			addMessageListeners(loader);
			loader.load(new URLRequest(url));
		}

		/**
		 * @private
		 */
		protected function addMessageListeners(loader : URLLoader) : void
		{
			loader.addEventListener(Event.COMPLETE, message_complete_handler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, message_error_handler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, message_error_handler);
		}

		/**
		 * @private
		 */
		protected function removeMessageListeners(loader : URLLoader) : void
		{
			loader.removeEventListener(Event.COMPLETE, message_complete_handler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, message_error_handler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, message_error_handler);
		}

		/**
		 * @private
		 */
		protected function addScriptListeners(loader : URLLoader) : void
		{
			loader.addEventListener(Event.COMPLETE, script_complete_handler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, script_error_handler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, script_error_handler);
		}

		/**
		 * @private
		 */
		protected function removeScriptListeners(loader : URLLoader) : void
		{
			loader.removeEventListener(Event.COMPLETE, script_complete_handler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, script_error_handler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, script_error_handler);
		}

		// --------------------------------------------------------------------------------------------------------------------------------//
		// HANDLERS
		// --------------------------------------------------------------------------------------------------------------------------------//
		/**
		 * @private
		 */
		protected function message_error_handler(event : ErrorEvent) : void
		{
			var loader : URLLoader = URLLoader(event.target);
			removeMessageListeners(loader);
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.text));
		}

		/**
		 * @private
		 */
		protected function message_complete_handler(event : Event) : void
		{
			var loader : URLLoader = URLLoader(event.target);
			removeMessageListeners(loader);
			message = loader.data;

			sendViaClient();
		}

		/**
		 * @private
		 */
		protected function script_error_handler(event : ErrorEvent) : void
		{
			var loader : URLLoader = URLLoader(event.target);
			removeScriptListeners(loader);
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.text));
		}

		/**
		 * @private
		 */
		protected function script_complete_handler(event : Event) : void
		{
			var loader : URLLoader = URLLoader(event.target);
			removeScriptListeners(loader);
			var response : String = loader.data;
			switch(response)
			{
				case "true":
					dispatchEvent(event);
					break;
				default:
					dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, response));
					break;
			}
		}
	}
}
