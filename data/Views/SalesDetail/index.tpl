{block name="title"}案件一覧画面{/block}

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
body:has(#invoice_format-input [value="2"]:checked) [data-visible="v2"],
body:has(#invoice_format-input [value="3"]:checked) [data-visible="v3"]{
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
				return (obj.sales_slip == null) ? "登録" : "編集";
			},
			equals(a, b){
				return (a == b) ? 1 : 0;
			},
			date(datetime){
				return datetime.split(" ")[0];
			}
		}, categories);
		let table = this.listItemQuery("ALL").apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
		let buttons = document.querySelectorAll('[data-create],[data-edit]');
		for(let i = buttons.length - 1; i >= 0; i--){
			buttons[i].addEventListener("click", this);
		}
	},
	listItemQuery(mode){
		return this.response.select(mode)
			.addTable("projects")
			.addField("projects.*")
			.leftJoin("master.managers AS managers ON projects.manager=managers.code")
			.addField("managers.name AS manager_name")
			.leftJoin("master.clients AS clients ON projects.client=clients.code")
			.addField("clients.name AS client_name")
			.leftJoin("master.apply_clients AS apply_clients ON projects.apply_client=apply_clients.code")
			.addField("apply_clients.name AS apply_client_name");
	},
	handleEvent(e){
		const content = document.querySelector('#formModal .modal-content');
		const range = e.currentTarget.closest('[data-range]');
		if(e.currentTarget.hasAttribute("data-create")){
			let data = this.response.select("ROW")
				.addTable("projects")
				.addField("projects.*")
				.andWhere("id=?", Number(e.currentTarget.getAttribute("data-create")))
				.leftJoin("master.managers AS managers ON projects.manager=managers.code")
				.addField("managers.name AS manager_name")
				.leftJoin("master.apply_clients AS apply_clients ON projects.apply_client=apply_clients.code")
				.addField("apply_clients.name AS apply_client_name")
				.leftJoin("master.clients AS clients ON projects.client=clients.code")
				.addField("clients.name AS delivery_destination")
				.apply();
			let detail = this.response.select("ALL")
				.addTable("projects")
				.andWhere("projects.id=?", Number(e.currentTarget.getAttribute("data-create")))
				.leftJoin("orders ON projects.code=orders.project")
				.addField("orders.*")
				.apply();
			let values = {length: detail.length};
			for(let row of detail){
				for(let k in row){
					let key = k.replace(/_[a-z]/g, function(ch){
						return ch.toUpperCase().substring(1);
					});
					if(!(key in values)){
						values[key] = [];
					}
					values[key].push(row[k]);
				}
			}
			data.detail = JSON.stringify(values);
			content.innerHTML = this.template.createForm(data, detail);
		}else{
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
			content.innerHTML = this.template.editForm(data, detail);
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
						let row = this.listItemQuery("ROW").andWhere("projects.id=?", id).apply();
						range.insertAdjacentHTML("afterend", this.template.listItem(row));
						range.parentNode.removeChild(range);
						let buttons = document.querySelectorAll(`[data-range="${id}"] [data-create],[data-range="${id}"] [data-edit]`);
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
							input.classList.add("is-invalid");
							let feedback = input.parentNode.querySelector('.invalid-feedback');
							if(feedback != null){
								feedback.textContent = messages[name];
							}
						}else{
							input.classList.remove("is-invalid");
						}
					}
				}
			});
		});
	}
});
{/literal}</script>
{/block}

