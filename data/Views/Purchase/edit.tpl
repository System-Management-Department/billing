{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jsuites.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jspreadsheet.css" />
{/literal}{/block}
{block name="scripts"}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
{jsiife id=$id}{literal}
new VirtualPage("/", class{
	constructor(vp){
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => { close(); });
	}
});

let master = new SQLite();
let transaction = new SQLite();
const objectData = Symbol("objectData");
const searchQuery = new FormData();
searchQuery.append("sd", id);
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	fetch("/Purchase/search", {method: "POST", body: searchQuery}).then(res => res.arrayBuffer()),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	transaction.import(response[1], "transaction");
	transaction.attach(master, "master");
	
	SinglePage.modal.supplier.querySelector('table-sticky').columns = dataTableQuery("/Modal/Supplier#list").setField("label,width,slot,part").apply();
	SinglePage.modal.supplier.setQuery(v => master.select("ONE").setTable("suppliers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.supplier.querySelector('table-sticky'),
			dataTableQuery("/Modal/Supplier#list").apply(),
			master.select("ALL")
				.setTable("suppliers")
				.apply(),
			row => {}
		);
	});
		
	const suppliers = master.select("ALL")
		.setTable("suppliers")
		.apply();
	
	SinglePage.location = "/";
	
	const refDetail = Symbol("refDetail");
	const taxableObj = {
		taxable: true,
		tax_rate: 0.1
	};
	const untaxableObj = {
		taxable: false,
		tax_rate: null
	};
	const toolbarDisplay = top => {
		const data = obj.options.data[top][objectData];
		obj.toolbar.querySelector('.toolbar-taxable').value = data.taxable ? "1" : "0";
		if(data.taxable){
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "block";
			obj.toolbar.querySelector('.toolbar-tax-rate input').value = data.tax_rate * 100;
		}else{
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "none";
		}
	};
	const toolbar = document.createDocumentFragment();
	toolbar.appendChild(Object.assign(document.createElement("div"), {innerHTML: '仕入先追加', className: 'btn btn-success toolbar-supplier'}));
	toolbar.appendChild(Object.assign(document.createElement("select"), {innerHTML: '<option value="1">課税</option><option value="0">非課税</option>', className: 'toolbar-taxable'}));
	toolbar.appendChild(Object.assign(document.createElement("div"), {innerHTML: '税率<input type="number" style="width: 7ex" />％', className: 'toolbar-tax-rate'}));
	
	let tableColumns = [
		{ [refDetail]: "supplier",     type: 'text', title: '仕入先', width: 200 },
		{ [refDetail]: "detail",       type: 'text', title: '内容', width: 200 },
		{ [refDetail]: "quantity",     type: 'numeric', title: '数量', width: 60, mask:'#,##.00' },
		{ [refDetail]: "unit",         type: 'text', title: '単位', width: 60 },
		{ [refDetail]: "unit_price",   type: 'numeric', title: '単価', width: 80, mask:'#,##.00' },
		{ [refDetail]: "amount_exc",   type: 'numeric', title: '税抜金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_tax",   type: 'numeric', title: '消費税金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_inc",   type: 'numeric', title: '税込金額', width: 100, mask:'#,##' },
		{ [refDetail]: "note",         type: 'text', title: '備考', width: 200 },
		{ [refDetail]: "payment_date", type: 'calendar', title: '支払日', width: 100 }
	];
	
	let pasteEvent = false;
	const obj = jspreadsheet(document.getElementById("detail"), {
		onbeforepaste: (el, data, x, y) => {
			if(x != 0){
				return data;
			}
			pasteEvent = true;
			return obj.parseCSV(data, "\t").filter(row => {
				// 仕入先チェック　無効な仕入先を除外
				let found = null;
				for(let supplier of suppliers){
					if(row[0] == supplier.name){
						found = supplier.code;
					}
				}
				return(found != null);
			}).map(row => row.map(val => `"${val.split("\"").join("\"\"")}"`).join("\t")).join("\r\n") + "\r\n";
		},
		onpaste: (el, data) => {
			pasteEvent = false;
		},
		onbeforeinsertrow: (el, rowNumber, numOfRows, insertBefore) => {
			return pasteEvent;
		},
		columns: tableColumns,
		toolbar: toolbar,
		dataProxy(){
			return new Proxy(
				Object.assign({
					supplier: null,
					detail: "",
					quantity: 0,
					unit: "",
					unit_price: 0,
					amount_exc: 0,
					amount_tax: 0,
					amount_inc: 0,
					note: "",
					payment_date: ""
				}, taxableObj), {
				get(target, prop, receiver){
					if(prop == "length"){
						return tableColumns.length;
					}
					if(prop == objectData){
						return target;
					}
					if(prop == Symbol.toPrimitive){
						return () => 0;
					}
					if((refDetail in tableColumns[prop]) && (tableColumns[prop][refDetail] == "supplier")){
						let found = null;
						const search = target.supplier;
						for(let supplier of suppliers){
							if(search == supplier.code){
								found = supplier.name;
							}
						}
						return found;
					}
					return target[tableColumns[prop][refDetail]];
				},
				set(obj, prop, value){
					if(refDetail in tableColumns[prop]){
						if((tableColumns[prop][refDetail] == "quantity") || (tableColumns[prop][refDetail] == "unit_price")){
							if(value == ""){
								value = 0;
							}else if(typeof value != "number"){
								value = Number(value.replace(/,/g, ""));
							}
						}else if(tableColumns[prop][refDetail] == "supplier"){
							let found = obj.supplier;
							for(let supplier of suppliers){
								if(value == supplier.name){
									found = supplier.code;
								}
							}
							value = found;
						}
						obj[tableColumns[prop][refDetail]] = value;
						obj.amount_exc = Math.floor(obj.quantity * obj.unit_price);
						obj.amount_tax = Math.floor((obj.taxable) ? obj.amount_exc * obj.tax_rate : 0);
						obj.amount_inc = obj.amount_exc + obj.amount_tax;
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
				a.amount_exc += row.amount_exc;
				a.amount_tax += row.amount_tax;
				a.amount_inc += row.amount_inc;
				return a; 
			}, {amount_exc: 0, amount_inc: 0, amount_tax: 0});
			//document.querySelector('form-control[name="amount_exc"]').value = total.amount_exc;
			//document.querySelector('form-control[name="amount_tax"]').value = total.amount_tax;
			//document.querySelector('form-control[name="amount_inc"]').value = total.amount_inc;
		}
	});
	obj.setData(transaction.select("ALL")
		.setTable("purchases")
		.apply()
		.map(row => {
			const insert = obj.options.dataProxy();
			Object.assign(insert[objectData], row);
			return insert;
		})
	);
	obj.toolbar.querySelector('.toolbar-supplier').addEventListener("click", e => {
		SinglePage.modal.supplier.show();
	});
	obj.toolbar.querySelector('.toolbar-taxable').addEventListener("change", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			const data = obj.options.data[i][objectData];
			Object.assign(data, e.currentTarget.value == "0" ? untaxableObj : taxableObj);
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
			data.tax_rate = rate;
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-tax-rate input').addEventListener("keydown", e => {
		e.stopPropagation();
	});
	
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
{/literal}{/jsiife}{/block}
{block name="body"}
	<div id="spmain">
		<template shadowroot="closed">
			<div part="body">
				<header part="header">
					<nav part="nav1">
						<div part="container">
							<div part="title">仕入登録</div>
						</div>
					</nav>
					<nav part="nav2">
						<div part="tools"><slot name="tools"></slot></div>
					</nav>
				</header>
				<slot name="main"></slot>
			</div>
		</template>
		<template data-page="/">
			<div slot="main" class="flex-grow-1">
				<div id="detail"></div>
				<div class="invalid"></div>
			</div>
		</template>
		<template data-page-share="">
			<span slot="tools"" class="btn btn-primary my-2" data-trigger="submit">仕入登録</span>
		</template>
	</div>
	<modal-dialog name="supplier" label="仕入先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
{/block}