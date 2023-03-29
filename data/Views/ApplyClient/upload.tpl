{block name="title"}請求先（納品先）CSV取込{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/common/CSVTokenizer.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	modifiers: JSON.parse("{$modifiers|@json_encode|escape:"javascript"}"),
	dbDownloadURL: "{url controller="Default" action="master"}",
	success: "{url action="index"}",{literal}
	template: null,
	response: new SQLite(),
	*[Symbol.iterator](){
		this.template = new Template(
			this.modifiers.closeProcessing,
			this.modifiers.prefectures,
			this.modifiers.invoiceFormat,
			this.modifiers.taxRound,
			this.modifiers.taxProcessing,
			this.modifiers.closeDate,
			this.modifiers.monthList,
			this.modifiers.unitPriceType,
			this.modifiers.existence
		);
		let fileElement = document.getElementById("file-input");
		let tbody = document.getElementById("list");
		let form = document.querySelector('form');
		let submitBtn = form.querySelector('button[type="submit"]');
		let reader = new FileReader();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		let pObj = {};
		
		fileElement.addEventListener("change", e => {
			if(fileElement.files.length > 0){
				reader.readAsText(fileElement.files[0], "SJIS");
			}
		});
		reader.addEventListener("load", e => {
			let data = CSVTokenizer.parse(reader.result.replace(/\r\n?/mg, "\n"));
			this.response.import(buffer, "list");
			this.response.createTable("csv", [
				"code","client","name","kana","short_name","location_zip","location_address1","location_address2","location_address3","phone","fax","email","homepage",
				"transactee","transactee_honorific","invoice_format","tax_round","tax_processing","close_processing","close_date","payment_cycle","payment_date",
				"unit_price_type","salse_with_ruled_lines","delivery_with_ruled_lines","receipt_with_ruled_lines","invoice_with_ruled_lines","receivables_balance","note"
			], data.slice(1));
			let table = this.response.select("ALL")
				.setTable("csv")
				.apply();
			tbody.innerHTML = table.map(row => this.template.listItem(row)).join("");
			submitBtn.disabled = false;
		});
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let formData = new FormData();
			let table = this.response.select("ALL")
				.setTable("csv")
				.apply();
			formData.append("json", JSON.stringify(table));
			pObj.resolve(formData);
		});
		
		do{
			let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
			if(res instanceof FormData){
				submitBtn.disabled = true;
				let response = yield fetch(form.getAttribute("action"), {
					method: form.getAttribute("method"),
					body: res
				}).then(res => res.json());
				if(response.success){
					// メッセージをpushしてリダイレクト
					for(let message of response.messages){
						Flow.DB.insertSet("messages", {title: "請求先CSV取込", message: message[0], type: message[1], name: message[2]}, {}).apply();
					}
					Flow.DB.commit().then(res => { location.href = this.success; });
				}
				submitBtn.disabled = false;
			}
			
		}while(true);
	}
});
{/literal}</script>
{/block}

{block name="body"}
<div class="container border border-secondary rounded p-4 mb-5 bg-white">
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="file-input">CSVファイル選択</label>
				</th>
				<td>
					<div class="col-3">
						<input type="file" class="form-control" id="file-input" />
					</div>
				</td>
			</tr>
		</tbody>
	</table>
</div>
<form action="{url action="import"}" method="POST">
	<div class="container border border-secondary rounded p-4 bg-white table-responsive">
		<table class="table table_sticky_list text-nowrap">
			<thead>
				<tr>
					<th>請求先コード</th>
					<th>得意先</th>
					<th>請求先名</th>
					<th>請求先名カナ</th>
					<th>請求先名称略</th>
					<th>郵便番号</th>
					<th>都道府県</th>
					<th>市区町村・番地</th>
					<th>建物名</th>
					<th>電話番号</th>
					<th>FAX</th>
					<th>メールアドレス</th>
					<th>ホームページ</th>
					<th>請求先担当者</th>
					<th>担当者敬称</th>
					<th>請求書パターン</th>
					<th>税端数処理</th>
					<th>税処理</th>
					<th>請求方法</th>
					<th>締日指定（28日以降は末日を選択）</th>
					<th>入金サイクル （◯ヶ月後）</th>
					<th>入金予定日（28日以降は末日を選択）</th>
					<th>単価種別</th>
					<th>売上伝票種別</th>
					<th>納品書種別</th>
					<th>受領書種別</th>
					<th>請求書種別</th>
					<th>期首売掛残高</th>
					<th>備考</th>
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" constructor=["closeProcessing", "prefectures", "invoiceFormat", "taxRound", "taxProcessing", "closeDate", "monthList", "unitPriceType", "existence"] assign="obj"}
				<tr>
					<td>{$obj.code}</td>
					<td>{$obj.client}</td>
					<td>{$obj.name}</td>
					<td>{$obj.kana}</td>
					<td>{$obj.short_name}</td>
					<td>{$obj.location_zip}</td>
					<td>{$prefectures[$obj.location_address1]}</td>
					<td>{$obj.location_address2}</td>
					<td>{$obj.location_address3}</td>
					<td>{$obj.phone}</td>
					<td>{$obj.fax}</td>
					<td>{$obj.email}</td>
					<td>{$obj.homepage}</td>
					<td>{$obj.transactee}</td>
					<td>{$obj.transactee_honorific}</td>
					<td>{$invoiceFormat[$obj.invoice_format]}</td>
					<td>{$taxRound[$obj.tax_round]}</td>
					<td>{$taxProcessing[$obj.tax_processing]}</td>
					<td>{$closeProcessing[$obj.close_processing]}</td>
					<td>{$closeDate[$obj.close_date]}</td>
					<td>{$monthList[$obj.payment_cycle]}</td>
					<td>{$closeDate[$obj.payment_date]}</td>
					<td>{$unitPriceType[$obj.unit_price_type]}</td>
					<td>{$existence[$obj.salse_with_ruled_lines]}</td>
					<td>{$existence[$obj.delivery_with_ruled_lines]}</td>
					<td>{$existence[$obj.receipt_with_ruled_lines]}</td>
					<td>{$existence[$obj.invoice_with_ruled_lines]}</td>
					<td>{$obj.receivables_balance}</td>
					<td>{$obj.note}</td>
				</tr>
			{/predefine}</tbody>
		</table>
	</div>
	<div class="grid-colspan-12 text-center mt-3">
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex" disabled><div class="flex-grow-1"></div>取込<div class="flex-grow-1"></div></button>
	</div>
</form>
{/block}