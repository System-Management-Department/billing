{block name="title"}得意先クライアント登録画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">
{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",
	success: "{url controller="Client" action="index"}",{literal}
	response: new SQLite(),
	form: null,
	detail: null,
	detailList: null,
	detailParameter: null,
	title: "得意先クライアント登録",
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
		let master;
		this.form = document.querySelector('form');
		this.detail = this.form.querySelector('[name="detail"]');
		
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
						<label class="form-label ls-1" for="code-input">得意先コード</label>
					</th>
					<td>
						<div class="col-3">
						<!-- <input type="text" name="code" class="form-control" id="code-input" autocomplete="off" /> -->
						<input type="hidden" name="code" value="" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">得意先名　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="name" class="form-control" id="name-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="kana-input">得意先名カナ　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="kana" class="form-control" id="kana-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="short_name-input">得意先名称略　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="short_name" class="form-control" id="short_name-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_zip-input">郵便番号　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-3">
							<input type="text" name="location_zip" class="form-control" id="location_zip-input" autocomplete="off" />
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
								<option value="{$value}">{$text}</option>
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
							<input type="text" name="location_address2" class="form-control" id="location_address2-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address3-input">建物名</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="location_address3" class="form-control" id="location_address3-input" autocomplete="off" />
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
							<input type="text" name="phone" class="form-control" id="phone-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="fax-input">FAX</label>
					</th>
					<td>
						<div class="col-5">
							<input type="text" name="fax" class="form-control" id="fax-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="email-input">メールアドレス</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="email" class="form-control" id="email-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="homepage-input">ホームページ</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="homepage" class="form-control" id="homepage-input" autocomplete="off" />
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
						<label class="form-label ls-1" for="transactee-input">得意先担当者</label>
					</th>
					<td>
						<div class="col-10">
						<input type="text" name="transactee" class="form-control" id="transactee-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="transactee_honorific-input">担当者敬称</label>
					</th>
					<td>
						<div class="col-4">
							<input type="text" name="transactee_honorific" class="form-control" id="transactee_honorific-input" autocomplete="off" value="様" />
						</div>
					</td>
				</tr>
				<tr>
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
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="tax_round-input">税端数処理　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<select name="tax_round" id="tax_round-input" class="form-select">{foreach from=["" => "選択"]|taxRound item="text" key="value"}
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
								<option value="{$value}">{$text}</option>
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
						<input type="text" name="receivables_balance" class="form-control" id="receivables_balance-input" autocomplete="off" />
						</div>
					</td>
				</tr>
				<!-- <tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_lat_lng-input">緯度経度</label>
					</th>
					<td>
						<div class="col-10">
						<input type="text" name="location_lat_lng" class="form-control" id="location_lat_lng-input" autocomplete="off" />
						</div>
					</td>
				</tr> -->
				<input type="hidden" name="location_lat_lng" value="" />
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="remarks-input">備考</label>
					</th>
					<td>
						<div class="col-10">
							<textarea name="remarks" class="form-control" id="remarks-input" autocomplete="off"></textarea>
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

{block name="scripts" append}
<script type="text/javascript">
	function loadFinished(){
		var select = document.getElementById("prefectures_list-input");
		select.options[13].selected = true;
	}

	window.onload = loadFinished;
</script>
{/block}