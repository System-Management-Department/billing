{block name="styles" append}
<style type="text/css">{literal}
html, body{
	margin: 0;
	padding: 0;
	width: 100vw;
}
table{
	border-collapse: collapse;
}
thead{
	position: sticky;
	top: 0;
	background: white;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/googleAPI/GoogleSheets.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript">
{call name="DriveItem"}
{call name="ItemList"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="master"}",{literal}
	jwt: {{/literal}
		spreadsheet: "{url controller="JWT" action="spreadsheet"}",
		drive: "{url controller="JWT" action="drive"}"
	{literal}},
	gd: null,
	gs: null,
	db: new SQLite(),
	*[Symbol.iterator](){
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.db.import(buffer, "list");
		
		let p = yield* this.driveInit();
		while("next" in p){
			p = yield* this[p.next](...p.args);
		}
	},
	*driveInit(){
		this.gd = new GoogleDrive(this.jwt.drive);
		const template = new DriveItem();
		const obj = yield this.gd.getAll();
		const tbody = document.querySelector('#drive tbody');
		let pObj = {};
		for(let item of obj.items){
			template.insertBeforeEnd(tbody, item);
		}
		let btns = tbody.querySelectorAll('[data-role]:not([data-role="owner"]) button');
		for(let i = btns.length - 1; i >= 0; i--){
			btns[i].parentNode.removeChild(btns[i]);
		}
		tbody.addEventListener("click", e => {
			if(e.target.hasAttribute("data-id") && e.target.hasAttribute("data-action")){
				if(e.target.getAttribute("data-action") == "delete"){
					pObj.resolve({next: "deleteBook", args: [e.target.getAttribute("data-id")]});
				}else{
					pObj.resolve({next: "sheetsInit", args: [e.target.getAttribute("data-id")]});
				}
			}
		}, true);
		document.getElementById('create').addEventListener("click", e => {
			let filename = prompt("filename", "");
			if(filename == null || filename == ""){
				return;
			}
			pObj.resolve({next: "createBook", args: [filename]});
		}, true);
		let p = new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		return yield p;
	},
	*sheetsInit(id){
		const template = new ItemList();
		let targetId = null;
		if(id == null){
		}else{
			this.gs = new GoogleSheets(this.jwt.spreadsheet, id);
			document.getElementById("title").textContent = "";
			document.getElementById("drive").style.display = "none";
			document.getElementById("spreadsheet").style.display = "table";
			document.getElementById("create").style.display = "none";
			document.getElementById("import").style.display = "inline-block";
		}
		let pObj = {};
		const book = yield this.gs.getAll();
		this.db.createTable("slips", [
			"import", "id", "slip_number", "accounting_date", "division_name", "team_name", "manager_name", "billing_destination_name",
			"delivery_destination", "subject", "note", "header1", "header2", "header3", "payment_date", "invoice_format_name"
		], book.sheet("売上").range.slice(1));
		this.db.createTable("details", [
			"id", "categoryName", "itemName", "unit", "quantity", "unitPrice", "amount", "data1", "data2", "data3", "circulation"
		], book.sheet("売上明細").range.slice(1));
		
		let tbody = Object.assign(document.querySelector('#spreadsheet tbody'), {innerHTML: ""});
		let data = this.db.select("ALL")
			.addTable("slips")
			.andWhere("import=0")
			.apply();
		targetId = book.sheet("取込済").sheetId;
		for(let item of data){
			template.insertBeforeEnd(tbody, item);
		}
		
		let controller = new AbortController();
		document.getElementById("import").addEventListener("click", e => {
			let importData = [];
			let checked = tbody.querySelectorAll('input:checked:not([disabled])');
			let n = checked.length;
			let appendValues = [];
			let values = [];
			for(let i = 0; i < n; i++){
				values.push(checked[i].value);
				appendValues.push([checked[i].value, GoogleSheets.now]);
			}
			this.db.create_function("is_checked", id => (values.includes(id) ? 1 : 0));
			this.db.create_aggregate("sales_tax", {
				init(){
					return 0;
				},
				step(state, value){
					if(typeof value === "number"){
						return state + value;
					}
					return state;
				},
				finalize(state){
					return state * 0.1;
				}
			});
			this.db.create_aggregate("json_detail", {
				init(){
					return {
						length: 0,
						categoryCode: [],
						itemName: [],
						unit: [],
						quantity: [],
						unitPrice: [],
						amount: [],
						data1: [],
						data2: [],
						data3: [],
						circulation: []
					};
				},
				step(state, categoryCode, itemName, unit, quantity, unitPrice, amount, data1, data2, data3, circulation){
					state.length++;
					state.categoryCode.push(categoryCode);
					state.itemName.push(itemName);
					state.unit.push(unit);
					state.quantity.push(quantity);
					state.unitPrice.push(unitPrice);
					state.amount.push(amount);
					state.data1.push(data1);
					state.data2.push(data2);
					state.data3.push(data3);
					state.circulation.push(circulation);
					return state;
				},
				finalize(state){
					return JSON.stringify(state);
				}
			});
			importData = this.db.select("ALL")
				.addTable("slips")
				.addField("slips.slip_number")
				.addField("slips.accounting_date")
				.leftJoin("divisions on slips.division_name=divisions.name")
				.addField("divisions.code as division")
				.leftJoin("teams on slips.team_name=teams.name")
				.addField("teams.code as team")
				.leftJoin("managers on slips.manager_name=managers.name")
				.addField("managers.code as manager")
				.leftJoin("apply_clients on slips.billing_destination_name=apply_clients.unique_name")
				.addField("apply_clients.code as billing_destination")
				.addField("slips.delivery_destination")
				.addField("slips.subject")
				.addField("slips.note")
				.addField("slips.header1")
				.addField("slips.header2")
				.addField("slips.header3")
				.addField("slips.payment_date")
				.leftJoin("invoice_formats on slips.invoice_format_name=invoice_formats.name")
				.addField("invoice_formats.id as invoice_format")
				.leftJoin("details on slips.id=details.id")
				.leftJoin("categories on details.categoryName=categories.name")
				.addField("sales_tax(details.amount) as sales_tax")
				.addField("json_detail(categories.code, details.itemName, details.unit, details.quantity, details.unitPrice, details.amount, details.data1, details.data2, details.data3, details.circulation) as detail")
				.andWhere("is_checked(slips.id)=1")
				.setGroupBy("slips.id")
				.apply();
			
			let formData = new FormData();
			formData.append("json", JSON.stringify(importData));
			formData.append("spreadsheets", this.gs.getId());
			fetch("{/literal}{url action="import"}{literal}", {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(data => {
			});
			this.gs.update({
				[GoogleSheets.requestSymbol]: "appendCells",
				[targetId]: appendValues
			}).then(res => {
				this.db.run("drop table slips");
				this.db.run("drop table details");
				pObj.resolve({next: "sheetsInit", args:[null]});
			});
		}, {signal: controller.signal});
		let p = new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let res =  yield p;
		controller.abort();
		return res;
	},
	*createBook(filename){
		this.gs = new GoogleSheets(this.jwt.drive);
		let master = {
			divisions:      this.db.select("COL").addTable("divisions").addField("name").apply(),
			teams:          this.db.select("COL").addTable("teams").addField("name").apply(),
			managers:       this.db.select("COL").addTable("managers").addField("name").apply(),
			applyClients:   this.db.select("COL").addTable("apply_clients").addField("name").apply(),
			invoiceFormats: this.db.select("COL").addTable("invoice_formats").addField("name").apply(),
			categories:     this.db.select("COL").addTable("categories").addField("name").apply()
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
		return this.gs.create(filename, [
			GoogleSheets.createSheetJson({index: 0, title: "売上"}, 100, 16, {
				frozenRowCount: 1,
				rows: [
					[
						GoogleSheets.formula`BYROW(B:B,LAMBDA(X,IF(ROW(X)=1,"取込済",COUNTIF('取込済'!A:A,X)>0)))`,
						GoogleSheets.formula`BYROW(C:C,LAMBDA(X,IF(ROW(X)=1,"通し番号",TEXT(ROW(X)-1,"00000000"))))`,
						"伝票番号", "売上日付", "部門", "チーム", "当社担当者", "請求先", "納品先", "件名", "備考", "摘要ヘッダー１", "摘要ヘッダー２", "摘要ヘッダー３", "入金予定日", "請求パターン"
					]
				],
				fillRows: function(rowData){
					rowData.values[4].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range1"}]
						},
						strict: true,
						showCustomUi: true
					};
					rowData.values[5].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range2"}]
						},
						strict: true,
						showCustomUi: true
					};
					rowData.values[6].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range3"}]
						},
						strict: true,
						showCustomUi: true
					};
					rowData.values[7].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range4"}]
						},
						strict: true,
						showCustomUi: true
					};
					rowData.values[15].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range5"}]
						},
						strict: true,
						showCustomUi: true
					};
				},
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 15}
				]
			}),
			GoogleSheets.createSheetJson({index: 1, title: "売上明細"}, 500, 11, {
				frozenRowCount: 1,
				rows: [
					["通し番号", "カテゴリー", "商品名", "単位", "数量", "単価", "金額", "摘要１", "摘要２", "摘要３", "発行部数"]
				],
				fillRows: function(rowData){
					rowData.values[1].dataValidation = {
						condition: {
							type: "ONE_OF_RANGE",
							values: [{userEnteredValue: "=range6"}]
						},
						strict: true,
						showCustomUi: true
					};
				},
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 11}
				]
			}),
			GoogleSheets.createSheetJson({index: 2, title: "取込済", hidden: true}, 100, 2, {
				protectedRanges: [{}]
			}),
			GoogleSheets.createSheetJson({index: 3, title: "マスター", hidden: true}, 100, 2, {
				rows: masterRowData,
				namedRanges: namedRanges,
				protectedRanges: [{}]
			})
		]).then(res => this.gd.createPermission(res.spreadsheetId)).then(res => {location.reload();});
	},
	*deleteBook(id){
		return this.gd.delete(id).then(res => {location.reload();});
	}
});
{/literal}</script>
{/block}

