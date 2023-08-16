class SearchFormEvent extends Event{
	constructor(type, formData){
		super(type);
		this.formData = formData;
	}
}
class ModalDialogEvent extends Event{
	constructor(type, dialog, trigger, result){
		super(type);
		this.dialog = dialog;
		this.trigger = trigger;
		this.result = result;
	}
}

/*
<page-link href="/">Home</page-link>
<search-form label="検索"><div slot="body">キーワード<input name="keyword" /></div></search-form>
<table-sticky columns="[{&quot;width&quot;: &quot;100px&quot;, &quot;label&quot;: &quot;データ&quot;, &quot;slot&quot;: &quot;data&quot;}]">
	<table-row><div slot="data">DATA</div></table-row>
</table-sticky>
<modal-dialog name="detail" label="詳細">
	<div slot="body">text text text text text</div>
	<button slot="footer" type="button" data-trigger="btn" data-result="1">決定</button>
</modal-dialog>
*/


class PageLinkElement extends HTMLElement{
	#connected;
	constructor(){
		super();
		this.#connected = false;
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(this.#connected && (newValue != null)){
			this.addEventListener("click", SinglePage.handleEvent);
		}
	}
	connectedCallback(){
		if(!this.#connected){
			this.#connected = true;
			if(this.hasAttribute("href")){
				this.addEventListener("click", SinglePage.handleEvent);
			}
		}
	}
	disconnectedCallback(){
	}
	static observedAttributes = ["href"];
}
customElements.define("page-link", PageLinkElement);

class SearchFormElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = null;
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(this.#root == null){
		}else if(name == "label"){
			this.#root.querySelector('.label').textContent = `${newValue}`;
		}
	}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: `
				<label part="header"><input type="checkbox" part="toggle" /><span class="label"></span></label>
				<div part="body"><slot name="body"></slot></div>
				<div part="footer">
					<div part="col-12 text-center">
						<span part="submit">検　索</span>
						<span part="reset">リセット</span>
					</div>
				</div>
			`});
			if(this.hasAttribute("label")){
				this.#root.querySelector('.label').textContent = this.getAttribute("label");
			}
			this.#root.querySelector('[part="toggle"]').addEventListener("change", this);
			this.#root.querySelector('[part="submit"]').addEventListener("click", this);
			this.#root.querySelector('[part="reset"]').addEventListener("click", this);
		}
	}
	disconnectedCallback(){
	}
	handleEvent(e){
		const part = e.currentTarget.getAttribute("part");
		if(part == "toggle"){
			if(e.currentTarget.checked){
				this.classList.add("search-form-hide");
			}else{
				this.classList.remove("search-form-hide");
			}
		}else if(part == "submit"){
			this.submit();
		}else if(part == "reset"){
			this.reset();
		}
	}
	submit(){
		const form = document.createElement("form");
		const range = document.createRange();
		range.selectNodeContents(this);
		form.appendChild(range.extractContents());
		const formData = new FormData(form);
		range.selectNodeContents(form);
		this.appendChild(range.extractContents());
		SinglePage.currentPage.dispatchEvent(new SearchFormEvent("search", formData));
	}
	reset(){
		const form = document.createElement("form");
		const range = document.createRange();
		range.selectNodeContents(this);
		form.appendChild(range.extractContents());
		form.reset();
		range.selectNodeContents(form);
		this.appendChild(range.extractContents());
	}
	static observedAttributes = ["label"];
}
customElements.define("search-form", SearchFormElement);

