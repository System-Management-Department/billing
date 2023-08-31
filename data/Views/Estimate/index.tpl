{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
<style type="text/css">
#spmain::part(body){
	height: auto;
}
#spmain::part(d-table){
	display: table;
}
#spmain::part(d-table-column-group){
	display: table-column-group;
}
#spmain::part(d-table-column){
	display: table-column;
}
#spmain::part(d-table-row-group){
	display: table-row-group;
}
#spmain::part(bg-light){
	background-color: rgba(var(--bs-light-rgb),1);
}
.d-table-row{
	border-color: var(--bs-table-border-color)
}
.d-table-cell{
	border-color: inherit;
	border-style: solid;
	border-width: 0;
}
.th{
	text-align: -webkit-match-parent;
	font-weight: bold;
	width: 10em;
}
form{
	display: contents;
}
print-page{
	padding: 24px;
}
edit-table{
	display: block;
	overflow: hidden;
	height: calc(100vh - 10rem);
}
.invalid{
	font-size: 1rem;
	color: #dc3545;
}
#HandsontableCopyPaste{
	display: none;
}
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/common/PrintPage.js"></script>
<script type="text/javascript" src="/assets/jspdf/jspdf.umd.min.js"></script>
<script type="text/javascript" src="/assets/handsontable/handsontable.full.min.js"></script>
<script type="text/javascript">
class Detail{
	#values;
	constructor(arg = null){
		if(arg == Detail.header){
			this.#values = {
				detail: "内容",
				quantity: "数量",
				unit: "単位",
				unit_price: "単価",
				amount_exc: "税抜金額",
				amount_tax: "消費税金額",
				amount_inc: "税込金額",
				category: "カテゴリー",
				circulation: "発行部数"
			};
		}else if((arg != null) && (typeof arg == "object")){
			this.#values = {
				sd: ("sd" in arg) ? arg.sd : null,
				detail: ("detail" in arg) ? arg.detail : null,
				quantity: ("quantity" in arg) ? arg.quantity : null,
				unit: ("unit" in arg) ? arg.unit : null,
				unit_price: ("unit_price" in arg) ? arg.unit_price : null,
				amount_exc: ("amount_exc" in arg) ? arg.amount_exc : null,
				amount_tax: ("amount_tax" in arg) ? arg.amount_tax : null,
				amount_inc: ("amount_inc" in arg) ? arg.amount_inc : null,
				category: ("category" in arg) ? arg.category : null,
				record: ("record" in arg) ? (arg.record == 1) : false,
				taxable: ("taxable" in arg) ? (arg.taxable == 1) : false,
				tax_rate: ("tax_rate" in arg) ? arg.tax_rate : null,
				[Detail.attributes]: ("attributes" in arg) ? JSON.parse(arg.attributes) : null
			};
		}else{
			this.#values = {
				sd: null,
				detail: null,
				quantity: null,
				unit: null,
				unit_price: null,
				amount_exc: null,
				amount_tax: null,
				amount_inc: null,
				category: null,
				record: false,
				taxable: false,
				tax_rate: null,
				[Detail.attributes]: null // {summary_data: ["", "", ""], circulation: null}
			};
		}
	}
	dataValue(key, ...args){
		if(args.length > 0){
			const value = args[0];
			if((key == "quantity") || (key == "unit_price")){
				this.#values[key] = Number(value);
				this.#values.record = true;
				this.#values.taxable = true;
				this.#values.tax_rate = 0.1;
				this.#values.amount_exc = Math.floor(this.#values.quantity * this.#values.unit_price);
				this.#values.amount_tax = Math.floor(this.#values.amount_exc * this.#values.tax_rate);
				this.#values.amount_inc = Math.floor(this.#values.amount_exc + this.#values.amount_tax);
			}else if(key == "category"){
				const optionElements = document.querySelectorAll('#category [value]');
				const n = optionElements.length;
				let found = false;
				for(let i = 0; i < n; i++){
					if(value == optionElements[i].textContent){
						this.#values[key] = optionElements[i].getAttribute("value");
						found = true;
						break;
					}
				}
				if(!found){
					this.#values[key] = null;
				}
			}else if(key == "circulation"){
				this.#values[Detail.attributes].circulation = value;
			}else if(key == "summary_data1"){
				this.#values[Detail.attributes].summary_data[0] = value;
			}else if(key == "summary_data2"){
				this.#values[Detail.attributes].summary_data[1] = value;
			}else if(key == "summary_data3"){
				this.#values[Detail.attributes].summary_data[2] = value;
			}else{
				this.#values[key] = value;
			}
		}else{
			if(!("record" in this.#values)){
				return this.#values[key];
			}else if(key == "category"){
				const optionElements = document.querySelectorAll('#category [value]');
				const n = optionElements.length;
				for(let i = 0; i < n; i++){
					if(this.#values[key] == optionElements[i].getAttribute("value")){
						return optionElements[i].textContent;
					}
				}
				return null;
			}else if(key == "circulation"){
				if(this.#values[Detail.attributes] == null){
					this.#values[Detail.attributes] = {};
				}
				return this.#values[Detail.attributes].circulation;
			}else if(key == "summary_data1"){
				if(this.#values[Detail.attributes] == null){
					this.#values[Detail.attributes] = {summary_data: ["", "", ""]};
				}
				return this.#values[Detail.attributes].summary_data[0];
			}else if(key == "summary_data2"){
				if(this.#values[Detail.attributes] == null){
					this.#values[Detail.attributes] = {summary_data: ["", "", ""]};
				}
				return this.#values[Detail.attributes].summary_data[1];
			}else if(key == "summary_data3"){
				if(this.#values[Detail.attributes] == null){
					this.#values[Detail.attributes] = {summary_data: ["", "", ""]};
				}
				return this.#values[Detail.attributes].summary_data[2];
			}else{
				return this.#values[key];
			}
		}
	}
	isReadOnly(col){
		if((Detail.tableKeys[col] == "detail") || (Detail.tableKeys[col] == "circulation") || (Detail.tableKeys[col] == "summary_data1") || (Detail.tableKeys[col] == "summary_data2") || (Detail.tableKeys[col] == "summary_data3")){
			return false;
		}
		if((Detail.tableKeys[col] != "quantity") && (Detail.tableKeys[col] != "unit") && (Detail.tableKeys[col] != "unit_price")){
			return true;
		}
		return false;
	}
	get detail(){
		let res = {};
		for(let key in this.#values){
			res[key] = (typeof this.#values[key] == "boolean") ? (this.#values[key] ? 1 : 0) : this.#values[key]
		}
		return res;
	}
	get attribute(){
		return {sd: this.#values.sd ,data: this.#values[Detail.attributes]};
	}
	static header = Symbol("header");
	static info = Symbol("info");
	static attributes = Symbol("attributes");
	static tableKeys = ["detail", "quantity", "unit", "unit_price", "amount_exc", "amount_tax", "amount_inc", "category"];
	static tableColumn(key){
		if((key == "amount_exc") || (key == "amount_tax") || (key == "amount_inc")){
			return {
				data: (...args) => {
					const obj = args.shift();
					return obj.dataValue(key, ...args);
				},
				type: "numeric",
				readOnly: true,
				numericFormat: {
					pattern: '0,0',
				},
			};
		}else if((key == "quantity") || (key == "unit_price") || (key == "circulation")){
			return {
				data: (...args) => {
					const obj = args.shift();
					return obj.dataValue(key, ...args);
				},
				type: "numeric",
				numericFormat: {
					pattern: '0,0',
				}
			};
		}else if((key == "detail") || (key == "unit") || (key == "summary_data1") || (key == "summary_data2") || (key == "summary_data3")){
			return {
				data: (...args) => {
					const obj = args.shift();
					return obj.dataValue(key, ...args);
				},
				type: "text"
			};
		}else{
			return {
				data: (...args) => {
					const obj = args.shift();
					return obj.dataValue(key, ...args);
				},
				type: "text",
				readOnly: true
			};
		}
	}
}
class EditTableElement extends HTMLElement{
	#root; #hot; #observer; #input1; #input2;
	constructor(){
		super();
		this.#root = null;
		this.#hot = null;
		this.#observer = new ResizeObserver((entries, observer) => {
			this.#hot.updateSettings({height: this.clientHeight});
		});
		this.#observer.observe(this);
		this.#input1 = document.createElement("input");
		this.#input1.setAttribute("name", "detail");
		this.#input1.setAttribute("type", "hidden");
		this.#input1.value = "[]";
		this.#input2 = document.createElement("input");
		this.#input2.setAttribute("name", "detail_attribute");
		this.#input2.setAttribute("type", "hidden");
		this.appendChild(this.#input1);
		this.appendChild(this.#input2);
	}
	attributeChangedCallback(name, oldValue, newValue){}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<link rel="stylesheet" type="text/css" href="/assets/handsontable/handsontable.full.min.css" /><div></div>'});
			this.#hot = new Handsontable(this.#root.querySelector('div'), this.detailOption);
			this.#hot.addHook("afterChange", () => {
				const sd = this.#hot.getSourceData().slice(1);
				this.dispatchEvent(new CustomEvent("change", {detail: sd.map(r => r.detail)}));
				this.#input1.value = JSON.stringify(sd.map(r => r.detail));
				this.#input2.value = JSON.stringify(sd.map((r, i) => Object.assign({row: i}, r.attribute)).filter(r => r.data != null));
			});
		}
	}
	disconnectedCallback(){
	}
	get detailOption(){
		const header = new Detail(Detail.header);
		return {
			fixedRowsTop: 1,
			columns: Detail.tableKeys.map(key => Detail.tableColumn(key)),
			manualColumnResize: true,
			trimWhitespace: false,
			data: [header],
			dataSchema(){
				return new Detail()
			},
			afterCreateRow(...amount){},
			cells: (row, cols, prop) => {
				if(row == 0){
					return {
						renderer: "html",
						readOnly: true
					};
				}
				if(this.#hot == null){
					return {readOnly: header.isReadOnly(cols)};
				}
				return {readOnly: this.#hot.getSourceData()[row].isReadOnly(cols)};
			},
			autoRowSize: true,
			minSpareRows: 1
		};
	}
	set value(data){
		let loadData = [new Detail(Detail.header)];
		if(Array.isArray(data)){
			for(let row of data){
				loadData.push(new Detail(row));
			}
		}
		this.#hot.updateSettings({columns: Detail.tableKeys.map(key => Detail.tableColumn(key))});
		this.#hot.loadData(loadData);
		this.#hot.render();
	}
	static observedAttributes = [];
}
customElements.define("edit-table", EditTableElement);


class ListButtonElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<span></span>'});
	}
	connectedCallback(){
		setTimeout(() => {this.setAttribute("data-result", this.textContent); } ,0);
	}
	disconnectedCallback(){}
	attributeChangedCallback(name, oldValue, newValue){
		if(name == "label"){
			const label = this.#root.querySelector('span');
			if(newValue == null){
				label.textContent = "";
			}else{
				label.textContent = newValue;
			}
		}
	}
	static get observedAttributes(){ return ["label"]; }
}
customElements.define("list-button", ListButtonElement);
</script>{/literal}
{jsiife id=$id}{literal}
if(id == "2"){
	Detail.tableKeys.push("circulation");
}else if(id == "3"){
	Detail.tableKeys.push("summary_data1", "summary_data2", "summary_data3");
}

new VirtualPage("/1", class{
	constructor(vp){
		document.querySelector('edit-table').addEventListener("change", e => {
			const total = e.detail.reduce((a, row) => {
				if(row.record == 1){
					a.amount_exc += row.amount_exc;
					a.amount_tax += row.amount_tax;
					a.amount_inc += row.amount_inc;
				}
				return a; 
			}, {amount_exc: 0, amount_inc: 0, amount_tax: 0});
			document.querySelector('form-control[name="amount_exc"]').value = total.amount_exc;
			document.querySelector('form-control[name="amount_tax"]').value = total.amount_tax;
			document.querySelector('form-control[name="amount_inc"]').value = total.amount_inc;
		});
		
		
		const template = document.querySelector('#spmain [slot="print"] print-page');
		document.querySelector('[data-trigger="print"]').addEventListener("click", e => {
			const slotObj = {
				today: new Intl.DateTimeFormat("ja-JP").format(new Date()),
				subject: document.querySelector('form-control[name="subject"]').value,
				leader: document.querySelector('form-control[name="leader"]').text,
				manager: document.querySelector('form-control[name="manager"]').text,
				client_name: document.querySelector('form-control[name="client_name"]').value,
				amount_exc: document.querySelector('form-control[name="amount_exc"]').text,
				amount_tax: document.querySelector('form-control[name="amount_tax"]').text,
				amount_inc: document.querySelector('form-control[name="amount_inc"]').text,
				note: document.querySelector('form-control[name="note"]').value
			};
			const printArea = document.querySelector('#spmain [slot="print"]');
			printArea.innerHTML = "";
			printArea.appendChild(template.cloneNode(true));
			const slotElements = printArea.querySelectorAll('[data-slot]');
			for(let i = slotElements.length - 1; i >= 0; i--){
				const attr = slotElements[i].getAttribute("data-slot");
				if(attr in slotObj){
					slotElements[i].textContent = slotObj[attr];
				}
			}
			const tbody = printArea.querySelector('tbody:has([data-table-slot])');
			const tr = tbody.querySelector('tr');
			tbody.removeChild(tr);
			const details = JSON.parse(document.querySelector('input[name="detail"]').value);
			const proc = {
				detail(value){
					if(value == ""){
						return "\u200B";
					}
					return value;
				},
				quantity(value){
					return SinglePage.modal.number_format2.query(value);
				},
				unit_price(value){
					return SinglePage.modal.number_format2.query(value);
				},
				amount_exc(value){
					return SinglePage.modal.number_format.query(value);
				}
			};
			for(let row of details){
				const insertRow = tr.cloneNode(true);
				const slotElements2 = insertRow.querySelectorAll('[data-table-slot]');
				for(let i = slotElements2.length - 1; i >= 0; i--){
					const attr = slotElements2[i].getAttribute("data-table-slot");
					if(attr in row){
						slotElements2[i].textContent = (attr in proc) ? proc[attr](row[attr]) : row[attr];
					}
				}
				tbody.appendChild(insertRow);
			}
			printArea.querySelector('print-page').pageBreak(
				(function*(){
					const elements = document.querySelectorAll('[data-page-break]');
					const n = elements.length;
					for(let i = 0; i < n; i++){
						yield elements[i];
					}
				})(),
				node => ((node.nodeType == Node.ELEMENT_NODE) && node.hasAttribute("data-page-clone")),
				(page, node) => { page.insertAdjacentElement("afterend", node); }
			);
			
			
			let docIds = {};
			const doc = new jspdf.jsPDF({unit: "pt"});
			for(let fontName in PrintPage.font){
				docIds[fontName] = `custom${Object.keys(docIds).length}`;
				doc.addFileToVFS(PrintPage.font[fontName].alias, PrintPage.font[fontName].data);
				doc.addFont(PrintPage.font[fontName].alias, docIds[fontName], 'normal');
			}
			
			const pxPt = 0.75;
			const textOpt = {align: "left", baseline: "top"};
			const printPages = document.querySelectorAll('#spmain [slot="print"] print-page');
			const pageCnt = printPages.length;
			for(let i = 0; i < pageCnt; i++){
				const printData = printPages[i].printData;
				const textLen = printData.text.length;
				let ctx = {};
				doc.addPage(printData.page.size, printData.page.orientation);
				for(let pos = 0; pos < textLen; pos++){
					if(pos in printData.style){
						let changeFont = false;
						if("fontFamily" in printData.style[pos]){
							changeFont = true;
							ctx.fontFamily = docIds[printData.style[pos].fontFamily];
						}
						if("fontWeight" in printData.style[pos]){
							changeFont = true;
							ctx.fontWeight = printData.style[pos].fontWeight ? "bold" : null;
						}
						if(changeFont){
							doc.setFont(ctx.fontFamily);
						}
						if("fontColor" in printData.style[pos]){
							const colorParts = printData.style[pos].fontColor.match(/\d+/g);
							doc.setTextColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
						}
						if("fontSize" in printData.style[pos]){
							doc.setFontSize(printData.style[pos].fontSize * pxPt);
						}
						if("line" in printData.style[pos]){
							for(let line of printData.style[pos].line){
								const colorParts = line.color.match(/\d+/g);
								doc.setDrawColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
								doc.setLineWidth(line.width * pxPt);
								doc.line(line.x1 * pxPt, line.y1 * pxPt, line.x2 * pxPt, line.y2 * pxPt);
							}
						}
					}
					const textData = printData.text[pos];
					doc.text(textData.ch, textData.x * pxPt, textData.y * pxPt, textOpt);
				}
			}
			doc.deletePage(1);
			//doc.save('output.pdf');
			open(doc.output("bloburi"));
		});
	}
});
new VirtualPage("/2", class{
	constructor(vp){
	}
});
new VirtualPage("/3", class{
	constructor(vp){
	}
});
new VirtualPage("/4", class{
	constructor(vp){
	}
});

