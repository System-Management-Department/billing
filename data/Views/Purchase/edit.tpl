{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jsuites.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jspreadsheet.css" />
<style type="text/css">
[data-grid]{
	--theme-color: #009EA7;
	--border-width: 1px;
	--border-color: #dedede;
	--grid-padding: 0.25rem;
	counter-reset: grid-row-counter;
	display: grid;
	position: relative;
	white-space: pre;
	gap: var(--border-width);
	>*{
		--background-base-color: white;
		--background-color: var(--background-base-color);
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
			&:focus-within{
				box-shadow: inset 0 0 5px 2px #86b7fe;
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
			--background-color: color-mix(in lab, var(--theme-color) 20%, var(--background-base-color));
		}
	}
	>*:first-child{
		position: sticky;
		top: var(--border-width);
		--background-base-color: var(--theme-color);
		color: white;
		text-align: center;
		z-index: 1;
		>*:first-child{
			z-index: 1;
		}
	}
	
	.table-secondary{
		--background-base-color: #e2e3e5;
	}
	.table-danger{
		--background-base-color: #f8d7da;
	}
	.grid-row-counter::before{
		counter-increment: grid-row-counter;
		content: counter(grid-row-counter);
	}
}
.overflow-auto [data-grid]{
	padding-right: 100vw;
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
<script type="text/javascript" src="/assets/cleave/cleave.min.js"></script>
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

class ShowDialogElement extends HTMLElement{
	constructor(){
		super();
		this.addEventListener("click", e => {
			const target = this.getAttribute("target");
			const detail = this.getAttribute("detail");
			SinglePage.modal[target].show({detail: null});
		});
	}
	connectedCallback(){}
	disconnectedCallback(){}
	attributeChangedCallback(name, oldValue, newValue){}
	static get observedAttributes(){ return []; }
}
customElements.define("show-dialog", ShowDialogElement);
{/literal}</script>
{jsiife id=$id}{literal}
var editPage = new VirtualPage("/edit", class{
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
					this.addSupplier(e.result);
				}
			}
		});
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
			const formData = new FormData();
			const grid = document.querySelector('[slot="main"] [data-grid]');
			const details = Array.from(grid.querySelectorAll(':scope>*')).filter(row => this.gridRowMap.has(row)).map(tempRow => {
				const row = this.gridRowMap.get(tempRow).data
				let res = {};
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
					
					const range = document.createRange();
					const tableInvalid = document.getElementById("detail_invalid");
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
{/literal}{if $smarty.session["User.role"] eq "entry"}{literal}
	master.delete("grid_columns").andWhere("((filter='d-admin'))").apply();
{/literal}{elseif $smarty.session["User.role"] eq "leader"}{literal}
	master.delete("grid_columns").andWhere("((filter='d-admin') OR (filter='d-entry'))").apply();
{/literal}{elseif $smarty.session["User.role"] eq "manager"}{literal}
	master.delete("grid_columns").andWhere("((filter='d-admin') OR (filter='d-entry') OR (filter='d-leader'))").apply();
{/literal}{/if}{literal}
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
	const recordObj = {
		pu: null,
		supplier: null,
		payment_date: "",
		detail: "",
		quantity: 0,
		unit: "",
		unit_price: 0,
		amount_exc: 0,
		amount_tax: 0,
		amount_inc: 0,
		note: "",
		taxable: true,
		tax_rate: 0.1
	};
	console.log(transaction.tables.purchases);
	const grid = document.querySelector('[slot="main"] [data-grid]');
	const gridLocation = grid.getAttribute("data-grid");
	const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
	const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
	const gridRowMap = new Map();
	const gridChangeEvent = e => {
		const gridInfo = GridGenerator.getInfo(e.target);
		const gridRows = Array.from(gridInfo.grid.querySelectorAll(':scope>*'));
		const {data, items, cleave} = gridRowMap.get(gridInfo.row);
		
		if(gridInfo.slot == "dtype"){
			const dt = e.target.value;
			if(dt == "1"){
				Object.assign(data, {}, taxableObj);
			}else if(dt == "2"){
				Object.assign(data, {}, untaxableObj);
			}
		}else if((gridInfo.slot == "quantity") || (gridInfo.slot == "unit_price")){
			data[gridInfo.slot] = Number(e.target.value.replace(/,/g, ""));
		}else if(gridInfo.slot == "tax_rate"){
			if(!data.taxable){
				Object.assign(data, taxableObj);
				if("dtype" in items){
					items.dtype.value = "1";
				}
			}
			data[gridInfo.slot] = Number(e.target.value.replace(/,/g, "")) / 100;
		}else{
			data[gridInfo.slot] = e.target.value;
		}
		if("quantity" in items){
			items.quantity.value = SinglePage.modal.number_format2.query(data.quantity).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(2).substring(1));
			data.quantity = Number(items.quantity.value.replace(/,/g, ""));
		}
		if("unit_price" in items){
			items.unit_price.value = SinglePage.modal.number_format2.query(data.unit_price).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(2).substring(1));
			data.unit_price = Number(items.unit_price.value.replace(/,/g, ""));
		}
		data.amount_exc = Math.floor(data.quantity * data.unit_price + 0.000000001);
		data.amount_tax = Math.floor((data.taxable) ? data.amount_exc * data.tax_rate + 0.000000001 : 0);
		data.amount_inc = data.amount_exc + data.amount_tax;
		if("unit" in items){
			items.unit.value = data.unit;
		}
		if("tax_rate" in items){
			items.tax_rate.value = data.taxable ? data.tax_rate * 100 : "";
		}
		if("amount_exc" in items){
			items.amount_exc.textContent = SinglePage.modal.number_format.query(data.amount_exc);
		}
		if("amount_tax" in items){
			items.amount_tax.textContent = SinglePage.modal.number_format.query(data.amount_tax);
		}
		if("amount_inc" in items){
			items.amount_inc.textContent = SinglePage.modal.number_format.query(data.amount_inc);
		}
	};
	const gridKeydownEvent = e => {
		if(e.keyCode == 13){
			const info = GridGenerator.getInfo(e.target);
			e.preventDefault();
			if(e.shiftKey){
				if(info.prevRow != null){
					info.prevRow.focus();
				}
			}else{
				if(info.nextRow != null){
					info.nextRow.focus();
				}
			}
		}
	};
	const gridCallback = (row, data, items) => {
		const cleave = {};
		gridRowMap.set(row, {data, items, cleave});
		row.addEventListener("change", gridChangeEvent);
		row.addEventListener("keydown", gridKeydownEvent);
		if("dtype" in items){
			items.dtype.innerHTML = `<option value="1">課税</option><option value="2">非課税</option>`;
			if(data.taxable){
				items.dtype.value = "1";
			}else{
				items.dtype.value = "2";
			}
		}
		if(data.taxable && ("tax_rate" in items)){
			items.tax_rate.value = data.tax_rate * 100;
		}
		if("quantity" in items){
			cleave.quantity = new Cleave(items.quantity, {
				numeral: true,
				numeralDecimalMark: '.',
				delimiter: ',',
				numeralDecimalScale: 2,
				numeralThousandsGroupStyle: 'thousand'
			});
			items.quantity.value = SinglePage.modal.number_format2.query(data.quantity).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(2).substring(1));
		}
		if("unit_price" in items){
			cleave.unit_price = new Cleave(items.unit_price, {
				numeral: true,
				numeralDecimalMark: '.',
				delimiter: ',',
				numeralDecimalScale: 2,
				numeralThousandsGroupStyle: 'thousand'
			});
			items.unit_price.value = SinglePage.modal.number_format2.query(data.unit_price).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(2).substring(1));
		}
		if("supplier" in items){
			items.supplier.textContent = SinglePage.modal.supplier.query(data.supplier);
		}
		if("amount_exc" in items){
			items.amount_exc.textContent = SinglePage.modal.number_format.query(data.amount_exc);
		}
		if("amount_tax" in items){
			items.amount_tax.textContent = SinglePage.modal.number_format.query(data.amount_tax);
		}
		if("amount_inc" in items){
			items.amount_inc.textContent = SinglePage.modal.number_format.query(data.amount_inc);
		}
	};
	GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
	GridGenerator.init(grid);
	GridGenerator.createTable(
		grid,
		transaction.select("All")
			.setTable("purchases")
			.apply()
			.map(row => {
				row.taxable = (row.taxable == 1);
				return row;
			})
	);
	editPage.instance.gridRowMap = gridRowMap;
	editPage.instance.addSupplier = supplier => {
		grid.appendChild(GridGenerator.createRows(grid, [Object.assign({}, recordObj, {supplier: supplier})]));
	};
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
				<div id="tools" class="navbar mx-1 px-2 mb-1 py-1">
					<show-dialog target="supplier" class="btn btn-success">仕入先追加</show-dialog>
				</div>
				<div class="overflow-auto" style="height: 50vh;"><div id="detail" data-grid="/Edit/Purchase"></div></div>
				<div class="invalid" id="detail_invalid"></div>
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