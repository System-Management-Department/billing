{block name="title"}売上データ登録画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">
{call name="ListItem"}
{call name="ManagerList"}
{call name="ApplyClientList"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",{literal}
	response: new SQLite(),
	form: null,
	detail: null,
	detailList: null,
	categories: null,
	title: "売上データ登録",
	template: new ListItem(),
	template1: new ManagerList(),
	template2: new ApplyClientList(),
	modalList1: null,
	modalList2: null,
	
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
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");;
		let master, checked;
		this.form = document.querySelector('form');
		this.detail = this.form.querySelector('[name="detail"]');
		this.detailList = document.getElementById("list");
		this.modalList1 = document.querySelector('#managerModal tbody');
		this.modalList2 = document.querySelector('#applyClientModal tbody');
		const division = this.form.querySelector('[name="division"]');
		const team = this.form.querySelector('[name="team"]')
		
		checked = division.querySelector('option:checked');
		master = this.response.select("ALL").setTable("divisions").apply();
		for(let row of master){
			let option = Object.assign(((checked != null) && (checked.value == row.code)) ? checked : document.createElement("option"), {textContent: row.name});
			if(checked == option){
				checked = null;
			}else{
				option.setAttribute("value", row.code);
			}
			division.appendChild(option);
		}
		if(checked != null){
			division.removeChild(checked);
			division.value = "";
		}
		checked = team.querySelector('option:checked');
		master = this.response.select("ALL").setTable("teams").apply();
		for(let row of master){
			let option = Object.assign(((checked != null) && (checked.value == row.code)) ? checked : document.createElement("option"), {textContent: row.name});
			if(checked == option){
				checked = null;
			}else{
				option.setAttribute("value", row.code);
			}
			team.appendChild(option);
		}
		if(checked != null){
			team.removeChild(checked);
			team.value = "";
		}
		
		this.categories = this.response.select("ALL").setTable("categories").apply();
		let detailData = JSON.parse(this.detail.value);
		let detailKeys = Object.keys(detailData).filter(k => Array.isArray(detailData[k]));
		for(let i = 0; i < detailData.length; i++){
			let tempRowData = {};
			for(let key of detailKeys){
				tempRowData[key] = detailData[key][i];
			}
			this.template.insertBeforeEnd(this.detailList, this.categories, tempRowData);
		}
		checked = this.detailList.querySelectorAll('select:has(optgroup[data-value])');
		for(let i = checked.length - 1; i >= 0; i--){
			let optgroup = checked[i].querySelector('optgroup[data-value]');
			checked[i].removeChild(optgroup);
			checked[i].value = optgroup.getAttribute("data-value");
		}
		
		checked = this.form.querySelector('[name="manager"]');
		master = this.response.select("ALL")
			.setTable("managers")
			.apply();
		for(let row of master){
			if(checked.value == row.code){
				this.form.querySelector('[data-form-label="manager"]').textContent = `${row.name}`;
			}
			this.template1.insertBeforeEnd(this.modalList1, row);
		}
		checked = this.form.querySelector('[name="billing_destination"]');
		master = this.response.select("ALL")
			.setTable("apply_clients")
			.addField("apply_clients.*")
			.leftJoin("clients on apply_clients.client=clients.code")
			.addField("clients.name as client_name")
			.apply();
		for(let row of master){
			if(checked.value == row.code){
				this.form.querySelector('[data-form-label="billing_destination"]').textContent = `${row.name}`;
			}
			this.template2.insertBeforeEnd(this.modalList2, row);
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
		document.getElementById("manager-input").addEventListener("change", e => {
			let table = this.response.select("ALL")
				.setTable("managers")
				.orWhere("name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			this.modalList1.innerHTML = "";
			for(let row of table){
				this.template1.insertBeforeEnd(this.modalList1, row);
			}
		}, {signal: controller.signal});
		document.getElementById("applyClient-input").addEventListener("change", e => {
			let table = this.response.select("ALL")
				.setTable("apply_clients")
				.addField("apply_clients.*")
				.leftJoin("clients on apply_clients.client=clients.code")
				.addField("clients.name as client_name")
				.orWhere("apply_clients.name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.unique_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.short_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			this.modalList2.innerHTML = "";
			for(let row of table){
				this.template2.insertBeforeEnd(this.modalList2, row);
			}
		}, {signal: controller.signal});
		this.modalList1.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				this.form.querySelector('input[name="manager"]').value = e.target.getAttribute("data-search-modal-value");
				this.form.querySelector('[data-form-label="manager"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true, signal: controller.signal});
		this.modalList2.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				this.form.querySelector('input[name="billing_destination"]').value = e.target.getAttribute("data-search-modal-value");
				this.form.querySelector('[data-form-label="billing_destination"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true, signal: controller.signal});
		document.querySelector('[data-form-output-reset="manager"]').addEventListener("click", e => {
			this.form.querySelector('input[name="manager"]').value = "";
			this.form.querySelector('[data-form-label="manager"]').textContent = "";
		}, {signal: controller.signal});
		document.querySelector('[data-form-output-reset="billing_destination"]').addEventListener("click", e => {
			this.form.querySelector('input[name="billing_destination"]').value = "";
			this.form.querySelector('[data-form-label="billing_destination"]').textContent = "";
		}, {signal: controller.signal});
		document.getElementById("add_detail_row").addEventListener("click", e => {
			this.template.insertBeforeEnd(this.detailList, this.categories, {});
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
				input.classList.add("is-invalid");
				//input.parentNode.querySelector('.invalid-feedback').textContent = messages[name];
			}else{
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
<form action="{url action="regist"}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="slip_number-input">伝票番号</label>
					</th>
					<td>
						<div class="col-3">
						<input type="text" name="slip_number" class="form-control" id="slip_number-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="salesdate-input">売上日付</label>
					</th>
					<td>
						<div class="col-5">
						<input type="date" name="accounting_date" class="form-control" id="salesdate-input" autocomplete="off" value="{$data.accounting_date|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="division-input">部門</label>
					</th>
					<td>
						<div class="col-md-10">
							<select name="division" id="division-input" class="form-select">
								<option value="">選択</option>
								<option value="{$data.division|escape:"html"}" selected></option>
							</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="team-input">チーム</label>
					</th>
					<td>
						<div class="col-md-10">
							<select name="team" id="team-input" class="form-select">
								<option value="">選択</option>
								<option value="{$data.team|escape:"html"}" selected></option>
							</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="manager-input">当社担当者</label>
					</th>
					<td>
						<div class="col-md-10" data-form-output="container">
							<div class="input-group" data-form-output="form">
								<input type="search" data-form-name="manager" class="form-control" id="manager-input" placeholder="担当者名・担当者CDで検索" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#managerModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result">
								<div class="form-control" data-form-label="manager"></div>
								<input type="hidden" name="manager" value="{$data.manager|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="manager">取 消</button>
							</div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="subject-input">請求書件名</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="subject" class="form-control" id="subject-input" autocomplete="off" value="{$data.subject|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="payment_date-input">入金予定日</label>
					</th>
					<td>
						<div class="col-5">
						<input type="date" name="payment_date" class="form-control" id="payment_date-input" autocomplete="off" value="{$data.payment_date|escape:"html"}" />
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
							<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=["" => "選択"]|invoiceFormat item="text" key="value"}
								<option value="{$value}"{if $data.invoice_format eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
							<span class="no-edit clearfix ms-2">請求書見本はこちら</span>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="slip_number-input">請求先</label>
					</th>
					<td>
						<div class="col-10" data-form-output="container">
							<div class="input-group" data-form-output="form">
								<input type="search" data-form-name="billing_destination" class="form-control" id="applyClient-input" placeholder="請求先CD、会社名で検索" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#applyClientModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result">
								<div class="form-control" data-form-label="billing_destination">****</div>
								<input type="hidden" name="billing_destination" value="{$data.billing_destination|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="billing_destination">取 消</button>
							</div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="slip_number-input">納品先</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="delivery_destination" class="form-control" id="slip_number-input" autocomplete="off" value="{$data.delivery_destination|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="note-input">備考</label>
					</th>
					<td>
						<div class="col-10">
							<textarea name="note" class="form-control" id="note-input" autocomplete="off">{$data.note|escape:"html"}</textarea>
						</div>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive">
		<input type="hidden" name="detail" value="{$data.detail|escape:"html"}" />
		<input type="hidden" name="sales_tax" value="{-$data.sales_tax|escape:"html"}" />
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
					<th class="py-0 align-middle"><input type="text" name="header1" class="form-control form-control-sm" placeholder="摘要ヘッダー１" autocomplete="off" value="{$data.header1|escape:"html"}" /></th>
					<th class="py-0 align-middle"><input type="text" name="header2" class="form-control form-control-sm" placeholder="摘要ヘッダー２" autocomplete="off" value="{$data.header2|escape:"html"}" /></th>
					<th class="py-0 align-middle"><input type="text" name="header3" class="form-control form-control-sm" placeholder="摘要ヘッダー３" autocomplete="off" value="{$data.header3|escape:"html"}" /></th>
					<th>発行部数</th>
					<th></th>
				</tr>
			</thead>
			<tfoot>
				<tr><th colspan="12"><button type="button" class="btn btn-primary bx bxs-message-add" id="add_detail_row">明細行を追加</button></th></tr>
			</tfoot>
			<tbody id="list">
			{function name="ListItem"}{template_class name="ListItem" assign=["categories", "obj"] iterators=["i"]}{strip}
				<tr>
					<td class="table-group-row-no align-middle"></td>
					<td><select name="_detail[categoryCode][]" class="form-select">
						<option value="">選択</option>
						{$categories->beginRepeat($categories.length, "i")}
						<option value="{$categories[$i].code}">{$categories[$i].name}</option>
						{$categories->endRepeat()}
						<optgroup data-value="{$obj.categoryCode}"></optgroup>
					</select></td>
					<td><input type="text" name="_detail[itemName][]" class="form-control" value="{$obj.itemName}" /></td>
					<td><input type="text" name="_detail[unit][]" class="form-control" value="{$obj.unit}" /></td>
					<td><input type="text" name="_detail[quantity][]" class="form-control" value="{$obj.quantity}" /></td>
					<td><input type="text" name="_detail[unitPrice][]" class="form-control" value="{$obj.unitPrice}" /></td>
					<td><input type="text" name="_detail[amount][]" class="form-control" value="{$obj.amount}" /></td>
					<td><input type="text" name="_detail[data1][]" class="form-control" value="{$obj.data1}" /></td>
					<td><input type="text" name="_detail[data2][]" class="form-control" value="{$obj.data2}" /></td>
					<td><input type="text" name="_detail[data3][]" class="form-control" value="{$obj.data3}" /></td>
					<td><input type="text" name="_detail[circulation][]" class="form-control" value="{$obj.circulation}" /></td>
					<td><label class="btn bi bi-trash3"><input type="checkbox" data-form-remove="" class="d-contents" /></label></td>
				</tr>
			{/strip}{/template_class}{/function}
			</tbody>
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
					<tbody>
						{function name="ManagerList"}{template_class name="ManagerList" assign="obj" iterators=[]}{strip}
						<tr>
							<td>{$obj.code}</td>
							<td>{$obj.name}</td>
							<td>{$obj.kana}</td>
							<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
						</tr>
						{/strip}{/template_class}{/function}
					</tbody>
				</table>
			</div>
		</div>
	</div>
</div>
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered">
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
					<tbody>
						{function name="ApplyClientList"}{template_class name="ApplyClientList" assign="obj" iterators=[]}{strip}
						<tr>
							<td>{$obj.code}</td>
							<td>{$obj.client_name}</td>
							<td>{$obj.name}</td>
							<td>{$obj.kana}</td>
							<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
						</tr>
						{/strip}{/template_class}{/function}
					</tbody>
				</table>
			</div>
		</div>
	</div>
</div>
{/block}