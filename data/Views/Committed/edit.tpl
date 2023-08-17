{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<style type="text/css">
edit-table{
	display: contents;
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
	constructor(arg){
		if(arg == Detail.header){
			this.#values = {
				detail: "内容",
				quantity: "数量",
				unit: "単位",
				unit_price: "単価",
				amount_exc: "税抜金額",
				amount_tax: "消費税金額",
				amount_inc: "税込金額",
				category: "カテゴリー"
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
				attributes: null // {summary_data: ["", "", ""], circulation: null}
			};
		}
	}
	set detail(value){
		this.#values.detail = value;
	}
	get detail(){
		return this.#values.detail;
	}
	set quantity(value){
		this.#values.quantity = Number(value);
		this.#values.record = true;
		this.#values.taxable = true;
		this.#values.tax_rate = 0.1;
		this.#values.amount_exc = this.#values.quantity * this.#values.unit_price;
		this.#values.amount_tax = this.#values.amount_exc * this.#values.tax_rate;
		this.#values.amount_inc = this.#values.amount_exc + this.#values.amount_tax;
	}
	get quantity(){
		return this.#values.quantity;
	}
	set unit(value){
		this.#values.unit = value;
	}
	get unit(){
		return this.#values.unit;
	}
	set unit_price(value){
		this.#values.unit_price = Number(value);
		this.#values.record = true;
		this.#values.taxable = true;
		this.#values.tax_rate = 0.1;
		this.#values.amount_exc = this.#values.quantity * this.#values.unit_price;
		this.#values.amount_tax = this.#values.amount_exc * this.#values.tax_rate;
		this.#values.amount_inc = this.#values.amount_exc + this.#values.amount_tax;
	}
	get unit_price(){
		return this.#values.unit_price;
	}
	get amount_exc(){
		return this.#values.amount_exc;
	}
	get amount_tax(){
		return this.#values.amount_tax;
	}
	get amount_inc(){
		return this.#values.amount_inc;
	}
	set category(value){
		this.#values.category = value;
	}
	get category(){
		return this.#values.category;
	}
	static header = Symbol("header");
}
class EditTableElement extends HTMLElement{
	#root; #hot;
	constructor(){
		super();
		this.#root = null;
		this.#hot = null;
	}
	attributeChangedCallback(name, oldValue, newValue){}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: `<link rel="stylesheet" type="text/css" href="/assets/handsontable/handsontable.full.min.css" />
<style type="text/css">
.container{
	overflow: auto;
	flex-grow: 1;
	background: lightgray;
}
</style>
<div class="container"><div class="table"></div></div>`});
			this.#hot = new Handsontable(this.#root.querySelector('.table'), this.detailOption);
		}
	}
	disconnectedCallback(){
	}
	get detailOption(){
		return {
			fixedRowsTop: 1,
			columns: [
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
							obj.detail = args[1];
						}else{
							return obj.detail;
						}
					},
					type: "text"
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
							obj.quantity = args[1];
						}else{
							return obj.quantity;
						}
					},
					type: "text"
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
							obj.unit = args[1];
						}else{
							return obj.unit;
						}
					},
					type: "text"
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
							obj.unit_price = args[1];
						}else{
							return obj.unit_price;
						}
					},
					type: "text"
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
						}else{
							return obj.amount_exc;
						}
					},
					type: "text",
					"readOnly": true
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
						}else{
							return obj.amount_tax;
						}
					},
					type: "text",
					"readOnly": true
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
						}else{
							return obj.amount_inc;
						}
					},
					type: "text",
					"readOnly": true
				},
				{
					data(...args){
						const obj = args[0];
						if(args.length > 1){
							obj.category = args[1];
						}else{
							return obj.category;
						}
					},
					type: "text"
				}
			],
			stretchH: "all",
			trimWhitespace: false,
			data: [new Detail(Detail.header)],
			dataSchema(){
				return new Detail()
			},
			afterCreateRow(...amount){
			},
			minRows: 20,
			cells(row, cols, prop){
				if(row == 0){
					return {
						renderer: "html",
						readOnly: true
					};
				}
				return {type: "text"};
			},
			autoRowSize: true
		};
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

(function(){
	new VirtualPage("/edit", class{
		constructor(vp){
			document.querySelector('[data-trigger="submit"]').addEventListener("click", e => { close(); });
			formTableInit(document.querySelector('.sales-form'), formTableQuery("/Sales#edit").apply()).then(form => {
			});
		}
	});
	
	let master = new SQLite();
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
			console.log(keyword);
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
			console.log(keyword);
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
			console.log(keyword);
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
})();
</script>
{/literal}{/block}
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
			<div slot="main">
				<div class="sales-form" style="max-height: 50vh; overflow-y: auto; display: grid; column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;"></div>
			</div>
			<edit-table slot="main"></edit-table>
			<div slot="main"><button type="button" class="btn btn-success" data-trigger="submit">登録</button></div>
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
{/block}