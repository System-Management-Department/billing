{* 順番の並び替えはなし、　計上になっているものは内容、数量、単位、単価のみ書き換え可能。計上でない場合は内容のみ *}
{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<style type="text/css">
#spmain::part(body){
	height: auto;
}
form[slot]{
	display: contents;
}
edit-table{
	display: block;
	overflow: hidden;
	max-height: calc(100vh - 10rem);
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
		return(!this.#values.record);
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
		return {
			fixedRowsTop: 1,
			columns: Detail.tableKeys.map(key => Detail.tableColumn(key)),
			manualColumnResize: true,
			trimWhitespace: false,
			data: [new Detail(Detail.header)],
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
				return {readOnly: this.#hot.getSourceData()[row].isReadOnly(cols)};
			},
			autoRowSize: true
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
new VirtualPage("/edit", class{
	constructor(vp){
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
			const form = document.querySelector("form");
			const formData = new FormData(form);
			fetch(`/Committed/update/${id}`, {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(result => {
				if(result.success){
					const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
						const found = t.match(/^(.*?)=(.*)$/);
						if(found){
							a[found[1]] = decodeURIComponent(found[2]);
						}
						return a;
					},{});
					new BroadcastChannel(search.channel).postMessage(JSON.stringify(result));
					close();
				}else{
					const messages = {};
					const messages2 = document.createDocumentFragment();
					for(let meaasge of result.messages.filter(m => (m[1] == 2))){
						let token = meaasge[2].split("/");
						if(token.length == 1){
							messages[meaasge[2]] = meaasge[0];
						}else if(token.length == 3){
							messages2.appendChild(Object.assign(document.createElement("div"), {textContent: `${Number(token[1]) + 1}行目：${meaasge[0]}`}));
						}
					}
					
					const inputElements = form.querySelectorAll('form-control[name]');
					const n = inputElements.length;
					for(let i = 0; i < n; i++){
						const name = inputElements[i].getAttribute("name");
						inputElements[i].invalid = (name in messages);
						inputElements[i].nextSibling.textContent = (name in messages) ? messages[name] : "";
					}
					const range = document.createRange();
					const tableInvalid = document.querySelector('edit-table~.invalid');
					range.selectNodeContents(tableInvalid);
					range.deleteContents();
					tableInvalid.appendChild(messages2);
				}
			});
		});
		
		const salesSlip = transaction.select("ROW")
			.setTable("sales_slips")
			.apply();
		formTableInit(document.querySelector('.sales-form'), formTableQuery("/Sales#edit").apply()).then(form => {
			const inputElements = form.querySelectorAll('form-control[name]');
			const n = inputElements.length;
			for(let i = 0; i < n; i++){
				const name = inputElements[i].getAttribute("name");
				if(name in salesSlip){
					inputElements[i].value = salesSlip[name];
				}
			}
		});
		
		if(salesSlip.invoice_format == 2){
			Detail.tableKeys.push("circulation");
		}else if(salesSlip.invoice_format == 3){
			Detail.tableKeys.push("summary_data1", "summary_data2", "summary_data3");
		}
		const detail = transaction.select("All")
			.setTable("sales_details")
			.addField("sales_details.*")
			.leftJoin("sales_detail_attributes using(sd)")
			.addField("sales_detail_attributes.data AS attributes")
			.apply();
		const table = document.querySelector('edit-table');
		table.value = detail;
		table.addEventListener("change", e => {
			const total = e.detail.reduce((a, r) => {
				if(r.record == 1){
					a.amount_exc += r.amount_exc;
					a.amount_tax += r.amount_tax;
					a.amount_inc += r.amount_inc;
				}
				return a;
			}, {amount_exc: 0, amount_tax: 0, amount_inc: 0});
			document.querySelector('form form-control[name="amount_exc"]').value = total.amount_exc;
			document.querySelector('form form-control[name="amount_tax"]').value = total.amount_tax;
			document.querySelector('form form-control[name="amount_inc"]').value = total.amount_inc;
			console.log(total);
			
		});
	}
});

let master = new SQLite();
let transaction = new SQLite();
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	transaction.use("transaction").then(transaction => fetch(`/Committed/detail/${id}`)).then(res => res.arrayBuffer()),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	transaction.import(response[1], "transaction");
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
	
	SinglePage.location = "/edit";
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
	<div id="spmain">
		<template shadowroot="closed">
			<div part="body">
				<header part="header">
					<nav part="nav1">
						<div part="container">
							<div part="title">追加修正</div>
						</div>
					</nav>
					<nav part="nav2">
						<div part="tools"><slot name="tools"></slot></div>
					</nav>
				</header>
				<slot name="main"></slot>
			</div>
		</template>
		<template data-page="/edit">
			<form slot="main">
				<div>
					<div class="sales-form" style="display: grid; column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;"></div>
				</div>
				<edit-table></edit-table>
				<div class="invalid"></div>
				<div><button type="button" class="btn btn-success" data-trigger="submit">登録</button></div>
			</form>
		</template>
	</div>
	
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
{/block}