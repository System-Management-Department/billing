/*
class JspreadsheetLoadEvent extends Event{
}
class JspreadsheetBeforeSaveEvent extends Event{
}
class JspreadsheetSaveEvent extends Event{
}
class JspreadsheetMergeEvent extends Event{
}
oneditionstart
oncreateeditor
oneditionend
onbeforechange
onchange
onblur
onfocus
onselection
onresizecolumn
onresizerow
onchangeheader
onchangemeta
onchangestyle
oncomments
onsort
onmoverow
onbeforeinsertrow
oninsertrow
onbeforedeleterow
ondeleterow
onmovecolumn
onbeforeinsertcolumn
oninsertcolumn
onbeforedeletecolumn
ondeletecolumn
onchangepage
oncopy
onbeforepaste
onpaste
onundo
onredo
onafterchanges
*/

Jspreadsheet.prototype[Mixin.init] = function(e){
	let events = {
		onselection: class extends Event{
			constructor(el, borderLeft, borderTop, borderRight, borderBottom, origin){
				super("selection");
				Object.assign(this, {
					el: el,
					borderLeft: borderLeft,
					borderTop: borderTop,
					borderRight: borderRight,
					borderBottom: borderBottom,
					origin: origin
				});
			}
		}
		
	};
	this.dispatch = function(type, ...args){
		if(type in events){
			let e = new events[type](...args);
			this[Mixin.proxy].dispatchEvent(e);
		}
	}
};
JspreadsheetEvents = Mixin.attach([Jspreadsheet, 0, 1], EventTarget);