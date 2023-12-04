{* 順番の並び替えはなし、　計上になっているものは内容、数量、単位、単価のみ書き換え可能。計上でない場合は内容のみ *}
{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
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
<script type="text/javascript" src="/assets/common/GridGenerator.js"></script>
<script type="text/javascript" src="/assets/cleave/cleave.min.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
{/literal}
{jsiife id=$id}{literal}
var editPage = new VirtualPage("/edit", class{
	constructor(vp){
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
			const form = document.querySelector("form");
			const formData = new FormData(form);
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
			const detailAttributes = details.map(row => {
				if(row.attributes == null){
					return null;
				}
				if(("summary_data1" in row.attributes) && ("summary_data2" in row.attributes) && ("summary_data3" in row.attributes)){
					row.attributes.summary_data = [row.attributes.summary_data1, row.attributes.summary_data2, row.attributes.summary_data3];
					delete row.attributes.summary_data1;
					delete row.attributes.summary_data2;
					delete row.attributes.summary_data3;
				}
				return {data: JSON.stringify(row.attributes), sd: row.sd};
			});
			if(this.attributes != null){
				formData.append("attribute", JSON.stringify(this.attributes));
			}
			formData.append("detail", JSON.stringify(details));
			formData.append("detail_attribute", JSON.stringify(detailAttributes));
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
				.setField("system_apply_clients.code,system_apply_clients.unique_name as name,system_apply_clients.kana")
				.leftJoin("clients on system_apply_clients.client=clients.code")
				.addField("clients.name as client")
				.andWhere("has(json_array(system_apply_clients.code,system_apply_clients.unique_name,system_apply_clients.name),?)", keyword)
				.apply()
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
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 3}).format(v));
	
	SinglePage.location = "/edit";
	
	const salesSlip = transaction.select("ROW")
		.setTable("sales_slips")
		.apply();
	const salesSlipAttributes = transaction.select("ROW")
		.setTable("sales_attributes")
		.apply();
	if(salesSlipAttributes != null){
		editPage.instance.attributes = JSON.parse(salesSlipAttributes.data);
		queueMicrotask(() => {
			const grid = document.querySelector('[slot="main"] [data-grid]');
			if("summary_header" in editPage.instance.attributes){
				let slotInfo = GridGenerator.getSlot(grid, "summary_data1");
				if(slotInfo != null){
					slotInfo.head.textContent = editPage.instance.attributes.summary_header[0];
				}
				slotInfo = GridGenerator.getSlot(grid, "summary_data2");
				if(slotInfo != null){
					slotInfo.head.textContent = editPage.instance.attributes.summary_header[1];
				}
				slotInfo = GridGenerator.getSlot(grid, "summary_data3");
				if(slotInfo != null){
					slotInfo.head.textContent = editPage.instance.attributes.summary_header[2];
				}
			}
			
		});
	}
	
	formTableInit(document.querySelector('.sales-form'), formTableQuery("/Sales#edit").apply()).then(form => {
		const inputElements = form.querySelectorAll('form-control[name]');
		const n = inputElements.length;
		const grid = document.querySelector('[slot="main"] [data-grid]');
		for(let i = 0; i < n; i++){
			const name = inputElements[i].getAttribute("name");
			if(name in salesSlip){
				inputElements[i].value = salesSlip[name];
			}
			if((name == "summary_header1") || (name == "summary_header2") || (name == "summary_header3")){
				inputElements[i].addEventListener("change", e => {
					const slotInfo = GridGenerator.getSlot(grid, name.replace("header", "data"));
					if(slotInfo != null){
						slotInfo.head.textContent = e.target.value;
					}
				});
				const slotInfo = GridGenerator.getSlot(grid, name.replace("header", "data"));
				if(slotInfo != null){
					slotInfo.head.textContent = inputElements[i].value;
				}
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
		quantity_place: 2,
		quantity: 0,
		unit: "",
		price_place: 2,
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
		quantity_place: 2,
		quantity: null,
		unit: null,
		price_place: 2,
		unit_price: null,
		amount_exc: null,
		amount_tax: null,
		amount_inc: null,
		category: "",
		record: false,
		taxable: false,
		tax_rate: null
	};
	
	if(salesSlip.invoice_format == "2"){
		master.delete("grid_columns").andWhere("filter=?", "d-summary-data").apply();
	}else if(salesSlip.invoice_format == "3"){
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
		const taxRate = {};
		const total = {amount_exc: 0, amount_inc: 0, amount_tax: 0};
		
		if(gridInfo.slot == "dtype"){
			const dt = e.target.value;
			if(dt == "1"){
				Object.assign(data, data.record ? {} : recordObj, taxableObj);
			}else if(dt == "2"){
				Object.assign(data, data.record ? {} : recordObj, untaxableObj);
			}
		}else if((gridInfo.slot == "summary_data1") || (gridInfo.slot == "summary_data2") || (gridInfo.slot == "summary_data3")){
			data.attributes[gridInfo.slot] = e.target.value;
		}else if(gridInfo.slot == "circulation"){
			data.attributes[gridInfo.slot] = e.target.value;
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
		
		for(let rowElement of gridRows){
			if(!gridRowMap.has(rowElement)){
				continue;
			}
			const {data: row} = gridRowMap.get(rowElement);
			if(row.record){
				total.amount_exc += Number(row.amount_exc);
				if(row.taxable){
					if(!(row.tax_rate in taxRate)){
						taxRate[row.tax_rate] = {amount_exc: 0, amount_inc: 0, amount_tax: 0};
					}
					taxRate[row.tax_rate].amount_exc += Number(row.amount_exc);
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
		if("dtype" in items){
			items.dtype.innerHTML = `<option value="1">通常行（課税）</option><option value="2">通常行（非課税）</option>`;
			if(data.taxable){
				items.dtype.value = "1";
			}else if(data.record){
				items.dtype.value = "2";
			}else{
				const item = document.createElement("div");
				item.textContent = "見出し行";
				item.setAttribute("tabindex", "0");
				items.dtype.parentNode.replaceChild(item, items.dtype);
				items.dtype = item;
			}
		}
		if("category" in items){
			if(data.record){
				items.category.innerHTML = '<option value=""></option>' + document.getElementById("category").innerHTML;
				items.category.value = data.category;
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.category.parentNode.replaceChild(item, items.category);
				items.category = item;
			}
		}
		if(data.taxable && ("tax_rate" in items)){
			if(data.record){
				items.tax_rate.value = data.tax_rate * 100;
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.tax_rate.parentNode.replaceChild(item, items.tax_rate);
				items.tax_rate = item;
			}
		}
		if("quantity_place" in items){
			if(data.record){
				items.quantity_place.innerHTML = '<option value="0">整数</option><option value="1">小数点以下1桁</option><option value="2">小数点以下2桁</option>';
				items.quantity_place.value = data.record ? data.quantity_place : "";
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.quantity_place.parentNode.replaceChild(item, items.quantity_place);
				items.quantity_place = item;
			}
		}
		if("quantity" in items){
			if(data.record){
				cleave.quantity = new Cleave(items.quantity, {
					numeral: true,
					numeralDecimalMark: '.',
					delimiter: ',',
					numeralDecimalScale: 2,
					numeralThousandsGroupStyle: 'thousand'
				});
				items.quantity.value = data.record ? SinglePage.modal.number_format2.query(data.quantity).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.quantity_place).substring(1)) : "";
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.quantity.parentNode.replaceChild(item, items.quantity);
				items.quantity = item;
			}
		}
		if("price_place" in items){
			if(data.record){
				items.price_place.innerHTML = '<option value="0">整数</option><option value="1">小数点以下1桁</option><option value="2">小数点以下2桁</option><option value="3">小数点以下3桁</option>';
				items.price_place.value = data.record ? data.price_place : "";
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.price_place.parentNode.replaceChild(item, items.price_place);
				items.price_place = item;
			}
		}
		if("unit_price" in items){
			if(data.record){
				cleave.unit_price = new Cleave(items.unit_price, {
					numeral: true,
					numeralDecimalMark: '.',
					delimiter: ',',
					numeralDecimalScale: 3,
					numeralThousandsGroupStyle: 'thousand'
				});
				items.unit_price.value = data.record ? SinglePage.modal.number_format2.query(data.unit_price).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(data.price_place).substring(1)) : "";
			}else{
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.unit_price.parentNode.replaceChild(item, items.unit_price);
				items.unit_price = item;
			}
		}
		if(!data.record){
			if("tax_rate" in items){
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.tax_rate.parentNode.replaceChild(item, items.tax_rate);
				items.tax_rate = item;
			}
			if("unit" in items){
				const item = document.createElement("div");
				item.setAttribute("tabindex", "0");
				items.unit.parentNode.replaceChild(item, items.unit);
				items.unit = item;
			}
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
				items.circulation.value = data.attributes.circulation;
			}
		}
	};
	GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
	GridGenerator.init(grid);
	GridGenerator.createTable(
		grid,
		transaction.select("All")
			.setTable("sales_details")
			.addField("sales_details.*")
			.leftJoin("sales_detail_attributes using(sd)")
			.addField("sales_detail_attributes.data AS attributes")
			.apply()
			.map(row => {
				row.record = (row.record == 1);
				row.taxable = (row.taxable == 1);
				row.attributes = JSON.parse(row.attributes);
				for(k in row.attributes){
					if(Array.isArray(row.attributes[k])){
						const n = row.attributes[k].length;
						for(let i = 0; i < n; i++){
							row.attributes[`${k}${i + 1}`] = row.attributes[k][i];
						}
						delete row.attributes[k];
					}
				}
				for(let key in unrecordObj){
					if(!(key in row)){
						row[key] = unrecordObj[key];
					}
				}
				return row;
			})
	);
	editPage.instance.gridRowMap = gridRowMap;
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
				<div id="tools" class="navbar mx-1 px-2 mb-1 py-1"></div>
				<div class="overflow-auto" style="height: 50vh;"><div id="detail" data-grid="/Edit/Committed"></div></div>
				<div class="invalid" id="detail_invalid"></div>
			</form>
			<span slot="tools" class="btn btn-primary my-2" data-trigger="submit">登録</span>
		</template>
	</div>
	
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option><option value="5">インボイス対応（軽減税率適用）請求書</option></datalist>
	<datalist id="specification"></datalist>
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
{/block}