class TableStickyElement extends HTMLElement{
	#root; #content;
	constructor(){
		super();
		this.#root = null;
		this.#content = null;
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(this.#root == null){
		}else if(name == "columns"){
			this.#tableInit(newValue == null ? "[]" : newValue);
		}
	}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: `
				<style type="text/css"></style>
				<div part="container">
					<div part="table">
						<div part="column-group"></div>
						<div part="header-group"><div part="row"></div></div>
						<div part="row-group"><slot name="row"></slot></div>
					</div>
				</div>
			`});
			if(this.hasAttribute("columns")){
				this.#tableInit(this.getAttribute("columns"));
			}
			const observer = new MutationObserver((mutationsList, observer) => {
				if(this.#content != null){
					for(let mutation of mutationsList.filter(m => m.type == "childList")){
						for(let i = mutation.addedNodes.length - 1; i >= 0; i--){
							const node = mutation.addedNodes[i];
							if((node.nodeType == Node.ELEMENT_NODE) && (node.tagName == "TABLE-ROW")){
								node.slotInit(this.#content.cloneNode(true));
								node.setAttribute("slot", "row");
							}
						}
						for(let i = mutation.removedNodes.length - 1; i >= 0; i--){
							const node = mutation.removedNodes[i];
							if((node.nodeType == Node.ELEMENT_NODE) && (node.tagName == "TABLE-ROW")){
								node.slotInit(null);
							}
						}
					}
				}
				observer.takeRecords();
			});
			observer.observe(this, {childList: true});
		}
	}
	disconnectedCallback(){
	}
	insertRow(...nodes){
		const tableRow = document.createElement("table-row");
		for(let node of nodes){
			tableRow.appendChild(node);
		}
		this.appendChild(tableRow);
		return tableRow;
	}
	tryInit(row){
		if(this.#content == null){
			row.slotInit(null);
		}else{
			row.slotInit(this.#content.cloneNode(true));
		}
		row.setAttribute("slot", "row");
	}
	set columns(value){
		if(this.#root == null){
		}else if(value == null){
			this.removeAttribute("columns");
		}else if(typeof value == "string"){
			this.setAttribute("columns", value);
		}else{
			this.setAttribute("columns", JSON.stringify(value));
		}
	}
	#tableInit(columnData){
		try{
			let widths = [];
			const colFragment = document.createDocumentFragment();
			const slotFragment = document.createDocumentFragment();
			const headerFragment = document.createDocumentFragment();
			const columns = JSON.parse(columnData);
			for(let column of columns){
				let partList = (column.part == null) ? [] : column.part.split(/\s/).filter(v => v != "");
				widths.push({value: column.width, part: partList.concat()});
				let slot = Object.assign(document.createElement("slot"), {innerHTML: '<div part="empty"></div>'});
				slot.setAttribute("name", column.slot);
				if(partList.length > 0){
					slot.setAttribute("part", partList.join(" "));
				}
				slotFragment.appendChild(slot);
				let header = Object.assign(document.createElement("div"), {innerHTML: column.label});
				partList.push("cell");
				header.setAttribute("part", partList.join(" "));
				headerFragment.appendChild(header);
			}
			let i = 0;
			const sheet = this.#root.querySelector("style").sheet;
			for(let n = sheet.cssRules.length - 1; n >= 0; n--){
				sheet.deleteRule(0);
			}
			for(let width of widths){
				width.part.push("col");
				let col = document.createElement("span");
				col.setAttribute("class", `col${i}`);
				col.setAttribute("part", width.part.join(" "));
				colFragment.appendChild(col);
				sheet.insertRule(`.col${i}{width: ${width.value};}`, i);
				i++;
			}
			const range = document.createRange();
			range.selectNodeContents(this.#root.querySelector('[part="column-group"]'));
			range.deleteContents();
			range.insertNode(colFragment);
			range.selectNodeContents(this.#root.querySelector('[part="row"]'));
			range.deleteContents();
			range.insertNode(headerFragment);
			this.#content = slotFragment;
			
			const tableRows = Array.from(this.children).filter(node => ((node.nodeType == Node.ELEMENT_NODE) && (node.tagName == "TABLE-ROW")));
			for(let n = tableRows.length - 1; n >= 0; n--){
				if("slotInit" in tableRows[n]){
					tableRows[n].slotInit(this.#content.cloneNode(true));
					tableRows[n].setAttribute("slot", "row");
				}
			}
			node.setAttribute("slot", "row");
		}catch(ex){
		}
	}
	static observedAttributes = ["columns"];
}
customElements.define("table-sticky", TableStickyElement);

class TableRowElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = null;
	}
	attributeChangedCallback(name, oldValue, newValue){}
	connectedCallback(){
		if(this.#root == null){
			this.#root = this.attachShadow({mode: "closed"});
			if((this.parentNode != null) && (this.parentNode.tagName == "TABLE-STICKY")){
				this.parentNode.tryInit(this);
			}
		}
	}
	disconnectedCallback(){
	}
	slotInit(doc){
		const range = document.createRange();
		range.selectNodeContents(this.#root);
		range.deleteContents();
		if(doc != null){
			range.insertNode(doc);
		}
	}
	static observedAttributes = [];
}
customElements.define("table-row", TableRowElement);

class ModalDialogElement extends HTMLElement{
	#root; #modal; #callback; #query;
	constructor(){
		super();
		this.#root = null;
		this.#modal = null;
		this.#callback = null;
		this.#query = null;
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(this.#root == null){
		}else if(name == "name"){
			if(newValue != null){
				SinglePage.modal[newValue] = this;
			}
		}else if(name == "label"){
			this.#root.querySelector('[part="label"]').textContent = `${newValue}`;
		}
	}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: `
				<style type="text/css">
					dialog[open]{ display: flex; }
					dialog::backdrop{ background: rgba(0, 0, 0, 0.5); }
				</style>
				<dialog part="content">
					<div part="header"><div part="label"></div><div part="close"></div></div>
					<div part="body">
						<slot name="body"></slot>
					</div>
					<div part="footer"><slot name="footer"></slot></div>
				</dialog>
			`});
			this.#modal = this.#root.querySelector('[part="content"]');
			this.#root.querySelector('[part="close"]').addEventListener("click", e => {
				this.#modal.close();
				if(this.#callback != null){
					this.#callback(null, null);
					this.#callback = null;
				}
				SinglePage.currentPage.dispatchEvent(new ModalDialogEvent("modal-close", this.getAttribute("name"), null, null));
			});
			this.addEventListener("click", e => {
				let trigger = null;
				let result = null;
				for(let node = e.target; (node != null) && (node != this); node = node.parentNode){
					if((trigger == null) && node.hasAttribute("data-trigger")){
						trigger = node.getAttribute("data-trigger");
						if(result != null){
							break;
						}
					}
					if((result == null) && node.hasAttribute("data-result")){
						result = node.getAttribute("data-result");
						if(trigger != null){
							break;
						}
					}
				}
				if((trigger != null) || (result != null)){
					this.#modal.close();
					if(this.#callback != null){
						this.#callback(trigger, result);
						this.#callback = null;
					}
					SinglePage.currentPage.dispatchEvent(new ModalDialogEvent("modal-close", this.getAttribute("name"), trigger, result));
				}
			}, {useCapture: true});
			
			if(this.hasAttribute("name")){
				SinglePage.modal[this.getAttribute("name")] = this;
			}
			if(this.hasAttribute("label")){
				this.#root.querySelector('[part="label"]').textContent = this.getAttribute("label");
			}
		}
	}
	disconnectedCallback(){
	}
	show(options = null){
		if(options != null){
			if("detail" in options){
				this.dispatchEvent(new CustomEvent("modal-open", {bubbles: true, composed: true, detail: options.detail}));
			}
			if("callback" in options){
				this.#callback = options.callback;
			}
		}
		this.#modal.showModal();
	}
	setQuery(func){
		this.#query = func;
		return this;
	}
	query(...args){
		if(this.#query == null){
			return null;
		}
		return this.#query(...args);
	}
	static observedAttributes = ["name", "label"];
}
customElements.define("modal-dialog", ModalDialogElement);

