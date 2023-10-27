{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jsuites.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jspreadsheet.css" />
<style type="text/css">
[data-grid]{
	--border-width: 1px;
	--border-color: #dedede;
	--grid-padding: 0.25rem;
	display: grid;
	position: relative;
	white-space: pre;
	gap: var(--border-width);
	>*{
		--background-color: white;
		display: grid;
		grid-template-columns: subgrid;
		grid-column: 1 / -1;
		>*:first-child{
			display: grid;
			grid-template-columns: subgrid;
			grid-column: 1 / span var(--freeze, 0);
			position: sticky;
			left: var(--border-width);
			&:empty{
				display: none;
			}
		}
		>*:first-child>*,>*:nth-child(n + 2){
			outline: var(--border-width) solid var(--border-color);
			overflow: hidden;
			text-overflow: ellipsis;
	    	background: var(--background-color);
			padding: var(--grid-padding);
			display: block;
			&.gcell{
				display: flex;
				justify-content: center;
				align-items: center;
			}
			&.gcell-auto{
				overflow: visible;
			}
		}
		[data-grid-width]{
			display: flex;
			background: none;
			padding: 0;
			overflow: visible;
			position: relative;
			>*:first-child{
				flex-grow: 1;
				flex-shrink: 1;
				overflow: hidden;
				text-overflow: ellipsis;
				background: var(--background-color);
				padding: var(--grid-padding);
				text-align: inherit;
			}
			>*:last-child{
				position: absolute;
				right: calc(-3px - var(--border-width));
				top: 0;
				width: calc(6px + var(--border-width));
				height: 100%;
				cursor: col-resize;
			}
		}
		&:nth-child(n + 2):hover{
			--background-color: yellow;
		}
	}
	>*:first-child{
		position: sticky;
		top: var(--border-width);
		--background-color: #009EA7;
		color: white;
		text-align: center;
		z-index: 1;
		>*:first-child{
			z-index: 1;
		}
	}
	
	.table-secondary{
		--background-color: #e2e3e5;
	}
	.table-danger{
		--background-color: #f8d7da;
	}
}
.jcalendar-header .jcalendar-year::after{
	content: "年";
}
</style>
{/literal}{/block}
{block name="scripts"}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/common/GridGenerator.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
<script type="text/javascript">{literal}
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
{/literal}</script>
{jsiife id=$id}{literal}
new VirtualPage("/edit", class{
	constructor(vp){
		formTableInit(document.getElementById("sales_slip"), formTableQuery("#sales_slip").apply()).then(form => {
			const res = transaction.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = form.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
		});
		formTableInit(document.getElementById("sales_detail"), formTableQuery("/Purchase#edit").apply()).then(form => {
			const res = transaction.select("ROW")
				.setTable("sales_details")
				.andWhere("sd=?", Number(id))
				.apply();
			const formControls = form.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
		});
		vp.addEventListener("modal-close", e => {
			if(e.dialog == "supplier"){
				if(e.trigger == "list"){
					const obj = document.getElementById("detail").jspreadsheet;
					const insert = obj.options.dataProxy();
					insert[objectData].supplier = e.result;
					if(obj.options.data.length == 0){
						obj.setData([insert]);
					}else{
						pasteEvent = true;
						obj.insertRow(insert);
						pasteEvent = false;
					}
				}
			}
		});
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
			const formData = new FormData();
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
			formData.append("sd",id);
			formData.append("detail", JSON.stringify(details));
			fetch(`/Purchase/regist`, {
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
					const messages = document.createDocumentFragment();
					for(let meaasge of result.messages.filter(m => (m[1] == 2))){
						let token = meaasge[2].split("/");
						if(token.length == 3){
							messages.appendChild(Object.assign(document.createElement("div"), {textContent: `${Number(token[1]) + 1}行目：${meaasge[0]}`}));
						}
					}
					
					const range = document.createRange();
					const tableInvalid = document.querySelector('#detail~.invalid');
					range.selectNodeContents(tableInvalid);
					range.deleteContents();
					tableInvalid.appendChild(messages);
				}
			});
		});
	}
});

