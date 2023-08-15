{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="assets/common/SinglePage.css" />
<style type="text/css">
show-dialog{ display: contents; }
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="assets/node_modules/co.min.js"></script>
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
		this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<span></span>'});
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
			open(`${this.getAttribute("base")}${this.textContent}`, "_blank", windowFeatures.join(","));
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
customElements.define("create-window", CreateWindowElement);

(function(){
	let master = new SQLite();
{/literal}{foreach from=$includeDir item="path"}{if file_exists("`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl")}
{include file="`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl"}
{/if}{/foreach}{literal}
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			master.use("master").then(master => {
				master.createTable("form_datas", ["location", "column", "label", "width", "name", "type", "list", "require", "placeholder", "no"], [
					["/Committed#search", "1", "伝票番号",       "10", "slip_number",          "text",      "",               "", "",                         "1"],
					["/Committed#search", "1", "確定日付",       "10", "accounting_date",      "daterange", "",               "", "",                         "2"],
					["/Committed#search", "1", "部門",           "10", "division",             "select",    "division",       "", "",                         "3"],
					["/Committed#search", "2", "当社担当者",     "10", "manager",              "keyword",   "manager",        "", "担当者名・担当者CDで検索", "4"],
					["/Committed#search", "2", "請求先",         "10", "billing_destination",  "keyword",   "apply_client",   "", "請求先名・請求先CDで検索", "5"],
					["/Sales#search",     "1", "伝票番号",       "10", "slip_number",          "text",      "",               "", "",                         "1"],
					["/Sales#search",     "1", "売上日付",       "10", "accounting_date",      "daterange", "",               "", "",                         "2"],
					["/Sales#search",     "1", "部門",           "10", "division",             "select",    "division",       "", "",                         "3"],
					["/Sales#search",     "2", "当社担当者",     "10", "manager",              "keyword",   "manager",        "", "担当者名・担当者CDで検索", "4"],
					["/Sales#search",     "2", "請求先",         "10", "billing_destination",  "keyword",   "apply_client",   "", "請求先名・請求先CDで検索", "5"],
					["/Billing#search",   "1", "伝票番号",       "10", "slip_number",          "text",      "",               "", "",                         "1"],
					["/Billing#search",   "1", "売上日付",       "10", "accounting_date",      "daterange", "",               "", "",                         "2"],
					["/Billing#search",   "1", "部門",           "10", "division",             "select",    "division",       "", "",                         "3"],
					["/Billing#search",   "2", "当社担当者",     "10", "manager",              "keyword",   "manager",        "", "担当者名・担当者CDで検索", "4"],
					["/Billing#search",   "2", "請求先",         "10", "billing_destination",  "keyword",   "apply_client",   "", "請求先名・請求先CDで検索", "5"],
					["/Purchase#search",  "1", "伝票番号",       "10", "slip_number",          "text",      "",               "", "",                         "1"],
					["/Purchase#search",  "1", "確定日付",       "10", "accounting_date",      "daterange", "",               "", "",                         "2"],
					["/Purchase#search",  "1", "クライアント名", "10", "delivery_destination", "text",      "",               "", "",                         "3"],
					["/Purchase#search",  "1", "部門",           "10", "division",             "select",    "division",       "", "",                         "4"],
					["/Purchase#search",  "2", "当社担当者",     "10", "manager",              "keyword",   "manager",        "", "担当者名・担当者CDで検索", "5"],
					["/Purchase#search",  "2", "仕入先",         "10", "supplier",             "keyword",   "supplier",       "", "仕入先名・仕入先CDで検索", "6"],
					["#sales_slip",       "1", "伝票番号",       "10", "slip_number",          "label",     "",               "", "",                         "1"],
					["#sales_slip",       "1", "確定日時",       "10", "regist_datetime",      "label",     "",               "", "",                         "2"],
					["#sales_slip",       "1", "売上日付",       "10", "approval_datetime",    "label",     "",               "", "",                         "3"],
					["#sales_slip",       "1", "当社担当者",     "10", "manager",              "label",     "manager",        "", "",                         "4"],
					["#sales_slip",       "1", "請求書件名",     "10", "subject",              "label",     "",               "", "",                         "5"],
					["#sales_slip",       "1", "入金予定日",     "10", "payment_date",         "label",     "",               "", "",                         "6"],
					["#sales_slip",       "2", "請求書パターン", "10", "invoice_format",       "label",     "invoice_format", "", "",                         "1"],
					["#sales_slip",       "2", "請求先",         "10", "apply_client",         "label",     "apply_client",   "", "",                         "2"],
					["#sales_slip",       "2", "納品先",         "10", "client_name",          "label",     "",               "", "",                         "3"],
					["#sales_slip",       "2", "備考",           "10", "note",                 "label",     "",               "", "",                         "4"]
				]);
				master.createTable("table_datas", ["location", "label", "width", "slot", "tag_name", "class_list", "property", "attributes", "no"], [
					["/Committed#list",         "仕入明細",           "5rem",                   "purchases_detail", "show-dialog", "btn btn-sm btn-success bx", "ss",              "label=\"仕入明細\" target=\"purchases_detail\"", "1"],
					["/Committed#list",         "売上明細",           "5rem",                   "salses_detail",    "show-dialog", "btn btn-sm btn-success bx", "ss",              "label=\"売上明細\" target=\"salses_detail\"",    "2"],
					["/Committed#list",         "確認承認",           "5rem",                   "approval",         "show-dialog", "btn btn-sm btn-primary bx", "ss",              "label=\"確認承認\" target=\"approval\"",         "3"],
					["/Committed#list",         "追加修正",           "5rem",                   "edit",             "create-window","btn btn-sm btn-primary bx", "ss",              "label=\"追加修正\" base=\"/Committed/edit/\" top=\"0\" left=\"0\" width=\"1200\" height=\"600\"", "4"],
					["/Committed#list",         "伝票番号",           "5rem",                   "slip_number",      "span",        "",                          "slip_number",     "",                                               "5"],
					["/Committed#list",         "確定日時",           "5rem",                   "regist_datetime",  "span",        "",                          "regist_datetime", "",                                               "6"],
					["/Committed#list",         "件名",               "5rem",                   "subject",          "span",        "",                          "subject",         "",                                               "7"],
					["/Committed#list",         "クライアント名",     "5rem",                   "client_name",      "span",        "",                          "client_name",     "",                                               "8"],
					["/Committed#list",         "請求先名",           "5rem",                   "apply_client",     "span",        "",                          "apply_client",    "",                                               "9"],
					["/Committed#list",         "担当者名",           "5rem",                   "manager",          "span",        "",                          "manager",         "",                                               "10"],
					["/Committed#list",         "備考",               "5rem",                   "note",             "span",        "",                          "note",            "",                                               "11"],
					["/Sales#list",             "仕入明細",           "5rem",                   "purchases_detail", "show-dialog", "btn btn-sm btn-success bx", "ss",              "label=\"仕入明細\" target=\"purchases_detail\"", "1"],
					["/Sales#list",             "売上明細",           "5rem",                   "salses_detail",    "show-dialog", "btn btn-sm btn-success bx", "ss",              "label=\"売上明細\" target=\"salses_detail\"",    "2"],
					["/Sales#list",             "承認解除",           "5rem",                   "approval",         "show-dialog", "btn btn-sm btn-primary bx", "ss",              "label=\"承認解除\" target=\"a2_details\"",       "3"],
					["/Sales#list",             "伝票番号",           "8rem",                   "slip_number",      "span",        "",                          "slip_number",     "",                                               "4"],
					["/Sales#list",             "確定日時",           "8rem",                   "regist_datetime",  "span",        "",                          "regist_datetime", "",                                               "5"],
					["/Sales#list",             "件名",               "auto",                   "subject",          "span",        "",                          "subject",         "",                                               "6"],
					["/Sales#list",             "クライアント名",     "auto",                   "client_name",      "span",        "",                          "client_name",     "",                                               "7"],
					["/Sales#list",             "請求先名",           "auto",                   "apply_client",     "span",        "",                          "apply_client",    "",                                               "8"],
					["/Sales#list",             "担当者名",           "auto",                   "manager",          "span",        "",                          "manager",         "",                                               "9"],
					["/Sales#list",             "備考",               "auto",                   "note",             "span",        "",                          "note",            "",                                               "10"],
					["/Billing#list",           "売上明細",           "5rem",                   "salses_detail",    "show-dialog", "btn btn-sm btn-success bx", "ss",              "label=\"売上明細\" target=\"salses_detail\"",    "1"],
					["/Billing#list",           "伝票番号",           "8rem",                   "slip_number",      "span",        "",                          "slip_number",     "",                                               "2"],
					["/Billing#list",           "確定日時",           "8rem",                   "regist_datetime",  "span",        "",                          "regist_datetime", "",                                               "3"],
					["/Billing#list",           "件名",               "auto",                   "subject",          "span",        "",                          "subject",         "",                                               "4"],
					["/Billing#list",           "クライアント名",     "auto",                   "client_name",      "span",        "",                          "client_name",     "",                                               "5"],
					["/Billing#list",           "請求先名",           "auto",                   "apply_client",     "span",        "",                          "apply_client",    "",                                               "6"],
					["/Billing#list",           "担当者名",           "auto",                   "manager",          "span",        "",                          "manager",         "",                                               "7"],
					["/Billing#list",           "備考",               "auto",                   "note",             "span",        "",                          "note",            "",                                               "8"],
					["/Purchase#list",          "仕入登録",           "5rem",                   "edit",             "span",        "btn btn-sm btn-primary bx", "sd",              "",                                               "1"],
					["/Purchase#list",          "担当者名",           "auto",                   "manager",          "span",        "",                          "manager",         "",                                               "2"],
					["/Purchase#list",          "伝票番号",           "8rem",                   "slip_number",      "span",        "",                          "slip_number",     "",                                               "3"],
					["/Purchase#list",          "確定日時",           "8rem",                   "regist_datetime",  "span",        "",                          "regist_datetime", "",                                               "4"],
					["/Purchase#list",          "クライアント名",     "auto",                   "client_name",      "span",        "",                          "client_name",     "",                                               "5"],
					["/Purchase#list",          "件名",               "auto",                   "subject",          "span",        "",                          "subject",         "",                                               "6"],
					["/Purchase#list",          "仕入先",             "auto",                   "supplier",         "span",        "",                          "supplier",        "",                                               "7"],
					["/Purchase#list",          "仕入金額（税抜き）", "auto",                   "amount_exc",       "span",        "d-block text-end",          "amount_exc",      "",                                               "8"],
					["/Purchase#list",          "仕入金額（税込み）", "auto",                   "amount_inc",       "span",        "d-block text-end",          "amount_inc",      "",                                               "9"],
					["/Purchase#list",          "請求書受領",         "auto",                   "payment",          "show-dialog", "btn btn-sm btn-primary bx", "pu",              "label=\"請求書受領\" target=\"\"",              "10"],
					["/Modal/Manager#list",     "コード",             "6rem",                   "code",             "span",        "",                          "code",            "",                                               "1"],
					["/Modal/Manager#list",     "担当者名",           "calc(50vw - 6rem)",      "name",             "span",        "",                          "name",            "",                                               "2"],
					["/Modal/Manager#list",     "カナ",               "calc(50vw - 6rem)",      "kana",             "span",        "",                          "kana",            "",                                               "3"],
					["/Modal/Manager#list",     "選択",               "3rem",                   "select",           "list-button", "btn btn-sm btn-success",    "code",            "label=\"選択\" data-trigger=\"list\"",           "4"],
					["/Modal/ApplyClient#list", "コード",             "6rem",                   "code",             "span",        "",                          "code",            "",                                               "1"],
					["/Modal/ApplyClient#list", "得意先名",           "calc(100vw / 3 - 4rem)", "client",           "span",        "",                          "client",          "",                                               "2"],
					["/Modal/ApplyClient#list", "請求先名",           "calc(100vw / 3 - 4rem)", "name",             "span",        "",                          "name",            "",                                               "3"],
					["/Modal/ApplyClient#list", "カナ",               "calc(100vw / 3 - 4rem)", "kana",             "span",        "",                          "kana",            "",                                               "4"],
					["/Modal/ApplyClient#list", "選択",               "3rem",                   "select",           "list-button", "btn btn-sm btn-success",    "code",            "label=\"選択\" data-trigger=\"list\"",           "5"],
					["/Modal/Client#list",      "コード",             "6rem",                   "code",             "span",        "",                          "code",            "",                                               "1"],
					["/Modal/Client#list",      "得意先名",           "calc(50vw - 6rem)",      "name",             "span",        "",                          "name",            "",                                               "2"],
					["/Modal/Client#list",      "カナ",               "calc(50vw - 6rem)",      "kana",             "span",        "",                          "kana",            "",                                               "3"],
					["/Modal/Client#list",      "選択",               "3rem",                   "select",           "list-button", "btn btn-sm btn-success",    "code",            "label=\"選択\" data-trigger=\"list\"",           "4"],
					["/Modal/Supplier#list",    "コード",             "6rem",                   "code",             "span",        "",                          "code",            "",                                               "1"],
					["/Modal/Supplier#list",    "仕入先名",           "calc(50vw - 6rem)",      "name",             "span",        "",                          "name",            "",                                               "2"],
					["/Modal/Supplier#list",    "カナ",               "calc(50vw - 6rem)",      "kana",             "span",        "",                          "kana",            "",                                               "3"],
					["/Modal/Supplier#list",    "選択",               "3rem",                   "select",           "list-button", "btn btn-sm btn-success",    "code",            "label=\"選択\" data-trigger=\"list\"",           "4"],
					["/Detail/Sales#list",      "内容",               "auto",                   "detail",           "span",        "",                          "detail",          "",                                               "1"],
					["/Detail/Sales#list",      "数量",               "auto",                   "quantity",         "span",        "",                          "quantity",        "",                                               "2"],
					["/Detail/Sales#list",      "単位",               "auto",                   "unit",             "span",        "",                          "unit",            "",                                               "3"],
					["/Detail/Sales#list",      "単価",               "auto",                   "unit_price",       "span",        "",                          "unit_price",      "",                                               "4"],
					["/Detail/Sales#list",      "税抜金額",           "auto",                   "amount_exc",       "span",        "",                          "amount_exc",      "",                                               "5"],
					["/Detail/Sales#list",      "消費税金額",         "auto",                   "amount_tax",       "span",        "",                          "amount_tax",      "",                                               "6"],
					["/Detail/Sales#list",      "税込金額",           "auto",                   "amount_inc",       "span",        "",                          "amount_inc",      "",                                               "7"],
					["/Detail/Sales#list",      "カテゴリー",         "auto",                   "category",         "span",        "",                          "category",        "",                                               "8"],
					["/Detail/Purchase#list",   "内容",               "auto",                   "detail",           "span",        "",                          "detail",          "",                                               "1"],
					["/Detail/Purchase#list",   "数量",               "auto",                   "quantity",         "span",        "",                          "quantity",        "",                                               "2"],
					["/Detail/Purchase#list",   "単位",               "auto",                   "unit",             "span",        "",                          "unit",            "",                                               "3"],
					["/Detail/Purchase#list",   "単価",               "auto",                   "unit_price",       "span",        "",                          "unit_price",      "",                                               "4"],
					["/Detail/Purchase#list",   "税抜金額",           "auto",                   "amount_exc",       "span",        "",                          "amount_exc",      "",                                               "5"],
					["/Detail/Purchase#list",   "消費税金額",         "auto",                   "amount_tax",       "span",        "",                          "amount_tax",      "",                                               "6"],
					["/Detail/Purchase#list",   "税込金額",           "auto",                   "amount_inc",       "span",        "",                          "amount_inc",      "",                                               "7"],
					["/Detail/Purchase#list",   "仕入先",             "auto",                   "supplier",         "span",        "",                          "supplier",        "",                                               "8"],
					["/Detail/Purchase#list",   "支払日",             "auto",                   "payment_date",     "span",        "",                          "payment_date",    "",                                               "9"]
				]);
				resolve();
			});
		});
	}).then(() => {
		SinglePage.modal.manager     .querySelector('table-sticky').columns = dataTableQuery("/Modal/Manager#list").setField("label,width,slot").apply();
		SinglePage.modal.apply_client.querySelector('table-sticky').columns = dataTableQuery("/Modal/ApplyClient#list").setField("label,width,slot").apply();
		SinglePage.modal.client      .querySelector('table-sticky').columns = dataTableQuery("/Modal/Client#list").setField("label,width,slot").apply();
		SinglePage.modal.supplier    .querySelector('table-sticky').columns = dataTableQuery("/Modal/Supplier#list").setField("label,width,slot").apply();
		
		SinglePage.modal.salses_detail   .querySelector('table-sticky').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot").apply();
		SinglePage.modal.purchases_detail.querySelector('table-sticky').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot").apply();
		SinglePage.modal.approval        .querySelector('table-sticky[data-table="1"]').columns = dataTableQuery("/Detail/Sales#list").setField("label,width,slot").apply();
		SinglePage.modal.approval        .querySelector('table-sticky[data-table="2"]').columns = dataTableQuery("/Detail/Purchase#list").setField("label,width,slot").apply();
		formTableInit(SinglePage.modal.salses_detail   .querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.purchases_detail.querySelector('div'), formTableQuery("#sales_slip").apply());
		formTableInit(SinglePage.modal.approval        .querySelector('div'), formTableQuery("#sales_slip").apply());
		
		SinglePage.modal.manager.setQuery(v => `${v}: manager`).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.manager.querySelector('table-sticky'),
				dataTableQuery("/Modal/Manager#list").apply(),
				master.select("ALL")
					.setField("'DATA' AS code,'DATA' AS name,'DATA' AS kana")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.apply_client.setQuery(v => `${v}: apply_client`).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.apply_client.querySelector('table-sticky'),
				dataTableQuery("/Modal/ApplyClient#list").apply(),
				master.select("ALL")
					.setField("'DATA' AS code,'DATA' AS name,'DATA' AS kana,'DATA' AS client")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.client.setQuery(v => `${v}: client`).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.client.querySelector('table-sticky'),
				dataTableQuery("/Modal/Client#list").apply(),
				master.select("ALL")
					.setField("'DATA' AS code,'DATA' AS name,'DATA' AS kana")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.supplier.setQuery(v => `${v}: supplier`).addEventListener("modal-open", e => {
			const keyword = e.detail;
			console.log(keyword);
			setDataTable(
				SinglePage.modal.supplier.querySelector('table-sticky'),
				dataTableQuery("/Modal/Supplier#list").apply(),
				master.select("ALL")
					.setField("'DATA' AS code,'DATA' AS name,'DATA' AS kana")
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.salses_detail.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW").setTable("sales_slips").andWhere("ss=?", Number(e.detail)).apply();
			const formControls = SinglePage.modal.salses_detail.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			setDataTable(
				SinglePage.modal.salses_detail.querySelector('table-sticky'),
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.purchases_detail.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW").setTable("sales_slips").andWhere("ss=?", Number(e.detail)).apply();
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
					.setField("DISTINCT purchases.*")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {}
			);
		});
		SinglePage.modal.approval.addEventListener("modal-open", e => {
			const db = SinglePage.currentPage.instance.transaction;
			const res = db.select("ROW").setTable("sales_slips").andWhere("ss=?", Number(e.detail)).apply();
			const formControls = SinglePage.modal.approval.querySelectorAll('form-control[name]');
			const n = formControls.length;
			for(let i = 0; i < n; i++){
				const name = formControls[i].getAttribute("name");
				formControls[i].value = res[name];
			}
			
			setDataTable(
				SinglePage.modal.approval.querySelector('table-sticky[data-table="1"]'),
				dataTableQuery("/Detail/Sales#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("sales_details using(sd)")
					.setField("DISTINCT sales_details.*")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {}
			);
			setDataTable(
				SinglePage.modal.approval.querySelector('table-sticky[data-table="2"]'),
				dataTableQuery("/Detail/Purchase#list").apply(),
				db.select("ALL")
					.setTable("purchase_relations")
					.leftJoin("purchases using(pu)")
					.setField("DISTINCT purchases.*")
					.andWhere("purchase_relations.ss=?", Number(e.detail))
					.apply(),
				row => {}
			);
			SinglePage.modal.approval.querySelector('[data-trigger="submit"]').setAttribute("data-result", e.detail);
		});
		
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
				if(row.list != ""){
					formControl.setAttribute("list", row.list);
				}
				if(row.placeholder != ""){
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
					const classList = col.class_list.split(/\s/).filter(v => v != "");
					let attrStr = col.attributes;
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
					callback(dataRow);
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
								<div>部署</div>
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
			<div part="toast"></div>
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
	
	<datalist id="category"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<modal-dialog name="manager" label="当社担当者選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);">
			<table-row><div slot="code">DATA</div><div slot="name">DATA</div><div slot="kana">DATA</div><div slot="select"><button type="button" class="btn btn-sm btn-success" data-trigger="list" data-result="data">選択</button></div></table-row>
		</table-sticky>
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
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			売上明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="purchases_detail" label="仕入明細">
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			仕入明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="approval" label="承認">
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			売上明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body">
			仕入明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="submit" class="btn btn-success" data-result="">承認</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="a2_details" label="承認解除">
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			売上明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="1"></table-sticky>
		<div slot="body">
			仕入明細
		</div>
		<table-sticky slot="body" style="height: calc(100vh - 20rem);" data-table="2"></table-sticky>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success" data-result="1">承認解除</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="a3_details" label="締め解除">
	</modal-dialog>
	<modal-dialog name="a4_details" label="請求書受領">
	</modal-dialog>
{/block}