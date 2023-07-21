{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/customElements.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link href="https://cdn.jsdelivr.net/npm/handsontable@6.2.2/dist/handsontable.full.min.css" rel="stylesheet" media="screen">
<style type="text/css">
.table_sticky{
	border-color: var(--bs-border-color);
}
#error{
	color: #dc3545;
}
</style>
{/block}
{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/Flow.js"></script>
<script type="text/javascript" src="/assets/common/customElements.js"></script>
<script src="https://cdn.jsdelivr.net/npm/handsontable@6.2.2/dist/handsontable.full.min.js"></script>
<script type="text/javascript">
{predefine name="main" assign="obj"}
<form id="res" action="{url action="update"}" class="py-4">
	<datalist id="invoice_format">{foreach from=[]|invoiceFormat item="text" key="value"}
		<option value="{$value}">{$text}</option>
	{/foreach}</datalist>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>見積</div>
		<div class="row gap-4 align-items-start">
			<div class="d-table col table">
				<row-form label="伝票番号" col="12" name="slip_number">{$obj.slip_number}</row-form>
				<row-form label="当社担当者" col="10">{$obj.manager_name}</row-form>
				<row-form label="請求書件名" col="10" name="subject" type="text" id="subject" require>{$obj.subject}</row-form>
				<row-form label="入金予定日" col="5" name="payment_date" type="date" require>{$obj.payment_date}</row-form>
			</div>
			<div class="d-table col table">
				<row-form label="請求書パターン" col="6" name="invoice_format" type="select" list="invoice_format">{$obj.invoice_format}</row-form>
				<row-form label="請求先" col="10" name="billing_destination" placeholder="請求先CD、会社名で検索"require>{$obj.billing_destination}</row-form>
				<row-form label="納品先" col="10" name="delivery_destination" type="text" id="client" require>{$obj.delivery_destination}</row-form>
				<row-form label="備考" col="10" name="note" type="textarea" id="note">{$obj.note}</row-form>
			</div>
		</div>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>見積明細</div>
		<input type="hidden" name="header1" value="{$obj.header1}" />
		<input type="hidden" name="header2" value="{$obj.header2}" />
		<input type="hidden" name="header3" value="{$obj.header3}" />
		<div id="list1"></div>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>仕入明細</div>
		<div id="list2"></div>
	</div>
	<div class="d-flex p-0 mx-5 gap-5">
		<div id="error" class="flex-grow-1"></div>
		<button type="submit" class="btn btn-success">登録</button>
	</div>
</form>
{/predefine}
{predefine name="applyClientList" assign="obj"}
	<tr>
		<td>{$obj.code}</td>
		<td>{$obj.client_name}</td>
		<td>{$obj.name}</td>
		<td>{$obj.kana}</td>
		<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}">選択</button></td>
	</tr>
{/predefine}
{predef_flash}{literal}
Flow.DbLocked = true;
Flow.start({{/literal}
	masterDownloadURL: "{url controller="Default" action="master"}",{literal}
	template: new Template(),
	data: null,
	tables: {},
	promise: new Promise((resolve, reject) => {
		addEventListener("message", function(e){
			resolve(JSON.parse(e.data));
		});
	}),
	*[Symbol.iterator](){
		{/literal}{master_download test="Object.keys(Flow.Master.tables).length < 1"}yield* this.masterUpdate();{/master_download}{literal}
		Flow.DbLocked = false;
		const editValues = yield this.promise;
		this.data = editValues.data;
		let categories = Flow.Master.select("OBJECT")
			.setTable("categories")
			.setField("code,name")
			.apply();
		for(let i = editValues.detail.length - 1; i >= 0; i--){
			if(editValues.detail[i].category_code in categories){
				editValues.detail[i].category = categories[editValues.detail[i].category_code].name;
			}else{
				editValues.detail[i].category = "";
			}
		}
		
class DetailTable{
	#data; #headers; #categories; #bind; #filter;
	constructor(data, headers, filter){
		this.#data = data;
		this.#headers = headers.map(a => a == "" ? "[摘要]" : a);
		this.#categories = Flow.Master.select("COL").setTable("categories").setField("name").apply();
		this.#bind = null;
		this.#filter = filter;
		Object.defineProperty(this, "data", {
			enumerable: true,
			get: this.#$data
		});
		Object.defineProperty(this, "columns", {
			enumerable: true,
			get: this.#$columns
		});
	}
	handleEvent(e){
		if(this.#bind != null){
			this.#filter = e.target.value;
			this.#bind.updateSettings({columns: this.columns});
		}
	}
	set bind(value){
		this.#bind = value;
	}
	#$data(){
		return this.#data;
	}
	#$columns(){
		let res = [
			{title: "商品カテゴリー", data: "category",    type: "autocomplete", source: this.#categories, strict: true},
			{title: "摘要",           data: "item_name"},
			{title: "数量",           data: "quantity",    type: "numeric"},
			{title: "単位",           data: "unit"},
			{title: "単価",           data: "unit_price",  type: "numeric"},
			{title: "金額",           data: "amount",      type: "numeric"},
		];
		if(this.#filter == "3"){
			res.push(
				{title: this.#headers[0], data: "data1"},
				{title: this.#headers[1], data: "data2"},
				{title: this.#headers[2], data: "data3"}
			);
		}
		if(this.#filter == "2"){
			res.push({title: "発行部数",       data: "circulation", type: "numeric"});
		}
		return res;
	}
}
		document.querySelector('main').innerHTML = this.template.main(editValues.data);
		let detailOptions = new DetailTable(editValues.detail, [editValues.data.header1, editValues.data.header2, editValues.data.header3], document.querySelector('[name="invoice_format"]').value);
		detailOptions.bind = this.tables.detail = new Handsontable(document.getElementById("list1"), detailOptions);
		document.querySelector('[name="invoice_format"]').addEventListener("change", detailOptions);
		this.tables.purchases = new Handsontable(document.getElementById("list2"), {
			data: editValues.detail2,
			columns: [
				{title: "内容（摘要）", data: "subject"},
				{title: "数量",         data: "quantity",     type: "numeric"},
				{title: "単位",         data: "unit"},
				{title: "単価",         data: "unit_price",   type: "numeric"},
				{title: "金額",         data: "amount",       type: "numeric"},
				{title: "仕入先",       data: "supplier"},
				{title: "支払日",       data: "payment_date", type: "date", dateFormat: 'YYYY-MM-DD'}
			]
		});
		
		
		// ダイアログ初期化
		const applyClientModal = new bootstrap.Modal(document.getElementById("applyClientModal"));
		const applyClientForm = document.querySelector('row-form[name="billing_destination"]');
		const applyClientSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("apply_clients")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				applyClientSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("apply_clients")
					.addField("apply_clients.*")
					.leftJoin("clients on apply_clients.client=clients.code")
					.addField("clients.name as client_name")
					.orWhere("apply_clients.name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.unique_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.short_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#applyClientModal tbody').innerHTML = table.map(row => this.template.applyClientList(row)).join("");
			},
			showModal: () => { applyClientModal.show(); },
			resetValue: () => { applyClientForm.value = ""; }
		});
		applyClientSearch.syncAttribute(applyClientForm);
		applyClientForm.bind(applyClientSearch, applyClientSearch.valueProperty);
		document.querySelector('#applyClientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				applyClientForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
		
		
		document.getElementById("res").addEventListener("submit", this);
	},
	*masterUpdate(){
		yield new Promise((resolve, reject) => {
			fetch(this.masterDownloadURL).then(response => response.arrayBuffer()).then(buffer => {
				Flow.Master.import(buffer, "master");
				Flow.Master.commit().then(res => {resolve(res);});
			});
		});
	},
	handleEvent(e){
		if(e.type == "submit"){
			e.stopPropagation();
			e.preventDefault();
			const editValues = this.data;
			const form = e.currentTarget;
			const formData = new FormData(form);
			let detail = {
				length: 0,
				itemName: [],
				quantity: [],
				unit: [],
				unitPrice: [],
				amount: [],
				circulation: [],
				data1: [],
				data2: [],
				data3: [],
				categoryCode: []
			};
			let categories = Flow.Master.select("OBJECT")
				.setTable("categories")
				.setField("name,code")
				.apply();
			const detailTable = this.tables.detail.getData();
			for(let row of detailTable){
				const i = detail.length;
				detail.length++;
				detail.categoryCode.push((row[0] in categories) ? categories[row[0]].code : null);
				detail.itemName.push(row[1]);
				detail.unit.push(row[2]);
				detail.quantity.push(row[3]);
				detail.unitPrice.push(row[4]);
				detail.amount.push(row[5]);
				detail.data1.push(row[6]);
				detail.data2.push(row[7]);
				detail.data3.push(row[8]);
				detail.circulation.push(row[9]);
			}
			const purchases = [];
			const purchasesTable = this.tables.purchases.getData();
			for(let row of purchasesTable){
				purchases.push({
					subject: row[0],
					unit: row[1],
					quantity: row[2],
					unit_price: row[3],
					amount: row[4],
					payment_date: row[6],
					ingest: {
						supplier: row[5]
					}
				});
			}
			formData.append("sid", editValues.spreadsheet);
			formData.append("detail", JSON.stringify(detail));
			formData.append("purchases", JSON.stringify(purchases));
			fetch(form.getAttribute("action"), {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(response => {
				if(response.success){
					// フォーム送信 成功
					
					close();
				}else{
					// フォーム送信 失敗
					
					// エラーメッセージをオブジェクトへ変更
					let messages = response.messages.reduce((a, message) => {
						if(message[1] == 2){
							a[message[2]] = message[0];
						}
						return a;
					}, {});
					
					// エラーメッセージの表示切替
					let inputs = form.querySelectorAll('[name],[data-form-name]');
					for(let input of inputs){
						let name = input.hasAttribute("name") ? input.getAttribute("name") : input.getAttribute("data-form-name");
						if(name in messages){
							if(input.tagName == "ROW-FORM"){
								input.setAttribute("invalid", messages[name]);
							}
							input.classList.add("is-invalid");
							let feedback = input.parentNode.querySelector('.invalid-feedback');
							if(feedback != null){
								feedback.textContent = messages[name];
							}
						}else{
							if(input.tagName == "ROW-FORM"){
								input.removeAttribute("invalid");
							}
							input.classList.remove("is-invalid");
						}
					}
					if("" in messages){
						document.getElementById("error").textContent = messages[""];
					}else{
						document.getElementById("error").textContent = "";
					}
				}
			});
		}
	}
});
{/literal}</script>
{/block}


{block name="body"}
<header class="sticky-top">
	<nav class="navbar p-0 bg-white border-bottom border-success border-2 shadow-sm">
		<div class="container-fluid gap-2">
			<div class="navbar-brand flex-grow-1">
				<span class="navbar-text text-dark fs-6">見積登録</span>
			</div>
		</div>
	</nav>
</header>
<main></main>
{/block}

{block name="dialogs" append}
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg flex-column">
		<div class="modal-content flex-grow-1">
			<div class="modal-header flex-row">
				<div class="text-center">請求先選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body position-relative me-4 mb-4">
				<div class="position-absolute h-100 w-100 overflow-auto">
					<table class="table table_sticky_list">
						<thead>
							<tr>
								<th>コード</th>
								<th>得意先名</th>
								<th>請求先名</th>
								<th>カナ</th>
								<th></th>
							</tr>
						</thead>
						<tbody></tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>
{/block}