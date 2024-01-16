{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
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
#tools{
	background: color-mix(in lab, var(--bs-success) 20%, white);
}
#spmain::part(nav2){
	justify-content: space-between;
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
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/common/GridGenerator.js"></script>
<script type="text/javascript" src="/assets/common/PrintPage.js"></script>
<script type="text/javascript" src="/assets/common/SJISEncoder.js"></script>
<script type="text/javascript" src="/assets/cleave/cleave.min.js"></script>
<script type="text/javascript" src="/assets/jspdf/jspdf.umd.min.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
<script type="text/javascript">
class EstimatePage{
	constructor(vp){
	}
}
new VirtualPage("/1", EstimatePage);
new VirtualPage("/2", EstimatePage);
new VirtualPage("/3", EstimatePage);
new VirtualPage("/4", EstimatePage);
new VirtualPage("/5", EstimatePage);

const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
	const found = t.match(/^(.*?)=(.*)$/);
	if(found){
		a[found[1]] = decodeURIComponent(found[2]);
	}
	return a;
},{});
let master = new SQLite();
let cache = new SQLite();
let transaction = new SQLite();
const objectData = Symbol("objectData");
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	cache.use("cache"),
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
	
	SinglePage.modal.leader.setQuery(v => master.select("ONE").setTable("leaders").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		GridGenerator.createTable(
			SinglePage.modal.leader.querySelector('[data-grid]'),
			master.select("ALL")
				.setTable("leaders")
				.andWhere("has(json_array(code,name),?)", keyword)
				.apply()
		);
	});
	SinglePage.modal.manager.setQuery(v => master.select("ONE").setTable("managers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		GridGenerator.createTable(
			SinglePage.modal.manager.querySelector('[data-grid]'),
			master.select("ALL")
				.setTable("managers")
				.andWhere("has(json_array(code,name),?)", keyword)
				.apply()
		);
	});
	SinglePage.modal.apply_client.setQuery(v => master.select("ONE").setTable("system_apply_clients").setField("unique_name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		GridGenerator.createTable(
			SinglePage.modal.apply_client.querySelector('[data-grid]'),
			master.select("ALL")
				.setTable("system_apply_clients")
				.setField("system_apply_clients.code,system_apply_clients.unique_name as name,system_apply_clients.kana,system_apply_clients.payment_cycle,system_apply_clients.payment_date")
				.leftJoin("clients on system_apply_clients.client=clients.code")
				.addField("clients.name as client")
				.andWhere("has(json_array(system_apply_clients.code,system_apply_clients.unique_name,system_apply_clients.name),?)", keyword)
				.apply()
		);
	});
	SinglePage.modal.insert_row.addEventListener("modal-open", e => {
		SinglePage.modal.insert_row.querySelector('[data-no]').textContent = e.detail;
	});
	SinglePage.modal.insert_row.querySelector('[data-proxy]').addEventListener("click", e => {
		const result = {
			position: SinglePage.modal.insert_row.querySelector('[name="position"]').value,
			rows: SinglePage.modal.insert_row.querySelector('[name="rows"]').value
		};
		SinglePage.modal.insert_row.hide("submit", result);
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
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 3}).format(v));
	
	const parser = new DOMParser();
	const xmlDoc = parser.parseFromString(cache.select("ONE").setTable("estimate").setField("xml").andWhere("dt=?", Number(search.key)).apply(), "application/xml");
	const root = xmlDoc.documentElement;
	const id = xmlDoc.querySelector('info').getAttribute("type");
	SinglePage.location = `/${id}`;
	const inputElements = document.querySelectorAll('form-control[name],input[name="tax_rate"]');
	const inputMap = {};
	const appendAttributes = {
		recording_date: ""
	};
	for(let key in appendAttributes){
		if(!root.hasAttribute(key)){
			root.setAttribute(key, appendAttributes[key]);
		}
	}
	for(let i = inputElements.length - 1; i >= 0; i--){
		const name = inputElements[i].getAttribute("name");
		inputMap[name] = inputElements[i];
		if(root.hasAttribute(name)){
			inputElements[i].value = (inputElements[i].getAttribute("type") == "month") ? root.getAttribute(name).replace(/-[0-9]+$/, "") : root.getAttribute(name);
			inputElements[i].addEventListener("change", e => {
				const target = e.currentTarget;
				const value = ((target.getAttribute("type") == "date") || (target.getAttribute("type") == "month")) ? target.querySelector('input[name]')?.value : target.value;
				root.setAttribute(name, (value == null) ? "" : value);
				cache.updateSet("estimate", {xml: root.outerHTML}, {}).andWhere("dt=?", Number(search.key)).apply();
				cache.commit();
			});
		}
	}
	if(("apply_client" in inputMap) && ("recording_date" in inputMap) && ("payment_date" in inputMap)){
		const datalistElement = document.getElementById("payment_date");
		const setDatalist = e => {
			const data = master.select("ROW").setTable("system_apply_clients").setField("IFNULL(payment_cycle, '') AS payment_cycle,IFNULL(payment_date, '') AS payment_date").andWhere("code=?", inputMap.apply_client.value).apply();
			datalistElement.innerHTML = "";
			if((data != null) && (inputMap.recording_date.value != null)){
				const currentDate = new Date(inputMap.recording_date.value);
				const matchNextCount = data.payment_cycle.match(/[0-9]+/)?.map(Number)?.at(0) || data.payment_cycle.match(/翌[翌々]*/)?.at(0).length || 0;
				currentDate.setMonth(currentDate.getMonth() + matchNextCount);
				const month = currentDate.getMonth();
				const calendar = {};
				const prefix = `${currentDate.getFullYear()}-` + `0${currentDate.getMonth() + 1}`.slice(-2) + "-";
				for(currentDate.setDate(1); currentDate.getMonth() == month; currentDate.setDate(currentDate.getDate() + 1)){
					const date = currentDate.getDate();
					calendar[date] = calendar["末"] = prefix + `0${date}`.slice(-2);
				}
				const options = data.payment_date.match(/[12][0-9]|3[01]|[1-9]|末/g)?.map(i => (i in calendar) ? calendar[i] : null).filter(v => v != null) || [];
				for(let value of options){
					const option = document.createElement("option");
					option.setAttribute("value", value);
					datalistElement.appendChild(option);
				}
			}
			inputMap.payment_date.setAttribute("list", "payment_date");
		};
		setDatalist({});
		inputMap.apply_client.addEventListener("change", setDatalist);
		inputMap.recording_date.addEventListener("change", setDatalist);
	}
	
	const refDetail = Symbol("refDetail");
	const refAttr = Symbol("refAttr");
	const taxableObj = {
		taxable: true,
		tax_rate: 0.1
	};
	const untaxableObj = {
		taxable: false,
		tax_rate: null
	};
	const recordObj = {
		quantity_place: 0,
		quantity: 0,
		unit: "",
		price_place: 0,
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
		quantity_place: 0,
		quantity: null,
		unit: null,
		price_place: 0,
		unit_price: null,
		amount_exc: null,
		amount_tax: null,
		amount_inc: null,
		category: "",
		record: false,
		taxable: false,
		tax_rate: null
	};
	
	if(id == "2"){
		master.delete("grid_columns").andWhere("filter=?", "d-summary-data").apply();
	}else if(id == "3"){
		master.delete("grid_columns").andWhere("filter=?", "d-circulation").apply();
	}else{
		master.delete("grid_columns").andWhere("filter=?", "d-summary-data").apply();
		master.delete("grid_columns").andWhere("filter=?", "d-circulation").apply();
	}
	
	const grid = document.querySelector('[slot="main"] [data-grid]');
	const gridLocation = grid.getAttribute("data-grid");
	const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
	const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
	const gridRowMap = new Map();
	const gridChangeEvent = e => {
		const gridInfo = GridGenerator.getInfo(e.target);
		const gridRows = Array.from(gridInfo.grid.querySelectorAll(':scope>*'));
		const {data, items, cleave} = gridRowMap.get(gridInfo.row);
		const fragment = xmlDoc.createDocumentFragment();
		const info = xmlDoc.querySelector('info');
		const taxRate = {};
		const total = {amount_exc: 0, amount_inc: 0, amount_tax: 0};
		
		if(gridInfo.slot == "dtype"){
			const dt = e.target.value;
			if(dt == "0"){
				Object.assign(data, unrecordObj);
			}else if(dt == "1"){
				Object.assign(data, data.record ? {} : recordObj, taxableObj);
			}else if(dt == "2"){
				Object.assign(data, data.record ? {} : recordObj, untaxableObj);
			}else{
				gridRowMap.delete(gridInfo.row);
				gridInfo.grid.removeChild(gridInfo.row);
			}
		}else if((gridInfo.slot == "summary_data1") || (gridInfo.slot == "summary_data2") || (gridInfo.slot == "summary_data3")){
			data.attributes[gridInfo.slot] = e.target.value;
		}else if(gridInfo.slot == "circulation"){
			if(e.target.value == ""){
				data.attributes[gridInfo.slot] = "";
			}else{
				data.attributes[gridInfo.slot] = Number(e.target.value.replace(/,/g, ""));
			}
		}else if((gridInfo.slot == "quantity") || (gridInfo.slot == "unit_price")){
			if(!data.record){
				Object.assign(data, data.record ? {} : recordObj);
				if("dtype" in items){
					items.dtype.value = "1";
				}
			}
			data[gridInfo.slot] = Number(e.target.value.replace(/,/g, ""));
		}else if(gridInfo.slot == "tax_rate"){
			if(!data.record){
				Object.assign(data, recordObj);
				if("dtype" in items){
					items.dtype.value = "1";
				}
			}else if(!data.taxable){
				Object.assign(data, taxableObj);
				if("dtype" in items){
					items.dtype.value = "1";
				}
			}
			data[gridInfo.slot] = Number(e.target.value.replace(/,/g, "")) / 100;
		}else if((gridInfo.slot == "quantity_place") || (gridInfo.slot == "price_place")){
			data[gridInfo.slot] = Number(e.target.value);
		}else{
			data[gridInfo.slot] = e.target.value;
		}
		if("quantity_place" in items){
			items.quantity_place.value = data.record ? data.quantity_place : "";
		}
		if("quantity" in items){
			if(data.record){
				items.quantity.value = SinglePage.modal.number_format2.query(data.quantity).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.quantity_place).substring(1));
				data.quantity = Number(items.quantity.value.replace(/,/g, ""));
			}else{
				items.quantity.value = "";
			}
		}
		if("price_place" in items){
			items.price_place.value = data.record ? data.price_place : "";
		}
		if("unit_price" in items){
			if(data.record){
				items.unit_price.value = SinglePage.modal.number_format2.query(data.unit_price).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.price_place).substring(1));
				data.unit_price = Number(items.unit_price.value.replace(/,/g, ""));
			}else{
				items.unit_price.value = "";
			}
		}
		if(data.record){
			data.amount_exc = Math.floor(data.quantity * data.unit_price + 0.000000001);
			data.amount_tax = Math.floor((data.taxable) ? data.amount_exc * data.tax_rate + 0.000000001 : 0);
			data.amount_inc = data.amount_exc + data.amount_tax;
		}
		if("unit" in items){
			items.unit.value = data.record ? data.unit : "";
		}
		if("tax_rate" in items){
			items.tax_rate.value = data.taxable ? data.tax_rate * 100 : "";
		}
		if("amount_exc" in items){
			items.amount_exc.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_exc) : "";
		}
		if("amount_tax" in items){
			items.amount_tax.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_tax) : "";
		}
		if("amount_inc" in items){
			items.amount_inc.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_inc) : "";
		}
		if("category" in items){
			items.category.value = data.category;
		}
		
		fragment.appendChild(info);
		for(let rowElement of gridRows){
			if(!gridRowMap.has(rowElement)){
				continue;
			}
			const {data: row} = gridRowMap.get(rowElement);
			const detail = xmlDoc.createElement("detail");
			const attributes = ("attributes" in row) ? xmlDoc.createElement("attributes") : null;
			if(attributes != null){
				detail.appendChild(attributes);
			}
			for(let key in row){
				if(key == "attributes"){
					for(let key2 in row.attributes){
						attributes.setAttribute(key2, `${row.attributes[key2]}`);
					}
				}else if(row[key] != null){
					detail.setAttribute(key, `${row[key]}`);
				}
			}
			fragment.appendChild(detail);
			if(row.record){
				total.amount_exc += Number(row.amount_exc);
				if(row.taxable){
					if(!(row.tax_rate in taxRate)){
						taxRate[row.tax_rate] = {amount_exc: 0, amount_inc: 0, amount_tax: 0};
					}
					taxRate[row.tax_rate].amount_exc += Number(row.amount_exc);
				}else{
					total.amount_inc += Number(row.amount_exc);
				}
			}
		}
		for(let tax_rate in taxRate){
			taxRate[tax_rate].amount_tax = Math.floor(taxRate[tax_rate].amount_exc * Number(tax_rate) + 0.000000001);
			taxRate[tax_rate].amount_inc = taxRate[tax_rate].amount_exc + taxRate[tax_rate].amount_tax;
			total.amount_tax += taxRate[tax_rate].amount_tax;
			total.amount_inc += taxRate[tax_rate].amount_inc;
		}
		
		document.querySelector('form-control[name="amount_exc"]').value = total.amount_exc;
		document.querySelector('form-control[name="amount_tax"]').value = total.amount_tax;
		document.querySelector('form-control[name="amount_inc"]').value = total.amount_inc;
		const taxRateInput = document.querySelector('input[name="tax_rate"]')
		if(taxRateInput != null){
			taxRateInput.value = JSON.stringify(taxRate);
			root.setAttribute("tax_rate", taxRateInput.value);
		}
		root.setAttribute("amount_exc", total.amount_exc);
		root.setAttribute("amount_tax", total.amount_tax);
		root.setAttribute("amount_inc", total.amount_inc);
		info.setAttribute("update", Date.now());
		root.innerHTML = "";
		root.appendChild(fragment);
		cache.updateSet("estimate", {xml: root.outerHTML}, {}).andWhere("dt=?", Number(search.key)).apply();
		cache.commit();
	};
	const gridPasteeEvent = e => {
		const paste = e.clipboardData.getData("text").split(/\r\n|[\r\n]/g).map(row => row.split("\t"));
		if((paste.length == 1) && (paste[0].length == 1)){
			return;
		}
		e.preventDefault();
		let gridInfo = GridGenerator.getInfo(e.target);
		let currentRow = gridInfo.cell;
		for(let rowData of paste){
			let currentCell = currentRow;
			for(let cellData of rowData){
				if(currentCell.tagName == "INPUT"){
					currentCell.value = cellData;
					gridChangeEvent({target: currentCell});
				}else if(currentCell.tagName == "SELECT"){
					const found = Array.from(currentCell.querySelectorAll('option[value]')).find(option => option.textContent == cellData);
					if(found != null){
						currentCell.value = found.getAttribute("value");
						gridChangeEvent({target: currentCell});
					}
				}
				gridInfo = GridGenerator.getInfo(currentCell);
				currentCell = gridInfo.next;
				if(currentCell == null){
					break;
				}
			}
			gridInfo = GridGenerator.getInfo(currentRow);
			if(gridInfo.nextRow == null){
				gridInfo.grid.appendChild(GridGenerator.createRows(gridInfo.grid, [Object.assign({}, unrecordObj)]));
				gridInfo = GridGenerator.getInfo(currentRow);
			}
			currentRow = gridInfo.nextRow;
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
				}else{
					info.grid.appendChild(GridGenerator.createRows(info.grid, [Object.assign({}, unrecordObj)]));
					GridGenerator.getInfo(e.target).nextRow.focus();
				}
			}
		}
	};
	const gridDblclickEvent = e => {
		if(e.button == 0){
			const info = GridGenerator.getInfo(e.target);
			if(info.slot == "no"){
				const no = Array.from(info.grid.children).indexOf(info.row);
				if(no > 0){
					const callback = (trigger, result) => {
						if(trigger == "submit"){
							for(let rows = Math.min(Number(result.rows), 10); rows > 0; rows--){
								info.row.insertAdjacentElement(result.position, GridGenerator.createRows(grid, [Object.assign({detail: ""}, unrecordObj)]).firstElementChild);
							}
						}
					};
					SinglePage.modal.insert_row.show({detail: no, callback: callback});
				}
			}
		}
	};
	const gridCallback = (row, data, items) => {
		const cleave = {};
		if(id == 2){
			if(!("attributes" in data) || (data.attributes == null)){
				data.attributes = {};
			}
			if(!("circulation" in data.attributes)){
				data.attributes.circulation = "";
			}
		}
		if(id == 3){
			if(!("attributes" in data) || (data.attributes == null)){
				data.attributes = {};
			}
			if(!("summary_data1" in data.attributes)){
				data.attributes.summary_data1 = "";
			}
			if(!("summary_data2" in data.attributes)){
				data.attributes.summary_data2 = "";
			}
			if(!("summary_data3" in data.attributes)){
				data.attributes.summary_data3 = "";
			}
		}
		gridRowMap.set(row, {data, items, cleave});
		row.addEventListener("change", gridChangeEvent);
		row.addEventListener("keydown", gridKeydownEvent);
		row.addEventListener("paste", gridPasteeEvent);
		row.addEventListener("dblclick", gridDblclickEvent);
		if("dtype" in items){
			items.dtype.innerHTML = `<option value="0">見出し行</option><option value="1">通常行（課税）</option><option value="2">通常行（非課税）</option><option value="-1">削除</option>`;
			if(data.taxable){
				items.dtype.value = "1";
			}else if(data.record){
				items.dtype.value = "2";
			}else{
				items.dtype.value = "0";
			}
		}
		if("category" in items){
			items.category.innerHTML = '<option value=""></option>' + document.getElementById("category").innerHTML;
			items.category.value = data.category;
		}
		if(data.taxable && ("tax_rate" in items)){
			items.tax_rate.value = data.tax_rate * 100;
		}
		if("quantity_place" in items){
			items.quantity_place.innerHTML = '<option value="0">整数</option><option value="1">小数点以下1桁</option><option value="2">小数点以下2桁</option>';
			items.quantity_place.value = data.record ? data.quantity_place : "";
		}
		if("quantity" in items){
			cleave.quantity = new Cleave(items.quantity, {
				numeral: true,
				numeralDecimalMark: '.',
				delimiter: ',',
				numeralDecimalScale: 2,
				numeralThousandsGroupStyle: 'thousand'
			});
			items.quantity.value = data.record ? SinglePage.modal.number_format2.query(data.quantity).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.quantity_place).substring(1)) : "";
		}
		if("price_place" in items){
			items.price_place.innerHTML = '<option value="0">整数</option><option value="1">小数点以下1桁</option><option value="2">小数点以下2桁</option><option value="3">小数点以下3桁</option>';
			items.price_place.value = data.record ? data.price_place : "";
		}
		if("unit_price" in items){
			cleave.unit_price = new Cleave(items.unit_price, {
				numeral: true,
				numeralDecimalMark: '.',
				delimiter: ',',
				numeralDecimalScale: 3,
				numeralThousandsGroupStyle: 'thousand'
			});
			items.unit_price.value = data.record ? SinglePage.modal.number_format2.query(data.unit_price).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.price_place).substring(1)) : "";
		}
		if("circulation" in items){
			cleave.circulation = new Cleave(items.circulation, {
				numeral: true,
				numeralDecimalMark: '.',
				delimiter: ',',
				numeralDecimalScale: 2,
				numeralThousandsGroupStyle: 'thousand'
			});
		}
		if("amount_exc" in items){
			items.amount_exc.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_exc) : "";
		}
		if("amount_tax" in items){
			items.amount_tax.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_tax) : "";
		}
		if("amount_inc" in items){
			items.amount_inc.textContent = data.record ? SinglePage.modal.number_format.query(data.amount_inc) : "";
		}
		if("attributes" in data){
			if("summary_data1" in items){
				items.summary_data1.value = data.attributes.summary_data1;
			}
			if("summary_data2" in items){
				items.summary_data2.value = data.attributes.summary_data2;
			}
			if("summary_data3" in items){
				items.summary_data3.value = data.attributes.summary_data3;
			}
			if("circulation" in items){
				if((typeof data.attributes.circulation == "string") && (data.attributes.circulation != "")){
					data.attributes.circulation = Number(data.attributes.circulation.replace(/,/g, ""));
				}
				if(data.attributes.circulation != ""){
					items.circulation.value = SinglePage.modal.number_format.query(data.attributes.circulation);
				}
			}
		}
	};
	GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
	GridGenerator.init(grid);
	GridGenerator.createTable(grid, Array.from({
		[Symbol.iterator]: function*(){
			const n = this.details.length;
			for(let i = 0; i < n; i++){
				const row = Array.from(this.details[i].attributes).reduce((a, attr) => {
					if((attr.name == "record") || (attr.name == "taxable")){
						a[attr.name] = (attr.value == "true");
					}else{
						a[attr.name] = attr.value;
					}
					return a;
				}, {});
				const attrElement = this.details[i].querySelector('attributes');
				if(attrElement == null){
					row.attributes = null;
				}else{
					row.attributes = Array.from(attrElement.attributes).reduce((a, attr) => {
						a[attr.name] = attr.value;
						return a;
					}, {});
				}
				for(let key in unrecordObj){
					if(!(key in row)){
						row[key] = unrecordObj[key];
					}
				}
				if(!("detail" in row)){
					row.detail = "";
				}
				yield row;
			}
		},
		details: xmlDoc.querySelectorAll('detail')
	}));
	document.getElementById("addrow").addEventListener("click", e => {
		grid.appendChild(GridGenerator.createRows(grid, [Object.assign({detail: ""}, unrecordObj)]));
	});
	for(let i = inputElements.length - 1; i >= 0; i--){
		const name = inputElements[i].getAttribute("name");
		if(root.hasAttribute(name)){
			if((name == "summary_header1") || (name == "summary_header2") || (name == "summary_header3")){
				inputElements[i].addEventListener("change", e => {
					const slotInfo = GridGenerator.getSlot(grid, name.replace("header", "data"));
					if(slotInfo != null){
						slotInfo.head.textContent = e.target.value;
					}
				});
				const slotInfo = GridGenerator.getSlot(grid, name.replace("header", "data"));
				if(slotInfo != null){
					slotInfo.head.textContent = root.getAttribute(name);
				}
			}
		}
	}
	
	const template = document.querySelector('#spmain [slot="print"] print-page');
	const getPdfDoc = () => {
		const slotObj = {
			today: new Intl.DateTimeFormat("ja-JP").format(new Date(document.querySelector('form-control[name="estimate_date"]').value)),
			subject: document.querySelector('form-control[name="subject"]').value,
			leader: document.querySelector('form-control[name="leader"]').text,
			manager: document.querySelector('form-control[name="manager"]').text,
			client_name: document.querySelector('form-control[name="client_name"]').value,
			amount_exc: "\\" + document.querySelector('form-control[name="amount_exc"]').text,
			amount_tax: "\\" + document.querySelector('form-control[name="amount_tax"]').text,
			amount_inc: "\\" + document.querySelector('form-control[name="amount_inc"]').text,
			specification: document.querySelector('form-control[name="specification"]').text,
			note: document.querySelector('form-control[name="note"]').value,
			summary_header1: (e => (e == null) ? void(0) : e.value)(document.querySelector('form-control[name="summary_header1"]')),
			summary_header2: (e => (e == null) ? void(0) : e.value)(document.querySelector('form-control[name="summary_header2"]')),
			summary_header3: (e => (e == null) ? void(0) : e.value)(document.querySelector('form-control[name="summary_header3"]')),
			amount_tax_8: (e => {
				if((e == null) || (e.value == "")){
					return "\\" + 0;
				}
				const taxRate = JSON.parse(e.value);
				if("0.08" in taxRate){
					return "\\" + SinglePage.modal.number_format.query(taxRate["0.08"].amount_tax);
				}
				return "\\" + 0;
			})(document.querySelector('input[name="tax_rate"]')),
			amount_tax_10: (e => {
				if((e == null) || (e.value == "")){
					return "\\" + 0;
				}
				const taxRate = JSON.parse(e.value);
				if("0.1" in taxRate){
					return "\\" + SinglePage.modal.number_format.query(taxRate["0.1"].amount_tax);
				}
				return "\\" + 0;
			})(document.querySelector('input[name="tax_rate"]'))
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
		const details = Array.from(grid.querySelectorAll(':scope>*')).filter(row => gridRowMap.has(row)).map(row => gridRowMap.get(row).data);
		const proc = {
			detail(data, value){
				if(value == ""){
					return "\u200B";
				}
				return value;
			},
			quantity(data, value){
				if(value == null){
					return "";
				}
				return SinglePage.modal.number_format2.query(value).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.quantity_place).substring(1));
			},
			unit_price(data, value){
				if(value == null){
					return "";
				}
				return "\\" + SinglePage.modal.number_format2.query(value).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.price_place).substring(1));
			},
			amount_exc(data, value){
				if(value == null){
					return "";
				}
				return "\\" + SinglePage.modal.number_format.query(value);
			},
			circulation(data, value){
				if((value == null) || (value == "")){
					return "";
				}
				return SinglePage.modal.number_format.query(value);
			}
		};
		for(let row of details){
			const insertRow = tr.cloneNode(true);
			const slotElements2 = insertRow.querySelectorAll('[data-table-slot]');
			const slotElements3 = insertRow.querySelectorAll('[data-table-slot-attribute]');
			for(let i = slotElements2.length - 1; i >= 0; i--){
				const attr = slotElements2[i].getAttribute("data-table-slot");
				if(attr in row){
					slotElements2[i].textContent = (attr in proc) ? proc[attr](row, row[attr]) : row[attr];
				}
			}
			for(let i = slotElements3.length - 1; i >= 0; i--){
				const attr = slotElements3[i].getAttribute("data-table-slot-attribute");
				if(attr in row.attributes){
					slotElements3[i].textContent = (attr in proc) ? proc[attr](row, row.attributes[attr]) : row.attributes[attr];
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
			for(let fill of printData.fill){
				const colorParts = fill.color.match(/\d+/g);
				doc.setFillColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
				doc.rect(fill.x1 * pxPt, fill.y1 * pxPt, (fill.x2 - fill.x1) * pxPt, (fill.y2 - fill.y1) * pxPt, "F");
			}
			for(let line of printData.line){
				const colorParts = line.color.match(/\d+/g);
				doc.setDrawColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
				doc.setLineWidth(line.width * pxPt);
				console.log(line);
				if(line.style == "solid"){
					doc.setLineDashPattern([], 0);
				}else if(line.style == "dashed"){
					doc.setLineDashPattern([2, 1], 0);
				}else if(line.style == "dotted"){
					doc.setLineDashPattern([1, 1], 0);
				}
				doc.line(line.x1 * pxPt, line.y1 * pxPt, line.x2 * pxPt, line.y2 * pxPt);
			}
			for(let img of printData.img){
				doc.addImage(img.src, "PNG", img.x1 * pxPt, img.y1 * pxPt, (img.x2 - img.x1) * pxPt, (img.y2 - img.y1) * pxPt);
			}
			doc.setLineDashPattern([], 0);
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
		return doc;
	};
	document.querySelector('[data-trigger="preview"]').addEventListener("click", e => {
		const doc = getPdfDoc();
		open(doc.output("bloburi"), "_blank", "left=0,top=0,width=1200,height=600");
	});
	document.querySelector('[data-trigger="print"]').addEventListener("click", e => {
		const doc = getPdfDoc();
		const formData = new FormData();
		const w = open("about:blank", "_blank", "left=0,top=0,width=1200,height=600");
		formData.append("pdf", doc.output("blob"), "print.pdf");
		fetch("/Upload/estimate", {
			method: "POST",
			body: formData
		}).then(res => res.json()).then(result => {
			if(result.success){
				let path = "about:blank";
				for(let meaasge of result.messages){
					if(meaasge[2] == "path"){
						path = meaasge[0];
						break;
					}
				}
				w.location = path;
			}else{
				alert(result.messages[0][0]);
			}
		});
	});
	
	document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
		const info = xmlDoc.querySelector('info');
		const form = document.querySelector('form');
		const formData = new FormData(form);
		const fev = [];
		const details = Array.from(grid.querySelectorAll(':scope>*')).filter(row => gridRowMap.has(row)).map((tempRow, i) => {
			const row = gridRowMap.get(tempRow).data
			const sjisError = SJISEncoder.validate(row.detail).map(msg => msg.replace(/^[0-9]+行/, "内容"));
			let res = {};
			if(sjisError.length > 0){
				fev.push([sjisError.join(" "), 2, `detail/${i}/detail`]);
			}
			for(let key in row){
				if(typeof row[key] == "boolean"){
					res[key] = row[key] ? 1 : 0;
				}else{
					res[key] = row[key];
				}
			}
			return res;
		});
		formData.append("invoice_format",id);
		formData.append("detail", JSON.stringify(details));
		if(fev.length > 0){
			formData.append("#error", "");
		}
		if(info.hasAttribute("ss")){
			formData.append("hide", `[${info.getAttribute("ss")}]`);
		}
		fetch(`/Estimate/regist`, {
			method: "POST",
			body: formData
		}).then(res => res.json()).then(result => {
			if(result.success){
				new BroadcastChannel(search.channel).postMessage(JSON.stringify(result));
				close();
			}else{
				const messages = {};
				const messages2 = document.createDocumentFragment();
				const alertMessages = [];
				for(let meaasge of result.messages.concat(fev).filter(m => (m[1] == 2))){
					let token = meaasge[2].split("/");
					if(token.length == 1){
						messages[meaasge[2]] = meaasge[0];
						alertMessages.push(meaasge[0]);
					}else if(token.length == 3){
						messages2.appendChild(Object.assign(document.createElement("div"), {textContent: `${Number(token[1]) + 1}行目：${meaasge[0]}`}));
						alertMessages.push(`明細${Number(token[1]) + 1}行目：${meaasge[0]}`);
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
				const tableInvalid = document.getElementById("detail_invalid");
				range.selectNodeContents(tableInvalid);
				range.deleteContents();
				tableInvalid.appendChild(messages2);
				alert(alertMessages.join("\n"));
			}
		});
	});
});

