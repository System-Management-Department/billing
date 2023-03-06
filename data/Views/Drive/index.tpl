{block name="title"}売上データ取り込み画面{/block}

{block name="styles" append}
<style type="text/css">
[data-search-output="container"]:has([data-search-output="result"] input[type="hidden"]:not([value=""])) [data-search-output="form"],
[data-search-output="container"] [data-search-output="result"]:has(input[type="hidden"][value=""]){
	display: none;
}
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/googleAPI/GoogleSheets.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript">
{call name="ListItem"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="master"}",
	id: "{$smarty.get.id}",
	jwt: "{url controller="JWT" action="spreadsheet"}",{literal}
	response: new SQLite(),
	gs: null,
	template: new ListItem(),
	dataList: null,
	isChecked: {
		length: 1,
		apply: function(dummy, args){
			let id = args[0];
			return this.values.includes(id) ? 1 : 0;
		},
		values: null,
		reset: function(checked){
			this.values = [];
			let n = checked.length;
			for(let i = 0; i < n; i++){
				this.values.push(checked[i].value);
			}
		}
	},
	*[Symbol.iterator](){
		this.gs = new GoogleSheets(this.jwt, this.id);
		const book = yield this.gs.getAll();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		const targetId = book.sheet("取込済").sheetId;
		this.response.import(buffer, "list");
		this.response.createTable("slips", [
			"import", "id", "slip_number", "accounting_date", "division_name", "team_name", "manager_name", "billing_destination_name",
			"delivery_destination", "subject", "note", "header1", "header2", "header3", "payment_date", "invoice_format_name"
		], book.sheet("売上").range.slice(1));
		this.response.createTable("details", [
			"id", "categoryName", "itemName", "unit", "quantity", "unitPrice", "amount", "data1", "data2", "data3", "circulation"
		], book.sheet("売上明細").range.slice(1));
		
		this.response.create_function("is_checked", this.isChecked);
		this.response.create_aggregate("sales_tax", {
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
		this.response.create_aggregate("json_detail", {
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
		this.dataList = document.getElementById("list");
		let parameter = new FormData();
		do{
			yield* this.search(parameter);
			parameter = yield* this.input(targetId);
		}while(true);
	},
	*search(parameter){
		let query = this.response.select("ALL")
			.setTable("slips")
			.andWhere("import=0")
			.andWhere("slip_number<>''");
			
		let searchObj = {
			slip_number(q, v){
				if(v != ""){
					q.andWhere("slip_number like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			accounting_date(q, v){
				if(v != ""){
					q.andWhere("accounting_date=?", v);
				}
			},
			division(q, v){
				if(v != ""){
					q.andWhere("division_name=?", v);
				}
			},
			team(q, v){
				if(v != ""){
					q.andWhere("team_name=?", v);
				}
			},
			manager(q, v){
				if(v != ""){
					let val = v.replace(/(?=[\\\%\_])/g, "\\");
					q.setField("slips.*")
						.leftJoin("managers on slips.manager_name=managers.name")
						.andWhere("((manager_name like '%' || ? || '%') OR (managers.code like '%' || ? || '%'))", val, val);
				}
			},
			billing_destination(q, v){
				if(v != ""){
					let val = v.replace(/(?=[\\\%\_])/g, "\\");
					q.setField("slips.*")
						.leftJoin("apply_clients on slips.billing_destination_name=apply_clients.unique_name")
						.andWhere("((billing_destination_name like '%' || ? || '%') OR (apply_clients.code like '%' || ? || '%'))", val, val);
				}
			},
			itemName(q, v){
				if(v != ""){
					q.andWhere("id IN(SELECT id FROM details WHERE itemName like '%' || ? || '%')", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			}
		};
		let it = parameter.keys();
		for(let k of it){
			if(k in searchObj){
				searchObj[k](query, ...parameter.getAll(k));
			}
		}
		let table = query.apply();
		this.dataList.innerHTML = "";
		for(let row of table){
			this.template.insertBeforeEnd(this.dataList, row);
		}
	},
	*input(targetId){
		let pObj = {};
		let controller = new AbortController();
		let searchBtn = document.getElementById("search");
		let form = document.getElementById("import");
		
		// イベントを設定
		searchBtn.addEventListener("click", e => {
			pObj.resolve(searchBtn);
		}, {signal: controller.signal});
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			pObj.resolve(new FormData(form));
		}, {signal: controller.signal});
		document.getElementById("checkall").addEventListener("click", e => {
			let checked = form.querySelectorAll('input:checked:not([disabled])');
			for(let i = checked.length - 1; i >= 0; i--){
				checked[i].checked = false;
			}
		}, {signal: controller.signal});
		
		// フォームを有効化
		let fieldsets = document.querySelectorAll('form fieldset:disabled');
		for(let i = fieldsets.length - 1; i >= 0; i--){
			fieldsets[i].disabled = false;
		}
		
		// 入力があるまで待つ
		let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		
		// 設定したイベントを一括削除
		controller.abort();
		
		// 検索条件を設定
		if(res instanceof FormData){
			let checked = form.querySelectorAll('input:checked:not([disabled])');
			this.isChecked.reset(checked);
		}
		let formData = new FormData(document.querySelector('form:has(#search)'));
		
		// フォームを無効化
		for(let i = fieldsets.length - 1; i >= 0; i--){
			fieldsets[i].disabled = true;
		}
		
		// インポート
		if(res instanceof FormData){
			let importData = this.response.select("ALL")
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
			let response = yield fetch(form.getAttribute("action"), {
				method: form.getAttribute("method"),
				body: formData
			}).then(res => res.json());
			if(response.success){
				this.gs.update({
					[GoogleSheets.requestSymbol]: "appendCells",
					[targetId]: this.isChecked.values.map(r => [r, GoogleSheets.now])
				});
				this.response.updateSet("slips", {import: 1}, {}).andWhere("is_checked(id)=1").apply();
			}
			for(let message of response.messages){
				Flow.DB.insertSet("messages", {title: "売上データ取り込み", message: message[0], type: message[1], name: message[2]}, {}).apply();
			}
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
		
		return formData;
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="spreadsheet-input">スプレッドシート</label>
				</th>
				<td>
					<a target="_blank" href="https://docs.google.com/spreadsheets/d/{$smarty.get.id}/edit" class="btn btn-info" id="spreadsheet">編集</a>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="slip_number-input">伝票番号</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="slip_number" class="form-control" id="slip_number-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light  align-middle ps-4">
					<label class="form-label ls-1" for="salesdate-input">売上日付</label>
				</th>
				<td>
					<div class="col-5">
						<input type="date" name="accounting_date" class="form-control" id="salesdate-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light  align-middle ps-4">
					<label class="form-label ls-1" for="division-input">部門</label>
				</th>
				<td>
					<div class="col-10">
						<select name="division" id="division-input" class="form-select"><option value="" selected>選択</option></select>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="team-input">チーム</label>
				</th>
				<td>
					<div class="col-10">
						<select name="team" id="team-input" class="form-select"><option value="" selected>選択</option></select>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="manager-input">当社担当者</label>
				</th>
				<td>
					<div class="col-10">
						<input name="manager" type="text" class="form-control" id="manager-input" placeholder="担当者名・担当者CD" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="applyClient-input">請求先</label>
				</th>
				<td>
					<div class="col-10">
						<input name="billing_destination" type="text" class="form-control" id="applyClient-input" placeholder="請求先名・請求先CD" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="manager-input">商品名</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="itemName" class="form-control" id="manager-input">
					</div>
				</td>
			</tr>
		</tbody>
	</table>
	<div class="col-12 text-center">
		<button type="button" class="btn btn-success" id="search">検　索</button>
	</div>
</fieldset></form>
<form id="import" action="{url action="import"}" method="POST"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 bg-white table-responsive">
		<table class="table table_sticky_list">
			<thead>
				<tr>
					<th></th>
					<th class="w-10">伝票番号</th>
					<th class="w-10">伝票日付</th>
					<th class="w-20">請求先名</th>
					<th class="w-10">担当者名</th>
					<th class="w-15">部門</th>
					<th class="w-10">チーム</th>
					<th class="w-20">備考欄</th>
				</tr>
			</thead>
			<tbody id="list">
				{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=[]}{strip}
				<tr>
					<td><input type="checkbox" name="id[]" value="{$obj.id}" checked /></td>
					<td>{$obj.slip_number}</td>
					<td>{$obj.accounting_date}</td>
					<td>{$obj.apply_client_name}</td>
					<td>{$obj.manager_name}</td>
					<td>{$obj.division_name}</td>
					<td>{$obj.team_name}</td>
					<td>{$obj.note}</td>
				</tr>
				{/strip}{/template_class}{/function}
			</tbody>
		</table>
		<div class="col-12 text-center">
			<button type="reset" class="btn btn-success">すべてチェック</button>
			<button type="button" id="checkall" class="btn btn-success">すべてチェックを外す</button>
			<button type="submit" class="btn btn-success">取　込</button>
		</div>
	</div>
</fieldset></form>
{/block}




{*
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
		const obj = yield this.gd.getAll("properties+has+{key='access'+and+value='billing'}");
		const tbody = document.querySelector('#drive tbody');
		const info = this.db.select("OBJECT").addTable("info").setField("key,value").apply();
		const dateFormatter = new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium", timeStyle: "medium", timeZone: "Asia/Tokyo"});

		let pObj = {};
		for(let item of obj.files){
			if("masterUpdate" in item.properties){
				let timestamp = Number(item.properties.masterUpdate);
				item.properties.masterUpdate = dateFormatter.format(new Date(timestamp * 1000));
				item.properties.masterUpdateFlag = (timestamp < info.update.value) ? "update" : null;
			}
			template.insertBeforeEnd(tbody, item);
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
		const info = this.db.select("OBJECT").addTable("info").setField("key,value").apply();
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
				rows: masterRowData,
				namedRanges: namedRanges,
				protectedRanges: [{}]
			})
		]).then(res => Promise.all([
			this.gd.createPermission(res.spreadsheetId),
			this.gd.setProperty(res.spreadsheetId, {access: "billing", masterUpdate: info.update.value})
		])).then(res => {location.reload();});
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
	<thead><th>ファイル名</th><th>種類</th><th>マスター更新日時</th><th>操作</th></thead>
	<tbody>
		{function name="DriveItem"}{template_class name="DriveItem" assign="obj" iterators=[]}{strip}
		<tr>
			<td><a target="_blank" href="https://docs.google.com/spreadsheets/d/{$obj.id}/edit">{$obj.name}</a></td>
			<td>{$obj.mimeType}</td>
			<td>{$obj.properties.masterUpdate}</td>
			<td data-master="{$obj.properties.masterUpdateFlag}">
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
*}