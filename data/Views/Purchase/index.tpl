{block name="title"}仕入一覧画面{/block}
{block name="tools"}<a class="btn btn-success my-2" href="{url controller="Home" action="index"}">メインメニュー</a>{/block}
{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
<style type="text/css">
.modal-form{
	--bs-modal-width: calc(100% - var(--bs-modal-margin) * 2);
}
body [data-visible]{
	display: none;
}
body:has(input[name="invoice_format"][value="2"]) [data-visible="v2"],
body:has(input[name="invoice_format"][value="3"]) [data-visible="v3"]{
	display: table-cell;
}


.card:has(#search-header :checked) .card-body,.card:has(#search-header :checked) .card-footer{
	display: none;
}
#detailModal .modal-header select{
	appearance: none;
	border: none;
	padding: 0;
	margin: 0;
	font: inherit;
}
#detailModal:has(.modal-header select [value="1"]:checked) [data-detail-modal="1"],
#detailModal:has(.modal-header select [value="2"]:checked) [data-detail-modal="2"],
#detailModal:has(.modal-header select [value="1"]:checked) [data-detail-modal="3"],
#detailModal:has(.modal-header select [value="2"]:checked) [data-detail-modal="3"]{
	display: none;
}
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	strage: null,
	response: new SQLite(),
	detail: null,
	detailModal: null,
	template: null,
	*[Symbol.iterator](){
		const form = document.querySelector('form');
		yield* this.init(form);
		yield* this.search(form);
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		
		let categories = Flow.Master.select("OBJECT")
			.setTable("categories")
			.setField("code,name")
			.apply();
		this.template = new Template({
			equals(a, b){
				return (a == b) ? 1 : 0;
			},
			getName(object){
				if(object == null){
					return "";
				}else{
					return ("name" in object) ? object.name : "";
				}
			},
			date(datetime){
				return datetime.split(" ")[0];
			},
			numberFormat(value){
				if(typeof value === "number"){
					return new Intl.NumberFormat().format(Math.round(value));
				}
				return value;
			},
			numberFormat2(value){
				if(typeof value === "number"){
					return new Intl.NumberFormat().format(Math.round(value)) + value.toFixed(2).slice(-3);
				}
				return value;
			}
		}, categories);
		
		// datalist初期化
		let datalist = document.getElementById("division");
		let mastarData = Flow.Master.select("ALL")
			.addTable("divisions")
			.addField("code,name")
			.apply();
		for(let division of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: division.name});
			option.setAttribute("value", division.code);
			datalist.appendChild(option);
		}
		
		// ダイアログ初期化
		const managerModal = new bootstrap.Modal(document.getElementById("managerModal"));
		const managerForm = document.querySelector('row-form[name="manager"]');
		const managerSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("managers")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				managerSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("managers")
					.orWhere("name like ('%' || ? || '%')", keyword)
					.orWhere("code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#managerModal tbody').innerHTML = table.map(row => this.template.managerList(row)).join("");
			},
			showModal: () => { managerModal.show(); },
			resetValue: () => { managerForm.value = ""; }
		});
		managerSearch.syncAttribute(managerForm);
		managerForm.bind(managerSearch, managerSearch.valueProperty);
		document.querySelector('#managerModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				managerForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
		const applyClientModal = new bootstrap.Modal(document.getElementById("applyClientModal"));
		const applyClientForm = document.querySelector('row-form[name="billing_destination"]');
		const applyClientSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("system_apply_clients")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				applyClientSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("system_apply_clients as apply_clients")
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
		
		// 検索履歴
		let history = this.strage.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", form.getAttribute("action"))
			.setOrderBy("time DESC")
			.apply();
		if(history != null){
			let {data, label} = JSON.parse(history.json);
			const searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
				}
			}
			const rowForms = document.querySelectorAll('row-form[name]');
			for(let i = rowForms.length - 1; i >= 0; i--){
				let name = rowForms[i].getAttribute("name");
				if((name in data) && (data[name].length > 0)){
					rowForms[i].value = data[name].shift();
				}
			}
			
			this.y = JSON.parse(history.scroll_y);
			addEventListener("beforeunload", e => {
				let sy = {};
				const scrollY = document.querySelectorAll('[data-scroll-y]');
				for(let i = scrollY.length - 1; i >= 0; i--){
					let ele = scrollY[i];
					sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
				}
				this.strage.updateSet("search_histories", {
					scroll_y: JSON.stringify(sy)
				}, {})
					.andWhere("location=?", history.location)
					.andWhere("time=?", history.time)
					.apply();
				this.strage.commit();
			});
		}
		
		// イベントを設定
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let formData = new FormData(form);
			let obj = {data:{}, label:{}};
			for(let k of formData.keys()){
				if(k in obj.data){
					continue;
				}
				obj.data[k] = formData.getAll(k);
			}
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				obj.label[key] = searchLabels[i].innerHTML;
			}
			let sy = {};
			const scrollY = document.querySelectorAll('[data-scroll-y]');
			for(let i = scrollY.length - 1; i >= 0; i--){
				let ele = scrollY[i];
				sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
			}
			this.strage.insertSet("search_histories", {
				location: form.getAttribute("action"),
				json: JSON.stringify(obj),
				time: Date.now(),
				scroll_y: JSON.stringify(sy)
			}, {}).apply();
			this.strage.commit().then(e => {
				location.href = form.getAttribute("action");
				location.reload();
			});
		});
		form.addEventListener("reset", e => {
			const rowForms = document.querySelectorAll('row-form');
			for(let i = rowForms.length - 1; i >= 0; i--){
				rowForms[i].reset();
			}
		});
		
		this.detailModal = new bootstrap.Modal(document.getElementById("detailModal"));
		document.getElementById("closeDetailModal").addEventListener("click", e => { this.detailModal.hide(); });
		document.getElementById("approval").addEventListener("click", this);
		
		// フォームを有効化
		form.querySelector('fieldset').disabled = false;
	},
	*search(form){
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(form)
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		this.response.attach(Flow.Master, "master");
		let table = this.listItemQuery("ALL").apply();
		const tbody = document.getElementById("list");
		tbody.innerHTML = table.map(row => this.template.listItem(row)).join("");
		let trElements = tbody.querySelectorAll('[data-range]');
		for(let i = trElements.length - 1; i >= 0; i--){
			trElements[i].addEventListener("click", this, {capture: true});
		}
	},
	listItemQuery(mode){
		return this.response.select(mode)
			.setTable("sales_slips")
			.addField("sales_slips.*")
			.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
			.addField("managers.name AS manager_name")
			.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name AS apply_client_name");
	},
	handleEvent(e){
		if(e.currentTarget.hasAttribute("data-range")){
			const id = Number(e.currentTarget.getAttribute("data-range"));
			if(e.target.hasAttribute("data-detail")){
				this.detail = id;
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", id)
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
					.addField("apply_clients.name AS apply_client_name")
					.apply();
				let values = JSON.parse(data.detail);
				let keys = Object.keys(values).filter(k => Array.isArray(values[k]));
				let detail = [];
				let detail2 = this.response.select("ALL")
					.addTable("purchases")
					.andWhere("spreadsheet=?", data.spreadsheet)
					.apply();
				for(let i = 0; i < values.length; i++){
					let obj = {};
					for(let k of keys){
						let key = k.replace(/[A-Z]/g, function(ch){
							return `_${ch.toLowerCase()}`;
						});
						obj[key] = values[k][i];
					}
					detail.push(obj);
				}
				document.querySelector('#detailModal .modal-header select').value = e.target.getAttribute("data-detail");
				document.querySelector('#detailModal .modal-body').innerHTML = this.template.detailView(data, detail, detail2);
				this.detailModal.show();
			}else if(e.target.hasAttribute("href")){
				e.stopPropagation();
				e.preventDefault();
				this.detail = id;
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", id)
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
					.addField("apply_clients.name AS apply_client_name")
					.apply();
				let values = JSON.parse(data.detail);
				let keys = Object.keys(values).filter(k => Array.isArray(values[k]));
				let detail = [];
				for(let i = 0; i < values.length; i++){
					let obj = {};
					for(let k of keys){
						let key = k.replace(/[A-Z]/g, function(ch){
							return `_${ch.toLowerCase()}`;
						});
						obj[key] = values[k][i];
					}
					detail.push(obj);
				}
				let detail2 = this.response.select("ALL")
					.addTable("purchases")
					.andWhere("spreadsheet=?", data.spreadsheet)
					.apply();
				const [w, h] = [1200, 900];
				const editWindow = window.open(e.target.getAttribute("href"), "regist", `left=${0},top=${0},width=${w},height=${h}`);
				editWindow.addEventListener("load", e => {
					editWindow.postMessage(JSON.stringify({data, detail, detail2}), "*");
				});
			}
		}else if(e.currentTarget == document.getElementById("approval")){
			const url = document.querySelector('#detailModal [data-approval]').getAttribute("data-approval");
			const formData = new FormData();
			fetch(url, {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(response => {
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "売上登録", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				Flow.DB.commit().then(e => { location.reload(); });
			});
			this.detailModal.hide();
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<datalist id="invoice_format">{foreach from=[]|invoiceFormat item="text" key="value"}
	<option value="{$value}">{$text}</option>
{/foreach}</datalist>
<datalist id="division"><option value="">選択</option></datalist>
<form method="POST" action="{url}" class="card position-sticky mx-5">
	<label id="search-header" class="card-header"><input type="checkbox" class="d-contents" />仕入一覧検索</label>
	<fieldset class="card-body  d-flex p-0 overflow-auto gap-3" style="max-height: calc(50vh - 10rem);" disabled>
		<div class="d-table table">
			<row-form label="伝票番号" col="5" name="slip_number" type="text"></row-form>
			<row-form label="確定日付（開始日）" col="8" name="accounting_date[from]" type="date">{"first day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
			<row-form label="確定日付（終了日）" col="8" name="accounting_date[to]" type="date">{"last day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
			<row-form label="クライアント名" col="10" name="delivery_destination" type="text"></row-form>
			{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}
			<row-form label="部門" col="10" name="division" type="select" list="division"></row-form>
			{/if}
		</div>
		<div class="d-table table">
			{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}
			<row-form label="当社担当者" col="10" name="manager" placeholder="担当者名・担当者CDで検索"></row-form>
			{/if}
			<row-form label="仕入先" col="10" name="billing_destination" placeholder="仕入先名・仕入先CDで検索"></row-form>
		</div>
	</fieldset>
	<div class="card-footer">
		<div class="col-12 text-center">
			<button type="submit" class="btn btn-success">検　索</button>
			<button type="reset" class="btn btn-outline-success">リセット</button>
		</div>
	</div>
</form>

<div class="mx-5 text-end">
	<button type="button" class="btn btn-dark me-3" id="export">仕入一覧出力</button>
</div>

<div class="flex-grow-1 mx-5 position-relative">
	<div class="position-absolute h-100 w-100 overflow-auto">
		<table class="table table-bordered bg-white table_sticky_list" data-scroll-y="list">
			<thead>
				<tr>
					<th>仕入登録</th>
					{if $smarty.session["User.role"] ne "manager"}<th class="w-10">担当者名</th>{/if}
					<th class="w-10">伝票番号</th>
					<th class="w-10">確定日時</th>
					<th class="w-10">クライアント名</th>
					<th class="w-10">件名</th>
					<th class="w-20">仕入先</th>
					<th class="w-20">仕入金額（税抜き）</th>
					<th class="w-20">仕入金額（税込み）</th>
					{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<th class="w-10">請求書受領</th>{/if}
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" constructor="sales" assign="obj"}
				<tr data-range="{$obj.id}">
					<td><a href="{url action="edit"}" class="btn btn-sm btn-info bx bxs-edit">仕入登録</a></td>
					{if $smarty.session["User.role"] ne "manager"}<td>{$obj.manager_name}</td>{/if}
					<td>{$obj.slip_number}</td>
					<td>{$obj.created}</td>
					<td>{$obj.delivery_destination}</td>
					<td>{$obj.subject}</td>
					<td></td>
					<td></td>
					<td></td>
					{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}
						<td><button type="button" data-detail="3" class="btn btn-sm btn-primary bx bxs-edit">受領</button></td>
					{/if}
				</tr>
			{/predefine}</tbody>
		</table>
	</div>
</div>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="managerModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg flex-column">
		<div class="modal-content flex-grow-1">
			<div class="modal-header flex-row">
				<div class="text-center">当社担当者選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body position-relative me-4 mb-4">
				<div class="position-absolute h-100 w-100 overflow-auto">
					<table class="table table_sticky_list">
						<thead>
							<tr>
								<th>コード</th>
								<th>担当者名</th>
								<th>カナ</th>
								<th></th>
							</tr>
						</thead>
						<tbody>{predefine name="managerList" assign="obj"}
							<tr>
								<td>{$obj.code}</td>
								<td>{$obj.name}</td>
								<td>{$obj.kana}</td>
								<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
							</tr>
						{/predefine}</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>
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
						<tbody>{predefine name="applyClientList" assign="obj"}
							<tr>
								<td>{$obj.code}</td>
								<td>{$obj.client_name}</td>
								<td>{$obj.name}</td>
								<td>{$obj.kana}</td>
								<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
							</tr>
						{/predefine}</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>
<div class="modal fade" id="detailModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-form">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<select tabindex="-1"><option value="1">仕入明細</option><option value="2">売上明細</option>{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<option value="3">売上承認</option>{/if}</select><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">{predefine name="detailView" constructor=["sales", "categories"] assign=["obj", "detail", "detail2"]}
				<div class="container border border-secondary rounded p-4 mb-5 bg-white" data-approval="{url action="approval"}/{$obj.id}">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="伝票番号" col="5">{$obj.slip_number}</row-form>
							<row-form label="確定日時" col="5">{$obj.created}</row-form>
							<row-form label="売上日付" col="5">{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}{$smarty.now|date_format:"%Y-%m-%d"}{/if}</row-form>
							<row-form label="当社担当者" col="10">{$obj.manager_name}</row-form>
							<row-form label="請求書件名" col="10">{$obj.subject}</row-form>
							<row-form label="入金予定日" col="5">{$obj.payment_date}</row-form>
						</div>
						<div class="d-table col table">
							<row-form label="請求書パターン" type="hidden" col="6">{$obj.invoice_format}<div slot="content">{foreach from=[]|invoiceFormat item="text" key="value"}{predef_repeat loop=$sales.equals|predef_invoke:$value:$obj.invoice_format}{$text}{/predef_repeat}{/foreach}</div></row-form>
							<row-form label="請求先" col="10">{$obj.apply_client_name}</row-form>
							<row-form label="納品先" col="10">{$obj.delivery_destination}</row-form>
							<row-form label="備考" col="10">{$obj.note}</row-form>
						</div>
					</div>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive" data-detail-modal="1">
					<div>売上明細</div>
					<table class="table table-bordered table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>商品カテゴリー</th>
								<th>内容（摘要）</th>
								<th>数量</th>
								<th>単位</th>
								<th>単価</th>
								<th>金額</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header1}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header2}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header3}</th>
								<th data-visible="v2">発行部数</th>
							</tr>
						</thead>
						<tbody>
							{predef_repeat loop=$detail.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{$sales.getName|predef_invoke:$categories[$detail[$i].category_code]}</td>
								<td>{$detail[$i].itemName}{$detail[$i].item_name}</td>
								<td class="text-end">{$sales.numberFormat2|predef_invoke:$detail[$i].quantity}</td>
								<td>{$detail[$i].unit}</td>
								<td class="text-end">{$sales.numberFormat2|predef_invoke:$detail[$i].unit_price}</td>
								<td class="text-end">{$sales.numberFormat|predef_invoke:$detail[$i].amount}</td>
								<td data-visible="v3">{$detail[$i].data1}</td>
								<td data-visible="v3">{$detail[$i].data2}</td>
								<td data-visible="v3">{$detail[$i].data3}</td>
								<td class="text-end" data-visible="v2">{$sales.numberFormat|predef_invoke:$detail[$i].circulation}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive" data-detail-modal="2">
					<div>仕入明細</div>
					<table class="table table-bordered table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>内容</th>
								<th>金額</th>
								<th>支払日</th>
							</tr>
						</thead>
						<tbody>
							{predef_repeat loop=$detail2.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{$detail2[$i].subject}</td>
								<td class="text-end">{$sales.numberFormat|predef_invoke:$detail2[$i].amount}</td>
								<td>{$detail2[$i].payment_date}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
			{/predefine}</div>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" id="closeDetailModal">閉じる</button>
				<button type="button" class="btn btn-success" id="approval" data-detail-modal="3">承認</button>
			</div>
		</div>
	</div>
</div>
{/block}