{/literal}</script>
{/block}
{block name="body"}
	<form>
		<input type="hidden" name="sequence" value="{$sequence}" />
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
							<div part="tools"><slot name="tools2"></slot></div>
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
			<template data-page="/1">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab" style="position: relative;">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
											<img src="/assets/common/image/inkan_kaku.png" style="position: absolute; top: 15px; right: 15px;width: 90px;" />
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1" style="font-size: 1.5rem; align-items: center;">
										<div>合計金額</div>
										<div class="price"><span data-slot="amount_inc">0,000,000</span>-</div>
										<div style="font-size: 1rem;">（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" style="width: 80px;" />
										<col class="tw3" style="width: 55px;" />
										<col class="tw4" style="width: 80px;" />
										<col class="tw5" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">
										<tr class="text-center">
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td class="text-center" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/2">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab" style="position: relative;">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
											<img src="/assets/common/image/inkan_kaku.png" style="position: absolute; top: 15px; right: 15px;width: 90px;" />
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1" style="font-size: 1.5rem; align-items: center;">
										<div>合計金額</div>
										<div class="price"><span data-slot="amount_inc">0,000,000</span>-</div>
										<div style="font-size: 1rem;">（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" />
										<col class="tw3" style="width: 80px;" />
										<col class="tw4" style="width: 55px;" />
										<col class="tw5" style="width: 80px;" />
										<col class="tw6" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">
										<tr class="text-center">
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">発行部数</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="circulation">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td class="text-center" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="5">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="5">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="5">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/3">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab" style="position: relative;">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
											<img src="/assets/common/image/inkan_kaku.png" style="position: absolute; top: 15px; right: 15px;width: 90px;" />
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1" style="font-size: 1.5rem; align-items: center;">
										<div>合計金額</div>
										<div class="price"><span data-slot="amount_inc">0,000,000</span>-</div>
										<div style="font-size: 1rem;">（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" />
										<col class="tw3" />
										<col class="tw4" />
										<col class="tw5" style="width: 80px;" />
										<col class="tw6" style="width: 55px;" />
										<col class="tw7" style="width: 80px;" />
										<col class="tw8" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">
										<tr class="text-center">
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot="summary_header1"></span></th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot="summary_header2"></span></th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot="summary_header3"></span></th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data1"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data2"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data3"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td class="text-center" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="7">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="7">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="7">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/4">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab" style="position: relative;">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
											<img src="/assets/common/image/inkan_kaku.png" style="position: absolute; top: 15px; right: 15px;width: 90px;" />
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1" style="font-size: 1.5rem; align-items: center;">
										<div>合計金額</div>
										<div class="price"><span data-slot="amount_inc">0,000,000</span>-</div>
										<div style="font-size: 1rem;">（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" style="width: 80px;" />
										<col class="tw3" style="width: 55px;" />
										<col class="tw4" style="width: 80px;" />
										<col class="tw5" style="width: 130px;" />
										<col class="tw6" style="width: 130px;" />
										<col class="tw7" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">
										<tr class="text-center">
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額（税抜）</th>
											<th style="border-left: solid black calc(1rem / 12);">消費税（10％）</th>
											<th style="border-left: solid black calc(1rem / 12);">金額（税込）</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td class="text-center" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_tax">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/5">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab" style="position: relative;">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
											<img src="/assets/common/image/inkan_kaku.png" style="position: absolute; top: 15px; right: 15px;width: 90px;" />
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1" style="font-size: 1.5rem; align-items: center;">
										<div>合計金額</div>
										<div class="price"><span data-slot="amount_inc">0,000,000</span>-</div>
										<div style="font-size: 1rem;">（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" style="width: 80px;" />
										<col class="tw3" style="width: 55px;" />
										<col class="tw4" style="width: 80px;" />
										<col class="tw5" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);background: #CCCCCC;">
										<tr class="text-center">
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td class="text-center" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">消費税（8％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax_8">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax_10">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">消費税</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page-share="">
				<div slot="table1" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">見積日付</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="estimate_date" type="date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">案件番号</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="project" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">件名</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="subject" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="division" type="select" list="division"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門長</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="leader" type="keyword" list="leader" placeholder="部門長名・部門長CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">営業担当者</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="manager" type="keyword" list="manager" placeholder="担当者名・担当者CDで検索"></form-control><div class="invalid"></div></div>
					</div>
				</div></div>
				<div slot="main">
					<div id="tools" class="navbar mx-1 px-2 mb-1 py-1"><button type="button" class="btn btn-success" id="addrow">行追加</button></div>
					<div class="overflow-auto" style="height: 50vh;"><div id="detail" data-grid="/Edit/Estimate"></div></div>
					<div class="invalid" id="detail_invalid"></div>
				</div>
			</template>
			<template data-page-share="/3|/5">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">得意先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">計上月</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="recording_date" type="month"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">支払期日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date" list="payment_date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">仕様</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="specification" type="select" list="specification"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
				</div></div>
			</template>
			<template data-page="/3">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">得意先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">計上月</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="recording_date" type="month"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">支払期日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date" list="payment_date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">仕様</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="specification" type="select" list="specification"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">摘要ヘッダ</div>
						<div class="d-table-cell">
							<div class="d-flex col-10 gap-3">
								<form-control name="summary_header1" type="text"></form-control>
								<form-control name="summary_header2" type="text"></form-control>
								<form-control name="summary_header3" type="text"></form-control>
							</div>
							<div class="invalid"></div>
						</div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
				</div></div>
			</template>
			<template data-page="/5">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">得意先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">計上月</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="recording_date" type="month"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">支払期日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date" list="payment_date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">仕様</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="specification" type="select" list="specification"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control><div class="invalid"></div></div>
					</div>
					<input name="tax_rate" type="hidden" />
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
				</div></div>
			</template>
			<template data-page-share="">
				<span slot="tools" class="btn btn-primary my-2" data-trigger="print">見積書生成</span>
				<span slot="tools"" class="btn btn-primary my-2" data-trigger="submit">確定登録</span>
				<span slot="tools2" class="btn btn-primary my-2" data-trigger="preview">プレビュー</span>
			</template>
		</div>
	</form>
	
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option><option value="5">インボイス対応（軽減税率適用）請求書</option></datalist>
	<datalist id="specification"><option value=""></option></datalist>
	<datalist id="payment_date"></datalist>
	<modal-dialog name="leader" label="部門長選択">
		<div slot="body" class="overflow-auto" style="height: calc(100vh - 20rem);"><div data-grid="/Modal/Leader#list"></div></div>
	</modal-dialog>
	<modal-dialog name="manager" label="当社担当者選択">
		<div slot="body" class="overflow-auto" style="height: calc(100vh - 20rem);"><div data-grid="/Modal/Manager#list"></div></div>
	</modal-dialog>
	<modal-dialog name="apply_client" label="請求先選択">
		<div slot="body" class="overflow-auto" style="height: calc(100vh - 20rem);"><div data-grid="/Modal/ApplyClient#list"></div></div>
	</modal-dialog>
	<modal-dialog name="number_format"></modal-dialog>
	<modal-dialog name="number_format2"></modal-dialog>
	<modal-dialog name="insert_row" label="行挿入" class="w-sm">
		<div slot="body" class="p-3">項番<span data-no=""></span>の<select name="position"><option value="beforebegin">前</option><option value="afterend">後</option></select>に<input type="number" name="rows" class="text-end" style="width: 8ex;" min="1" max="10" />行挿入</div>
		<button slot="footer" type="button" data-proxy="insert" class="btn btn-success">挿入</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
{/block}