let master = new SQLite();
let transaction = new SQLite();
const objectData = Symbol("objectData");
const searchQuery = new FormData();
searchQuery.append("sd", id);
let pasteEvent = false;
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
	master.create_function("has", {
		length: 2,
		apply(thisObj, args){
			const [array, search] = args;
			if(search == ""){
				return 1;
			}
			return array.indexOf(JSON.stringify(search).replace(/^"|"$/g, "")) > 0 ? 1 : 0;
		}
	});
	const callbackList = {};
	master.updateSet("grid_columns", {},{
		label: "IFNULL(label, '')",
		width: "IFNULL(width, 'auto')",
		slot: "IFNULL(slot, '')",
		cell: "(cell='YES')",
		tag_name: "IFNULL(tag_name, 'span')",
		class_list: "IFNULL(class_list, '')",
		text: "IFNULL(text, '')",
		attributes: "IFNULL(attributes, '')"
	}).apply();
	//master.delete("grid_columns").andWhere("filter=?");
	master.select("ALL").setTable("grid_infos").apply().forEach(info => {
		const columns = master.select("ALL").setTable("grid_columns").andWhere("location=?", info.location).apply();
		GridGenerator.define(info.location, info, columns, (info.location in callbackList) ? callbackList[info.location] : null);
	});
	Array.from(document.querySelectorAll('[data-grid]')).forEach(grid => {
		GridGenerator.init(grid);
	});
	
	transaction.import(response[1], "transaction");
	transaction.attach(master, "master");
	
	SinglePage.modal.supplier.setQuery(v => master.select("ONE").setTable("suppliers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		GridGenerator.createTable(
			SinglePage.modal.supplier.querySelector('[data-grid]'),
			master.select("ALL")
				.setTable("suppliers")
				.apply()
		);
	});
	SinglePage.modal.supplier.querySelector('[data-search="search-btn"]').addEventListener("click", e => {
		const keyword = SinglePage.modal.supplier.querySelector('[data-search="keyword"]').value;
		GridGenerator.createTable(
			SinglePage.modal.supplier.querySelector('[data-grid]'),
			master.select("ALL")
				.setTable("suppliers")
				.andWhere("has(json_array(code,name,kana),?)", keyword)
				.apply()
		);
	});
	
	const suppliers = master.select("ALL")
		.setTable("suppliers")
		.apply();
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
	SinglePage.modal.leader.setQuery(v => master.select("ONE").setTable("leaders").setField("name").andWhere("code=?", v).apply());
	SinglePage.modal.manager.setQuery(v => master.select("ONE").setTable("managers").setField("name").andWhere("code=?", v).apply());
	SinglePage.modal.apply_client.setQuery(v => master.select("ONE").setTable("system_apply_clients").setField("unique_name").andWhere("code=?", v).apply());
	SinglePage.modal.number_format.setQuery(v => new Intl.NumberFormat().format(v));
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 2}).format(v));
	
	SinglePage.location = "/edit";
	
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
		{ [refDetail]: "payment_date", type: 'calendar', title: '支払日', width: 100, options: {
			format: 'YYYY-MM-DD',
			months: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
			monthsFull: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
			weekdays: [ '日曜日','月曜日','火曜日','水曜日','木曜日','金曜日','土曜日' ],
			textDone: '完了',
			textReset: '取消',
			textUpdate: '更新'
		} }
	];
	
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
		onbeforedeleterow: (el, rowNumber, numOfRows) => {
			const obj = el.jspreadsheet;
			const n = rowNumber + numOfRows;
			for(let i = rowNumber; i < n; i++){
				if(obj.options.data[i][objectData].pu != null){
					return false;
				}
			}
		},
		allowDeletingAllRows: true,
		columns: tableColumns,
		toolbar: toolbar,
		dataProxy(){
			return new Proxy(
				Object.assign({
					pu: null,
					supplier: null,
					detail: "",
					quantity: 0,
					unit: "",
					unit_price: 0,
					amount_exc: 0,
					amount_tax: 0,
					amount_inc: 0,
					note: "",
					payment_date: "",
					[objectData]: {}
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
						}else if(tableColumns[prop][refDetail] == "payment_date"){
							if(value != ""){
								value = value.replace(/\s[0-9:]+$/, "");
							}
						}else if(tableColumns[prop][refDetail] == "supplier"){
							if((obj.supplier == null) || (obj.pu == null)){
								let found = obj.supplier;
								for(let supplier of suppliers){
									if(value == supplier.name){
										found = supplier.code;
									}
								}
								value = found;
							}else{
								value = obj.supplier;
							}
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
		SinglePage.modal.supplier.show({detail: null});
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
		<template data-page="/edit">
			<div slot="main" id="sales_slip" class="d-grid flex-row" style="column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;"></div>
			<div slot="main" id="sales_detail" class="d-grid flex-row" style="column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;"></div>
			<div slot="main" class="flex-grow-1">
				<div id="detail"></div>
				<div class="invalid"></div>
			</div>
		</template>
		<template data-page-share="">
			<span slot="tools"" class="btn btn-primary my-2" data-trigger="submit">仕入登録</span>
		</template>
	</div>
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<modal-dialog name="number_format"></modal-dialog>
	<modal-dialog name="number_format2"></modal-dialog>
	<modal-dialog name="leader" label="部門長選択"></modal-dialog>
	<modal-dialog name="manager" label="当社担当者選択"></modal-dialog>
	<modal-dialog name="apply_client" label="請求先選択"></modal-dialog>
	<modal-dialog name="supplier" label="仕入先選択">
		<div slot="body" class="col-6"><div class="input-group"><input class="form-control" type="text" data-search="keyword" /><button type="button" class="btn btn-success" data-search="search-btn">検索</button></div></div>
		<div slot="body" class="overflow-auto" style="height: calc(100vh - 20rem);"><div data-grid="/Modal/Supplier#list"></div></div>
	</modal-dialog>
{/block}