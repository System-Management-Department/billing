{* 順番の並び替えはなし、　計上になっているものは内容、数量、単位、単価のみ書き換え可能。計上でない場合は内容のみ *}
{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jsuites.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jspreadsheet.css" />
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
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
<script type="text/javascript">
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
			const details = document.getElementById("detail").jspreadsheet.options.data.map(rowProxy => {
				let res = {};
				const row = rowProxy[objectData];
				for(let key in row){
					if(typeof row[key] == "boolean"){
						res[key] = row[key] ? 1 : 0;
					}else{
						res[key] = row[key];
					}
				}
				return res;
			});
			formData.append("detail", JSON.stringify(details));
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
	}
});

let master = new SQLite();
let transaction = new SQLite();
const objectData = Symbol("objectData");
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
	
	const categories = master.select("ALL")
		.setTable("categories")
		.apply();
	categories.forEach(function(row){
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
	master.select("ALL")
		.setTable("specifications")
		.apply()
		.forEach(function(row){
			const option = document.createElement("option");
			option.setAttribute("value", row.code);
			option.textContent = row.name;
			this.appendChild(option);
		}, document.getElementById("specification"));
	
	SinglePage.modal.number_format.setQuery(v => new Intl.NumberFormat().format(v));
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 2}).format(v));
	
	SinglePage.location = "/edit";
	
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
	const refDetail = Symbol("refDetail");
	const refAttr = Symbol("refAttr");
	const jse = document.getElementById("detail");
	const taxableObj = {
		taxable: true,
		tax_rate: 0.1
	};
	const untaxableObj = {
		taxable: false,
		tax_rate: null
	};
	const recordObj = {
		quantity: 0,
		unit: "",
		unit_price: 0,
		amount_exc: 0,
		amount_tax: 0,
		amount_inc: 0,
		category: "",
		record: true,
		taxable: true,
		tax_rate: 0.1
	};
	const unrecordObj = {
		quantity: null,
		unit: null,
		unit_price: null,
		amount_exc: null,
		amount_tax: null,
		amount_inc: null,
		category: "",
		record: false,
		taxable: false,
		tax_rate: null
	};
	const toolbarDisplay = top => {
		const data = obj.options.data[top][objectData];
		obj.toolbar.querySelector('.toolbar-record').textContent = data.record ? "通常行" : "見出し行";
		if(data.record){
			obj.toolbar.querySelector('.toolbar-taxable').style.display = "block";
		}else{
			obj.toolbar.querySelector('.toolbar-taxable').style.display = "none";
		}
		obj.toolbar.querySelector('.toolbar-taxable').value = data.taxable ? "1" : "0";
		if(data.taxable){
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "block";
			obj.toolbar.querySelector('.toolbar-tax-rate input').value = data.tax_rate * 100;
			
		}else{
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "none";
		}
	};
	const toolbar = document.createDocumentFragment();
	toolbar.appendChild(Object.assign(document.createElement("span"), {innerHTML: '見出し行', className: 'toolbar-record'}));
	toolbar.appendChild(Object.assign(document.createElement("select"), {innerHTML: '<option value="1">課税</option><option value="0">非課税</option>', className: 'toolbar-taxable'}));
	toolbar.appendChild(Object.assign(document.createElement("div"), {innerHTML: '税率<input type="number" style="width: 7ex" />％', className: 'toolbar-tax-rate'}));
	
	let tableColumns = [
		{ [refDetail]: "detail",     type: 'text', title: '内容', width: 200 },
		{ [refDetail]: "quantity",   type: 'numeric', title: '数量', width: 60, mask:'#,##.00' },
		{ [refDetail]: "unit",       type: 'text', title: '単位', width: 60 },
		{ [refDetail]: "unit_price", type: 'numeric', title: '単価', width: 80, mask:'#,##.00' },
		{ [refDetail]: "amount_exc", type: 'numeric', title: '税抜金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_tax", type: 'numeric', title: '消費税金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_inc", type: 'numeric', title: '税込金額', width: 100, mask:'#,##' },
		{ [refDetail]: "category",   type: 'dropdown', title: 'カテゴリー', width: 200, source: categories.map(r => r.name) }
	];
	if(salesSlip.invoice_format == "2"){
		tableColumns.push(
			{ [refAttr]: "circulation", type: 'numeric', title: '発行部数', width: 60, mask:'#,##' }
		);
	}else if(salesSlip.invoice_format == "3"){
		tableColumns.push(
			{ [refAttr]: "summary_data1", type: 'text', title: '摘要１', width: 200 },
			{ [refAttr]: "summary_data2", type: 'text', title: '摘要２', width: 200 },
			{ [refAttr]: "summary_data3", type: 'text', title: '摘要３', width: 200 }
		);
	}
	const obj = jspreadsheet(jse, {
		minDimensions: [1, 1],
		columns: tableColumns,
		toolbar: toolbar,
		dataProxy(){
			return new Proxy(
				Object.assign({detail: "", attributes: {}}, unrecordObj), {
				get(target, prop, receiver){
					if(prop == "length"){
						return tableColumns.length;
					}
					if(prop == objectData){
						return target;
					}
					if((refDetail in tableColumns[prop]) && (tableColumns[prop][refDetail] == "category")){
						let found = null;
						const search = target.category;
						for(let category of categories){
							if(search == category.code){
								found = category.name;
							}
						}
						return found;
					}
					if(refAttr in tableColumns[prop]){
						return target.attributes[tableColumns[prop][refAttr]];
					}
					return target[tableColumns[prop][refDetail]];
				},
				set(obj, prop, value){
					if(refAttr in tableColumns[prop]){
						if(tableColumns[prop][refAttr] == "circulation"){
							if(value == ""){
								value = 0;
							}else if(typeof value != "number"){
								value = Number(value.replace(/,/g, ""));
							}
						}
						obj.attributes[tableColumns[prop][refAttr]] = value;
					}else if(refDetail in tableColumns[prop]){
						//if((tableColumns[prop][refDetail] != "detail") && (value != "") && (!obj.record)){
						//	Object.assign(obj, recordObj);
						//}
						if(tableColumns[prop][refDetail] == "detail"){
							obj[tableColumns[prop][refDetail]] = value;
						}else if(obj.record){
							if((tableColumns[prop][refDetail] == "quantity") || (tableColumns[prop][refDetail] == "unit_price")){
								if(value == ""){
									value = 0;
								}else if(typeof value != "number"){
									value = Number(value.replace(/,/g, ""));
								}
							}else if(tableColumns[prop][refDetail] == "category"){
								let found = null;
								for(let category of categories){
									if(value == category.name){
										found = category.code;
									}
								}
								value = found;
							}
							obj[tableColumns[prop][refDetail]] = value;
							obj.amount_exc = Math.floor(obj.quantity * obj.unit_price);
							obj.amount_tax = Math.floor((obj.taxable) ? obj.amount_exc * obj.tax_rate : 0);
							obj.amount_inc = obj.amount_exc + obj.amount_tax;
						}
					}
					return true;
				}
			});
		},
		text: { rowNumber: "項番" },
		onselection: (el, borderLeft, borderTop, borderRight, borderBottom, origin) => {
			toolbarDisplay(borderTop);
		},
		onchange: (el, cell, x, y, value, oldValue) => {
			const total = obj.options.data.reduce((a, rowProxy) => {
				const row = rowProxy[objectData];
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
		}
	});
	//obj.toolbar.querySelector('.toolbar-record').addEventListener("change", e => {
	//	const selected = obj.selectedCell.map(Number);
	//	const top = Math.min(selected[1], selected[3]);
	//	const bottom = Math.max(selected[1], selected[3]);
	//	for(let i = top; i <= bottom; i++){
	//		Object.assign(obj.options.data[i][objectData], e.currentTarget.value == "0" ? unrecordObj : recordObj);
	//		obj.updateRow(null, i, null, null);
	//	}
	//	toolbarDisplay(top);
	//});
	obj.toolbar.querySelector('.toolbar-taxable').addEventListener("change", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			const data = obj.options.data[i][objectData];
			//if((e.currentTarget.value == "1") && (!data.record)){
			//	Object.assign(data, recordObj);
			//	obj.updateRow(null, i, null, null);
			//}
			if(data.record){
				Object.assign(data, e.currentTarget.value == "0" ? untaxableObj : taxableObj);
			}
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-tax-rate input').addEventListener("input", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			const data = obj.options.data[i][objectData];
			const rate = Number(e.currentTarget.value / 100);
			//if(!data.record){
			//	Object.assign(data, recordObj, {taxable: true});
			//	obj.updateRow(null, i, null, null);
			//}
			if(data.record){
				if(!data.taxable){
					Object.assign(data, {taxable: true});
				}
				data.tax_rate = rate;
			}
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-tax-rate input').addEventListener("keydown", e => {
		e.stopPropagation();
	});
	obj.setData(transaction.select("All")
		.setTable("sales_details")
		.addField("sales_details.*")
		.leftJoin("sales_detail_attributes using(sd)")
		.addField("sales_detail_attributes.data AS attributes")
		.apply()
		.map(row => {
			const insert = obj.options.dataProxy();
			row.record = (row.record == 1);
			row.taxable = (row.taxable == 1);
			Object.assign(insert[objectData], row);
			return insert;
		}),
		true
	);
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
				<div id="detail"></div>
				<div class="invalid"></div>
			</form>
			<span slot="tools" class="btn btn-primary my-2" data-trigger="submit">登録</span>
		</template>
	</div>
	
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<datalist id="specification"></datalist>
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