class FormControlElement extends HTMLElement{
	#root; #input; #id; #observer; #value; #name; #props; #tempInnerHTML;
	constructor() {
		super();
		this.#tempInnerHTML = this.innerHTML;
		this.#root = this.attachShadow({mode: "closed"});
		this.#id = FormControlElement.#counter++;
		this.#input = document.createElement("fc-label");
		this.#observer = new MutationObserver((mutationsList, observer) => {
			let inputElements = this.querySelectorAll('input');
			if(inputElements.length == 0){
				this.#input.value = this.textContent;
				this.#setValue(this.#input.value);
			}else{
				const n = inputElements.length;
				const cmpName = (this.#name == null) ? [] : this.#name;
				let value = null;
				for(let i = 0; i < n; i++){
					const val = inputElements[i].value;
					if(inputElements[i].hasAttribute("name")){
						let reduce = true;
						let name = inputElements[i].getAttribute("name");
						if(name.slice(-1) == "]"){
							name = name.replace(/^([^\[]*)(.*)\]$/, "$1]$2");
						}
						let tokens = name.split("][");
						if(tokens[0] == ""){
							tokens.shift();
						}
						for(let j = cmpName.length - 1; j >= 0; j--){
							if(cmpName[j] != tokens[j]){
								reduce = false;
								break;
							}
						}
						if(reduce){
							tokens.splice(0, cmpName.length);
						}
						tokens.push(null);
						let ref = null;
						let prev = null;
						for(let token of tokens){
							if(token == null){
								if(ref == null){
									value = val;
								}else if(prev == ""){
									ref.push(val);
								}else{
									ref[prev] = val;
								}
							}else if(token == ""){
								if(ref == null){
									if(!Array.isArray(value)){
										value = [];
									}
									ref = value;
								}else{
									if(!Array.isArray(ref[prev])){
										ref[prev] = [];
									}
									ref = ref[prev];
								}
								prev = token;
							}else{
								if(ref == null){
									if((value == null) || (typeof value == "string") || Array.isArray(value)){
										value = {[token]: null};
									}else{
										value[token] = null;
									}
									ref = value;
								}else{
									if((ref[prev] == null) || (typeof ref[prev] == "string") || Array.isArray(ref[prev])){
										ref[prev] = {[token]: null};
									}else{
										ref[prev][token] = null;
									}
									ref = ref[prev];
								}
								prev = token;
							}
						}
					}else if(value == null){
						value = val;
					}else if(typeof value == "string"){
						value = [value, val];
					}else if(Array.isArray(value)){
						value.push(val);
					}
				}
				this.#input.value = value;
				this.#setValue(this.#input.value);
			}
		});
		this.#name = null;
		this.#observer.observe(this, {childList: true});
		this.#root.appendChild(this.#input);
		this.#props = {list: {fc: `FC${(0x10000000 | Date.now()).toString(16).slice(-7)}${(0x10000000 | this.#id).toString(16).slice(-7)}`}, invalid: false};
		this.#input.props = this.#props;
		this.#setParts("label");
		this.#setValue(this.#input.value);
		this.#input.addEventListener("change", e => { this.#setValue(this.#input.value); });
	}
	connectedCallback(){
		this.innerHTML = this.#tempInnerHTML;
	}
	disconnectedCallback(){
		this.#tempInnerHTML = this.innerHTML;
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(name == "name"){
			if(newValue == null){
				this.#name = null;
			}else{
				let value = newValue;
				if(value.slice(-1) == "]"){
					value = value.replace(/^([^\[]*)(.*)\]$/, "$1]$2");
				}
				this.#name = value.split("][");
			}
		}else if(name == "type"){
			const type = newValue in FormControlElement.#types ? newValue : "label";
			const element = document.createElement(`fc-${type}`);
			this.#root.replaceChild(element, this.#input);
			this.#input = element;
			this.#input.props = this.#props;
			this.#input.value = this.#value;
			this.#setParts(newValue);
			this.#setValue(this.#input.value);
			this.#input.addEventListener("change", e => { this.#setValue(this.#input.value); });
		}else if(name == "list"){
			if(newValue == null){
				delete this.#props.list.id;
			}else{
				this.#props.list.id = newValue;
			}
			this.#input.props = this.#props;
			
		}else{
			if(newValue == null){
				delete this.#props[name];
			}else{
				this.#props[name] = newValue;
			}
			this.#input.props = this.#props;
		}
	}
	set invalid(value){
		this.#props.invalid = value;
	}
	get invalid(){
		return this.#props.invalid;
	}
	set value(value){
		this.#input.value = value;
		this.#setValue(this.#input.value);
	}
	get value(){
		return this.#value;
	}
	#setParts(type){
		this.#input.setAttribute("part", "control");
		this.#input.setAttribute("exportparts", FormControlElement.#types[type]);
	}
	#setValue(value){
		const range = document.createRange();
		const fragment = document.createDocumentFragment();
		range.selectNodeContents(this);
		range.deleteContents();
		this.#genValue(value, (this.#name == null) ? [] : this.#name, fragment);
		this.appendChild(fragment);
		this.#value = value;
		this.#observer.takeRecords();
	}
	#genValue(value, name, fragment){
		if(value == null){
		}else if(Array.isArray(value)){
			const next = [...name, ""];
			for(let val of value){
				this.#genValue(val, next, fragment);
			}
		}else if(typeof value == "object"){
			for(let key in value){
				this.#genValue(value[key], [...name, key], fragment);
			}
		}else if(name.filter(token => token != "").length > 0){
			const input = document.createElement("input");
			let inputName = null;
			if(name.length == 1){
				inputName = name[0];
			}else{
				inputName = (name.join("][") + "]").replace(/^([^\]]*)\]/, "$1");
			}
			input.setAttribute("type", "hidden");
			input.setAttribute("name", inputName);
			input.setAttribute("value", `${value}`);
			fragment.appendChild(input);
		}else{
			const input = document.createElement("input");
			input.setAttribute("type", "hidden");
			input.setAttribute("value", `${value}`);
		}
		return fragment;
	}
	static get observedAttributes(){ return ["default", "name", "placeholder", "list", "type", "fc-class"]; }
	static append(type, className, ...parts){
		let exportparts = [];
		for(let partObj of parts){
			if(typeof partObj == "string"){
				exportparts.push(partObj);
			}else if(Array.isArray(partObj)){
				exportparts.push(...partObj);
			}else if(typeof partObj == "object"){
				for(let inputPart in partObj){
					exportparts.push(`${inputPart}:${partObj[inputPart]}`);
				}
			}
		}
		FormControlElement.#types[type] = exportparts.join(",");
		customElements.define(`fc-${type}`, className);
	}
	static gridColumnParts = ["col-1", "col-2", "col-3", "col-4", "col-5", "col-6", "col-7", "col-8", "col-9", "col-10", "col-11", "col-12"];
	static #types = {};
	static #counter = 0;
}
customElements.define(`form-control`, FormControlElement);