let master = new SQLite();
let transaction = new SQLite();
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	SinglePage.modal.leader      .querySelector('table-sticky').columns = dataTableQuery("/Modal/Leader#list").setField("label,width,slot,part").apply();
	SinglePage.modal.manager     .querySelector('table-sticky').columns = dataTableQuery("/Modal/Manager#list").setField("label,width,slot,part").apply();
	SinglePage.modal.apply_client.querySelector('table-sticky').columns = dataTableQuery("/Modal/ApplyClient#list").setField("label,width,slot,part").apply();
	
	SinglePage.modal.leader.setQuery(v => master.select("ONE").setTable("leaders").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.leader.querySelector('table-sticky'),
			dataTableQuery("/Modal/Leader#list").apply(),
			master.select("ALL")
				.setTable("leaders")
				.apply(),
			row => {}
		);
	});
	SinglePage.modal.manager.setQuery(v => master.select("ONE").setTable("managers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.manager.querySelector('table-sticky'),
			dataTableQuery("/Modal/Manager#list").apply(),
			master.select("ALL")
				.setTable("managers")
				.apply(),
			row => {}
		);
	});
	SinglePage.modal.apply_client.setQuery(v => master.select("ONE").setTable("system_apply_clients").setField("unique_name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.apply_client.querySelector('table-sticky'),
			dataTableQuery("/Modal/ApplyClient#list").apply(),
			master.select("ALL")
				.setTable("system_apply_clients")
				.setField("system_apply_clients.code,system_apply_clients.unique_name as name,system_apply_clients.kana")
				.leftJoin("clients on system_apply_clients.client=clients.code")
				.addField("clients.name as client")
				.apply(),
			row => {}
		);
	});
	
	master.select("ALL")
		.setTable("categories")
		.apply()
		.forEach(function(row){
			const option = document.createElement("option");
			option.setAttribute("value", row.code);
			option.textContent = row.name;
			this.appendChild(option);
		}, document.getElementById("category"));
	master.select("ALL")
		.setTable("divisions")
		.apply()
		.forEach(function(row){
			const option = document.createElement("option");
			option.setAttribute("value", row.code);
			option.textContent = row.name;
			this.appendChild(option);
		}, document.getElementById("division"));
	
	SinglePage.modal.number_format.setQuery(v => new Intl.NumberFormat().format(v));
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 2}).format(v));
	
	SinglePage.location = `/${id}`;
});

