{block name="title"}売上データ取り込み画面{/block}

{block name="styles" append}
<style type="text/css">{literal}
[data-error~="apply_client"] [data-column="apply_client"],
[data-error~="manager"] [data-column="manager"],
[data-error~="division"] [data-column="division"],
[data-error~="team"] [data-column="team"]{
	background-color: #f8d7da;
	color: var(--bs-danger);
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/tesseract.js@4/dist/tesseract.min.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleSheets.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript" src="/assets/common/SJISEncoder.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="master"}",
	id: "{$smarty.get.id}",
	jwt: "{url controller="JWT" action="spreadsheet"}",{literal}
	response: new SQLite(),
	duplication: {},
	gs: null,
	template: null,
	template2: null,
	dataList: null,
	isChecked: {
		length: 1,
		apply: function(dummy, args){
			let id = `${args[0]}`;
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
		
		let createTables = [book.sheet("売上").range.slice(1), book.sheet("売上明細").range.slice(1)];
		yield* this.ocrProc(createTables);
		this.response.import(buffer, "list");
		this.response.createTable("slips", [
			"import", "id", "slip_number", "accounting_date", "division_name", "team_name", "manager_name", "billing_destination_name",
			"delivery_destination", "subject", "note", "header1", "header2", "header3", "payment_date", "invoice_format_name"
		], createTables[0]);
		this.response.createTable("details", [
			"id", "categoryName", "itemName", "unit", "quantity", "unitPrice", "amount", "data1", "data2", "data3", "circulation"
		], createTables[1]);
		
		this.response.create_function("equals", {
			length: 2,
			apply(dummy, args){
				return (args[0] == args[1]) ? 1 : 0;
			},
		});
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
		
		let select = document.querySelector('select[name="division"]');
		let mastarData = this.response.select("ALL")
			.addTable("divisions")
			.addField("code,name")
			.apply();
		for(let division of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: division.name});
			option.setAttribute("value", division.name);
			select.appendChild(option);
		}
		select = document.querySelector('select[name="team"]');
		mastarData = this.response.select("ALL")
			.addTable("teams")
			.addField("code,name")
			.apply();
		for(let team of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: team.name});
			option.setAttribute("value", team.name);
			select.appendChild(option);
		}
		
		let dataValidation = {
			divisions: this.response.select("COL").setTable("divisions").setField("name").apply(),
			// teams: this.response.select("COL").setTable("teams").setField("name").apply(),
			managers: this.response.select("COL").setTable("managers").setField("name").apply(),
			apply_clients: this.response.select("COL").setTable("apply_clients").setField("unique_name").apply(),
			apply(row){
				let res = [];
				if(!this.divisions.includes(row.division_name)){
					res.push("division");
				}
				if(!this.managers.includes(row.manager_name)){
					res.push("manager");
				}
				if(!this.apply_clients.includes(row.billing_destination_name)){
					res.push("apply_client");
				}
				return res.join(" ");
			}
		};
		this.duplication = this.response.select("OBJECT").setTable("slips").setField("slip_number,count(1) as `count`").andWhere("import=0").andWhere("slip_number<>''").setGroupBy("slip_number").setHaving("count(1)>1").apply();
		this.template = new Template(dataValidation, (a, k) => (k in a) ? 1 : 0);
		this.template2 = new Template(i => i + 1);
		this.dataList = document.getElementById("list");
		this.dataList.addEventListener("click", e => {
			if((e.target.nodeType == Node.ELEMENT_NODE) && (e.target.hasAttribute("data-info"))){
				let id = e.target.getAttribute("data-info");
				let info = this.response.select("ROW")
					.setTable("slips")
					.andWhere("equals(id,?)", id)
					.apply();
				let details = this.response.select("ALL")
					.setTable("details")
					.andWhere("equals(id,?)", info.slip_number)
					.apply();
				let listinfo = document.getElementById("listinfo");
				listinfo.innerHTML = this.template2.listInfo(info, details);
			}
		}, {useCapture: true});
		let parameter = new FormData();
		do{
			yield* this.search(parameter);
			parameter = yield* this.input(targetId);
		}while(true);
	},
	*ocrProc(createTables){
		let worker = yield Tesseract.createWorker({});
		yield worker.loadLanguage('jpn');
		yield worker.initialize('jpn');
		let chary = "";
		for(let cd in SJISEncoder.table){
			if(cd > 0xff){
				chary += String.fromCharCode(cd);
			}
		}
		worker.setParameters({
			tessedit_char_whitelist: chary
		});
		let tch = {};
		for(let table of createTables){
			for(let row of table){
				for(let i = row.length - 1; i >= 0; i--){
					let val = row[i];
					if(typeof val !== "string"){
						continue;
					}
					let nval = "";
					for(let ch of val){
						if(ch.codePointAt(0) in SJISEncoder.table){
							nval += ch;
							continue;
						}
						if(ch in tch){
							nval += tch[ch];
							continue;
						}
						const canvas = Object.assign(document.createElement("canvas"), {width: 100, height: 100});
						Object.assign(canvas.getContext("2d"), {font: "50px serif"}).fillText(ch, 0, 50);
						const res = yield worker.recognize(canvas);
						tch[ch] = res.data.text.replace(/\s/g, "");
						nval += tch[ch];
					}
					row[i] = nval;
				}
			}
		}
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
					q.andWhere("slip_number IN(SELECT id FROM details WHERE itemName like '%' || ? || '%')", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			mode(q, v){
				if(v == "2"){
					q.andWhere("billing_destination_name IS NOT NULL")
					.andWhere("billing_destination_name<>''");
				}
				if(v == "3"){
					q.andWhere("billing_destination_name IS NOT NULL")
					.andWhere("billing_destination_name<>''")
					.andWhere("EXISTS(SELECT 1 FROM details WHERE details.id=slips.id AND (details.amount > 0 OR details.amount < 0))");
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
		let html = "";
		let added = {};
		for(let row of table){
			if(row.slip_number in this.duplication){
				if(row.slip_number in added){
					continue;
				}else{
					added[row.slip_number] = 1;
				}
			}
			html += this.template.listItem(row, this.duplication);
		}
		this.dataList.innerHTML = html;
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
				.addField("CASE WHEN slips.delivery_destination IS NULL THEN '' ELSE slips.delivery_destination END AS delivery_destination")
				.addField("slips.subject")
				.addField("slips.note")
				.addField("slips.header1")
				.addField("slips.header2")
				.addField("slips.header3")
				.addField("slips.payment_date")
				.leftJoin("invoice_formats on slips.invoice_format_name=invoice_formats.name")
				.addField("invoice_formats.id as invoice_format")
				.leftJoin("details on slips.slip_number=details.id")
				.leftJoin("categories on details.categoryName=categories.name")
				.addField("sales_tax(details.amount) as sales_tax")
				.addField("json_detail(categories.code, details.itemName, details.unit, details.quantity, details.unitPrice, details.amount, details.data1, details.data2, details.data3, details.circulation) as detail")
				.andWhere("is_checked(slips.slip_number)=1")
				.setGroupBy("slips.slip_number")
				.apply();
			
			let formData = new FormData();
			formData.append("json", JSON.stringify(importData));
			formData.append("spreadsheets", this.gs.getId());
			let response = yield fetch(form.getAttribute("action"), {
				method: form.getAttribute("method"),
				body: formData
			}).then(res => res.json());
			if(response.success){
				if(document.getElementById("update").checked){
					this.gs.update({
						[GoogleSheets.requestSymbol]: "appendCells",
						[targetId]: this.isChecked.values.map(r => [r, GoogleSheets.now])
					});
					this.response.updateSet("slips", {import: 1}, {}).andWhere("is_checked(slip_number)=1").apply();
				}
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
<form class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row gap-4 align-items-start" disabled>
	<table class="col table">
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
	<table class="col table">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="mode-input">検索条件</label>
				</th>
				<td>
					<div class="col-10">
						<select name="mode" class="form-select" id="mode-input">
							<option value="1" selected>伝票番号が設定されているもの</option>
							<option value="2">伝票番号・請求先が設定されているもの</option>
							<option value="3">伝票番号・請求先・金額が設定されているもの</option>
						</select>
					</div>
				</td>
			</tr>
		</tbody>
	</table>
	<div class="col-12 text-center">
		<button type="button" class="btn btn-success" id="search">検　索</button>
	</div>
</fieldset></form>
<label class="ms-3"><input type="checkbox" id="update" checked />スプレッドシートを取込済に更新</label>
<form id="import" action="{url action="import"}" method="POST"><fieldset disabled>
	<div class="container border border-secondary rounded p-4 bg-white table-responsive">
		<table class="table table_sticky_list" data-scroll-y="list">
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
					<th></th>
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" constructor=["dataValidation","exists"] assign=["obj", "duplication"]}
				<tr data-error="{$dataValidation.apply|predef_invoke:$obj}">
					<td><input type="checkbox" name="id[]" value="{$obj.slip_number}" checked /></td>
					<td>{$obj.slip_number}</td>
					<td>{$obj.accounting_date}</td>
					<td data-column="apply_client">{$obj.billing_destination_name}</td>
					<td data-column="manager">{$obj.manager_name}</td>
					<td data-column="division">{$obj.division_name}</td>
					<td data-column="team">{$obj.team_name}</td>
					<td>{$obj.note}</td>
					<td>
						{predef_repeat loop=$exists|predef_invoke:$duplication:$obj.slip_number}
						<span class="text-danger">伝票番号の重複が{$duplication[$obj.slip_number].count}行あります。</span>
						{/predef_repeat}
						<button type="button" class="btn btn-sm btn-info" data-bs-toggle="modal" data-bs-target="#infoModal" data-info="{$obj.id}">詳細</button>
					</td>
				</tr>
			{/predefine}</tbody>
		</table>
		<div class="col-12 text-center">
			<button type="reset" class="btn btn-success">すべてチェック</button>
			<button type="button" id="checkall" class="btn btn-success">すべてチェックを外す</button>
			<button type="submit" class="btn btn-success">取　込</button>
		</div>
	</div>
</fieldset></form>
{/block}

{block name="dialogs"}
<div class="modal fade" id="infoModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">売上明細</div>
			<div class="modal-body" id="listinfo">{predefine name="listInfo" constructor="inc" assign=["header","detail"]}
				<table class="table">
					<tbody>
						<tr>
							<th scope="row" class="bg-light align-middle ps-4">伝票番号</th>
							<td>{$header.slip_number}</td>
						</tr>
					</tbody>
				</table>
				<table class="table table-md table_sticky_list">
					<thead>
						<tr>
							<th>No</th>
							<th>商品カテゴリー</th>
							<th>内容（摘要）</th>
							<th>単位</th>
							<th>数量</th>
							<th>単価</th>
							<th>金額</th>
							<th>{$header.header1}</th>
							<th>{$header.header2}</th>
							<th>{$header.header3}</th>
							<th>発行部数</th>
						</tr>
					</thead>
					<tbody>
						{predef_repeat loop=$detail.length index="i"}
						<tr>
							<td>{$inc|predef_invoke:$i}</td>
							<td>{$detail[$i].categoryName}</td>
							<td>{$detail[$i].itemName}</td>
							<td>{$detail[$i].unit}</td>
							<td>{$detail[$i].quantity}</td>
							<td>{$detail[$i].unitPrice}</td>
							<td>{$detail[$i].amount}</td>
							<td>{$detail[$i].data1}</td>
							<td>{$detail[$i].data2}</td>
							<td>{$detail[$i].data3}</td>
							<td>{$detail[$i].circulation}</td>
						</tr>
						{/predef_repeat}
					</tbody>
				</table>
			{/predefine}</div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>閉じる<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}
