{block name="title"}サービスアカウント{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script src="https://cdnjs.cloudflare.com/ajax/libs/jsrsasign/8.0.20/jsrsasign-all-min.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleSheets.js"></script>
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript">
{if not empty($value)}{call name="ListItem"}{/if}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="master"}",
	jwtDrive: "{url controller="JWT" action="drive"}",
	jwtSpreadsheet: "{url controller="JWT" action="spreadsheet"}",{literal}
	db: new SQLite(),
	newFilename: "無題のスプレッドシート",
	*[Symbol.iterator](){
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.db.import(buffer, "list");
		if(document.getElementById("create") != null){
			yield* this.init();
		}
		do{
			yield* this.input();
		}while(true);
	},
	*init(){
		const info = this.db.select("OBJECT").addTable("info").setField("key,value").apply();
		let template = new ListItem();
		let gd = new GoogleDrive(this.jwtDrive);
		let gs = new GoogleSheets(this.jwtSpreadsheet);
		document.getElementById("create").addEventListener("click", e => {
			this.createBook(gs, gd, this.db).then(e => { location.reload(); });
		});
		const obj = yield gd.getAll("properties+has+{key='access'+and+value='billing'}");
		let tbody = document.getElementById("list");
		tbody.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-delete")){
				gd.delete(e.target.getAttribute("data-search-delete")).then(e => { location.reload(); });
			}else if(e.target.hasAttribute("data-search-update")){
				const id = e.target.getAttribute("data-search-update");
				const sheets = new GoogleSheets(this.jwtSpreadsheet, id);
				const masterData = this.getMasterData(this.db);
				const names = Object.keys(masterData.namedRanges);
				sheets.get(names).then(book => {
					const sheetId = book.sheet("マスター").sheetId;
					for(let name of names){
						masterData.namedRanges[name].namedRangeId = book.getNamedRangeId(name);
					}
					return sheets.update({
						[GoogleSheets.requestSymbol]: "updateCells",
						[sheetId]: {
							rowIndex: 0,
							columnIndex: 0,
							rowData: masterData.rows
						}
					}, {
						[GoogleSheets.requestSymbol]: "updateNamedRange",
						[sheetId]: masterData.namedRanges
					});
				}).then(e => gd.setProperty(id, {masterUpdate: info.update.value}))
				.then(e => { location.reload(); });
			}
		}, {useCapture: true});
		const dateFormatter = new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium", timeStyle: "medium", timeZone: "Asia/Tokyo"});
		for(let item of obj.files){
			if("masterUpdate" in item.properties){
				let timestamp = Number(item.properties.masterUpdate);
				item.properties.masterUpdate = dateFormatter.format(new Date(timestamp * 1000));
				item.properties.masterUpdateFlag = (timestamp < info.update.value) ? "1" : "0";
			}
			template.insertBeforeEnd(tbody, item);
		}
		const disabled = tbody.querySelectorAll('[data-disabled="0"]');
		for(let i = disabled.length - 1; i >= 0; i--){
			disabled[i].disabled = true;
		}
	},
	*input(){
		let pObj = {};
		let controller = new AbortController();
		let form = document.querySelector('form');
		
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let input = document.getElementById("input");
			if(input.files.length > 0){
				pObj.resolve(input.files[0]);
			}
		}, {signal: controller.signal});
		
		// フォームを有効化
		let fieldset = Object.assign(form.querySelector("fieldset"), {disabled: false});
		
		// 入力があるまで待つ
		let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		
		// フォームを無効化
		fieldset.disabled = true;
		
		if(res instanceof File){
			let reader = new FileReader();
			let pObj = {};
			reader.addEventListener("loadend", e => {
				try{
					j = JSON.parse(reader.result);
				}catch(ex){
					pObj.reject(null);
				}
				pObj.resolve(j);
			});
			let key = yield new Promise((resolve, reject) => {
				Object.assign(pObj, {resolve, reject});
				reader.readAsText(res);
			});
			let value = reader.result;
			
			// Driveへアクセス
			const header = {
				alg: "RS256",
				typ: "JWT"
			};
			let payload = {
				iss: key.client_email,
				scope: "https://www.googleapis.com/auth/drive",
				aud: "https://oauth2.googleapis.com/token",
				iat: Math.floor(Date.now() / 1000),
				exp: Math.floor(Date.now() / 1000) + 3600
			};
			const privateKey = KEYUTIL.getKey(key.private_key);
			let assertion = KJUR.jws.JWS.sign("RS256", header, payload, privateKey);
			let blob = new Blob([JSON.stringify({assertion: assertion})], {type: "application/json"});
			let url1 = URL.createObjectURL(blob);
			let gd = new GoogleDrive(url1);
			const obj1 = yield gd.getAll("properties+has+{key='access'+and+value='billing'}").catch(e => null);
			if(obj1 == null){
				Flow.DB.insertSet("messages", {title: "サービスアカウント", message: "ドライブへのアクセス権がありません", type: 2, name: null}, {}).apply();
				let messages = Flow.DB
					.select("ALL")
					.addTable("messages")
					.leftJoin("toast_classes using(type)")
					.apply();
				if(messages.length > 0){
					Toaster.show(messages);
					Flow.DB.delete("messages").apply();
				}
				URL.revokeObjectURL(url1);
				return;
			}
			
			// Sheetsへアクセス
			payload = {
				iss: key.client_email,
				scope: "https://www.googleapis.com/auth/spreadsheets",
				aud: "https://oauth2.googleapis.com/token",
				iat: Math.floor(Date.now() / 1000),
				exp: Math.floor(Date.now() / 1000) + 3600
			};
			assertion = KJUR.jws.JWS.sign("RS256", header, payload, privateKey);
			blob = new Blob([JSON.stringify({assertion: assertion})], {type: "application/json"});
			let url2 = URL.createObjectURL(blob);
			if(obj1.files.length == 0){
				let gs = new GoogleSheets(url2);
				const obj2 = yield this.createBook(gs, gd, this.db);
				URL.revokeObjectURL(url1);
				URL.revokeObjectURL(url2);
				if(obj2 == null){
					Flow.DB.insertSet("messages", {title: "サービスアカウント", message: "スプレッドシートへのアクセス権がありません", type: 2, name: null}, {}).apply();
					let messages = Flow.DB
						.select("ALL")
						.addTable("messages")
						.leftJoin("toast_classes using(type)")
						.apply();
					if(messages.length > 0){
						Toaster.show(messages);
						Flow.DB.delete("messages").apply();
					}
					URL.revokeObjectURL(url1);
					return;
				}
			}else{
				let gs = new GoogleSheets(url2, obj1.files[0].id);
				const obj2 = yield gs.getAll().catch(e => null);
				URL.revokeObjectURL(url1);
				URL.revokeObjectURL(url2);
				if(obj2 == null){
					Flow.DB.insertSet("messages", {title: "サービスアカウント", message: "スプレッドシートへのアクセス権がありません", type: 2, name: null}, {}).apply();
					let messages = Flow.DB
						.select("ALL")
						.addTable("messages")
						.leftJoin("toast_classes using(type)")
						.apply();
					if(messages.length > 0){
						Toaster.show(messages);
						Flow.DB.delete("messages").apply();
					}
					URL.revokeObjectURL(url1);
					return;
				}
			}
			
			let formData = new FormData();
			formData.append("value", value);
			let response = yield fetch(form.getAttribute("action"), {
				method: form.getAttribute("method"),
				body: formData
			}).then(res => res.json());
			if(response.success){
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "サービスアカウント", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				Flow.DB.commit().then(e => { location.reload(); });
			}else{
				let messages = Flow.DB
					.select("ALL")
					.addTable("messages")
					.leftJoin("toast_classes using(type)")
					.apply();
				if(messages.length > 0){
					Toaster.show(messages);
					Flow.DB.delete("messages").apply();
				}
			}
		}
	},
	getMasterData(db){
		let master = {
			divisions:      db.select("COL").addTable("divisions").addField("name").apply(),
			teams:          db.select("COL").addTable("teams").addField("name").apply(),
			managers:       db.select("COL").addTable("managers").addField("name").apply(),
			applyClients:   db.select("COL").addTable("apply_clients").addField("name").apply(),
			invoiceFormats: db.select("COL").addTable("invoice_formats").addField("name").apply(),
			categories:     db.select("COL").addTable("categories").addField("name").apply()
		};
		let masterRowData = [];
		let namedRanges = {};
		namedRanges.range1 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.divisions == null || master.divisions.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.divisions){
				masterRowData.push([value]);
			}
		}
		namedRanges.range1.endRowIndex = masterRowData.length;
		namedRanges.range2 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.teams == null || master.teams.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.teams){
				masterRowData.push([value]);
			}
		}
		namedRanges.range2.endRowIndex = masterRowData.length;
		namedRanges.range3 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.managers == null || master.managers.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.managers){
				masterRowData.push([value]);
			}
		}
		namedRanges.range3.endRowIndex = masterRowData.length;
		namedRanges.range4 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.applyClients == null || master.applyClients.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.applyClients){
				masterRowData.push([value]);
			}
		}
		namedRanges.range4.endRowIndex = masterRowData.length;
		namedRanges.range5 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.invoiceFormats == null || master.invoiceFormats.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.invoiceFormats){
				masterRowData.push([value]);
			}
		}
		namedRanges.range5.endRowIndex = masterRowData.length;
		namedRanges.range6 = {startRowIndex: masterRowData.length, startColumnIndex: 0, endColumnIndex: 1};
		if(master.categories == null || master.categories.length < 1){
			masterRowData.push([null]);
		}else{
			for(let value of master.categories){
				masterRowData.push([value]);
			}
		}
		namedRanges.range6.endRowIndex = masterRowData.length;
		return {
			rows: masterRowData,
			namedRanges: namedRanges
		};
	},
	createBook(gs, gd, db){
		const info = db.select("OBJECT").addTable("info").setField("key,value").apply();
		const masterData = this.getMasterData(db);
		return gs.create(this.newFilename, [
			GoogleSheets.createSheetJson({index: 0, title: "売上"}, 100, 16, {
				frozenRowCount: 1,
				rows: [
					[
						GoogleSheets.formula`BYROW(B:B,LAMBDA(X,IF(ROW(X)=1,"取込済",COUNTIF('取込済'!A:A,X)>0)))`,
						GoogleSheets.formula`BYROW(C:C,LAMBDA(X,IF(ROW(X)=1,"通し番号",TEXT(ROW(X)-1,"00000000"))))`,
						"伝票番号", "売上日付", "部門", "チーム", "当社担当者", "請求先", "納品先", "件名", "備考", "摘要ヘッダー１", "摘要ヘッダー２", "摘要ヘッダー３", "入金予定日", "請求パターン"
					]
				],
				validationRanges: [
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 100,
							startColumnIndex: 4,
							endColumnIndex: 5
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range1"}]
							},
							strict: true,
							showCustomUi: true
						}
					},
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 100,
							startColumnIndex: 5,
							endColumnIndex: 6
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range2"}]
							},
							strict: true,
							showCustomUi: true
						}
					},
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 100,
							startColumnIndex: 6,
							endColumnIndex: 7
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range3"}]
							},
							strict: true,
							showCustomUi: true
						}
					},
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 100,
							startColumnIndex: 7,
							endColumnIndex: 8
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range4"}]
							},
							strict: true,
							showCustomUi: true
						}
					},
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 100,
							startColumnIndex: 15,
							endColumnIndex: 16
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range5"}]
							},
							strict: true,
							showCustomUi: true
						}
					}
				],
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 15}
				]
			}),
			GoogleSheets.createSheetJson({index: 1, title: "売上明細"}, 500, 11, {
				frozenRowCount: 1,
				rows: [
					["通し番号", "カテゴリー", "商品名", "単位", "数量", "単価", "金額", "摘要１", "摘要２", "摘要３", "発行部数"]
				],
				validationRanges: [
					{
						range: {
							startRowIndex: 1,
							endRowIndex: 500,
							startColumnIndex: 1,
							endColumnIndex: 2
						},
						rule: {
							condition: {
								type: "ONE_OF_RANGE",
								values: [{userEnteredValue: "=range6"}]
							},
							strict: true,
							showCustomUi: true
						}
					}
				],
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 11}
				]
			}),
			GoogleSheets.createSheetJson({index: 2, title: "取込済", hidden: true}, 100, 2, {
				protectedRanges: [{}]
			}),
			GoogleSheets.createSheetJson({index: 3, title: "マスター", hidden: true}, 100, 2, {
				rows: masterData.rows,
				namedRanges: masterData.namedRanges,
				protectedRanges: [{}]
			})
		]).then(res => Promise.all([
			gd.createPermission(res.spreadsheetId),
			gd.setProperty(res.spreadsheetId, {access: "billing", masterUpdate: info.update.value})
		])).then(res => res)
		.catch(res => null);
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url action="x_update"}" method="POST" class="form-grid-12"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row gap-4 align-items-start">
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1">サービスアカウント</label>
					</th>
					<td>
						<div class="col-10">
							{if empty($value)}サービスアカウントが設定されていません{else}{$value.client_email}{/if}
						</div>
					</td>
				</tr>
			</table>
			<table class="col table">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="input">サービスアカウントキー</label>
					</th>
					<td>
						<div class="col-10">
							<input class="form-control" type="file" id="input" accept="application/json" />
						</div>
					</td>
				</tr>
			</table>
		</div>
		<div class="grid-colspan-12 text-center">
			<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex"><div class="flex-grow-1"></div>登録・更新<div class="flex-grow-1"></div></button>
		</div>
	</div>
</fieldset></form>
{if not empty($value)}
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th>ファイル名</th>
				<th>マスター更新日時</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">
			{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=[]}{strip}
			<tr>
				<td>{$obj.name}</td>
				<td>{$obj.properties.masterUpdate}</td>
				<td>
					<div class="d-flex gap-2">
						<a target="_blank" href="https://docs.google.com/spreadsheets/d/{$obj.id}/edit" class="btn btn-success btn-sm">編集</a>
						<button type="button" class="btn btn-info btn-sm" data-search-update="{$obj.id}" data-disabled="{$obj.properties.masterUpdateFlag}">マスタ更新</button>
						<button type="button" class="btn btn-danger btn-sm" data-search-delete="{$obj.id}">削除</button>
					</div>
				</td>
			</tr>
			{/strip}{/template_class}{/function}
		</tbody>
	</table>
	<div class="col-12 text-center">
		<button type="button" class="btn btn-success" id="create">新　規</button>
	</div>
</div>
{/if}
{/block}