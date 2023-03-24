{block name="title"}請求先（納品先）編集画面{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	deleteUrl: "{url action="delete"}",
	success: "{url action="index"}",{literal}
	*[Symbol.iterator](){
		let deleteBtn = document.querySelector('[data-delete]');
		let pObj = {};
		
		deleteBtn.addEventListener("click", e => {
			pObj.resolve(null);
		});
		
		yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let formData = new FormData();
		formData.append("id", deleteBtn.getAttribute("data-delete"));
		fetch(this.deleteUrl, {
			method: "POST",
			body: formData
		})
		.then(response => response.json())
		.then(response => {
			if(response.success){
				// フォーム送信 成功
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "請求先削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				Flow.DB.commit().then(res => { location.href = this.success; });
			}
		});
		
	}
});
{/literal}</script>
{/block}

{block name="tools"}
<a href="{url action="edit" id="*"}" class="btn btn-success">編集</a>
<button type="button" class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#deleteModal">削除</button>
{/block}

{block name="body"}
<form action="{url action="edit" id=$data.code}" method="POST" class="form-grid-12">
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="code-input">請求先コード</label>
					</th>
					<td>
						<div class="col-3">{$data.code|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="client-input">得意先</label>
					</th>
					<td>
						<div class="col-10">{$data.client|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">請求先名</label>
					</th>
					<td>
						<div class="col-10">{$data.name|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="kana-input">請求先名カナ</label>
					</th>
					<td>
						<div class="col-10">{$data.kana|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="short_name-input">請求先名称略</label>
					</th>
					<td>
						<div class="col-10">{$data.short_name|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_zip-input">郵便番号</label>
					</th>
					<td>
						<div class="col-6">{$data.location_zip|escape:"html"}</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address1-input">都道府県</label>
					</th>
					<td>
						<div class="col-6">{$data.location_address1|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address2-input">市区町村・番地</label>
					</th>
					<td>
						<div class="col-10">{$data.location_address2|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_address3-input">建物名</label>
					</th>
					<td>
						<div class="col-10">{$data.location_address3|escape:"html"}</div>
					</td>
				</tr>
			</table>

			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="phone-input">電話番号</label>
					</th>
					<td>
						<div class="col-5">{$data.phone|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="fax-input">FAX</label>
					</th>
					<td>
						<div class="col-5">{$data.fax|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="email-input">メールアドレス</label>
					</th>
					<td>
						<div class="col-10">{$data.email|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="homepage-input">ホームページ</label>
					</th>
					<td>
						<div class="col-10">{$data.homepage|escape:"html"}</div>
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
						<div class="col-10">{$data.transactee|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="transactee_honorific-input">担当者敬称</label>
					</th>
					<td>
						<div class="col-4">{$data.transactee_honorific|escape:"html"}</div>
					</td>
				</tr>
				<!-- <tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="department-input">部署名</label>
					</th>
					<td>
						<div class="col-10">{$data.department|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="managerial_position-input">役職名</label>
					</th>
					<td>
						<div class="col-10">{$data.managerial_position|escape:"html"}</div>
					</td>
				</tr> -->
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="invoice_format-input">請求書パターン</label>
					</th>
					<td>
						<div class="col-6">{$data.invoice_format|invoiceFormat}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="tax_round-input">税端数処理</label>
					</th>
					<td>
						<div class="col-6">{$data.tax_round|taxRound}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="tax_processing-input">税処理</label>
					</th>
					<td>
						<div class="col-6">{$data.tax_processing|taxProcessing}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="close_processing-input">請求方法</label>
					</th>
					<td>
						<div class="col-6">{$data.close_processing|closeProcessing}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="close_date-input">締日指定（28日以降は末日を選択）</label>
					</th>
					<td>
						<div class="col-6">{$data.close_date|closeDate}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="payment_cycle-input">入金サイクル （◯ヶ月後）</label>
					</th>
					<td>
						<div class="col-6">{$data.payment_cycle|monthList}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="payment_date-input">入金予定日（28日以降は末日を選択）</label>
					</th>
					<td>
						<div class="col-6">{$data.payment_date|closeDate}</div>
					</td>
				</tr>
			</table>

			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="unit_price_type-input">単価種別</label>
					</th>
					<td>
						<div class="col-6">{$data.unit_price_type|unitPriceType}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="salse_with_ruled_lines-input">売上伝票種別</label>
					</th>
					<td>
						<div class="col-6">{$data.salse_with_ruled_lines|existence}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="delivery_with_ruled_lines-input">納品書種別</label>
					</th>
					<td>
						<div class="col-6">{$data.delivery_with_ruled_lines|existence}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="receipt_with_ruled_lines-input">受領書種別</label>
					</th>
					<td>
						<div class="col-6">{$data.receipt_with_ruled_lines|existence}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="invoice_with_ruled_lines-input">請求書種別</label>
					</th>
					<td>
						<div class="col-6">{$data.invoice_with_ruled_lines|existence}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="receivables_balance-input">期首売掛残高</label>
					</th>
					<td>
						<div class="col-10">{$data.receivables_balance|escape:"html"}</div>
					</td>
				</tr>
				<!-- <tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="location_lat_lng-input">緯度経度</label>
					</th>
					<td>
						<div class="col-10">{$data.location_lat_lng|escape:"html"}</div>
					</td>
				</tr> -->
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="note-input">備考</label>
					</th>
					<td>
						<div class="col-10">{$data.note|escape:"html"}</div>
					</td>
				</tr>
			</table>
		</div>
	</div>
</form>
{/block}

{block name="dialogs"}
<div class="modal fade" id="deleteModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center text-danger">本当に削除しますか？</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body"></div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal" data-delete="{$data.code}"><div class="flex-grow-1"></div>はい<div class="flex-grow-1"></div></button>
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>いいえ<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}
