{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="assets/common/SinglePage.css" />
<style type="text/css">
table-sticky.h-summary-data::part(d-summary-data),table-sticky.h-summary-data table-row::part(d-summary-data){
	display: none;
}
table-sticky.h-circulation::part(d-circulation),table-sticky.h-circulation table-row::part(d-circulation){
	display: none;
}

</style>
{/literal}{/block}
{block name="scripts" append}{literal}
<script type="text/javascript" src="assets/common/SQLite.js"></script>
<script type="text/javascript" src="assets/common/Toaster.js"></script>
<script type="text/javascript" src="assets/common/SinglePage.js"></script>
<script type="text/javascript">
class ShowDialogElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<span></span>'});
		this.addEventListener("click", e => {
			const target = this.getAttribute("target");
			SinglePage.modal[target].show({detail: this.textContent});
		});
	}
	connectedCallback(){}
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
customElements.define("show-dialog", ShowDialogElement);

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

class CreateWindowElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<slot name="label"><span></span></slot>'});
		this.addEventListener("click", e => {
			let windowFeatures = [];
			if(this.hasAttribute("width")){
				windowFeatures.push(`width=${this.getAttribute("width")}`);
			}
			if(this.hasAttribute("height")){
				windowFeatures.push(`height=${this.getAttribute("height")}`);
			}
			if(this.hasAttribute("left")){
				windowFeatures.push(`left=${this.getAttribute("left")}`);
			}
			if(this.hasAttribute("top")){
				windowFeatures.push(`top=${this.getAttribute("top")}`);
			}
			const href = this.hasAttribute("href") ? this.getAttribute("href") : `${this.getAttribute("base")}${this.textContent}`;
			open(`${href}?channel=${CreateWindowElement.channel}`, "_blank", windowFeatures.join(","));
		});
	}
	connectedCallback(){}
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
	static channel = null;
}
customElements.define("create-window", CreateWindowElement);

Toaster.classTranslate = function(code){
	const classes = ["toast show bg-success", "toast show bg-warning", "toast show bg-danger"];
	return classes[code];
}
CreateWindowElement.channel = "";
new BroadcastChannel(CreateWindowElement.channel).addEventListener("message", e => {
	const message = JSON.parse(e.data);
	Toaster.show(message.messages.map(m => {
		return {
			"class": m[1],
			message: m[0],
			title: message.title
		};
	}));
});

