{block name="title"}売上伝票出力{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
	deleteURL: "{url action="delete"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	attrEntries1: [
		["slip_number", "伝票番号"],
		["accounting_date", "売上日付"],
		["division", "部門コード"],
		["division_name", "部門名"],
		["team", "チームコード"],
		["team_name", "チーム名"],
		["manager", "当社担当者コード"],
		["manager_name", "当社担当者名"],
		["manager_kana", "当社担当者カナ"],
		["billing_destination", "請求先コード"],
		["apply_client_name", "請求先名"],
		["apply_client_kana", "請求先カナ"],
		["apply_client_short_name", "請求先略式名称"],
		["client_code", "得意先コード"],
		["client_name", "得意先名"],
		["client_kana", "得意先カナ"],
		["client_short_name", "得意先略式名称"],
		["delivery_destination", "納品先"],
		["subject", "件名"],
		["note", "備考"],
		["payment_date", "支払期日"]
	],
	attrEntries2: [
		["categoryCode", "カテゴリーコード"],
		["itemName", "商品名"],
		["unit", "単位"],
		["quantity", "数量"],
		["unitPrice", "単価"],
		["amount", "金額"],
		["circulation", "発行部数"]
	],
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
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.accounting_date,sales_slips.note,sales_slips.output_processed")
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
			let xParser = new DOMParser();
			let xSerializer = new XMLSerializer();
			let xDoc = xParser.parseFromString('<?xml version="1.0" encoding="UTF-8"?>\n<売上 xmlns:摘要="/data"/>', "application/xml");
			let xRoot = xDoc.documentElement;
			let categories = this.response.select("OBJECT")
				.addTable("categories")
				.addField("code,name")
				.apply();
			this.isChecked.reset(outputForm.querySelectorAll('input:checked:not([disabled])'));
			let table = this.response.select("ALL")
				.addTable("sales_slips")
				.addField("sales_slips.*")
				.leftJoin("divisions on sales_slips.division=divisions.code")
				.addField("divisions.name as division_name")
				.leftJoin("teams on sales_slips.team=teams.code")
				.addField("teams.name as team_name")
				.leftJoin("managers on sales_slips.manager=managers.code")
				.addField("managers.name as manager_name,managers.kana as manager_kana")
				.leftJoin("apply_clients on sales_slips.billing_destination=apply_clients.code")
				.addField("apply_clients.name as apply_client_name")
				.addField("apply_clients.kana as apply_client_kana")
				.addField("apply_clients.short_name as apply_client_short_name")
				.addField("apply_clients.client as client_code")
				.leftJoin("clients on apply_clients.client=clients.code")
				.addField("clients.name as client_name")
				.addField("clients.kana as client_kana")
				.addField("clients.short_name as client_short_name")
				.andWhere("is_checked(sales_slips.id)=1")
				.apply();
			for(let item of table){
				let xElement1 = xDoc.createElement("伝票");
				for(let [k, attr] of this.attrEntries1){
					if(item[k] != null){
						xElement1.setAttribute(attr, item[k]);
					}
				}
				let detail = JSON.parse(item.detail);
				for(let i = 0; i < detail.length; i++){
					let xElement2 = xDoc.createElement("明細");
					for(let [k, attr] of this.attrEntries2){
						if(detail[k][i] != null){
							xElement2.setAttribute(attr, detail[k][i]);
						}
					}
					if(detail.categoryCode[i] in categories){
						xElement2.setAttribute("カテゴリー名", categories[detail.categoryCode[i]].name);
					}
					if((item["header1"] != null) && (detail["data1"] != null)){
						xElement2.setAttribute("摘要:" + item["header1"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data1"]);
					}
					if((item["header2"] != null) && (detail["data2"] != null)){
						xElement2.setAttribute("摘要:" + item["header2"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data2"]);
					}
					if((item["header3"] != null) && (detail["data3"] != null)){
						xElement2.setAttribute("摘要:" + item["header3"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data3"]);
					}
					xElement1.appendChild(xElement2);
				}
				xRoot.appendChild(xElement1);
			}
			
			let response = yield fetch(outputForm.getAttribute("action"), {
				method: outputForm.getAttribute("method"),
				body: res
			}).then(res => res.json());
			if(response.success){
				let blob;
				let downloadName;
				yield fetch("/assets/common/salesOutput.xsl").then(res => res.text()).then(text => {
					const proc = new XSLTProcessor();
					proc.importStylesheet(xParser.parseFromString(text, "application/xml"));
					const tDoc = proc.transformToDocument(xDoc);
					blob = new Blob([xSerializer.serializeToString(tDoc)], {type: "text/html"});
					downloadName = "output.html";
				}).catch(e => {
					blob = new Blob([xSerializer.serializeToString(xDoc)], {type: "application/xml"});
					downloadName = "output.xml";
				});
				
				let a = document.createElement("a");
				a.setAttribute("href", URL.createObjectURL(blob));
				a.setAttribute("download", downloadName);
				a.click();
				
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "売上伝票出力", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				yield Flow.DB.commit();
				location.reload();
			}else{
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
			};
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
				<tr{predef_repeat loop=$obj.output_processed} class="table-success"{/predef_repeat}>
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