{block name="body"}
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list" data-scroll-y="list">
		<thead>
			<tr>
				<th class="w-10">案件番号</th>
				<th class="w-10">件名</th>
				<th class="w-10">クライアント名</th>
				<th class="w-20">請求先名</th>
				{if $smarty.session["User.role"] ne "manager"}<th class="w-10">担当者名</th>{/if}
				<th class="w-20">備考</th>
				<th>登録</th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" constructor="sales" assign="obj"}
			<tr data-range="{$obj.id}">
				<td>{$obj.code}</td>
				<td>{$obj.subject}</td>
				<td>{$obj.client_name}</td>
				<td>{$obj.apply_client_name}</td>
				{if $smarty.session["User.role"] ne "manager"}<td>{$obj.manager_name}</td>{/if}
				<td>{$obj.note}</td>
				<td>
					<button type="button" data-{$sales.formType|predef_invoke:$obj}="{$sales.modalId|predef_invoke:$obj}" class="btn btn-sm bx bxs-edit" data-bs-toggle="modal" data-bs-target="#formModal">{$sales.modalText|predef_invoke:$obj}</button>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="formModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-form">
		<div class="modal-content">{predefine name="createForm" constructor="sales" assign=["obj", "detail"]}
			<div class="modal-header flex-row">
				<div class="text-center">売上登録</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<form action="{url action="regist"}/{$obj.code}" method="POST" class="modal-body">
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<table class="col table">
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1">案件番号</label>
								</th>
								<td>
									<div class="col-5">{$obj.code}</div>
								</td>
							</tr>
							
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1" for="salesdate-input">売上日付</label>
								</th>
								<td>
									<div class="col-5">
										<input type="date" name="accounting_date" class="form-control" id="salesdate-input" autocomplete="off" value="{$sales.date|predef_invoke:$obj.created}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1">当社担当者</label>
								</th>
								<td>
									<div class="col-md-10">{$obj.manager_name}</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="subject-input">請求書件名</label>
								</th>
								<td>
									<div class="col-10">
										<input type="text" name="subject" class="form-control" id="subject-input" autocomplete="off" value="{$obj.subject}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1" for="payment_date-input">入金予定日</label>
								</th>
								<td>
									<div class="col-5">
										<input type="date" name="payment_date" class="form-control" id="payment_date-input" autocomplete="off" value="{$obj.payment_date}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
						</table>
						<table class="col table">
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="slip_number-input">請求書パターン</label>
								</th>
								<td>
									<div class="col-6">
										<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=[]|invoiceFormat item="text" key="value"}
											<option value="{$value}">{$text}</option>
										{/foreach}</select>
										<div class="invalid-feedback"></div>
										<span class="no-edit clearfix ms-2">請求書見本はこちら</span>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1">請求先</label>
								</th>
								<td>
									<div class="col-10">{$obj.apply_client_name}</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="slip_number-input">納品先</label>
								</th>
								<td>
									<div class="col-10">
										<input type="text" name="delivery_destination" class="form-control" id="slip_number-input" autocomplete="off" value="{$obj.delivery_destination}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="note-input">備考</label>
								</th>
								<td>
									<div class="col-10">
										<textarea name="note" class="form-control" id="note-input" autocomplete="off">{$obj.note}</textarea>
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
						</table>
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
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header1" class="form-control form-control-sm" placeholder="摘要ヘッダー１" autocomplete="off" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header2" class="form-control form-control-sm" placeholder="摘要ヘッダー２" autocomplete="off" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header3" class="form-control form-control-sm" placeholder="摘要ヘッダー３" autocomplete="off" /></th>
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
									<option value="{$categories[$i].code}"{predef_repeat loop=$sales.equals|predef_invoke:$categories[$i].code:$obj.category} selected{/predef_repeat}>{$categories[$i].name}</option>
									{/predef_repeat}
								</select></td>
								<td><input type="text" name="_detail[itemName][]" class="form-control" value="{$obj.itemName}{$obj.item_name}" /></td>
								<td><input type="text" name="_detail[unit][]" class="form-control" value="{$obj.unit}" /></td>
								<td><input type="text" name="_detail[quantity][]" class="form-control" value="{$obj.quantity}" /></td>
								<td><input type="text" name="_detail[unitPrice][]" class="form-control"  value="{$obj.unitPrice}{$obj.unit_price}" /></td>
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
			{/predefine}{predefine name="editForm" constructor="sales" assign="obj"}
			<div class="modal-header flex-row">
				<div class="text-center">売上登録</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<form action="{url action="update"}/{$obj.id}" method="POST" class="modal-body">
				<div class="container border border-secondary rounded p-4 mb-5 bg-white">
					<div class="row gap-4 align-items-start">
						<table class="col table">
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1">案件番号</label>
								</th>
								<td>
									<div class="col-5">{$obj.project}</div>
								</td>
							</tr>
							
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1">伝票番号</label>
								</th>
								<td>
									<div class="col-5">{$obj.slip_number}</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1" for="salesdate-input">売上日付</label>
								</th>
								<td>
									<div class="col-5">
										<input type="date" name="accounting_date" class="form-control" id="salesdate-input" autocomplete="off" value="{$obj.accounting_date}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1">当社担当者</label>
								</th>
								<td>
									<div class="col-md-10">{$obj.manager_name}</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="subject-input">請求書件名</label>
								</th>
								<td>
									<div class="col-10">
										<input type="text" name="subject" class="form-control" id="subject-input" autocomplete="off" value="{$obj.subject}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light  align-middle ps-4">
									<label class="form-label ls-1" for="payment_date-input">入金予定日</label>
								</th>
								<td>
									<div class="col-5">
										<input type="date" name="payment_date" class="form-control" id="payment_date-input" autocomplete="off" value="{$obj.payment_date}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
						</table>
						<table class="col table">
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="slip_number-input">請求書パターン</label>
								</th>
								<td>
									<div class="col-6">
										<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=[]|invoiceFormat item="text" key="value"}
											<option value="{$value}"{predef_repeat loop=$sales.equals|predef_invoke:$value:$obj.invoice_format} selected{/predef_repeat}>{$text}</option>
										{/foreach}</select>
										<div class="invalid-feedback"></div>
										<span class="no-edit clearfix ms-2">請求書見本はこちら</span>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1">請求先</label>
								</th>
								<td>
									<div class="col-10">{$obj.apply_client_name}</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="slip_number-input">納品先</label>
								</th>
								<td>
									<div class="col-10">
										<input type="text" name="delivery_destination" class="form-control" id="slip_number-input" autocomplete="off" value="{$obj.delivery_destination}" />
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
							<tr>
								<th scope="row" class="bg-light align-middle ps-4">
									<label class="form-label ls-1" for="note-input">備考</label>
								</th>
								<td>
									<div class="col-10">
										<textarea name="note" class="form-control" id="note-input" autocomplete="off">{$obj.note}</textarea>
										<div class="invalid-feedback"></div>
									</div>
								</td>
							</tr>
						</table>
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
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header1" class="form-control form-control-sm" placeholder="摘要ヘッダー１" autocomplete="off" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header2" class="form-control form-control-sm" placeholder="摘要ヘッダー２" autocomplete="off" /></th>
								<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header3" class="form-control form-control-sm" placeholder="摘要ヘッダー３" autocomplete="off" /></th>
								<th data-visible="v2">発行部数</th>
								<th></th>
							</tr>
						</thead>
						<tfoot>
							<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
						</tfoot>
						<tbody id="detail_list">
							{predef_repeat loop=$detail.length index="i"}{predef_call name="detailForm" param=$detail[$i]}{/predef_repeat}
						</tbody>
					</table>
				</div>
			</form>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" data-bs-dismiss="modal">登録</button>
			</div>
			{/predefine}
		</div>
	</div>
</div>

{/block}