class FCLabelElement extends HTMLElement{
	#root; #input; #props; #value;
	constructor(){
		super();
		this.#root = this.attachShadow({mode: "closed"});
		this.#input = document.createElement("span");
		this.#root.appendChild(this.#input);
		this.#props = {};
		this.#value = "";
	}
	attributeChangedCallback(name, oldValue, newValue){}
	get value(){
		return this.#value;
	}
	set value(value){
		this.#value = (typeof value == "string") ? value : JSON.stringify(value);
		this.#setLabel();
	}
	set props(value){
		this.#props = value;
		this.#setLabel();
	}
	#setLabel(){
		let tempVal = this.#value;
		if("id" in this.#props.list){
			let found = false;
			const dataList = document.getElementById(this.#props.list.id);
			if(dataList != null){
				const optionElements = dataList.querySelectorAll('option[value]');
				const n = optionElements.length;
				for(let i = 0; i < n; i++){
					const option = optionElements[i];
					if(option.getAttribute("value") == tempVal){
						found = true;
						tempVal = option.textContent;
					}
				}
			}else if(this.#props.list.id in SinglePage.modal){
				tempVal = SinglePage.modal[this.#props.list.id].query(this.#value);
				found = (tempVal != null);
			}
			if(!found){
				this.#value = null;
				tempVal = "";
			}
		}
		if("fc-class" in this.#props){
			this.#input.setAttribute("part", this.#props["fc-class"]);
		}
		this.#input.textContent = tempVal;
	}
	static get observedAttributes(){ return []; }
}
FormControlElement.append("label", FCLabelElement);

class FCTextElement extends HTMLElement{
	#root; #input; #props;
	constructor(){
		super();
		this.#root = this.attachShadow({mode: "closed"});
		this.#input = document.createElement("input");
		this.#root.appendChild(this.#input);
		this.#props = {};
		this.#input.addEventListener("change", e => this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true})));
	}
	attributeChangedCallback(name, oldValue, newValue){}
	get value(){
		return this.#input.value;
	}
	set value(value){
		this.#input.value = (typeof value == "string") ? value : JSON.stringify(value);
		this.#setList();
	}
	set props(value){
		this.#props = value;
		this.#setList();
		if("placeholder" in this.#props){
			this.#input.setAttribute("placeholder", this.#props.placeholder);
		}else{
			this.#input.removeAttribute("placeholder");
		}
	}
	#setList(){
		let found = false;
		let dataListElement = this.#root.getElementById(this.#props.list.fc);
		if(dataListElement != null){
			this.#root.removeChild(dataListElement);
		}
		if("id" in this.#props.list){
			const dataList = document.getElementById(this.#props.list.id);
			if(dataList != null){
				dataListElement = dataList.cloneNode(true);
				dataListElement.setAttribute("id", this.#props.list.fc);
				this.#root.appendChild(dataListElement);
				this.#input.setAttribute("list", this.#props.list.fc);
				found = true;
			}
		}
		if(!found){
			this.#input.removeAttribute("list");
		}
		let classList = ("fc-class" in this.#props) ? this.#props["fc-class"].split(/\s+/).filter(v => v != "") : [];
		classList.push("fc-text");
		if(this.#props.invalid){
			classList.push("fc-text-invalid");
		}
		this.#input.setAttribute("part", classList.join(" "));
	}
	static get observedAttributes(){ return []; }
}
FormControlElement.append("text", FCTextElement, ["fc-text", "fc-text-invalid"], FormControlElement.gridColumnParts);

class FCSelectElement extends HTMLElement{
	#root; #input; #props; #value;
	constructor(){
		super();
		this.#root = this.attachShadow({mode: "closed"});
		this.#input = document.createElement("select");
		this.#root.appendChild(this.#input);
		this.#props = {};
		this.#value = "";
		this.#input.addEventListener("change", e => {
			this.#value = this.#input.value;
			this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true}));
		});
	}
	attributeChangedCallback(name, oldValue, newValue){}
	get value(){
		return this.#input.value;
	}
	set value(value){
		this.#value = value;
		this.#setList();
		this.#input.value = (typeof value == "string") ? value : `${value}`;
	}
	set props(value){
		this.#props = value;
		this.#setList();
	}
	#setList(){
		const range = document.createRange();
		range.selectNodeContents(this.#input);
		range.deleteContents();
		if("id" in this.#props.list){
			const dataList = document.getElementById(this.#props.list.id);
			if(dataList != null){
				range.selectNodeContents(dataList);
				this.#input.appendChild(range.cloneContents());
			}
		}
		this.#input.value = this.#value;
		let classList = ("fc-class" in this.#props) ? this.#props["fc-class"].split(/\s+/).filter(v => v != "") : [];
		classList.push("fc-select", "fc-text");
		if(this.#props.invalid){
			classList.push("fc-text-invalid");
		}
		this.#input.setAttribute("part", classList.join(" "));
	}
	static get observedAttributes(){ return []; }
}
FormControlElement.append("select", FCSelectElement, ["fc-select", "fc-text", "fc-text-invalid"], FormControlElement.gridColumnParts);

class FCDateRangeElement extends HTMLElement{
	#root; #inputRange; #inputFrom; #inputTo; #props; #value;
	constructor(){
		super();
		this.#root = this.attachShadow({mode: "closed"});
		this.#inputRange = document.createElement("div");
		this.#inputFrom = document.createElement("input");
		this.#inputTo = document.createElement("input");
		const rangeSeparator = document.createElement("div");
		this.#inputRange.appendChild(this.#inputFrom);
		this.#inputRange.appendChild(rangeSeparator);
		this.#inputRange.appendChild(this.#inputTo);
		this.#root.appendChild(this.#inputRange);
		this.#props = {};
		this.#value = {from: "", to: ""};
		rangeSeparator.setAttribute("part", "fc-sep");
		this.#inputFrom.setAttribute("type", "date");
		this.#inputTo.setAttribute("type", "date");
		this.#inputFrom.addEventListener("change", e => {
			if(this.#inputFrom.value == ""){
				delete this.#value.from;
			}else{
				this.#value.from = this.#inputFrom.value;
			}
			this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true}))
		});
		this.#inputTo.addEventListener("change", e => {
			if(this.#inputTo.value == ""){
				delete this.#value.from;
			}else{
				this.#value.from = this.#inputTo.value;
			}
			this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true}))
		});
	}
	attributeChangedCallback(name, oldValue, newValue){}
	get value(){
		const value = {};
		if(this.#inputFrom.value != ""){
			value.from = this.#inputFrom.value;
		}
		if(this.#inputTo.value != ""){
			value.to = this.#inputTo.value;
		}
		return value;
	}
	set value(value){
		this.#value = {};
		if(typeof value == "string"){
			const fdate = this.#formatDate(value);
			if(fdate != null){
				this.#value = {from: fdate,to: fdate};
			}
		}else if(Array.isArray(value)){
			if(value.length < 1){
			}else if(value.length == 1){
				const fdate = this.#formatDate(value[0]);
				if(fdate != null){
					this.#value = {from: fdate,to: fdate};
				}
			}else{
				const fdate = {from: this.#formatDate(value[0]), to: this.#formatDate(value[1])};
				if(fdate.from != null){
					this.#value.from = fdate.from;
				}
				if(fdate.to != null){
					this.#value.to = fdate.to;
				}
			}
		}else if(typeof value == "object"){
			if("from" in value){
				const fdate = this.#formatDate(value.from);
				if(fdate != null){
					this.#value.from = fdate;
				}
			}
			if("to" in value){
				const fdate = this.#formatDate(value.to);
				if(fdate != null){
					this.#value.to = fdate;
				}
			}
		}
		this.#setList();
	}
	set props(value){
		this.#props = value;
		this.#setList();
		if("placeholder" in this.#props){
			this.#inputFrom.setAttribute("placeholder", this.#props.placeholder);
			this.#inputTo.setAttribute("placeholder", this.#props.placeholder);
		}else{
			this.#inputFrom.setAttribute("placeholder", "開始日");
			this.#inputTo.setAttribute("placeholder", "終了日");
		}
	}
	#formatDate(value){
		if(value == null || value == ""){
			return null;
		}
		const ins = new Date(value);
		if(Number.isNaN(ins.getTime())){
			return null;
		}
		return `${ins.getFullYear()}-${`0${ins.getMonth() + 1}`.slice(-2)}-${`0${ins.getDay()}`.slice(-2)}`;
	}
	#setList(){
		let found = false;
		let dataListElement = this.#root.getElementById(this.#props.list.fc);
		if(dataListElement != null){
			this.#root.removeChild(dataListElement);
		}
		if("id" in this.#props.list){
			const dataList = document.getElementById(this.#props.list.id);
			if(dataList != null){
				dataListElement = dataList.cloneNode(true);
				dataListElement.setAttribute("id", this.#props.list.fc);
				this.#root.appendChild(dataListElement);
				this.#inputFrom.setAttribute("list", this.#props.list.fc);
				this.#inputTo.setAttribute("list", this.#props.list.fc);
				found = true;
			}
		}
		if(!found){
			this.#inputFrom.removeAttribute("list");
			this.#inputTo.removeAttribute("list");
		}
		let classList = ("fc-class" in this.#props) ? this.#props["fc-class"].split(/\s+/).filter(v => v != "") : [];
		let innerClassList = [];
		classList.push("fc-range")
		innerClassList.push("fc-text");
		if(this.#props.invalid){
			innerClassList.push("fc-text-invalid");
		}
		this.#inputRange.setAttribute("part", classList.join(" "));
		this.#inputFrom.setAttribute("part", innerClassList.join(" ") + " fc-from");
		this.#inputTo.setAttribute("part", innerClassList.join(" ") + " fc-to");
	}
	static get observedAttributes(){ return []; }
}
FormControlElement.append("daterange", FCDateRangeElement, ["fc-range", "fc-from", "fc-to", "fc-sep", "fc-text", "fc-text-invalid"], FormControlElement.gridColumnParts);

class FCKeywordElement extends HTMLElement{
	#root; #input; #keyword; #result; #props; #value;
	constructor(){
		super();
		this.#root = this.attachShadow({mode: "closed"});
		this.#input = document.createElement("div");
		this.#keyword = document.createElement("input");
		this.#result = document.createElement("div");
		const keywordContainer = document.createElement("label");
		const resultContainer = document.createElement("div");
		const searchBtn = document.createElement("button");
		const resetBtn = document.createElement("button");
		this.#result.textContent = "\u200B";
		this.#keyword.setAttribute("part", "fc-text fc-text-icon");
		keywordContainer.setAttribute("part", "input-group input-group-search");
		resultContainer.setAttribute("part", "input-group input-group-result");
		searchBtn.setAttribute("type", "button");
		resetBtn.setAttribute("type", "button");
		searchBtn.setAttribute("part", "fc-btn-icon fc-btn-icon-search");
		resetBtn.setAttribute("part", "fc-btn-icon fc-btn-icon-reset");
		keywordContainer.appendChild(this.#keyword);
		keywordContainer.appendChild(searchBtn);
		resultContainer.appendChild(this.#result);
		resultContainer.appendChild(resetBtn);
		this.#input.appendChild(keywordContainer);
		this.#input.appendChild(resultContainer);
		this.#root.appendChild(this.#input);
		this.#props = {};
		this.#value = {keyword: "", result: null};
		const dialogCallback = (trigger, result) => {
			if(trigger == "list"){
				this.value = result;
				this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true}));
			}
		};
		searchBtn.addEventListener("click", e => {
			if(("id" in this.#props.list) && (this.#props.list.id in SinglePage.modal)){
				SinglePage.modal[this.#props.list.id].show({detail: this.#keyword.value, callback: dialogCallback});
			}
		});
		resetBtn.addEventListener("click", e => {
			this.#value.result = null;
			this.#result.textContent = "\u200B";
			this.dispatchEvent(new CustomEvent("change", {bubbles: true, composed: true}));
		});
	}
	attributeChangedCallback(name, oldValue, newValue){}
	get value(){
		return this.#value.result;
	}
	set value(value){
		let res = null;
		if(("id" in this.#props.list) && (this.#props.list.id in SinglePage.modal)){
			res = SinglePage.modal[this.#props.list.id].query(value);
		}
		if(res != null){
			this.#value.result = value;
			this.#result.textContent = "\u200B" + res;
		}else{
			this.#value.result = null;
			this.#result.textContent = "\u200B";
		}
	}
	set props(value){
		this.#props = value;
		let classList = ("fc-class" in this.#props) ? this.#props["fc-class"].split(/\s+/).filter(v => v != "") : [];
		let innerClassList = [];
		classList.push("fc-keyword");
		innerClassList.push("fc-text", "fc-text-icon");
		if(this.#props.invalid){
			innerClassList.push("fc-text-invalid");
		}
		this.#input.setAttribute("part", classList.join(" "));
		this.#result.setAttribute("part", innerClassList.join(" "));
		if("placeholder" in this.#props){
			this.#keyword.setAttribute("placeholder", this.#props.placeholder);
		}else{
			this.#keyword.removeAttribute("placeholder");
		}
	}
	static get observedAttributes(){ return []; }
}
FormControlElement.append("keyword", FCKeywordElement, ["fc-keyword", "fc-text-icon", "fc-btn-icon", "fc-btn-icon-search", "fc-btn-icon-reset", "input-group-search", "input-group-result", "fc-text", "fc-text-invalid"], FormControlElement.gridColumnParts, ["input-group"]);







class VirtualPage extends EventTarget{
	/*
		Event.type
		  search
		  modal-close
	*/
	#className; #loaded;
	constructor(name, className){
		super();
		this.#className = className;
		this.#loaded = false;
		this.slots = [];
		SinglePage.pageSlots[name] = this;
	}
	append(nodeList){
		this.slots.push(...nodeList);
	}
	load(){
		SinglePage.currentPage = this;
		if(this.#loaded){
		}else{
			this.#loaded = true;
			this.instance = (this.#className == null) ? null : new this.#className(this);
			this.#className = null;
		}
	}
}
class SinglePage{
	static pageSlots = {};
	static modal = {};
	static currentPage = null;
	static set location(value){
		if(value in SinglePage.pageSlots){
			const spmain = document.getElementById("spmain");
			const fragment = document.createDocumentFragment();
			for(let node of SinglePage.pageSlots[value].slots){
				fragment.appendChild(node);
			}
			const range = document.createRange();
			range.selectNodeContents(spmain);
			range.extractContents();
			spmain.appendChild(fragment);
			SinglePage.pageSlots[value].load();
		}
	}
	static handleEvent(e){
		SinglePage.location = e.currentTarget.getAttribute("href");
	}
}
document.addEventListener("DOMContentLoaded", function(){
	let templates = document.querySelectorAll('template[data-page]');
	for(let i = templates.length - 1; i >= 0; i--){
		const page = templates[i].getAttribute("data-page");
		const fragment = templates[i].content;
		if(!(page in SinglePage.pageSlots)){
			new VirtualPage(page, null);
		}
		const pageDatas = Array.from(fragment.children).filter(node => (node.nodeType == Node.ELEMENT_NODE) && node.hasAttribute("slot"));
		pageDatas.forEach(node => node.setAttribute("data-page", page));
		SinglePage.pageSlots[page].append(pageDatas);
	}
	templates = document.querySelectorAll('template[data-page-share]');
	for(let i = templates.length - 1; i >= 0; i--){
		const pages = templates[i].getAttribute("data-page-share").split("|");
		const fragment = templates[i].content;
		const append = Array.from(fragment.children).filter(node => (node.nodeType == Node.ELEMENT_NODE) && node.hasAttribute("slot"));
		for(let page in SinglePage.pageSlots){
			if(pages.includes(page)){
				continue;
			}
			SinglePage.pageSlots[page].append(append);
		}
	}
});