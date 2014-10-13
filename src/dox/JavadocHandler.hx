package dox;
using StringTools;

class JavadocHandler {

	var config:Config;
	var infos:Infos;
	var markdown:MarkdownHandler;

	public function new(cfg:Config, inf:Infos, mdown:MarkdownHandler) {
		config = cfg;
		infos = inf;
		markdown = mdown;
	}

	static inline function isValidChar(c) {
		return (c >= 'a'.code && c <= 'z'.code) || (c >= 'A'.code && c <= 'Z'.code) || (c >= '0'.code && c <= '9'.code) || c == '_'.code;
	}

	public function parse(path:String, doc:String):DocInfos {
		var onNewLine = true;
		var i = 0;
		function readWord() {
			var buf = new StringBuf();
			while (true) {
				var c = doc.fastCodeAt(i++);
				if (!isValidChar(c)) {
					return buf.toString();
				} else {
					buf.addChar(c);
				}
			}
		}
		function skipSpaces() {
			while (true) {
				var c = doc.fastCodeAt(i);
				switch (c) {
					case ' '.code, '\t'.code:
						++i;
					case _:
						return;
				}
			}
		}
		var mainDoc = null;
		var currentTag:DocTag = null;
		var tags = [];
		var buf = new StringBuf();
		function commitBuf() {
			if (buf.length == 0) {
				return;
			}
			var doc = markdown.markdownToHtml(path, buf.toString());
			if (currentTag != null) {
				currentTag.doc = doc;
			} else {
				mainDoc = doc;
			}
			buf = new StringBuf();
		}
		while (true) {
			var c = doc.fastCodeAt(i++);
			if (StringTools.isEof(c)) {
				break;
			}
			switch (c) {
				case '@'.code if (onNewLine):
					commitBuf();
					var name = readWord();
					skipSpaces();
					var value = switch (name) {
						case "param" | "exception" | "throws":
							readWord();
						case _:
							null;
					}
					currentTag = {
						name: name,
						value: value,
						doc: "",
					}
					tags.push(currentTag);
				case '\n'.code:
					onNewLine = true;
				case ' '.code, '\t'.code, '*'.code, '\r'.code, '\n'.code if (onNewLine):

				case _:
					onNewLine = false;
					buf.addChar(c);
			}
		}
		commitBuf();
		var infos:DocInfos = {doc:mainDoc, throws:[], params:[], tags:tags};
		for (tag in tags) switch (tag.name)
		{
			case 'param': infos.params.push(tag);
			case 'exception', 'throws': infos.throws.push(tag);
			case 'deprecated': infos.deprecated = tag;
			case 'return', 'returns': infos.returns = tag;
			case 'since': infos.since = tag;
			case 'default': infos.defaultValue = tag;
			default:
		}
		return infos;
	}

	function trimDoc(doc:String)
	{
		var ereg = ~/^\s+/m;
		if (ereg.match(doc))
		{
			var space = new EReg('^' + ereg.matched(0), 'mg');
			doc = space.replace(doc, '');
		}
		return doc;
	}
}

typedef DocInfos = {
	doc:String,
	?returns:DocTag,
	?deprecated:DocTag,
	?since:DocTag,
	?defaultValue:DocTag,
	params:Array<DocTag>,
	throws:Array<DocTag>,
	tags:Array<DocTag>
}

typedef DocTag = {
	name:String,
	doc:String,
	value:String
}
