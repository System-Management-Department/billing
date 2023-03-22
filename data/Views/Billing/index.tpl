{block name="title"}請求データ検索{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
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
			yield* this.input(form);
		}while(true);
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		let history = this.strage.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", form.getAttribute("action"))
			.setOrderBy("time DESC")
			.apply();
		let {data, label} = yield* this.search(history);
		if(history != null){
			for(let input of form.elements){
				if(!input.hasAttribute("name")){
					continue;
				}
				let name = input.getAttribute("name");
				if((name in data) && (data[name].length > 0)){
					input.value = data[name].shift();
				}
			}
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
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
	},
	*search(history){
		let res = {data: null, label: null};
		let formData = new FormData();
		if(history != null){
			let {data, label} = res = JSON.parse(history.json);
			for(let k in data){
				for(let v of data[k]){
					formData.append(k, v);
				}
			}
		}
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: formData
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
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
		
		let select = document.querySelector('select[name="division"]');
		let mastarData = this.response.select("ALL")
			.addTable("divisions")
			.addField("code,name")
			.apply();
		for(let division of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: division.name});
			option.setAttribute("value", division.code);
			select.appendChild(option);
		}
		select = document.querySelector('select[name="team"]');
		mastarData = this.response.select("ALL")
			.addTable("teams")
			.addField("code,name")
			.apply();
		for(let team of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: team.name});
			option.setAttribute("value", team.code);
			select.appendChild(option);
		}
		
		let table = this.response.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.accounting_date,sales_slips.note")
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.leftJoin("apply_clients on sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name as apply_client_name")
			.apply();
		document.getElementById("list").insertAdjacentHTML("beforeend", table.map(row => this.template.listItem(row)).join(""));
		
		return res;
	},
	*input(form){
		let pObj = {};
		let controller = new AbortController();
		let outputForm = document.getElementById("output");
		
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
			document.querySelector('input[name="manager"]').value = "";
			document.querySelector('[data-search-label="manager"]').textContent = "";
			document.querySelector('input[name="billing_destination"]').value = "";
			document.querySelector('[data-search-label="billing_destination"]').textContent = "";
		});
		
		const changeEvent1 = e => {
			let table = this.response.select("ALL")
				.setTable("managers")
				.orWhere("name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#managerModal tbody').innerHTML = table.map(row => this.template.managerList(row)).join("");
		};
		const changeEvent2 = e => {
			let table = this.response.select("ALL")
				.setTable("apply_clients")
				.addField("apply_clients.*")
				.leftJoin("clients on apply_clients.client=clients.code")
				.addField("clients.name as client_name")
				.orWhere("apply_clients.name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.unique_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.short_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#applyClientModal tbody').innerHTML = table.map(row => this.template.applyClientList(row)).join("");
		};
		changeEvent1({currentTarget: document.getElementById("manager-input")});
		changeEvent2({currentTarget: document.getElementById("applyClient-input")});
		document.getElementById("manager-input").addEventListener("change", changeEvent1, {signal: controller.signal});
		document.getElementById("applyClient-input").addEventListener("change", changeEvent2, {signal: controller.signal});
		document.querySelector('#managerModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="manager"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="manager"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true, signal: controller.signal});
		document.querySelector('#applyClientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="billing_destination"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="billing_destination"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true, signal: controller.signal});
		document.querySelector('[data-search-output-reset="manager"]').addEventListener("click", e => {
			document.querySelector('input[name="manager"]').value = "";
			document.querySelector('[data-search-label="manager"]').textContent = "";
		}, {signal: controller.signal});
		document.querySelector('[data-search-output-reset="billing_destination"]').addEventListener("click", e => {
			document.querySelector('input[name="billing_destination"]').value = "";
			document.querySelector('[data-search-label="billing_destination"]').textContent = "";
		}, {signal: controller.signal});
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
			let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(new Date());
			let csvData = [new Uint8Array(Encoding.convert(Encoding.stringToCode([
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
				"明細単価"
			].join(",") + "\r\n"), {to: "SJIS", from: "UNICODE"}))];
			
			
			
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
				.leftJoin("managers on sales_slips.manager=managers.code")
				.addField("managers.name as manager_name")
				.leftJoin("apply_clients on sales_slips.billing_destination=apply_clients.code")
				.addField("apply_clients.name as client_name,apply_clients.kana as client_kana")
				.andWhere("is_checked(sales_slips.id)=1")
				.apply();
			for(let item of table){
				item.detail = JSON.parse(item.detail);
				let taxRate = 0.1;
				let cols = new Array(37);
				cols[0] = item.accounting_date.split("-").join("/");
				cols[1] = item.slip_number;
				cols[2] = item.billing_destination;
				cols[3] = item.client_name;
				cols[4] = item.total_amount;
				cols[5] = item.total_amount_s;
				cols[6] = item.total_amount + item.total_amount_s;
				cols[7] = item.payment_date.split("-").join("/");
				cols[8] = item.accounting_date.split("-").join("/");
				cols[9] = item.item_name;
				cols[10] = item.quantity;
				cols[11] = item.unit_price;
				cols[12] = item.amount;
				cols[13] = item.note;
				cols[14] = "";
				cols[15] = "";
				cols[16] = "";
				cols[17] = "";
				cols[18] = "";
				cols[19] = item.client_kana;
				cols[20] = today;
				cols[21] = item.total_amount + item.total_amount_s;
				cols[22] = item.subject;
				cols[23] = item.unit;
				cols[24] = item.header1;
				cols[25] = item.header2;
				cols[26] = item.header3;
				cols[27] = item.data1;
				cols[28] = item.data2;
				cols[29] = item.data3;
				cols[30] = item.total_amount_p;
				cols[31] = item.total_amount + item.total_amount_p;
				cols[32] = (typeof item.amount === "number") ? item.amount * taxRate : "";
				cols[33] = (typeof item.amount === "number") ? (item.amount + item.amount * taxRate) : "";
				cols[34] = item.manager_name;
				cols[35] = item.circulation;
				cols[36] = item.unit_price;
				
				csvData.push(new Uint8Array(Encoding.convert(Encoding.stringToCode(cols.map(v => {
					if(v == null){
						return "";
					}else if(typeof v === "string" && v.match(/[,"\r\n]/)){
						return `"${v.split('"').join('""')}"`;
					}
					return `${v}`;
				}).join(",") + "\r\n"), {to: "SJIS", from: "UNICODE"})));
			}
			
			let response = yield fetch(outputForm.getAttribute("action"), {
				method: outputForm.getAttribute("method"),
				body: res
			}).then(res => res.json());
			if(response.success){
				let blob = new Blob(csvData, {type: "text/csv"});
				let a = document.createElement("a");
				a.setAttribute("href", URL.createObjectURL(blob));
				a.setAttribute("download", "output.csv");
				a.click();
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "請求締データ", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				yield Flow.DB.commit();
				location.reload();
			}else{
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "請求締データ", message: message[0], type: message[1], name: message[2]}, {}).apply();
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
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
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
					<div class="col-10" data-search-output="container">
						<div class="input-group" data-search-output="form">
							<input type="search" class="form-control" id="manager-input" placeholder="担当者名・担当者CDで検索">
							<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#managerModal">検 索</button>
						</div>
						<div class="input-group" data-search-output="result">
							<div class="form-control" data-search-label="manager"></div>
							<input type="hidden" name="manager" value="" />
							<button type="button" class="btn btn-danger" data-search-output-reset="manager">取 消</button>
						</div>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="applyClient-input">請求先</label>
				</th>
				<td>
					<div class="col-10" data-search-output="container">
						<div class="input-group" data-search-output="form">
							<input type="search" class="form-control" id="applyClient-input" placeholder="請求先名・請求先CDで検索">
							<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#applyClientModal">検 索</button>
						</div>
						<div class="input-group" data-search-output="result">
							<div class="form-control" data-search-label="billing_destination"></div>
							<input type="hidden" name="billing_destination" value="" />
							<button type="button" class="btn btn-danger" data-search-output-reset="billing_destination">取 消</button>
						</div>
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
		<input type="hidden" name="output_processed" value="1" />
		<input type="hidden" name="close_processed" value="0" />
		<button type="submit" class="btn btn-success">検　索</button>
		<button type="reset" class="btn btn-outline-success">リセット</button>
	</div>
</fieldset></form>
<form id="output" action="{url action="close"}" method="POST"><fieldset disabled>
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