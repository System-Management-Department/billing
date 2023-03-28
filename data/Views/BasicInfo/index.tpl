{block name="title"}基本情報{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({
	form: null,
	title: "基本情報",
	
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
		this.form = document.querySelector('form');
		
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
		Flow.DB.commit().then(res => { location.reload(); });
		
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
<form action="{url action="update"}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">名称</label>
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
						<label class="form-label ls-1" for="kana-input">フリガナ</label>
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
						<label class="form-label ls-1" for="location_zip-input">郵便番号</label>
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
						<label class="form-label ls-1" for="location_address1-input">都道府県</label>
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
						<label class="form-label ls-1" for="location_address2-input">市区町村・番地</label>
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
						<label class="form-label ls-1" for="phone-input">電話番号</label>
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
						<label class="form-label ls-1" for="invoice_numbering_system-input">請求書付番方法</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="invoice_numbering_system" class="form-control" id="invoice_numbering_system-input" autocomplete="off" value="{$data.invoice_numbering_system|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="unit_price_round-input">単価端数処理</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="unit_price_round" class="form-control" id="unit_price_round-input" autocomplete="off" value="{$data.unit_price_round|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="quantity_decimal_places-input">数量小数桁数</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="quantity_decimal_places" class="form-control" id="quantity_decimal_places-input" autocomplete="off" value="{$data.quantity_decimal_places|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="amount_round-input">金額端数処理</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="amount_round" class="form-control" id="amount_round-input" autocomplete="off" value="{$data.amount_round|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="current_unit_price_decimal_places-input">現単価小数桁数</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="current_unit_price_decimal_places" class="form-control" id="current_unit_price_decimal_places-input" autocomplete="off" value="{$data.current_unit_price_decimal_places|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="unit_price_decimal_places-input">単価小数桁数</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="unit_price_decimal_places" class="form-control" id="unit_price_decimal_places-input" autocomplete="off" value="{$data.unit_price_decimal_places|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="settlement_month-input">本年度決済月</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="settlement_month" class="form-control" id="settlement_month-input" autocomplete="off" value="{$data.settlement_month|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="closing_date-input">自社締日</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="closing_date" class="form-control" id="closing_date-input" autocomplete="off" value="{$data.closing_date|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="current_fiscal_year-input">年度範囲</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="current_fiscal_year" class="form-control" id="current_fiscal_year-input" autocomplete="off" value="{$data.current_fiscal_year|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
			</table>
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="company_print_form-input">会社名印刷区分</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="company_print_form" class="form-control" id="company_print_form-input" autocomplete="off" value="{$data.company_print_form|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="division_print_form-input">部門マスタ住所使用区分</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="division_print_form" class="form-control" id="division_print_form-input" autocomplete="off" value="{$data.division_print_form|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_print_form-input">会社住所等印刷区分</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="location_print_form" class="form-control" id="location_print_form-input" autocomplete="off" value="{$data.location_print_form|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="stamp_print_form-input">印鑑印刷</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="stamp_print_form" class="form-control" id="stamp_print_form-input" autocomplete="off" value="{$data.stamp_print_form|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="stamp_image-input">請求書印刷アップロード</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="stamp_image" class="form-control" id="stamp_image-input" autocomplete="off" value="{$data.stamp_image|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="sales_unit_price_display_name-input">売上単価</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="sales_unit_price_display_name" class="form-control" id="sales_unit_price_display_name-input" autocomplete="off" value="{$data.sales_unit_price_display_name|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="transfer_account-input">口座情報</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="transfer_account" class="form-control" id="transfer_account-input" autocomplete="off" value="{$data.transfer_account|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="invoice_display_name-input">請求書タイトル</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="invoice_display_name" class="form-control" id="invoice_display_name-input" autocomplete="off" value="{$data.invoice_display_name|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="payment_date_print_form-input">支払期限</label>
					</th>
					<td>
						<div class="col-10">
							<input type="text" name="payment_date_print_form" class="form-control" id="payment_date_print_form-input" autocomplete="off" value="{$data.payment_date_print_form|escape:"html"}" />
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
							<input type="text" name="note" class="form-control" id="note-input" autocomplete="off" value="{$data.note|escape:"html"}" />
							<div class="invalid-feedback"></div>
						</div>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div class="grid-colspan-12 text-center">
		<input type="hidden" name="gserviceaccount" value="{$data.gserviceaccount|escape:"html"}" />
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex"><div class="flex-grow-1"></div>登録・更新<div class="flex-grow-1"></div></button>
	</div>
</fieldset></form>
{/block}