function formTableInit(parent, data){
	return new Promise((resolve, reject) => {
		let tableList = {};
		for(let row of data){
			if(!(row.column in tableList)){
				tableList[row.column] = {
					table: Object.assign(document.createElement("table"), {className: "table my-0"}),
					tbody: document.createElement("tbody")
				};
				const colgroup = document.createElement("colgroup");
				colgroup.appendChild(Object.assign(document.createElement("col"), {className: "bg-light"}));
				colgroup.appendChild(document.createElement("col"));
				tableList[row.column].table.appendChild(colgroup)
				tableList[row.column].table.appendChild(tableList[row.column].tbody);
			}
			const tr = document.createElement("tr");
			const th = document.createElement("th");
			const td = document.createElement("td");
			const formControl = document.createElement("form-control");
			const invalid = Object.assign(document.createElement("div"), {className: "invalid"});
			th.textContent = row.label;
			th.className = "align-middle ps-4";
			formControl.setAttribute("fc-class", `col-${row.width}`);
			formControl.setAttribute("name", row.name);
			formControl.setAttribute("type", row.type);
			if((row.list != null) && (row.list != "")){
				formControl.setAttribute("list", row.list);
			}
			if((row.placeholder != null) && (row.placeholder != "")){
				formControl.setAttribute("placeholder", row.placeholder);
			}
			
			td.appendChild(formControl);
			td.appendChild(invalid);
			tr.appendChild(th);
			tr.appendChild(td);
			tableList[row.column].tbody.appendChild(tr);
		}
		const tableColumns = Object.keys(tableList).sort();
		for(let tableNo of tableColumns){
			if(parent.tagName == "SEARCH-FORM"){
				tableList[tableNo].table.setAttribute("slot", "body");
			}
			parent.appendChild(tableList[tableNo].table);
		}
		setTimeout(() => { resolve(parent); }, 0);
	});
}
function formTableQuery(location){
	return master.select("ALL").setTable("form_datas").andWhere("location=?", location).setOrderBy("CAST(no AS INTEGER)");
}
function dataTableQuery(location){
	return master.select("ALL").setTable("table_datas").andWhere("location=?", location).setOrderBy("CAST(no AS INTEGER)");
}
function setDataTable(parent, columns, data, callback = null){
	return new Promise((resolve, reject) => {
		parent.innerHTML = "";
		const text = document.createElement("span");
		for(let row of data){
			const elements = [];
			for(let col of columns){
				const div = document.createElement("div");
				const dataElement = document.createElement(col.tag_name);
				const classList = (col.class_list == null) ? [] : col.class_list.split(/\s/).filter(v => v != "");
				let attrStr = (col.attributes == null) ? "" : col.attributes;
				do{
					const nextStr = attrStr.replace(/^\s*([a-zA-Z0-9\-]+)="([^"]*?)"/, (str, name, value) => {
						if(name != ""){
							dataElement.setAttribute(name, Object.assign(text, {innerHTML: value}).textContent);
						}
						return "";
					});
					if(attrStr == nextStr){
						break;
					}
					attrStr = nextStr;
				}while(true);
				div.setAttribute("slot", col.slot);
				dataElement.textContent = row[col.property];
				if(classList.length > 0){
					dataElement.classList.add(...classList);
				}
				div.appendChild(dataElement);
				elements.push(div);
			}
			const dataRow = parent.insertRow(...elements);
			if(callback != null){
				callback(dataRow, row);
			}
		}
		setTimeout(() => { resolve(parent); }, 0);
	});
}
{/literal}{/jsiife}
{/block}
{block name="body"}
	<form>
		<div id="spmain">
			<template shadowroot="closed">
				<slot name="print"></slot>
				<div part="body">
					<header part="header">
						<nav part="nav1">
							<div part="container">
								<div part="title">見積作成</div>
							</div>
						</nav>
						<nav part="nav2">
							<div part="tools"><slot name="tools"></slot></div>
						</nav>
					</header>
					<div>
						<div style="display: grid; column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;">
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table1"></slot>
								</div>
							</div>
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table2"></slot>
								</div>
							</div>
						</div>
					</div>
					<slot name="main"></slot>
				</div>
			</template>
			<template data-page-share="">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div>
									<div class="border-xs border-ts border-bs">仕様</div>
									<div class="border-xs border-bd"><span>仕様1</span></div>
									<div class="border-xs border-bs"><span>仕様2</span></div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1">
										<div>合計金額</div>
										<div class="price">\<span data-slot="amount_inc">0,000,000</span>-</div>
										<div>（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" />
										<col class="tw3" />
										<col class="tw4" />
										<col class="tw5" />
									</colgroup>
									<thead  data-page-clone="1">
										<tr>
											<th>摘要</th>
											<th>数量</th>
											<th>単位</th>
											<th>単価</th>
											<th>金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end"><span data-table-slot="quantity">0,000.00</span></td>
											<td><span data-table-slot="unit">DATA</span></td>
											<td class="text-end"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate">
										<tr>
											<td colspan="4">上記計</td>
											<td class="text-end" data-slot="amount_exc"><span>0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="4">消費税（10％）</td>
											<td class="text-end" data-slot="amount_tax"><span>0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column">
								<div>備考</div>
								<div class="grow-1 border-2"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
				<div slot="table1" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">案件番号</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="project" type="text"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">件名</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="subject" type="text"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="division" type="select" list="division"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門長</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="leader" type="keyword" list="leader" placeholder="部門長名・部門長CDで検索"></form-control></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">営業担当者</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="manager" type="keyword" list="manager" placeholder="担当者名・担当者CDで検索"></form-control></form-control></div>
					</div>
				</div></div>
				<div slot="main">
					<edit-table></edit-table>
					<div class="invalid"></div>
				</div>
			</template>
			<template data-page-share="/3">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">納品先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">入金予定日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format"></form-control></div>
					</div>
				</div></div>
			</template>
			<template data-page="/3">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">納品先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">入金予定日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">摘要ヘッダ</div>
						<div class="d-table-cell">
							<div class="d-flex col-10 gap-3">
								<form-control name="" type="text"></form-control>
								<form-control name="" type="text"></form-control>
								<form-control name="" type="text"></form-control>
							</div>
						</div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format"></form-control></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format"></form-control></div>
					</div>
				</div></div>
			</template>
			<template data-page-share="">
				<span slot="tools" class="btn btn-primary my-2" data-trigger="export">見積データ出力</span>
				<span slot="tools" class="btn btn-primary my-2" data-trigger="print">見積書生成</span>
				<span slot="tools"" class="btn btn-primary my-2" data-trigger="submit">登録</span>
			</template>
		</div>
	</form>
	
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<modal-dialog name="leader" label="部門長選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="manager" label="当社担当者選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="apply_client" label="請求先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="number_format"></modal-dialog>
	<modal-dialog name="number_format2"></modal-dialog>
{/block}