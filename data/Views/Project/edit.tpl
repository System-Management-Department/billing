{block name="title"}案件データ登録画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	success: "{url action="index"}",{literal}
	response: null,
	form: null,
	categories: null,
	title: "案件データ登録",
	template: null,
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
		this.response = Flow.Master;
		let master, checked;
		this.form = document.querySelector('form');
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
		/*
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
		*/
		
		checked = this.form.querySelector('[name="manager"]');
		master = this.response.select("ALL").setTable("managers").apply();
		for(let row of master){
			if(checked.value == row.code){
				this.form.querySelector('[data-form-label="manager"]').textContent = `${row.name}`;
			}
			this.modalList1.insertAdjacentHTML("beforeend",this.template.managerList(row));
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
			this.modalList2.insertAdjacentHTML("beforeend",this.template.applyClientList(row));
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
				this.modalList1.insertAdjacentHTML("beforeend",this.template.managerList(row));
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
				this.modalList2.insertAdjacentHTML("beforeend",this.template.applyClientList(row));
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
				let feedback = input.parentNode.querySelector('.invalid-feedback');
				if(feedback != null){
					feedback.textContent = messages[name];
				}
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

<form action="{url action="update" id=$data.id}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="code-input">案件番号</label>
					</th>
					<td>
						<div class="col-3">
						{$data.code|escape:"html"}
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
								<input type="search" data-form-name="manager" class="form-control" id="manager-input" placeholder="担当者名・担当者CDで検索" value="{$ingest.manager|escape:"html"}" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#managerModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result" data-form-name="manager">
								<div class="form-control" data-form-label="manager"></div>
								<input type="hidden" name="manager" value="{$data.manager|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="manager">取 消</button>
							</div>
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="division-input">確度</label>
					</th>
					<td>
						<div class="col-md-10">
							<select name="division" id="division-input" class="form-select">
								<option value="">選択</option>
								<option value="{$data.confidence|escape:"html"}" selected></option>
							</select>
							<div class="invalid-feedback"></div>
							{$ingest.confidence|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="billing_month-input">請求月</label>
					</th>
					<td>
						<div class="col-5">
							<input type="month" name="billing_month" class="form-control" id="billing_month-input" autocomplete="off" value="{$data.billing_month|escape:"html"}" />
							<div class="invalid-feedback"></div>
							{$ingest.billing_month|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="client-input">クライアント</label>
					</th>
					<td>
						<div class="col-10" data-form-output="container">
							<div class="input-group" data-form-output="form">
								<input type="search" data-form-name="client" class="form-control" id="client-input" placeholder="得意先CD、会社名で検索" value="{$ingest.client|escape:"html"}" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#clientModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result" data-form-name="client">
								<div class="form-control" data-form-label="client"></div>
								<input type="hidden" name="client" value="{$data.client|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="client">取 消</button>
							</div>
							<div class="invalid-feedback"></div>
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
								<input type="search" data-form-name="apply_client" class="form-control" id="applyClient-input" placeholder="請求先CD、会社名で検索" value="{$ingest.apply_client|escape:"html"}" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#applyClientModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result" data-form-name="apply_client">
								<div class="form-control" data-form-label="apply_client"></div>
								<input type="hidden" name="apply_client" value="{$data.apply_client|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="apply_client">取 消</button>
							</div>
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="invoice_delivery-input">請求書発送</label>
					</th>
					<td>
						<div class="col-5">
							<input type="text" name="invoice_delivery" class="form-control" id="invoice_delivery-input" autocomplete="off" value="{$data.invoice_delivery|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="payment_date-input">入金日</label>
					</th>
					<td>
						<div class="col-5">
							<input type="date" name="payment_date" class="form-control" id="payment_date-input" autocomplete="off" value="{$data.payment_date|escape:"html"}" />
							<div class="invalid-feedback"></div>
							{$ingest.payment_date|escape:"html"}
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
							<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=["" => "選択"]|invoiceFormat item="text" key="value"}
								<option value="{$value}"{if $data.invoice_format eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
							<div class="invalid-feedback"></div>
							<span class="no-edit clearfix ms-2">請求書見本はこちら</span>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="header1-input">摘要ヘッダー１</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="header1" class="form-control" id="header1-input" autocomplete="off" value="{$data.header1|escape:"html"}" />
							<div class="invalid-feedback"></div>
							{$ingest.header1|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="header2-input">摘要ヘッダー２</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="header2" class="form-control" id="header2-input" autocomplete="off" value="{$data.header2|escape:"html"}" />
							<div class="invalid-feedback"></div>
							{$ingest.header2|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light  align-middle ps-4">
						<label class="form-label ls-1" for="header3-input">摘要ヘッダー３</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="header3" class="form-control" id="header3-input" autocomplete="off" value="{$data.header3|escape:"html"}" />
							<div class="invalid-feedback"></div>
							{$ingest.header3|escape:"html"}
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
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div class="grid-colspan-12 text-center">
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex"><div class="flex-grow-1"></div>登録・更新<div class="flex-grow-1"></div></button>
	</div>
</fieldset></form>
{/block}