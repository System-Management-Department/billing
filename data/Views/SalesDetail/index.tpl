{block name="title"}売上一覧画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
<style type="text/css">
.table_sticky_list{
	display: block;
	overflow-y: scroll;
	height: calc(100vh/2);
	border: 1px solid #dedede;
	border-collapse: collapse;
}
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
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	strage: null,
	response: new SQLite(),
	template: null,
	*[Symbol.iterator](){
		yield* this.init();
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		this.response.attach(Flow.Master, "master");
		let categories = Flow.Master.select("ALL")
			.addTable("categories")
			.apply();
		this.template = new Template({
			formType(obj){
				return (obj.sales_slip == null) ? "create" : "edit";
			},
			modalId(obj){
				return (obj.sales_slip == null) ? obj.id : obj.sales_slip
			},
			modalText(obj){
				return (obj.sales_slip == null) ? "登録" : "追加修正";
			},
			equals(a, b){
				return (a == b) ? 1 : 0;
			},
			date(datetime){
				return datetime.split(" ")[0];
			}
		}, categories);
		let table = this.listItemQuery("ALL").andWhere("sales_slips.approval=0").apply();
		document.getElementById("list2").innerHTML = table.map(row => this.template.listItem2(row)).join("");
		table = this.listItemQuery("ALL").andWhere("sales_slips.approval=1").apply();
		document.getElementById("list3").innerHTML = table.map(row => this.template.listItem3(row)).join("");
		let buttons = document.querySelectorAll('[data-create],[data-edit],[data-detail],[data-detail2],[data-purchase]');
		for(let i = buttons.length - 1; i >= 0; i--){
			buttons[i].addEventListener("click", this);
		}
	},
	listItemQuery(mode){
		return this.response.select(mode)
			.setTable("sales_slips")
			.addField("sales_slips.*")
			.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
			.addField("managers.name AS manager_name")
			.leftJoin("master.apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name AS apply_client_name");
	},
	handleEvent(e){
		if(e.currentTarget.hasAttribute("data-purchase")){
			let data = this.response.select("ROW")
				.addTable("sales_slips")
				.addField("sales_slips.*")
				.andWhere("sales_slips.spreadsheet=?", e.currentTarget.getAttribute("data-purchase"))
				.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
				.addField("managers.name AS manager_name")
				.leftJoin("master.apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
				.addField("apply_clients.name AS apply_client_name")
				.apply();
			let detail = this.response.select("ALL")
				.addTable("purchases")
				.andWhere("spreadsheet=?", e.currentTarget.getAttribute("data-purchase"))
				.apply();
			document.getElementById("purchase_list").innerHTML = this.template.purchaseView(data, detail);
			console.log({data, detail});
			
		}else{
			const content = document.querySelector('#formModal .modal-content');
			const range = e.currentTarget.closest('[data-range]');
			if(e.currentTarget.hasAttribute("data-edit")){
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", Number(e.currentTarget.getAttribute("data-edit")))
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
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
				console.log(detail);
				content.innerHTML = this.template.editForm(data, detail);
			}else if(e.currentTarget.hasAttribute("data-detail")){
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", Number(e.currentTarget.getAttribute("data-detail")))
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
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
				content.innerHTML = this.template.detailView(data, detail, detail2);
			}else{
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", Number(e.currentTarget.getAttribute("data-detail2")))
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
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
				content.innerHTML = this.template.detailView2(data, detail, detail2);
			}
			const detailList = document.getElementById("detail_list");
			document.getElementById("add_detail_row").addEventListener("click", e => {
				detailList.insertAdjacentHTML("beforeend", this.template.detailForm({}));
			});
			detailList.addEventListener("change", e => {
				let checked = detailList.querySelectorAll('tr:has([data-form-remove]:checked)');
				for(let i = checked.length - 1; i >= 0; i--){
					detailList.removeChild(checked[i]);
				}
				let tr = detailList.querySelectorAll('tr');
				let data = {
					length: tr.length
				};
				let total = 0;
				for(let i = 0; i < data.length; i++){
					let input = tr[i].querySelectorAll('[name]');
					for(let j = input.length - 1; j >= 0; j--){
						let name = input[j].getAttribute("name").replace(/^_detail\[|\]\[\]$/g, "");
						if(!(name in data)){
							data[name] = new Array(data.length);
						}
						if(input[j].value == ""){
							data[name][i] = null;
						}else if(isNaN(input[j].value)){
							data[name][i] = input[j].value;
						}else{
							data[name][i] = Number(input[j].value);
						}
					}
					if(("amount" in data) && (typeof data.amount[i] === 'number')){
						total += data.amount[i];
					}
				}
				content.querySelector('input[name="detail"]').value = JSON.stringify(data);
				content.querySelector('input[name="sales_tax"]').value = total * 0.1;
				
			}, {useCapture: true/*, signal: controller.signal*/});
			content.querySelector('.btn[data-bs-dismiss="modal"]').addEventListener("click", e => {
				const form = content.querySelector('form');
				let formData = new FormData(form);
				fetch(form.getAttribute("action"), {
					method: form.getAttribute("method"),
					body: formData
				}).then(res => res.json()).then(response => {
					if(response.success){
						// フォーム送信 成功
						for(let message of response.messages){
							Flow.DB.insertSet("messages", {title: "売上登録", message: message[0], type: message[1], name: message[2]}, {}).apply();
						}
						let messages = Flow.DB.select("ALL")
							.addTable("messages")
							.leftJoin("toast_classes using(type)")
							.apply();
						Toaster.show(messages);
						Flow.DB.delete("messages").apply();
						fetch(this.dbDownloadURL).then(response => response.arrayBuffer()).then(buffer => {
							this.response.import(buffer, "list");
							this.response.attach(Flow.Master, "master");
							const id = Number(range.getAttribute("data-range"));
							let row = this.listItemQuery("ROW").andWhere("sales_slips.id=?", id).apply();
							if(row.approval == 0){
								document.getElementById("list2").insertAdjacentHTML("afterend", this.template.listItem2(row));
							}else if(row.approval == 1){
								document.getElementById("list3").insertAdjacentHTML("afterend", this.template.listItem3(row));
							}
							range.parentNode.removeChild(range);
							let approvalRows = document.querySelectorAll('[data-approval="1"]:has([data-edit])');
							for(let i = approvalRows.length - 1; i >= 0; i--){
								const span = Object.assign(document.createElement("span"), {textContent: "承認済"});
								const button = approvalRows[i].querySelector('[data-edit]');
								button.parentNode.replaceChild(span, button);
							}
							let buttons = document.querySelectorAll(`[data-range="${id}"] [data-create],[data-range="${id}"] [data-edit],[data-range="${id}"] [data-detail],[data-range="${id}"] [data-detail2],[data-range="${id}"] [data-purchase]`);
							for(let i = buttons.length - 1; i >= 0; i--){
								buttons[i].addEventListener("click", this);
							}
						});
					}else{
						// フォーム送信 失敗
						new bootstrap.Modal(document.getElementById("formModal")).show();
						
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
					}
				});
			});
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<datalist id="invoice_format">{foreach from=[]|invoiceFormat item="text" key="value"}
	<option value="{$value}">{$text}</option>
{/foreach}</datalist>
<div class="container border border-secondary rounded p-4 bg-white table-responsive mb-4">
	<p>売上一覧</p>
	<table class="table table_sticky_list" data-scroll-y="list">
		<thead>
			<tr>
				<th class="w-10">伝票番号</th>
				<th class="w-10">取込日時</th>
				<th class="w-10">件名</th>
				<th class="w-10">クライアント名</th>
				<th class="w-20">請求先名</th>
				{if $smarty.session["User.role"] ne "manager"}<th class="w-10">担当者名</th>{/if}
				<th class="w-20">備考</th>
				<th class="w-10">仕入明細</th>
				<th>売上追加修正</th>
				{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<th class="w-10">確認承認</th>{/if}
			</tr>
		</thead>
		<tbody id="list2">{predefine name="listItem2" constructor="sales" assign="obj"}
			<tr data-range="{$obj.id}">
				<td>{$obj.slip_number}</td>
				<td>{$obj.created}</td>
				<td>{$obj.subject}</td>
				<td>{$obj.delivery_destination}</td>
				<td>{$obj.apply_client_name}</td>
				{if $smarty.session["User.role"] ne "manager"}<td>{$obj.manager_name}</td>{/if}
				<td>{$obj.note}</td>
				<td>{predef_repeat loop=$obj.import_purchases}<button type="button" data-purchase="{$obj.spreadsheet}" class="btn btn-sm btn-success" data-bs-toggle="modal" data-bs-target="#purchaseModal">仕入明細</button>{/predef_repeat}</td>
				<td>
					<button type="button" data-edit="{$obj.id}" class="btn btn-sm btn-info bx bxs-edit" data-bs-toggle="modal" data-bs-target="#formModal">追加修正</button>
				</td>
				{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<td>
					<button type="button" data-detail="{$obj.id}" class="btn btn-sm btn-primary bx bxs-edit" data-bs-toggle="modal" data-bs-target="#formModal">確認承認</button>
				</td>{/if}
			</tr>
		{/predefine}</tbody>
	</table>
</div>
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<p>売上承認済み案件</p>
	<table class="table table_sticky_list" data-scroll-y="list">
		<thead>
			<tr>
				<th class="w-10">伝票番号</th>
				<th class="w-10">取込日時</th>
				<th class="w-10">件名</th>
				<th class="w-10">クライアント名</th>
				<th class="w-20">請求先名</th>
				{if $smarty.session["User.role"] ne "manager"}<th class="w-10">担当者名</th>{/if}
				<th class="w-20">備考</th>
				<th class="w-10">仕入明細</th>
				{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<th class="w-10">確認承認解除</th>{/if}
			</tr>
		</thead>
		<tbody id="list3">{predefine name="listItem3" constructor="sales" assign="obj"}
			<tr data-range="{$obj.id}">
				<td>{$obj.slip_number}</td>
				<td>{$obj.created}</td>
				<td>{$obj.subject}</td>
				<td>{$obj.delivery_destination}</td>
				<td>{$obj.apply_client_name}</td>
				{if $smarty.session["User.role"] ne "manager"}<td>{$obj.manager_name}</td>{/if}
				<td>{$obj.note}</td>
				<td>{predef_repeat loop=$obj.import_purchases}<button type="button" data-purchase="{$obj.spreadsheet}" class="btn btn-sm btn-success" data-bs-toggle="modal" data-bs-target="#purchaseModal">仕入明細</button>{/predef_repeat}</td>
				{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<td>
					<button type="button" data-detail2="{$sales.modalId|predef_invoke:$obj}" class="btn btn-sm btn-primary bx bxs-edit" data-bs-toggle="modal" data-bs-target="#formModal">確認承認解除</button>
				</td>{/if}
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="formModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-form">
		<div class="modal-content">{predefine name="editForm" constructor="sales" assign=["obj", "detail"]}
			<div class="modal-header flex-row">
				<div class="text-center">売上登録</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<form action="{url action="update"}/{$obj.id}" method="POST" class="modal-body">
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="伝票番号" col="5">{$obj.slip_number}</row-form>
							<row-form label="売上日付" col="5" type="date" name="accounting_date">{$obj.accounting_date}</row-form>
							<row-form label="当社担当者" col="10">{$obj.manager_name}</row-form>
							<row-form label="請求書件名" col="10" type="text" name="subject" require>{$obj.subject}</row-form>
							<row-form label="入金予定日" col="5" type="date" name="payment_date" require>{$obj.payment_date}</row-form>
						</div>
						<div class="d-table col table">
							<row-form label="請求書パターン" col="6" type="select" name="invoice_format" list="invoice_format" default="1">{$obj.invoice_format}<span slot="content" class="no-edit clearfix ms-2">請求書見本はこちら</span></row-form>
							<row-form label="請求先" col="10">{$obj.apply_client_name}</row-form>
							<row-form label="納品先" col="10" type="text" name="delivery_destination" require>{$obj.delivery_destination}</row-form>
							<row-form label="備考" col="10" type="textarea" name="note">{$obj.note}</row-form>
						</div>
					</div>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<input type="hidden" name="detail" value="{$obj.detail}" />
					<input type="hidden" name="sales_tax" value="0" />
					<table class="table table-md table_sticky">
						<thead>
							<tr>
								<th>No</th>
								<th>商品カテゴリー</th>
								<th>内容（摘要）</th>
								<th>単位</th>
								<th>数量</th>
								<th>単価</th>
								<th>金額</th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header1" class="form-control form-control-sm" placeholder="摘要ヘッダー１" autocomplete="off" value="{$obj.header1}" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header2" class="form-control form-control-sm" placeholder="摘要ヘッダー２" autocomplete="off" value="{$obj.header2}" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header3" class="form-control form-control-sm" placeholder="摘要ヘッダー３" autocomplete="off" value="{$obj.header3}" /></th>
								<th data-visible="v2">発行部数</th>
								<th></th>
							</tr>
						</thead>
						<tfoot>
							<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
						</tfoot>
						<tbody id="detail_list">
							{predef_repeat loop=$detail.length index="i"}{predef_call name="detailForm" param=$detail[$i]}{/predef_repeat}
							{predefine name="detailForm" constructor=["sales", "categories"] assign="obj"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td><select name="_detail[categoryCode][]" class="form-select">
									<option value="">選択</option>
									{predef_repeat loop=$categories.length index="i"}
									<option value="{$categories[$i].code}"{predef_repeat loop=$sales.equals|predef_invoke:$categories[$i].code:$obj.category_code} selected{/predef_repeat}>{$categories[$i].name}</option>
									{/predef_repeat}
								</select></td>
								<td><input type="text" name="_detail[itemName][]" class="form-control" value="{$obj.item_name}" /></td>
								<td><input type="text" name="_detail[unit][]" class="form-control" value="{$obj.unit}" /></td>
								<td><input type="text" name="_detail[quantity][]" class="form-control" value="{$obj.quantity}" /></td>
								<td><input type="text" name="_detail[unitPrice][]" class="form-control"  value="{$obj.unit_price}" /></td>
								<td><input type="text" name="_detail[amount][]" class="form-control" value="{$obj.amount}" /></td>
								<td data-visible="v3"><input type="text" name="_detail[data1][]" class="form-control" value="{$obj.data1}" /></td>
								<td data-visible="v3"><input type="text" name="_detail[data2][]" class="form-control" value="{$obj.data2}" /></td>
								<td data-visible="v3"><input type="text" name="_detail[data3][]" class="form-control" value="{$obj.data3}" /></td>
								<td data-visible="v2"><input type="text" name="_detail[circulation][]" class="form-control" value="{$obj.circulation}" /></td>
								<td><label class="btn bi bi-trash3"><input type="checkbox" data-form-remove="" class="d-contents" /></label></td>
							</tr>
							{/predefine}
						</tbody>
					</table>
				</div>
			</form>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" data-bs-dismiss="modal">登録</button>
			</div>
			{/predefine}{predefine name="detailView" constructor="sales" assign=["obj", "detail", "detail2"]}
			<div class="modal-header flex-row">
				<div class="text-center">売上明細</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<form action="{url action="approval"}/{$obj.id}" method="POST" class="modal-body">
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="伝票番号" col="5">{$obj.slip_number}</row-form>
							<row-form label="売上日付" col="5">{$obj.accounting_date}</row-form>
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
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<input type="hidden" name="detail" value="{$obj.detail}" />
					<input type="hidden" name="sales_tax" value="0" />
					<table class="table table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>商品カテゴリー</th>
								<th>内容（摘要）</th>
								<th>単位</th>
								<th>数量</th>
								<th>単価</th>
								<th>金額</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header1}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header2}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header3}</th>
								<th data-visible="v2">発行部数</th>
							</tr>
						</thead>
						<tfoot hidden>
							<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
						</tfoot>
						<tbody id="detail_list">
							{predef_repeat loop=$detail.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{predef_repeat loop=$categories.length index="j"}
									{predef_repeat loop=$sales.equals|predef_invoke:$categories[$j].code:$detail[$i].category_code}{$categories[$j].name}{/predef_repeat}
								{/predef_repeat}</td>
								<td>{$detail[$i].itemName}{$detail[$i].item_name}</td>
								<td>{$detail[$i].unit}</td>
								<td>{$detail[$i].quantity}</td>
								<td>{$detail[$i].unitPrice}{$detail[$i].unit_price}</td>
								<td>{$detail[$i].amount}</td>
								<td data-visible="v3">{$detail[$i].data1}</td>
								<td data-visible="v3">{$detail[$i].data2}</td>
								<td data-visible="v3">{$detail[$i].data3}</td>
								<td data-visible="v2">{$detail[$i].circulation}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<table class="table table-md table_sticky_list">
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
								<td>{$detail2[$i].amount}</td>
								<td>{$detail2[$i].payment_date}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
			</form>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" data-bs-dismiss="modal">承認</button>
			</div>
			{/predefine}{predefine name="detailView2" constructor="sales" assign=["obj", "detail", "detail2"]}
			<div class="modal-header flex-row">
				<div class="text-center">売上明細</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<form action="{url action="disapproval"}/{$obj.id}" method="POST" class="modal-body">
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="伝票番号" col="5">{$obj.slip_number}</row-form>
							<row-form label="売上日付" col="5">{$obj.accounting_date}</row-form>
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
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<input type="hidden" name="detail" value="{$obj.detail}" />
					<input type="hidden" name="sales_tax" value="0" />
					<table class="table table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>商品カテゴリー</th>
								<th>内容（摘要）</th>
								<th>単位</th>
								<th>数量</th>
								<th>単価</th>
								<th>金額</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header1}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header2}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header3}</th>
								<th data-visible="v2">発行部数</th>
							</tr>
						</thead>
						<tfoot hidden>
							<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
						</tfoot>
						<tbody id="detail_list">
							{predef_repeat loop=$detail.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{predef_repeat loop=$categories.length index="j"}
									{predef_repeat loop=$sales.equals|predef_invoke:$categories[$j].code:$detail[$i].category_code}{$categories[$j].name}{/predef_repeat}
								{/predef_repeat}</td>
								<td>{$detail[$i].itemName}{$detail[$i].item_name}</td>
								<td>{$detail[$i].unit}</td>
								<td>{$detail[$i].quantity}</td>
								<td>{$detail[$i].unitPrice}{$detail[$i].unit_price}</td>
								<td>{$detail[$i].amount}</td>
								<td data-visible="v3">{$detail[$i].data1}</td>
								<td data-visible="v3">{$detail[$i].data2}</td>
								<td data-visible="v3">{$detail[$i].data3}</td>
								<td data-visible="v2">{$detail[$i].circulation}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<table class="table table-md table_sticky_list">
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
								<td>{$detail2[$i].amount}</td>
								<td>{$detail2[$i].payment_date}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
			</form>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" data-bs-dismiss="modal">承認解除</button>
			</div>
			{/predefine}
		</div>
	</div>
</div>

<div class="modal fade" id="purchaseModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-form">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">仕入明細</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body" id="purchase_list">{predefine name="purchaseView" constructor="sales" assign=["obj", "detail"]}
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="当社担当者" col="10">{$obj.manager_name}</row-form>
							<row-form label="件名" col="10">{$obj.subject}</row-form>
						</div>
						<div class="d-table col table">
							<row-form label="得意先" col="10">{$obj.delivery_destination}</row-form>
							<row-form label="請求先" col="10">{$obj.apply_client_name}</row-form>
							<row-form label="備考" col="10">{$obj.note}</row-form>
						</div>
					</div>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
					<table class="table table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>内容</th>
								<th>金額</th>
								<th>支払日</th>
							</tr>
						</thead>
						<tbody>
							{predef_repeat loop=$detail.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{$detail[$i].subject}</td>
								<td>{$detail[$i].amount}</td>
								<td>{$detail[$i].payment_date}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
			{/predefine}</div>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" data-bs-dismiss="modal">閉じる</button>
			</div>
		</div>
	</div>
</div>
{/block}