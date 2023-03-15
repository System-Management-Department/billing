{block name="title"}請求先（納品先）編集画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">
{call name="clientList"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",
	success: "{url controller="ApplyClient" action="index"}",{literal}
	response: new SQLite(),
	form: null,
	detail: null,
	detailList: null,
	detailParameter: null,
	title: "請求先（納品先）編集",
	template2: new clientList(),
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
		this.response.import(buffer, "list");
		let master, checked;;
		this.form = document.querySelector('form');
		this.modalList2 = document.querySelector('#clientModal tbody');

		checked = this.form.querySelector('[name="client"]');
		master = this.response.select("ALL")
			.setTable("clients")
			.addField("clients.*")
			.apply();
		for(let row of master){
			if(checked.value == row.code){
				this.form.querySelector('[data-form-label="client"]').textContent = `${row.name}`;
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
		document.getElementById("client-input").addEventListener("change", e => {
			let table = this.response.select("ALL")
				.setTable("clients")
				.addField("clients.*")
				.orWhere("clients.name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("clients.short_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("clients.code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			this.modalList2.innerHTML = "";
			for(let row of table){
				this.template2.insertBeforeEnd(this.modalList2, row);
			}
		}, {signal: controller.signal});
		this.modalList2.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				this.form.querySelector('input[name="client"]').value = e.target.getAttribute("data-search-modal-value");
				this.form.querySelector('[data-form-label="client"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true, signal: controller.signal});
		document.querySelector('[data-form-output-reset="client"]').addEventListener("click", e => {
			this.form.querySelector('input[name="client"]').value = "";
			this.form.querySelector('[data-form-label="client"]').textContent = "";
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
<form action="{url action="update" id=$data.code}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="code-input">請求先コード</label>
					</th>
					<td>
						<div class="col-3">
						{$data.code|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="client-input">得意先　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10" data-form-output="container">
							<div class="input-group" data-form-output="form">
								<input type="search" data-form-name="client" class="form-control" id="client-input" placeholder="得意先CD、得意先名で検索" />
								<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#clientModal">検 索</button>
							</div>
							<div class="input-group" data-form-output="result">
								<div class="form-control" data-form-label="client"></div>
								<input type="hidden" name="client" value="{$data.client|escape:"html"}" />
								<button type="button" class="btn btn-danger" data-form-output-reset="client">取 消</button>
							</div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">請求先名　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="name" class="form-control" id="name-input" autocomplete="off" value="{$data.name|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="kana-input">請求先名カナ　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="kana" class="form-control" id="kana-input" autocomplete="off" value="{$data.kana|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="short_name-input">請求先名称略　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="short_name" class="form-control" id="short_name-input" autocomplete="off" value="{$data.short_name|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_zip-input">郵便番号　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-3">
							<input type="text" name="location_zip" class="form-control" id="location_zip-input" autocomplete="off" value="{$data.location_zip|escape:"html"}" />
						</div>
						<span class="no-edit clearfix ms-2">ハイフン無しで入力</span>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address1-input">都道府県　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="location_address1" id="prefectures_list-input" class="form-select">{foreach from=["" => "選択"]|prefectures item="text" key="value"}
								<option value="{$value}"{if $data.location_address1 eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address2-input">市区町村・番地　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="location_address2" class="form-control" id="location_address2-input" autocomplete="off" value="{$data.location_address2|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address3-input">建物名</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="location_address3" class="form-control" id="location_address3-input" autocomplete="off" value="{$data.location_address3|escape:"html"}" />
						</div>
					</td>
				</tr>
			</table>

			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="phone-input">電話番号</label>
					</th>
					<td>
						<div class="col-5">
							<input type="text" name="phone" class="form-control" id="phone-input" autocomplete="off" value="{$data.phone|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="fax-input">FAX</label>
					</th>
					<td>
						<div class="col-5">
							<input type="text" name="fax" class="form-control" id="fax-input" autocomplete="off" value="{$data.fax|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="email-input">メールアドレス</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="email" class="form-control" id="email-input" autocomplete="off" value="{$data.email|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="homepage-input">ホームページ</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="homepage" class="form-control" id="homepage-input" autocomplete="off" value="{$data.homepage|escape:"html"}" />
						</div>
					</td>
				</tr>
			</table>
		</div>
	</div>

	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="transactee-input">請求先担当者</label>
					</th>
					<td>
						<div class="col-10">
						<input type="text" name="transactee" class="form-control" id="transactee-input" autocomplete="off" value="{$data.transactee|escape:"html"}" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="transactee_honorific-input">担当者敬称</label>
					</th>
					<td>
						<div class="col-4">
							<input type="text" name="transactee_honorific" class="form-control" id="transactee_honorific-input" autocomplete="off" value="{$data.transactee_honorific|escape:"html"}" />
						</div>
					</td>
				</tr>
				<!-- <tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="department-input">部署名</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="department" class="form-control" id="department-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="managerial_position-input">役職名</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="managerial_position" class="form-control" id="managerial_position-input" autocomplete="off" />
						</div>
					</td>
				</tr> -->
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="invoice_format-input">請求書パターン　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=["" => "選択"]|invoiceFormat item="text" key="value"}
								<option value="{$value}"{if $data.invoice_format eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="tax_round-input">税端数処理　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="tax_round" id="tax_round-input" class="form-select">{foreach from=["" => "選択"]|taxRound item="text" key="value"}
								<option value="{$value}"{if $data.tax_round eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="tax_processing-input">税処理　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="tax_processing" id="tax_processing-input" class="form-select">{foreach from=["" => "選択"]|taxProcessing item="text" key="value"}
								<option value="{$value}"{if $data.tax_processing eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="close_processing-input">請求方法　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="close_processing" id="close_processing-input" class="form-select">{foreach from=["" => "選択"]|closeProcessing item="text" key="value"}
								<option value="{$value}"{if $data.close_processing eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="close_date-input">締日指定（28日以降は末日を選択）　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="close_date" id="close_date-input" class="form-select">{foreach from=["99" => "末日"]|closeDate item="text" key="value"}
								<option value="{$value}"{if $data.close_date eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="payment_cycle-input">入金サイクル （◯ヶ月後）　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="payment_cycle" id="payment_cycle-input" class="form-select">{foreach from=["" => "選択"]|monthList item="text" key="value"}
								<option value="{$value}"{if $data.payment_cycle eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="payment_date-input">入金予定日（28日以降は末日を選択）　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="payment_date" id="payment_date-input" class="form-select">{foreach from=["99" => "末日"]|closeDate item="text" key="value"}
								<option value="{$value}"{if $data.payment_date eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
			</table>

			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="unit_price_type-input">単価種別</label>
					</th>
					<td>
						<div class="col-6">
							<select name="unit_price_type" id="unitPriceType-input" class="form-select">{foreach from=["0" => "選択"]|unitPriceType item="text" key="value"}
								<option value="{$value}"{if $data.unit_price_type eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="salse_with_ruled_lines-input">売上伝票種別</label>
					</th>
					<td>
						<div class="col-6">
							<select name="salse_with_ruled_lines" id="salse_with_ruled_lines-input" class="form-select">{foreach from=["0" => "選択"]|existence item="text" key="value"}
								<option value="{$value}"{if $data.salse_with_ruled_lines eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="delivery_with_ruled_lines-input">納品書種別</label>
					</th>
					<td>
						<div class="col-6">
							<select name="delivery_with_ruled_lines" id="delivery_with_ruled_lines-input" class="form-select">{foreach from=["0" => "選択"]|existence item="text" key="value"}
								<option value="{$value}"{if $data.delivery_with_ruled_lines eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="receipt_with_ruled_lines-input">受領書種別</label>
					</th>
					<td>
						<div class="col-6">
							<select name="receipt_with_ruled_lines" id="receipt_with_ruled_lines-input" class="form-select">{foreach from=["0" => "選択"]|existence item="text" key="value"}
								<option value="{$value}"{if $data.receipt_with_ruled_lines eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="invoice_with_ruled_lines-input">請求書種別</label>
					</th>
					<td>
						<div class="col-6">
							<select name="invoice_with_ruled_lines" id="invoice_with_ruled_lines-input" class="form-select">{foreach from=["0" => "選択"]|existence item="text" key="value"}
								<option value="{$value}"{if $data.invoice_with_ruled_lines eq $value} selected{/if}>{$text}</option>
							{/foreach}</select>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="receivables_balance-input">期首売掛残高</label>
					</th>
					<td>
						<div class="col-10">
						<input type="text" name="receivables_balance" class="form-control" id="receivables_balance-input" autocomplete="off" value="{$data.receivables_balance|escape:"html"}" />
						</div>
					</td>
				</tr>
				<!-- <tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_lat_lng-input">緯度経度</label>
					</th>
					<td>
						<div class="col-10">
						<input type="text" name="location_lat_lng" class="form-control" id="location_lat_lng-input" autocomplete="off" value="{$data.location_lat_lng|escape:"html"}" />
						</div>
					</td>
				</tr> -->
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="note-input">備考</label>
					</th>
					<td>
						<div class="col-10">
							<textarea name="note" class="form-control" id="note-input" autocomplete="off" >{$data.note|escape:"html"}</textarea>
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

{block name="dialogs" append}
<div class="modal fade" id="clientModal" tabindex="-1">
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
							<th>カナ</th>
							<th></th>
						</tr>
					</thead>
					<tbody>
						{function name="clientList"}{template_class name="clientList" assign="obj" iterators=[]}{strip}
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
{/block}
