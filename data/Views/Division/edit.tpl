{block name="title"}部門編集画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",
	success: "{url action="index"}",{literal}
	response: new SQLite(),
	form: null,
	detail: null,
	detailList: null,
	detailParameter: null,
	title: "部門編集",
	
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
				try{
					input.parentNode.querySelector('.invalid-feedback').textContent = messages[name];
				}catch(e){
					console.log(e);
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
<form action="{url action="update" id=$data.code}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="code-input">部門コード</label>
					</th>
					<td>
						<div class="col-3">
						{$data.code|escape:"html"}
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">部門名　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="name" class="form-control" id="name-input" autocomplete="off" value="{$data.name|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="kana-input">部門名カナ　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="kana" class="form-control" id="kana-input" autocomplete="off" value="{$data.kana|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_zip-input">郵便番号　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-6">
							<input type="text" name="location_zip" class="form-control" id="location_zip-input" autocomplete="off" value="{$data.location_zip|escape:"html"}" />
							<div class="invalid-feedback"></div>
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
							<div class="invalid-feedback"></div>
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
							<div class="invalid-feedback"></div>
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
						<label class="form-label ls-1" for="phone-input">電話番号　<span class="text-danger fw-light">※</span></label>
					</th>
					<td>
						<div class="col-5">
							<input type="text" name="phone" class="form-control" id="phone-input" autocomplete="off" value="{$data.phone|escape:"html"}" />
							<div class="invalid-feedback"></div>
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
						<label class="form-label ls-1" for="print_flag-input">部門名印刷区分</label>
					</th>
					<td>
						<div class="col-5">
							<input type="checkbox" name="print_flag" class="form-check-input" id="print_flag-input" autocomplete="off" {if $data.print_flag eq 1} checked{/if} />
						</div>
					</td>
				</tr>
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