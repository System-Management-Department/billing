{block name="title"}売上データ登録画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
<style type="text/css">{literal}
body [data-visible]{
	display: none;
}
body:has(input[name="invoice_format"][value="2"]) [data-visible="v2"],
body:has(input[name="invoice_format"][value="3"]) [data-visible="v3"]{
	display: table-cell;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	success: "{url action="index"}",{literal}
	form: null,
	detail: null,
	detailList: null,
	title: "売上データ登録",
	template: null,
	
	/**
	 * 状態を監視
	 */
	*[Symbol.iterator](){
		let obj = {next: "init", args: []};
		while(obj.next != null){
			obj = yield* this[obj.next](...obj.args);
		}
	},
	
	/**
	 * 初期化
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*init(){
		this.strage = yield* Flow.waitDbUnlock();
		
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
		datalist = document.getElementById("team");
		mastarData = Flow.Master.select("ALL")
			.addTable("teams")
			.addField("code,name")
			.apply();
		for(let team of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: team.name});
			option.setAttribute("value", team.code);
			datalist.appendChild(option);
		}
		mastarData = Flow.Master.select("ALL")
			.addTable("categories")
			.addField("code,name")
			.apply();
		this.template = new Template(mastarData);
		
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
		
		
		this.form = document.querySelector('form');
		this.detail = this.form.querySelector('[name="detail"]');
		this.detailList = document.getElementById("list");
		let detailData = JSON.parse(this.detail.value);
		let detailKeys = Object.keys(detailData).filter(k => Array.isArray(detailData[k]));
		for(let i = 0; i < detailData.length; i++){
			let tempRowData = {};
			for(let key of detailKeys){
				tempRowData[key] = detailData[key][i];
			}
			this.detailList.insertAdjacentHTML("beforeend",this.template.listItem(tempRowData));
		}
		let checked = this.detailList.querySelectorAll('select:has(optgroup[data-value])');
		for(let i = checked.length - 1; i >= 0; i--){
			let optgroup = checked[i].querySelector('optgroup[data-value]');
			checked[i].removeChild(optgroup);
			checked[i].value = optgroup.getAttribute("data-value");
		}
		
		return {next: "input", args: []};
	},
	
	/**
	 * 入力待ち
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*input(){
		let pObj = {};
		let controller = new AbortController();
		
		// イベントを設定
		this.form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			// 次の状態 フォーム送信
			pObj.resolve({next: "submit", args: [new FormData(this.form)]});
		}, {signal: controller.signal});
		document.getElementById("add_detail_row").addEventListener("click", e => {
			this.detailList.insertAdjacentHTML("beforeend",this.template.listItem({}));
			let checked = this.detailList.querySelectorAll('select:has(optgroup[data-value])');
			for(let i = checked.length - 1; i >= 0; i--){
				let optgroup = checked[i].querySelector('optgroup[data-value]');
				checked[i].removeChild(optgroup);
				checked[i].value = optgroup.getAttribute("data-value");
			}
		}, {signal: controller.signal});
		this.detailList.addEventListener("change", e => {
			let checked = this.detailList.querySelectorAll('tr:has([data-form-remove]:checked)');
			for(let i = checked.length - 1; i >= 0; i--){
				this.detailList.removeChild(checked[i]);
			}
			let tr = this.detailList.querySelectorAll('tr');
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
			this.form.querySelector('input[name="detail"]').value = JSON.stringify(data);
			this.form.querySelector('input[name="sales_tax"]').value = total * 0.1;
			
		}, {useCapture: true, signal: controller.signal});
		
		
		// フォームを有効化
		let fieldset = Object.assign(this.form.querySelector("fieldset"), {disabled: false});
		
		// 入力があるまで待つ
		let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		
		// 設定したイベントを一括削除
		controller.abort();
		
		// フォームを無効化
		fieldset.disabled = true;
		return res;
	},
	
	/**
	 * フォーム送信
	 * @param formData 送信するFormData
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submit(formData){
		let response = yield fetch(this.form.getAttribute("action"), {
			method: this.form.getAttribute("method"),
			body: formData
		}).then(res => res.json());
		if(response.success){
			// フォーム送信 成功
			return yield* this.submitThen(response);
		}
		// フォーム送信 失敗
		return yield* this.submitCatch(response);
	},
	
	/**
	 * フォーム送信 成功
	 * @param response レスポンス
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submitThen(response){
		// メッセージをpushしてリダイレクト
		for(let message of response.messages){
			Flow.DB.insertSet("messages", {title: this.title, message: message[0], type: message[1], name: message[2]}, {}).apply();
		}
		Flow.DB.commit().then(res => { location.href = this.success; });
		
		// 次の状態 入力待ち
		return {next: "input", args: []};
	},
	
	/**
	 * フォーム送信 失敗
	 * @param response レスポンス
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submitCatch(response){
		// エラーメッセージをオブジェクトへ変更
		let messages = response.messages.reduce((a, message) => {
			if(message[1] == 2){
				a[message[2]] = message[0];
			}
			return a;
		}, {});
		
		// エラーメッセージの表示切替
		let inputs = this.form.querySelectorAll('[name],[data-form-name]');
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
		
		// 次の状態 入力待ち
		return {next: "input", args: []};
	}
});
{/literal}</script>
{/block}


{block name="body"}
<form action="{url action="update" id=$data.id}" method="POST" class="form-grid-12"><fieldset disabled>
	<datalist id="division"><option value="">選択</option></datalist>
	<datalist id="team"><option value="">選択</option></datalist>
	<datalist id="invoice_format">{foreach from=["" => "選択"]|invoiceFormat item="text" key="value"}
		<option value="{$value}">{$text}</option>
	{/foreach}</datalist>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<div class="d-table col table">
				<row-form label="伝票番号" col="3">{$data.slip_number|escape:"html"}</row-form>
				<row-form label="売上日付" col="5" name="accounting_date" type="date" require>{$data.accounting_date|escape:"html"}</row-form>
				<row-form label="部門" col="10" name="division" type="select" list="division" require>{$data.division|escape:"html"}</row-form>
				{* <row-form label="チーム" col="10" name="team" type="select" list="team">{$data.team|escape:"html"}</row-form> *}
				<row-form label="当社担当者" col="10" name="manager" placeholder="担当者名・担当者CDで検索" require>{$data.manager|escape:"html"}</row-form>
				<row-form label="請求書件名" col="10" name="subject" type="text" require>{$data.subject|escape:"html"}</row-form>
				<row-form label="入金予定日" col="5" name="payment_date" type="date" require>{$data.payment_date|escape:"html"}</row-form>
			</div>
			<div class="d-table col table">
				<row-form label="請求書パターン" col="6" name="invoice_format" type="select" list="invoice_format" require>{$data.invoice_format|escape:"html"}<span slot="content" class="no-edit clearfix ms-2">請求書見本はこちら</span></row-form>
				<row-form label="請求先" col="10" name="billing_destination" placeholder="請求先CD、会社名で検索" require>{$data.billing_destination|escape:"html"}</row-form>
				<row-form label="納品先" col="10" name="delivery_destination" type="text" require>{$data.delivery_destination|escape:"html"}</row-form>
				<row-form label="備考" col="10" name="note" type="textarea">{$data.note|escape:"html"}</row-form>
			</div>
		</div>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
		<input type="hidden" name="detail" value="{$data.detail|escape:"html"}" />
		<input type="hidden" name="sales_tax" value="{$data.sales_tax|escape:"html"}" />
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
					<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header1" class="form-control form-control-sm" placeholder="摘要ヘッダー１" autocomplete="off" value="{$data.header1|escape:"html"}" /></th>
					<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header2" class="form-control form-control-sm" placeholder="摘要ヘッダー２" autocomplete="off" value="{$data.header2|escape:"html"}" /></th>
					<th class="py-0 align-middle" data-visible="v3"><input type="text" name="header3" class="form-control form-control-sm" placeholder="摘要ヘッダー３" autocomplete="off" value="{$data.header3|escape:"html"}" /></th>
					<th data-visible="v2">発行部数</th>
					<th></th>
				</tr>
			</thead>
			<tfoot>
				<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
			</tfoot>
			<tbody id="list">{predefine name="listItem" constructor="categories" assign="obj"}
				<tr>
					<td class="table-group-row-no align-middle"></td>
					<td><select name="_detail[categoryCode][]" class="form-select">
						<option value="">選択</option>
						{predef_repeat loop=$categories.length index="i"}
						<option value="{$categories[$i].code}">{$categories[$i].name}</option>
						{/predef_repeat}
						<optgroup data-value="{$obj.categoryCode}"></optgroup>
					</select></td>
					<td><input type="text" name="_detail[itemName][]" class="form-control" value="{$obj.itemName}" /></td>
					<td><input type="text" name="_detail[unit][]" class="form-control" value="{$obj.unit}" /></td>
					<td><input type="text" name="_detail[quantity][]" class="form-control" value="{$obj.quantity}" /></td>
					<td><input type="text" name="_detail[unitPrice][]" class="form-control" value="{$obj.unitPrice}" /></td>
					<td><input type="text" name="_detail[amount][]" class="form-control" value="{$obj.amount}" /></td>
					<td data-visible="v3"><input type="text" name="_detail[data1][]" class="form-control" value="{$obj.data1}" /></td>
					<td data-visible="v3"><input type="text" name="_detail[data2][]" class="form-control" value="{$obj.data2}" /></td>
					<td data-visible="v3"><input type="text" name="_detail[data3][]" class="form-control" value="{$obj.data3}" /></td>
					<td data-visible="v2"><input type="text" name="_detail[circulation][]" class="form-control" value="{$obj.circulation}" /></td>
					<td><label class="btn bi bi-trash3"><input type="checkbox" data-form-remove="" class="d-contents" /></label></td>
				</tr>
			{/predefine}</tbody>
		</table>
	</div>
	<div class="grid-colspan-12 text-center">
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex"><div class="flex-grow-1"></div>登録・更新<div class="flex-grow-1"></div></button>
	</div>
</fieldset></form>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="managerModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">当社担当者選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
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
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">請求先選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
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
{/block}