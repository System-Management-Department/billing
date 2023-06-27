{block name="title"}請求データ検索{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
<script type="text/javascript" src="/assets/common/CSVSerializer.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	isChecked: {
		length: 1,
		apply: function(dummy, args){
			let id = args[0].toString();
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
	template: new Template(),
	*[Symbol.iterator](){
		const form = document.querySelector('form');
		yield* this.init(form);
		do{
			yield* this.search(form);
			yield* this.input(form);
		}while(true);
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		
		// datalist初期化
		let datalist = document.getElementById("division");
		let mastarData = Flow.Master.select("ALL")
			.addTable("divisions")
			.addField("code,name")
			.apply();
		for(let division of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: division.name});
			option.setAttribute("value", division.code);
			datalist.appendChild(option);
		}
		datalist = document.getElementById("team");
		mastarData = Flow.Master.select("ALL")
			.addTable("teams")
			.addField("code,name")
			.apply();
		for(let team of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: team.name});
			option.setAttribute("value", team.code);
			datalist.appendChild(option);
		}
		
		// ダイアログ初期化
		const managerModal = new bootstrap.Modal(document.getElementById("managerModal"));
		const managerForm = document.querySelector('row-form[name="manager"]');
		const managerSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("managers")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				managerSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("managers")
					.orWhere("name like ('%' || ? || '%')", keyword)
					.orWhere("code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#managerModal tbody').innerHTML = table.map(row => this.template.managerList(row)).join("");
			},
			showModal: () => { managerModal.show(); },
			resetValue: () => { managerForm.value = ""; }
		});
		managerSearch.syncAttribute(managerForm);
		managerForm.bind(managerSearch, managerSearch.valueProperty);
		document.querySelector('#managerModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				managerForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
		const applyClientModal = new bootstrap.Modal(document.getElementById("applyClientModal"));
		const applyClientForm = document.querySelector('row-form[name="billing_destination"]');
		const applyClientSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("apply_clients")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				applyClientSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("apply_clients")
					.addField("apply_clients.*")
					.leftJoin("clients on apply_clients.client=clients.code")
					.addField("clients.name as client_name")
					.orWhere("apply_clients.name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.unique_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.short_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#applyClientModal tbody').innerHTML = table.map(row => this.template.applyClientList(row)).join("");
			},
			showModal: () => { applyClientModal.show(); },
			resetValue: () => { applyClientForm.value = ""; }
		});
		applyClientSearch.syncAttribute(applyClientForm);
		applyClientForm.bind(applyClientSearch, applyClientSearch.valueProperty);
		document.querySelector('#applyClientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				applyClientForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
		
		// イベントを設定
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let formData = new FormData(form);
			let obj = {data:{}, label:{}};
			for(let k of formData.keys()){
				if(k in obj.data){
					continue;
				}
				obj.data[k] = formData.getAll(k);
			}
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				obj.label[key] = searchLabels[i].innerHTML;
			}
			let sy = {};
			const scrollY = document.querySelectorAll('[data-scroll-y]');
			for(let i = scrollY.length - 1; i >= 0; i--){
				let ele = scrollY[i];
				sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
			}
			this.strage.insertSet("search_histories", {
				location: form.getAttribute("action"),
				json: JSON.stringify(obj),
				time: Date.now(),
				scroll_y: JSON.stringify(sy)
			}, {}).apply();
			this.strage.commit().then(e => {
				location.href = form.getAttribute("action");
				location.reload();
			});
		});
		form.addEventListener("reset", e => {
			const rowForms = document.querySelectorAll('row-form');
			for(let i = rowForms.length - 1; i >= 0; i--){
				rowForms[i].reset();
			}
		});
		
		// 検索履歴
		let history = this.strage.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", form.getAttribute("action"))
			.setOrderBy("time DESC")
			.apply();
		if(history != null){
			let {data, label} = JSON.parse(history.json);
			const searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
				}
			}
			const rowForms = document.querySelectorAll('row-form[name]');
			for(let i = rowForms.length - 1; i >= 0; i--){
				let name = rowForms[i].getAttribute("name");
				if((name in data) && (data[name].length > 0)){
					rowForms[i].value = data[name].shift();
				}
			}
			
			this.y = JSON.parse(history.scroll_y);
			addEventListener("beforeunload", e => {
				let sy = {};
				const scrollY = document.querySelectorAll('[data-scroll-y]');
				for(let i = scrollY.length - 1; i >= 0; i--){
					let ele = scrollY[i];
					sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
				}
				this.strage.updateSet("search_histories", {
					scroll_y: JSON.stringify(sy)
				}, {})
					.andWhere("location=?", history.location)
					.andWhere("time=?", history.time)
					.apply();
				this.strage.commit();
			});
		}
		
		// フォームを有効化
		form.querySelector('fieldset').disabled = false;
	},
	*search(form){
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body:  new FormData(form)
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		this.response.attach(Flow.Master, "master");
		this.response.create_function("is_checked", this.isChecked);
		this.response.create_function("detail_each", {
			length: 1,
			apply(dummy, args){
				let taxRate = 0.1;
				let obj = JSON.parse(args[0]);
				let values = {amount: 0, amountPt: 0, amountSt: 0};
				for(let i = 0; i < obj.length; i++){
					if(typeof obj.amount[i] === "number"){
						values.amount += obj.amount[i];
						values.amountPt += obj.amount[i] * taxRate;
					}
				}
				values.amountSt = values.amount * taxRate;
				let res = new Array(obj.length).fill(values);
				return JSON.stringify(res);
			}
		});
		
		let table = this.response.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.accounting_date,sales_slips.note")
			.leftJoin("master.divisions as divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("master.teams as teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("master.managers as managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.leftJoin("master.apply_clients as apply_clients on sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name as apply_client_name")
			.apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
	},
	*input(form){
		let pObj = {};
		let controller = new AbortController();
		let outputForm = document.getElementById("output");
		
		outputForm.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			pObj.resolve(new FormData(outputForm));
		}, {signal: controller.signal});
		
		document.getElementById("checkall").addEventListener("click", e => {
			let checked = outputForm.querySelectorAll('input:checked:not([disabled])');
			for(let i = checked.length - 1; i >= 0; i--){
				checked[i].checked = false;
			}
		}, {signal: controller.signal});
		
		// フォームを有効化
		let fieldsets = document.querySelectorAll('form fieldset:disabled');
		for(let i = fieldsets.length - 1; i >= 0; i--){
			fieldsets[i].disabled = false;
		}
		
		if(this.y != null){
			const scrollY = document.querySelectorAll('[data-scroll-y]');
			for(let i = scrollY.length - 1; i >= 0; i--){
				let ele = scrollY[i];
				let k = ele.getAttribute("data-scroll-y");
				if(k in this.y){
					ele.scrollTop = this.y[k]
				}
			}
			this.y = null;
		}
		let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		
		// 設定したイベントを一括削除
		controller.abort();
		
		// 検索条件を設定
		if(res instanceof FormData){
			let checked = outputForm.querySelectorAll('input:checked:not([disabled])');
			this.isChecked.reset(checked);
		}
		
		// フォームを無効化
		for(let i = fieldsets.length - 1; i >= 0; i--){
			fieldsets[i].disabled = true;
		}
		
		// 出力
		if(res instanceof FormData){
			let vSerializer = new CSVSerializer((val, col) => {
				if(col == 2){
					return (typeof val === 'string') ? val.replace(/-.*$/, "") : val;
				}
				if(
					(col == 4) || (col == 5) || (col == 6) ||
					(col == 12) || (col == 21) || (col == 30) ||
					(col == 31) || (col == 32) || (col == 33)){
					return (typeof val === "number") ? Math.floor(val) : "";
				}
				if((col == 7) || (col == 8)){
					return (typeof val === "string") ? val.split("-").join("/") : val;
				}
				if(col == 37){
					if(Array.isArray(val)){
						let date = new Date(val[0]);
						if(val[1] == 99){
							date.setMonth(date.getMonth() + 1);
							date.setDate(-1);
						}else{
							date.setDate(val[1]);
						}
						return Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(date);
					}
				}
				return val;
			}).setHeader([
				"対象日付",
				"帳票No",
				"顧客コード",
				"顧客名",
				"税抜金額",
				"消費税",
				"合計金額",
				"支払期限",
				"明細日付",
				"摘要",
				"数量",
				"明細単価",
				"明細金額",
				"備考(見出し)",
				"税抜金額(8%)",
				"税抜金額(10%)",
				"消費税(8%)",
				"消費税(10%)",
				"税率",
				"顧客名カナ",
				"請求日",
				"請求金額",
				"件名",
				"単位",
				"摘要ヘッダー１",
				"摘要ヘッダー２",
				"摘要ヘッダー３",
				"摘要ヘッダー１値",
				"摘要ヘッダー２値",
				"摘要ヘッダー３値",
				"消費税(明細別合計)",
				"税込金額(明細合計)",
				"消費税(明細別)",
				"税込金額(明細別)",
				"担当者氏名",
				"発行部数",
				"明細単価",
				"売上日"
			]).setFilter(data => data[6] > 0)
			.setConverter(data => new Blob([new Uint8Array(Encoding.convert(Encoding.stringToCode(data), {to: "SJIS", from: "UNICODE"}))], {type: "text/csv"}));
			let now = new Date();
			let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(now);
			let csvData = [];
			
			let table = this.response.select("ALL")
				.addTable("sales_slips")
				.addTable("json_each(detail_each(sales_slips.detail)) as d")
				.addField("sales_slips.*")
				.addField("json_extract(sales_slips.detail, '$.amount[' || d.key || ']') as amount")
				.addField("json_extract(sales_slips.detail, '$.itemName[' || d.key || ']') as item_name")
				.addField("json_extract(sales_slips.detail, '$.quantity[' || d.key || ']') as quantity")
				.addField("json_extract(sales_slips.detail, '$.unitPrice[' || d.key || ']') as unit_price")
				.addField("json_extract(sales_slips.detail, '$.unit[' || d.key || ']') as unit")
				.addField("json_extract(sales_slips.detail, '$.data1[' || d.key || ']') as data1")
				.addField("json_extract(sales_slips.detail, '$.data2[' || d.key || ']') as data2")
				.addField("json_extract(sales_slips.detail, '$.data3[' || d.key || ']') as data3")
				.addField("json_extract(d.value, '$.amount') as total_amount")
				.addField("json_extract(d.value, '$.amountPt') as total_amount_p")
				.addField("json_extract(d.value, '$.amountSt') as total_amount_s")
				.leftJoin("master.managers as managers on sales_slips.manager=managers.code")
				.addField("managers.name as manager_name")
				.leftJoin("master.apply_clients as apply_clients on sales_slips.billing_destination=apply_clients.code")
				.addField("apply_clients.name as client_name,apply_clients.kana as client_kana,apply_clients.close_date as client_close")
				.andWhere("is_checked(sales_slips.id)=1")
				.apply();
			for(let item of table){
				item.detail = JSON.parse(item.detail);
				let taxRate = 0.1;
				let cols = [
					item.accounting_date.split("-").join("/"),
					item.slip_number,
					item.billing_destination,
					item.client_name,
					item.total_amount,
					item.total_amount_s,
					item.total_amount + item.total_amount_s,
					item.payment_date,
					item.accounting_date,
					item.item_name,
					item.quantity,
					item.unit_price,
					item.amount,
					item.note,
					"",
					"",
					"",
					"",
					"",
					item.client_kana,
					today,
					item.total_amount + item.total_amount_s,
					item.subject,
					item.unit,
					item.header1,
					item.header2,
					item.header3,
					item.data1,
					item.data2,
					item.data3,
					item.total_amount_p,
					item.total_amount + item.total_amount_p,
					(typeof item.amount === "number") ? item.amount * taxRate : "",
					(typeof item.amount === "number") ? (item.amount + item.amount * taxRate) : "",
					item.manager_name,
					item.circulation,
					item.unit_price,
					(item.client_close == null) ? today : [now, item.client_close]
				];
				
				csvData.push(cols);
			}
			
			let blob = vSerializer.serializeToString(csvData);
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "output.csv");
			a.click();
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<datalist id="division"><option value="">選択</option></datalist>
	<datalist id="team"><option value="">選択</option></datalist>
	<div class="d-table w-50 mb-3">
		<row-form label="伝票番号" col="5" name="slip_number" type="text"></row-form>
		<row-form label="売上日付（開始日）" col="8" name="accounting_date[from]" type="date">{"first day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
		<row-form label="売上日付（終了日）" col="8" name="accounting_date[to]" type="date">{"last day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
		<row-form label="部門" col="10" name="division" type="select" list="division"></row-form>
		<row-form label="チーム" col="10" name="team" type="select" list="team"></row-form>
		<row-form label="当社担当者" col="10" name="manager" placeholder="担当者名・担当者CDで検索"></row-form>
		<row-form label="請求先" col="10" name="billing_destination" placeholder="請求先名・請求先CDで検索"></row-form>
		<row-form label="商品名" col="10" name="itemName" type="text"></row-form>
	</div>
	<div class="col-12 text-center">
		<input type="hidden" name="close_processed" value="1" />
		<button type="submit" class="btn btn-success">検　索</button>
		<button type="reset" class="btn btn-outline-success">リセット</button>
	</div>
</fieldset></form>
<form id="output" action="{url action="output"}" method="POST"><fieldset disabled>
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
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" assign="obj"}
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
			{/predefine}</tbody>
		</table>
		<div class="col-12 text-center">
			<button type="reset" class="btn btn-outline-success">すべてチェック</button>
			<button type="button" id="checkall" class="btn btn-outline-success">すべてチェックを外す</button>
			<button type="submit" class="btn btn-success">出　力</button>
		</div>
	</div>
</fieldset></form>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="managerModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">当社担当者選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
				<table class="table table_sticky_list">
					<thead>
						<tr>
							<th>コード</th>
							<th>担当者名</th>
							<th>カナ</th>
							<th></th>
						</tr>
					</thead>
					<tbody>{predefine name="managerList" assign="obj"}
						<tr>
							<td>{$obj.code}</td>
							<td>{$obj.name}</td>
							<td>{$obj.kana}</td>
							<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
						</tr>
					{/predefine}</tbody>
				</table>
			</div>
		</div>
	</div>
</div>
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
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
							<th>請求先名</th>
							<th>カナ</th>
							<th></th>
						</tr>
					</thead>
					<tbody>{predefine name="applyClientList" assign="obj"}
						<tr>
							<td>{$obj.code}</td>
							<td>{$obj.client_name}</td>
							<td>{$obj.name}</td>
							<td>{$obj.kana}</td>
							<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
						</tr>
					{/predefine}</tbody>
				</table>
			</div>
		</div>
	</div>
</div>
{/block}