{block name="body"}
<button type="button" id="create">新規</button><span id="title"></span><button type="button" id="import" style="display: none;">取込</button>
<table border="1" id="drive">
	<thead><th>ファイル名</th><th>種類</th><th>権限</th><th>操作</th></thead>
	<tbody>
		{function name="DriveItem"}{template_class name="DriveItem" assign="obj" iterators=[]}{strip}
		<tr data-role="{$obj.userPermission.role}">
			<td><a target="_blank" href="https://docs.google.com/spreadsheets/d/{$obj.id}/edit">{$obj.title}</a></td>
			<td>{$obj.mimeType}</td>
			<td>{$obj.userPermission.role}</td>
			<td>
				<button type="button" data-id="{$obj.id}" data-action="load" data-title="{$obj.title}">読込</button>
				<button type="button" data-id="{$obj.id}" data-action="delete">削除</button>
			</td>
		</tr>
		{/strip}{/template_class}{/function}
	</tbody>
</table>
<table border="1" id="spreadsheet" style="display: none;">
	<thead><th>取込</th><th>通し番号</th><th>伝票番号</th><th>売上日付</th><th>部門</th><th>チーム</th><th>当社担当者</th><th>請求先</th><th>納品先</th><th>件名</th><th>備考</th><th>摘要ヘッダー１</th><th>摘要ヘッダー２</th><th>摘要ヘッダー３</th><th>入金予定日</th><th>請求パターン</th></thead>
	<tbody>
		{function name="ItemList"}{template_class name="ItemList" assign="obj" iterators=[]}{strip}
		<tr>
			<td><input type="checkbox" value="{$obj.id}" /></td>
			<td>{$obj.id}</td>
			<td>{$obj.slip_number}</td>
			<td>{$obj.accounting_date}</td>
			<td>{$obj.division_name}</td>
			<td>{$obj.team_name}</td>
			<td>{$obj.manager_name}</td>
			<td>{$obj.billing_destination_name}</td>
			<td>{$obj.delivery_destination}</td>
			<td>{$obj.subject}</td>
			<td>{$obj.note}</td>
			<td>{$obj.header1}</td>
			<td>{$obj.header2}</td>
			<td>{$obj.header3}</td>
			<td>{$obj.payment_date}</td>
			<td>{$obj.invoice_format}</td>
		</tr>
		{/strip}{/template_class}{/function}
	</tbody>
</table>
{/block}