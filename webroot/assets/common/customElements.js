class RowFormElement extends HTMLElement{
	#input; #defaultValue; #initValue; #root; #elements; #fragment; #observer; #list;
	constructor(){
		super();
		const link = document.createElement("link");
		link.setAttribute("rel", "stylesheet");
		link.setAttribute("href", RowFormElement.styleSheet);
		this.#input = document.createElement("input");
		this.#input.setAttribute("type", "hidden");
		this.#initValue = null;
		this.#defaultValue = "";
		this.#root = null;
		this.#elements = {
			h: document.createElement("label"),
			d: document.createElement("div"),
			c: document.createElement("div"),
			i: document.createElement("span"),
			v: document.createElement("div"),
			l: document.createElement("datalist"),
			s: document.createElement("slot")
		};
		this.#elements.h.setAttribute("id", "h");
		this.#elements.h.setAttribute("for", "i");
		this.#elements.d.setAttribute("id", "d");
		this.#elements.c.setAttribute("id", "c");
		this.#elements.i.setAttribute("id", "i");
		this.#elements.l.setAttribute("id", "l");
		this.#elements.s.setAttribute("name", "content");
		this.#fragment = document.createDocumentFragment();
		this.#fragment.appendChild(link);
		this.#fragment.appendChild(this.#elements.h);
		this.#fragment.appendChild(this.#elements.d);
		this.#elements.d.appendChild(this.#elements.l);
		this.#elements.d.appendChild(this.#elements.c);
		this.#elements.d.appendChild(this.#elements.s);
		this.#elements.d.appendChild(this.#elements.v);
		this.#elements.c.appendChild(this.#elements.i);
		this.#observer = new MutationObserver((mutationsList, observer) => {
			observer.disconnect();
			const content = this.querySelector('[slot="content"]');
			this.#initValue = true;
			this.#fragment.appendChild(this.#input);
			if(content != null){
				this.#fragment.appendChild(content);
			}
			this.#input.value = this.textContent;
			if(this.#elements.i.tagName == "SPAN"){
				this.#elements.i.textContent = this.textContent;
			}else{
				this.#elements.i.value = this.textContent;
			}
			Object.assign(this, {innerHTML: ""}).appendChild(this.#fragment);
		});
		this.#list = {
			observer: new MutationObserver((mutationsList, observer) => {
				this.#elements.l.innerHTML = this.#list.copyFrom.innerHTML;
				if(this.#elements.i.tagName == "SELECT"){
					this.#elements.i.innerHTML = this.#list.copyFrom.innerHTML;
					this.#elements.i.value = this.#input.value;
				}
			}),
			copyFrom: null
		};
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(name == "label"){
			this.#elements.h.textContent = newValue;
		}else if(name == "name"){
			if(newValue == null){
				this.#input.removeAttribute("name");
			}else{
				this.#input.setAttribute("name", newValue);
			}
		}else if(name == "col"){
			if(newValue == null){
				this.#elements.c.removeAttribute("class");
			}else{
				this.#elements.c.setAttribute("class", `c${newValue}`);
			}
		}else if(name == "type"){
			if(newValue == null){
				const input = Object.assign(document.createElement("span"), {textContent: this.#input.value});
				this.#elements.c.replaceChild(input, this.#elements.i);
				input.setAttribute("id", "i");
				this.#elements.i = input;
			}else if(newValue == "textarea"){
				const input = Object.assign(document.createElement("textarea"), {value: this.#input.value});
				this.#elements.c.replaceChild(input, this.#elements.i);
				input.setAttribute("id", "i");
				input.setAttribute("autocomplete", "off");
				if(this.hasAttribute("placeholder")){
					input.setAttribute("placeholder", this.getAttribute("placeholder"));
				}
				input.addEventListener("change", this);
				this.#elements.i = input;
			}else if(newValue == "select"){
				const input = document.createElement("select");
				this.#elements.c.replaceChild(input, this.#elements.i);
				input.setAttribute("id", "i");
				if(this.hasAttribute("list") && (this.#list.copyFrom != null)){
					input.innerHTML = this.#list.copyFrom.innerHTML;
				}
				input.value = this.#input.value;
				input.addEventListener("change", this);
				this.#elements.i = input;
			}else{
				const input = Object.assign(document.createElement("input"), {value: this.#input.value});
				this.#elements.c.replaceChild(input, this.#elements.i);
				input.setAttribute("id", "i");
				input.setAttribute("autocomplete", "off");
				input.setAttribute("type", newValue);
				if(this.hasAttribute("placeholder")){
					input.setAttribute("placeholder", this.getAttribute("placeholder"));
				}
				if(this.hasAttribute("list")){
					input.setAttribute("list", "l");
				}
				input.addEventListener("change", this);
				this.#elements.i = input;
			}
		}else if(name == "placeholder"){
			if(newValue == null){
				this.#elements.i.removeAttribute("placeholder");
			}else if(this.#elements.i.tagName == "INPUT" || this.#elements.i.tagName == "TEXTAREA"){
				this.#elements.i.setAttribute("placeholder", newValue);
			}
		}else if(name == "invalid"){
			if(newValue == null){
				Object.assign(this.#elements.v, {textContent: ""}).removeAttribute("class");
			}else{
				Object.assign(this.#elements.v, {textContent: newValue}).setAttribute("class", "invalid");
			}
		}else if(name == "default"){
			this.#defaultValue = (newValue == null) ? "" : newValue;
		}else if(name == "list"){
			this.#list.observer.disconnect();
			if(newValue == null){
				this.#list.copyFrom = null;
			}else{
				const from = document.getElementById(newValue);
				if(from == null){
					this.#list.copyFrom = null;
				}else{
					this.#list.copyFrom = from;
					this.#initValue = false;
					this.#list.observer.observe(from, {subtree: true, attributes: true, childList: true, characterData: true});
					this.#elements.l.innerHTML = from.innerHTML;
					if(this.#elements.i.tagName == "SELECT"){
						this.#elements.i.innerHTML = from.innerHTML;
						this.#elements.i.value = this.#input.value;
					}
				}
			}
		}else if(name == "require"){
			if(newValue == null){
				this.#elements.h.removeAttribute("class");
			}else{
				this.#elements.h.setAttribute("class", "require");
			}
		}
	}
	connectedCallback(){
		if(this.textContent == ""){
			this.appendChild(this.#input);
			this.#observer.observe(this, {childList: true});
		}else{
			const content = this.querySelector('[slot="content"]');
			this.#initValue = true;
			if(content != null){
				content.parentNode.removeChild(content);
			}
			this.#input.value = this.textContent;
			if(this.#elements.i.tagName == "SPAN"){
				this.#elements.i.textContent = this.textContent;
			}else{
				this.#elements.i.value = this.textContent;
			}
			this.innerHTML = "";
			if(content != null){
				this.appendChild(content);
			}
			this.appendChild(this.#input);
		}
		this.#root = this.attachShadow({mode: "closed"});
		this.#root.appendChild(this.#fragment);
	}
	set value(v){
		this.#input.value = v;
		if(this.#elements.i.tagName == "SPAN"){
			this.#elements.i.textContent = v;
		}else{
			this.#elements.i.value = v;
		}
	}
	get value(){
		return this.#input.value;
	}
	reset(){
		this.#input.value = this.#defaultValue;
		if(this.#elements.i.tagName == "SPAN"){
			this.#elements.i.textContent = this.#defaultValue;
		}else{
			this.#elements.i.value = this.#defaultValue;
		}
	}
	bind(element, property){
		const input = document.createElement("slot");
		if(!this.#initValue){
			const content = this.querySelector('[slot="content"]');
			this.#observer.disconnect();
			this.#fragment.appendChild(this.#input);
			if(content != null){
				this.#fragment.appendChild(content);
			}
			this.#input.value = this.textContent;
			Object.assign(this, {innerHTML: ""}).appendChild(this.#fragment);
		}
		this.#elements.c.replaceChild(input, this.#elements.i);
		input.setAttribute("id", "i");
		input.setAttribute("name", "bind");
		Object.defineProperty(input, "value", property);
		this.appendChild(element);
		element.setAttribute("slot", "bind");
		input.value = this.#input.value;
		this.#elements.i = input;
	}
	handleEvent(e){
		if(e.type == "change"){
			this.#input.value = this.#elements.i.value;
		}
	}
	static observedAttributes = ["label", "name", "col", "type", "placeholder", "invalid", "list", "require"];
	static styleSheet = URL.createObjectURL(new Blob([`
		#h,#d{
			display: table-cell;
			border-bottom: 1px solid #dee2e6;
		}
		#h{
			padding: 0.5rem 0.5rem 0.5rem 1.5rem;
			background: #f8f9fa;
			vertical-align: middle;
			font-weight: bold;
		}
		.require#h::after{
			content: "\\0203b";
			margin-left: 1em;
			color: rgb(220,53,69);
		}
		#d{
			padding: 0.5rem;
		}
		#c{
			flex: 0 0 auto;
		}
		:not(span,slot)#i{
			display: block;
			width: 100%;
			padding: 0.375rem 0.75rem;
			font-size: 1rem;
			font-weight: 400;
			line-height: 1.5;
			color: #212529;
			background-color: #fff;
			background-clip: padding-box;
			border: 1px solid #ced4da;
			appearance: none;
			border-radius: 0.375rem;
			transition: border-color .15s ease-in-out,box-shadow .15s ease-in-out;
			margin: 0;
			font-family: inherit;
			box-sizing: border-box;
		}
		select#i{
			padding: 0.375rem 2.25rem 0.375rem 0.75rem;
			background-color: #fff;
			background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23343a40' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='m2 5 6 6 6-6'/%3e%3c/svg%3e");
			background-repeat: no-repeat;
			background-position: right 0.75rem center;
			background-size: 16px 12px;
		}
		textarea#i{
			resize: vertical;
		}
		:not(span,slot)#i:focus{
			color: #212529;
			background-color: #fff;
			border-color: #86b7fe;
			outline: 0;
			box-shadow: 0 0 0 0.25rem rgba(13,110,253,.25);
		}
		#d:has(.invalid) :not(span,slot)#i{
			border-color: #dc3545;
			padding-right: calc(1.5em + 0.75rem);
			background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 12 12' width='12' height='12' fill='none' stroke='%23dc3545'%3e%3ccircle cx='6' cy='6' r='4.5'/%3e%3cpath stroke-linejoin='round' d='M5.8 3.6h.4L6 6.5z'/%3e%3ccircle cx='6' cy='8.2' r='.6' fill='%23dc3545' stroke='none'/%3e%3c/svg%3e");
			background-repeat: no-repeat;
			background-position: right calc(0.375em + 0.1875rem) center;
			background-size: calc(0.75em + 0.375rem) calc(0.75em + 0.375rem);
		}
		#d:has(.invalid) :not(span,slot)#i:focus{
			border-color: #dc3545;
			box-shadow: 0 0 0 0.25rem rgba(220,53,69,.25);
		}
		.invalid{
			margin-top: 0.25rem;
			font-size: .875em;
			color: #dc3545;
		}
		.c1{ width: 8.33333333%; }
		.c2{ width: 16.66666667%; }
		.c3{ width: 25%; }
		.c4{ width: 33.33333333%; }
		.c5{ width: 41.66666667%; }
		.c6{ width: 50%; }
		.c7{ width: 58.33333333%; }
		.c8{ width: 66.66666667%; }
		.c9{ width: 75%; }
		.c10{ width: 83.33333333%; }
		.c11{ width: 91.66666667%; }
		.c12{ width: 100% }
	`], {type: "text/css"}));
}
customElements.define("row-form", RowFormElement);

class ModalSelectElement extends HTMLElement{
	#value; #root; #elements; #fragment; #callback; #view; #observer;
	constructor(){
		super();
		this.#value = "";
		this.#root = null;
		this.#elements = {
			i: document.createElement("input"),
			s: document.createElement("button"),
			d: document.createElement("div"),
			r: document.createElement("button")
		};
		this.#fragment = document.createDocumentFragment();
		this.#fragment.appendChild(this.#elements.d);
		this.#fragment.appendChild(this.#elements.r);
		this.#elements.i.setAttribute("id", "i");
		this.#elements.s.setAttribute("id", "s");
		this.#elements.d.setAttribute("id", "d");
		this.#elements.r.setAttribute("id", "r");
		this.#elements.s.setAttribute("type", "button");
		this.#elements.s.textContent = "検索";
		this.#elements.r.setAttribute("type", "button");
		this.#elements.r.textContent = "取消";
		this.#callback = {
			searchKeyword: null,
			showModal: null,
			getTitle: null,
			resetValue: null
		};
		this.#view = null;
		this.#observer = new MutationObserver((mutationsList, observer) => {
			for(let record of mutationsList){
				if(record.type == "attributes"){
					if(record.target.hasAttribute(record.attributeName)){
						this.setAttribute(record.attributeName, record.target.getAttribute(record.attributeName));
					}else{
						this.removeAttribute(record.attributeName);
					}
				}
			}
		});
	}
	attributeChangedCallback(name, oldValue, newValue){
		if(name == "placeholder"){
			if(newValue == null){
				this.#elements.i.removeAttribute("placeholder");
			}else{
				this.#elements.i.setAttribute("placeholder", newValue);
			}
		}else if(name == "invalid"){
			if(newValue == null){
				this.#elements.i.removeAttribute("class");
				this.#elements.d.removeAttribute("class");
			}else{
				this.#elements.i.setAttribute("class", "invalid");
				this.#elements.d.setAttribute("class", "invalid");
			}
		}
	}
	connectedCallback(){
		const link = document.createElement("link");
		link.setAttribute("rel", "stylesheet");
		link.setAttribute("href", ModalSelectElement.styleSheet);
		this.#root = this.attachShadow({mode: "closed"});
		this.#elements.i.addEventListener("change", this);
		this.#elements.s.addEventListener("click", this);
		this.#elements.r.addEventListener("click", this);
		this.#root.appendChild(link);
		this.#root.appendChild(this.#elements.i);
		this.#root.appendChild(this.#elements.s);
		this.#view = 1;
	}
	handleEvent(e){
		if(e.type == "change"){
			if(this.#callback.searchKeyword != null){
				this.#callback.searchKeyword(this.#elements.i.value);
			}
		}else if(e.type == "click"){
			if(e.currentTarget == this.#elements.s){
				if(this.#callback.showModal != null){
					this.#callback.showModal();
				}
			}else if(e.currentTarget == this.#elements.r){
				if(this.#view == 2){
					this.#view = 1;
					this.#elements.d.textContent = "";
					const range = document.createRange();
					range.selectNodeContents(this.#root);
					range.setStart(this.#root, 1);
					const flagment = range.extractContents();
					range.insertNode(this.#fragment);
					this.#fragment = flagment;
				}
				if(this.#callback.resetValue != null){
					this.#callback.resetValue();
				}
			}
		}
	}
	showTitle(title){
		if(title == null){
			if(this.#view == 2){
				this.#view = 1;
				this.#elements.d.textContent = "";
				const range = document.createRange();
				range.selectNodeContents(this.#root);
				range.setStart(this.#root, 1);
				const flagment = range.extractContents();
				range.insertNode(this.#fragment);
				this.#fragment = flagment;
			}
		}else{
			this.#elements.d.textContent = title;
			if(this.#view == 1){
				this.#view = 2;
				const range = document.createRange();
				range.selectNodeContents(this.#root);
				range.setStart(this.#root, 1);
				const flagment = range.extractContents();
				range.insertNode(this.#fragment);
				this.#fragment = flagment;
			}
		}
	}
	syncAttribute(element){
		this.#observer.disconnect();
		for(let attr of ModalSelectElement.observedAttributes){
			if(element.hasAttribute(attr)){
				this.setAttribute(attr, element.getAttribute(attr));
			}else{
				this.removeAttribute(attr);
			}
		}
		this.#observer.observe(element, {attributes: true, attributeFilter: ModalSelectElement.observedAttributes});
	}
	set searchKeyword(func){
		this.#callback.searchKeyword = func;
		if(func != null){
			func(this.#elements.i.value);
		}
	}
	set resetValue(func){
		this.#callback.resetValue = func;
	}
	set showModal(func){
		this.#callback.showModal = func;
	}
	set getTitle(func){
		this.#callback.getTitle = func;
	}
	get valueProperty(){
		return {
			get: () => this.#value,
			set: newValue => {
				this.#value = newValue;
				if(this.#callback.getTitle != null){
					this.#callback.getTitle(newValue);
				}
			}
		};
	}
	set keyword(str){
		this.#elements.i.value = str;
		if(this.#callback.searchKeyword != null){
			this.#callback.searchKeyword(str);
		}
	}
	get keyword(){
		return this.#elements.i.value;
	}
	static observedAttributes = ["placeholder", "invalid"];
	static styleSheet = URL.createObjectURL(new Blob([`
		#i, #d{
			display: block;
			flex-grow: 1;
			min-width: 0;
			padding: 0.375rem 0.75rem;
			font-size: 1rem;
			font-weight: 400;
			line-height: 1.5;
			color: #212529;
			background-color: #fff;
			background-clip: padding-box;
			border: 1px solid #ced4da;
			border-right: none;
			appearance: none;
			border-radius: 0.375rem 0 0 0.375rem;
			transition: border-color .15s ease-in-out,box-shadow .15s ease-in-out;
			margin: 0;
			font-family: inherit;
		}
		.invalid#i, .invalid#d{
			border-color: #dc3545;
			padding-right: calc(1.5em + 0.75rem);
			background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 12 12' width='12' height='12' fill='none' stroke='%23dc3545'%3e%3ccircle cx='6' cy='6' r='4.5'/%3e%3cpath stroke-linejoin='round' d='M5.8 3.6h.4L6 6.5z'/%3e%3ccircle cx='6' cy='8.2' r='.6' fill='%23dc3545' stroke='none'/%3e%3c/svg%3e");
			background-repeat: no-repeat;
			background-position: right calc(0.375em + 0.1875rem) center;
			background-size: calc(0.75em + 0.375rem) calc(0.75em + 0.375rem);
		}
		#i:focus{
			color: #212529;
			background-color: #fff;
			border-color: #86b7fe;
			outline: 0;
			box-shadow: 0 0 0 0.25rem rgba(13,110,253,.25);
		}
		.invalid#i:focus{
			border-color: #dc3545;
			box-shadow: 0 0 0 0.25rem rgba(220,53,69,.25);
		}
		#s,#r{
			display: block;
			flex-shrink: 0;
			padding: 0.375rem 0.75rem;
			font-size: 1rem;
			font-weight: 400;
			line-height: 1.5;
			color: #fff;
			text-align: center;
			text-decoration: none;
			vertical-align: middle;
			cursor: pointer;
			user-select: none;
			border-radius: 0 0.375rem 0.375rem 0;
			transition: color .15s ease-in-out,background-color .15s ease-in-out,border-color .15s ease-in-out,box-shadow .15s ease-in-out;
		}
		#s{
			border: 1px solid #009ea7;
			background-color: #009ea7;
		}
		#s:hover{
			border: 1px solid #007e86;
			background-color: #00868e;
		}
		#s:active{
			border: 1px solid #00777d;
			background-color: #007e86;
		}
		#s:focus{
			outline: 0;
			border-radius: 0.375rem;
			box-shadow: 0 0 0 0.25rem rgba(38, 173, 180,.25);
		}
		#r{
			border: 1px solid #dc3545;
			background-color: #dc3545;
		}
		#r:hover{
			border: 1px solid #b02a37;
			background-color: #bb2d3b;
		}
		#r:active{
			border: 1px solid #a52834;
			background-color: #b02a37;
		}
		#r:focus{
			outline: 0;
			border-radius: 0.375rem;
			box-shadow: 0 0 0 0.25rem rgba(225,83,97,.25);
		}
	`], {type: "text/css"}));
}
customElements.define("modal-select", ModalSelectElement);