(function(){
	let master = new SQLite();
	let cache = new SQLite();
{/literal}{foreach from=$includeDir item="path"}{if file_exists("`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl")}
{include file="`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl"}
{/if}{/foreach}{literal}
	Promise.all([
		new Promise((resolve, reject) => {
			document.addEventListener("DOMContentLoaded", e => {
				master.use("master").then(master => {
					fetch("/Default/master").then(res => res.arrayBuffer()).then(buffer => {
						master.import(buffer, "master");
						resolve();
					});
				});
			});
		}),
		cache.use("cache").then(db => {
			let update = false;
			if(!("close_data" in db.tables)){
				update = true;
				db.createTable("close_data", ["selected", "dt"], []);
			}
			if(!("sales_data" in db.tables)){
				update = true;
				db.createTable("sales_data", ["selected", "slip_number", "dt"], []);
			}
			if(!("billing_data" in db.tables)){
				update = true;
				db.createTable("billing_data", ["selected", "slip_number", "dt"], []);
			}
			if(update){
				return db.commit();
			}
			return Promise.resolve(null);
		})
	]).then(() => {
		SinglePage.modal.leader      .querySelector('table-sticky').columns = dataTableQuery("/Modal/Leader#list").setField("label,width,slot,part").apply();
		SinglePage.modal.manager     .querySelector('table-sticky').columns = dataTableQuery("/Modal/Manager#list").setField("label,width,slot,part").apply();
		SinglePage.modal.apply_client.querySelector('table-sticky').columns = dataTableQuery("/Modal/ApplyClient#list").setField("label,width,slot,part").apply();
		SinglePage.modal.client      .querySelector('table-sticky').columns = dataTableQuery("/Modal/Client#list").setField("label,width,slot,part").apply();
		SinglePage.modal.supplier    .querySelector('table-sticky').columns = dataTableQuery("/Modal/Supplier#list").setField("label,width,slot,part").apply();
		
		SinglePage.modal.salses_detail   .querySelector('table-sticky').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.purchases_detail.querySelector('table-sticky').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.request         .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.request         .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.withdraw        .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.withdraw        .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.delete_slip     .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.delete_slip     .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.approval        .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.approval        .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.disapproval     .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.disapproval     .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot,part").apply();
		SinglePage.modal.red_slip        .querySelector('table-sticky').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot,part").apply();
		SinglePage.modal.estimate        .querySelector('table-sticky').columns = [
			{label: "フォーマット", width: "10rem", slot: "format", part: null},
			{label: "件名", width: "10rem", slot: "subject", part: null},
			{label: "納品先", width: "10rem", slot: "client", part: null},
			{label: "更新日時", width: "10rem", slot: "datetime", part: null},
			{label: "出力", width: "3rem", slot: "export", part: null},
			{label: "削除", width: "3rem", slot: "delete", part: null}
		];
		formTableInit(SinglePage.modal.salses_detail   .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.purchases_detail.querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.request         .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.withdraw        .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.delete_slip     .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.approval        .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.disapproval     .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.red_slip        .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.payment         .querySelector('div[data-table="1"]'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.payment         .querySelector('div[data-table="2"]'), formTableQuery("#payment").apply());
		
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
		SinglePage.modal.client.setQuery(v => master.select("ONE").setTable("clients").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.client.querySelector('table-sticky'),
				dataTableQuery("/Modal/Client#list").apply(),
				master.select("ALL")
					.setTable("clients")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.supplier.setQuery(v => master.select("ONE").setTable("suppliers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.supplier.querySelector('table-sticky'),
				dataTableQuery("/Modal/Supplier#list").apply(),
				master.select("ALL")
					.setTable("suppliers")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.salses_detail.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.salses_detail.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.salses_detail.querySelector('table-sticky');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
		});
		SinglePage.modal.purchases_detail.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.purchases_detail.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			setDataTable(
				SinglePage.modal.purchases_detail.querySelector('table-sticky'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
		});
		SinglePage.modal.request.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.request.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.request.querySelector('table-sticky[data-table="1"]');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
			setDataTable(
				SinglePage.modal.request.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
			SinglePage.modal.request.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		SinglePage.modal.withdraw.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.withdraw.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.withdraw.querySelector('table-sticky[data-table="1"]');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
			setDataTable(
				SinglePage.modal.withdraw.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
			SinglePage.modal.withdraw.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		SinglePage.modal.delete_slip.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.delete_slip.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.delete_slip.querySelector('table-sticky[data-table="1"]');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
			setDataTable(
				SinglePage.modal.delete_slip.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
			SinglePage.modal.delete_slip.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		SinglePage.modal.approval.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.approval.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.approval.querySelector('table-sticky[data-table="1"]');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
			setDataTable(
				SinglePage.modal.approval.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
			SinglePage.modal.approval.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		SinglePage.modal.disapproval.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.disapproval.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			const stable = SinglePage.modal.disapproval.querySelector('table-sticky[data-table="1"]');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
			setDataTable(
				SinglePage.modal.disapproval.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("purchases.*")
					.andWhere("pu IS NOT NULL")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {
					const supplier = row.querySelector('[slot="supplier"]');
					supplier.textContent = SinglePage.modal.supplier.query(supplier.textContent);
				}
			);
			SinglePage.modal.disapproval.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		SinglePage.modal.red_slip.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW")
				.setTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("ss=?", Number(e.detail))
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			const formControls = SinglePage.modal.red_slip.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			SinglePage.modal.red_slip.querySelector('[slot="footer"] input').value = "";
			
			const stable = SinglePage.modal.red_slip.querySelector('table-sticky');
			const attrs = db.select("ROW").setTable("sales_attributes").andWhere("ss=?", Number(e.detail)).apply();
			const attrData = (attrs == null) ? {} : JSON.parse(attrs.data);
			setDataTable(
				stable,
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.leftJoin("sales_detail_attributes using(sd)")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[0]') AS summary_data1")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[1]') AS summary_data2")
					.addField("json_extract(sales_detail_attributes.data, '$.summary_data[2]') AS summary_data3")
					.addField("json_extract(sales_detail_attributes.data, '$.circulation') AS circulation")
					.apply(),
				(row, data) => {
					const category = row.querySelector('[slot="category"]');
					const categoryOptions = document.querySelectorAll('#category option[value]');
					const categoryCnt = categoryOptions.length;
					let found = false;
					for(let i = 0; i < categoryCnt; i++){
						if(categoryOptions[i].getAttribute("value") == category.textContent){
							category.textContent = categoryOptions[i].textContent;
							found = true;
							break;
						}
					}
					if(!found){
						category.textContent = "";
					}
					if(data.record == 0){
						row.classList.add("table-secondary");
					}
				}
			);
			if("summary_header" in attrData){
				let a = 1;
				for(let header of attrData.summary_header){
					const span = document.createElement("span");
					span.textContent = header;
					span.setAttribute("slot", `summary_data${a}`);
					a++;
					stable.appendChild(span);
				}
				stable.classList.remove("h-summary-data");
			}else{
				stable.classList.add("h-summary-data");
			}
			if(db.select("ONE").setTable("sales_slips").setField("invoice_format").andWhere("ss=?", Number(e.detail)).apply() == 2){
				stable.classList.remove("h-circulation");
			}else{
				stable.classList.add("h-circulation");
			}
		});
		SinglePage.modal.payment.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			let res = db.select("ROW")
				.setTable("purchase_relations")
				.andWhere("purchase_relations.pu=?", Number(e.detail))
				.leftJoin("sales_slips using(ss)")
				.addField("sales_slips.*")
				.leftJoin("sales_workflow using(ss)")
				.addField("sales_workflow.regist_datetime")
				.addField("sales_workflow.approval_datetime")
				.apply();
			let formControls = SinglePage.modal.payment.querySelectorAll('[data-table="1"] form-control[name]');
			let n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			res = db.select("ROW")
				.setTable("purchases")
				.andWhere("pu=?", Number(e.detail))
				.apply();
			formControls = SinglePage.modal.payment.querySelectorAll('[data-table="2"] form-control[name]');
			n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			SinglePage.modal.payment.querySelector('[slot="footer"] input').value = "";
		});
		SinglePage.modal.release.querySelector('[data-proxy]').addEventListener("click", e => {
			const result = SinglePage.modal.release.querySelector('[slot="footer"] input').value;
			if(result == ""){
				alert("コメントを入力してください。");
			}else{
				SinglePage.modal.release.hide("submit", result);
			}
		});
		SinglePage.modal.red_slip.querySelector('[data-proxy]').addEventListener("click", e => {
			const result = SinglePage.modal.red_slip.querySelector('[slot="footer"] input').value;
			if(result == ""){
				alert("コメントを入力してください。");
			}else{
				SinglePage.modal.red_slip.hide("submit", result);
			}
		});
		SinglePage.modal.payment.querySelector('[data-proxy]').addEventListener("click", e => {
			const result = SinglePage.modal.payment.querySelector('[slot="footer"] input').value;
			if(result == ""){
				alert("コメントを入力してください。");
			}else{
				SinglePage.modal.payment.hide("submit", result);
			}
		});
		SinglePage.modal.number_format.setQuery(v => new Intl.NumberFormat().format(v));
		
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
		
		SinglePage.location = "/";
		document.getElementById("reload").addEventListener("click", e => { SinglePage.currentPage.dispatchEvent(new CustomEvent("reload")); });
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
						<div part="title">
							<slot name="title"></slot>
						</div>
						<div part="icon"></div>
						<div>
							<div part="account">
								<div>{$smarty.session["User.department"]}</div>
								<div part="name">{$smarty.session["User.username"]}</div>
							</div>
							<div>{$smarty.session["User.email"]}</div>
						</div>
						<div>
							<a href="/Default/logout" part="logout">ログアウト</a>
						</div>
					</div>
				</nav>
				<nav part="nav2">
					<div part="tools"><slot name="tools"></slot></div>
				</nav>
			</header>
			<slot name="main"></slot>
		</div>
		<div part="toast-grid">
			<div part="toast"><slot name="toast"></slot></div>
		</div>
		<slot name="dialog"></slot>
	</template>
{foreach from=$includeDir item="path"}{if file_exists("`$path``$smarty.const.DIRECTORY_SEPARATOR`template.tpl")}
{include file="`$path``$smarty.const.DIRECTORY_SEPARATOR`template.tpl"}
{/if}{/foreach}
	<template data-page-share="">
		<span slot="tools" href="/" class="btn btn-primary my-2" style="order: 0;" id="reload">更新</span>
	</template>
	<template data-page-share="/">
		<page-link slot="tools" href="/" class="btn btn-success my-2" style="order: 1;">メインメニュー</page-link>
	</template>
		<span slot="title" class="navbar-text text-dark">読込中</span>
		<main slot="main" class="d-contents" data-page="/">
			<div class="card mx-5">
				<div class="card-header">読込中</div>
				<div class="card-body">
					情報を取得しています。<br />読込が完了するまでお待ちください。
				</div>
			</div>
		</main>
	</div>
	
	<datalist id="request"><option value="">すべて</option><option value="1">申請中のもののみ</option></datalist>
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
	<modal-dialog name="client" label="得意先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="supplier" label="仕入先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="salses_detail" label="売上明細">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="purchases_detail" label="仕入明細">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="request" label="申請">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-success" data-result="">申請</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="withdraw" label="申請取下">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-success" data-result="">取下</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="delete_slip" label="案件削除">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-danger" data-result="">削除</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="approval" label="承認">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-success" data-result="">承認</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="disapproval" label="承認解除">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body" class="mt-3">仕入明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-success" data-result="">承認解除</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="release" label="締め解除">
		<div slot="body"></div>
		<label slot="footer" class="d-contents"><span>コメント<span class="text-danger">（必須入力）</span></span><input class="flex-grow-1 w-auto form-control" /></label>
		<button slot="footer" type="button" data-proxy="submit" class="btn btn-success">締め解除</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="red_slip" label="赤伝票登録">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body" class="mt-3">売上明細</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<label slot="footer" class="d-contents"><span>コメント<span class="text-danger">（必須入力）</span></span><input class="flex-grow-1 w-auto form-control" /></label>
		<button slot="footer" type="button" data-proxy="submit" class="btn btn-success">登録</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="payment" label="請求書受領">
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;" data-table="1"></div>
		<div slot="body" class="mt-3">仕入明細</div>
		<div slot="body" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;" data-table="2"></div>
		<label slot="footer" class="d-contents"><span>コメント<span class="text-danger">（必須入力）</span></span><input class="flex-grow-1 w-auto form-control" /></label>
		<button slot="footer" type="button" data-proxy="submit" class="btn btn-success">請求書受領</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="estimate" label="見積選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="number_format"></modal-dialog>
{/block}