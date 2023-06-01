{block name="title"}案件データ検索画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
class DeleteListItem{{/literal}
	static modifiers = JSON.parse("{$modifiers|@json_encode|escape:"javascript"}");{literal}
	#url;#id;#db;#pObj;#template;
	constructor(url, id, db, pObj){
		this.#url = url;
		this.#id = id;
		this.#db = db;
		this.#pObj = pObj;
		this.#template = new Template(DeleteListItem.modifiers.confidence, DeleteListItem.modifiers.invoiceFormat, {func: new Intl.NumberFormat(), format(value){ return (typeof value === 'number') ? this.func.format(value) : value; }});
	}
	*[Symbol.iterator](){
		let table = this.#db.select("ROW")
			.addTable("projects")
			.andWhere("id=?", Number(this.#id))
			.addField("projects.code")
			.addField("projects.confidence")
			.addField("projects.billing_month")
			.addField("projects.invoice_delivery")
			.addField("projects.payment_date")
			.addField("projects.subject")
			.addField("projects.invoice_format")
			.addField("projects.header1")
			.addField("projects.header2")
			.addField("projects.header3")
			.addField("projects.note")
			.addField("projects.ingest")
			.leftJoin("master.managers as managers on projects.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.leftJoin("master.clients as clients on projects.client=clients.code")
			.addField("clients.name as client_name")
			.leftJoin("master.apply_clients as apply_clients on projects.apply_client=apply_clients.code")
			.addField("apply_clients.name as apply_client_name")
			.apply();
		document.querySelector('#deleteModal .modal-body').innerHTML = this.#template.deleteModal(table);
		
		let res = yield new Promise((resolve, reject) => { Object.assign(this.#pObj, {resolve: resolve, reject: reject}); });
		this.#pObj.value = false;
		if(res){
			let formData = new FormData();
			formData.append("id", this.#id);
			fetch(this.#url, {
				method: "POST",
				body: formData
			})
			.then(response => response.json())
			.then(response => {
				if(response.success){
					// フォーム送信 成功
					for(let message of response.messages){
						Flow.DB.insertSet("messages", {title: "案件削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
					}
					Flow.DB.commit().then(res => { location.reload(); });
				}
			});
		}
	}
}
Flow.start({{/literal}
	modifiers: JSON.parse("{$modifiers|@json_encode|escape:"javascript"}"),
	dbDownloadURL: "{url action="search"}",
	deleteURL: "{url action="delete"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	template: null,
	*[Symbol.iterator](){
		this.template = new Template(this.modifiers.confidence, this.modifiers.invoiceFormat);
		const form = document.querySelector('form');
		yield* this.init(form);
		form.querySelector('fieldset:disabled').disabled = false;
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
			document.querySelector('input[name="apply_client"]').value = "";
			document.querySelector('[data-search-label="apply_client"]').textContent = "";
			document.querySelector('input[name="client"]').value = "";
			document.querySelector('[data-search-label="client"]').textContent = "";
		});
		
		const changeEvent1 = e => {
			let table = this.response.select("ALL")
				.setTable("master.managers")
				.orWhere("name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#managerModal tbody').innerHTML = table.map(row => this.template.managerList(row)).join("");
		};
		const changeEvent2 = e => {
			let table = this.response.select("ALL")
				.setTable("master.apply_clients as apply_clients")
				.addField("apply_clients.*")
				.leftJoin("master.clients as clients on apply_clients.client=clients.code")
				.addField("clients.name as client_name")
				.orWhere("apply_clients.name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.unique_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.short_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("apply_clients.code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#applyClientModal tbody').innerHTML = table.map(row => this.template.applyClientList(row)).join("");
		};
		const changeEvent3 = e => {
			let table = this.response.select("ALL")
				.setTable("master.clients as clients")
				.addField("clients.*")
				.orWhere("clients.name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("clients.short_name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("clients.code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#clientModal tbody').innerHTML = table.map(row => this.template.clientList(row)).join("");
		};
		changeEvent1({currentTarget: document.getElementById("manager-input")});
		changeEvent2({currentTarget: document.getElementById("applyClient-input")});
		changeEvent3({currentTarget: document.getElementById("client-input")});
		document.getElementById("manager-input").addEventListener("change", changeEvent1);
		document.getElementById("applyClient-input").addEventListener("change", changeEvent2);
		document.getElementById("client-input").addEventListener("change", changeEvent3);
		document.querySelector('#managerModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="manager"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="manager"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true});
		document.querySelector('#applyClientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="apply_client"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="apply_client"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true});
		document.querySelector('#clientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="client"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="client"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true});
		document.querySelector('[data-search-output-reset="manager"]').addEventListener("click", e => {
			document.querySelector('input[name="manager"]').value = "";
			document.querySelector('[data-search-label="manager"]').textContent = "";
		});
		document.querySelector('[data-search-output-reset="apply_client"]').addEventListener("click", e => {
			document.querySelector('input[name="apply_client"]').value = "";
			document.querySelector('[data-search-label="apply_client"]').textContent = "";
		});
		document.querySelector('[data-search-output-reset="client"]').addEventListener("click", e => {
			document.querySelector('input[name="client"]').value = "";
			document.querySelector('[data-search-label="client"]').textContent = "";
		});
		
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
		this.response.attach(Flow.Master, "master");
		
		let table = this.response.select("ALL")
			.addTable("projects")
			.addField("projects.id")
			.addField("projects.code")
			.addField("projects.confidence")
			.addField("projects.billing_month")
			.addField("projects.invoice_delivery")
			.addField("projects.payment_date")
			.addField("projects.subject")
			.addField("projects.invoice_format")
			.addField("projects.header1")
			.addField("projects.header2")
			.addField("projects.header3")
			.addField("projects.note")
			.addField("projects.ingest")
			.leftJoin("master.managers as managers on projects.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.leftJoin("master.clients as clients on projects.client=clients.code")
			.addField("clients.name as client_name")
			.leftJoin("master.apply_clients as apply_clients on projects.apply_client=apply_clients.code")
			.addField("apply_clients.name as apply_client_name")
			.apply();
		let tbody = document.getElementById("list");
		tbody.insertAdjacentHTML("beforeend", table.map(row => this.template.listItem(row)).join(""));
		
		this.response.create_function("json_table", {
			length: 1,
			apply(dummy, args){
				let data = JSON.parse(args[0]);
				let keys = Object.keys(data).filter(k => Array.isArray(data[k]));
				let res = [];
				for(let i = 0; i < data.length; i++){
					let row = {};
					for(let k of keys){
						row[k] = data[k][i];
					}
					res.push(row);
				}
				return JSON.stringify(res);
			}
		});
		let pObj = {value: false};
		tbody.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-delete")){
				co(new DeleteListItem(this.deleteURL, e.target.getAttribute("data-search-delete"), this.response, pObj));
			}
		}, {useCapture: true});
		document.getElementById("deleteModal").addEventListener("hidden.bs.modal", e => {
			pObj.resolve(pObj.value);
		});
		document.getElementById("deleteModalYes").addEventListener("click", e => {
			pObj.value = true;
		});
		
		return res;
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
					<label class="form-label ls-1" for="code-input">案件番号</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="code" class="form-control" id="code-input" />
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
				<th scope="row" class="bg-light  align-middle ps-4">
					<label class="form-label ls-1" for="confidence-input">確度</label>
				</th>
				<td>
					<div class="col-10">
						<select name="confidence" id="confidence-input" class="form-select">{foreach from=["" => "選択"]|confidence item="text" key="value"}
							<option value="{$value}">{$text}</option>
						{/foreach}</select>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="billing_month-input">請求月</label>
				</th>
				<td>
					<div class="col-10">
						<input type="month" name="billing_month" class="form-control" id="billing_month-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="client-input">クライアント</label>
				</th>
				<td>
					<div class="col-10" data-search-output="container">
						<div class="input-group" data-search-output="form">
							<input type="search" class="form-control" id="client-input" placeholder="クライアント名・クライアントCDで検索">
							<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#clientModal">検 索</button>
						</div>
						<div class="input-group" data-search-output="result">
							<div class="form-control" data-search-label="client"></div>
							<input type="hidden" name="client" value="" />
							<button type="button" class="btn btn-danger" data-search-output-reset="client">取 消</button>
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
							<div class="form-control" data-search-label="apply_client"></div>
							<input type="hidden" name="apply_client" value="" />
							<button type="button" class="btn btn-danger" data-search-output-reset="apply_client">取 消</button>
						</div>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="invoice_delivery-input">CL請求書発送</label>
				</th>
				<td>
					<div class="col-10">
						<input type="month" name="invoice_delivery" class="form-control" id="invoice_delivery-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="payment_date-input">CL入金日</label>
				</th>
				<td>
					<div class="col-10">
						<input type="date" name="payment_date" class="form-control" id="payment_date-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="subject-input">件名</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="subject" class="form-control" id="subject-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light  align-middle ps-4">
					<label class="form-label ls-1" for="invoice_format-input">請求書パターン</label>
				</th>
				<td>
					<div class="col-10">
						<select name="invoice_format" id="invoice_format-input" class="form-select">{foreach from=["" => "選択"]|invoiceFormat item="text" key="value"}
							<option value="{$value}">{$text}</option>
						{/foreach}</select>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="header1-input">摘要ヘッダー１</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="header1" class="form-control" id="header1-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="header1-input">摘要ヘッダー２</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="header2" class="form-control" id="header2-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="header1-input">摘要ヘッダー３</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="header3" class="form-control" id="header3-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="note-input">備考</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="note" class="form-control" id="note-input" />
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
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list" data-scroll-y="list">
		<thead>
			<tr>
				<th class="w-20">案件番号</th>
				<th class="w-20">当社担当者</th>
				<th class="w-20">確度</th>
				<th class="w-20">請求月</th>
				<th class="w-20">クライアント名</th>
				<th class="w-20">請求先名</th>
				<th class="w-20">CL請求書発送</th>
				<th class="w-20">CL入金日</th>
				<th class="w-20">件名</th>
				<th class="w-20">請求書パターン</th>
				<th class="w-20">摘要ヘッダー１</th>
				<th class="w-20">摘要ヘッダー２</th>
				<th class="w-20">摘要ヘッダー３</th>
				<th class="w-20">備考</th>
				<th>
					<div class="d-flex">
						<div class="flex-fill text-center">編集</div>
						<div class="flex-fill text-center">削除</div>
					</div>
				</th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" constructor=["confidence","invoiceFormat"] assign="obj"}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.manager_name}</td>
				<td>{$confidence[$obj.confidence]}</td>
				<td>{$obj.billing_month}</td>
				<td>{$obj.client_name}</td>
				<td>{$obj.apply_client_name}</td>
				<td>{$invoiceFormat[$obj.invoice_delivery]}</td>
				<td>{$obj.payment_date}</td>
				<td>{$obj.subject}</td>
				<td>{$obj.invoice_format}</td>
				<td>{$obj.header1}</td>
				<td>{$obj.header2}</td>
				<td>{$obj.header3}</td>
				<td>{$obj.note}</td>
				<td>
					<div class="d-flex">
						<div class="flex-fill text-center"><a href="{url action="edit"}/{$obj.id}" class="btn btn-sm bx bxs-edit">編集</a></div>
						<div class="flex-fill text-center"><button type="button" class="btn btn-sm bi bi-trash3" data-search-delete="{$obj.id}" data-bs-toggle="modal" data-bs-target="#deleteModal">削除</button></div>
					</div>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
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
<div class="modal fade" id="clientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">クライアント選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
				<table class="table table_sticky_list">
					<thead>
						<tr>
							<th>コード</th>
							<th>得意先名</th>
							<th>カナ</th>
							<th></th>
						</tr>
					</thead>
					<tbody>{predefine name="clientList" assign="obj"}
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
<div class="modal fade" id="deleteModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center text-danger">本当に削除しますか？</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">{predefine name="deleteModal" constructor=["confidence","invoiceFormat","numberFormat"] assign=["obj"]}
				<table class="table">
					<tbody>
						<tr><th scope="row" class="bg-light align-middle ps-4">案件番号</th><td>{$obj.code}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">当社担当者</th><td>{$obj.manager_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">確度</th><td>{$confidence[$obj.confidence]}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">請求月</th><td>{$obj.billing_month}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">クライアント名</th><td>{$obj.client_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">請求先名</th><td>{$obj.apply_client_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">CL請求書発送</th><td>{$invoiceFormat[$obj.invoice_delivery]}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">CL入金日</th><td>{$obj.payment_date}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">件名</th><td>{$obj.subject}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">請求書パターン</th><td>{$obj.invoice_format}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">摘要ヘッダー１</th><td>{$obj.header1}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">摘要ヘッダー２</th><td>{$obj.header2}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">摘要ヘッダー３</th><td>{$obj.header3}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">備考</th><td>{$obj.note}</td></tr>
					</tbody>
				</table>
			{/predefine}</div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal" id="deleteModalYes"><div class="flex-grow-1"></div>はい<div class="flex-grow-1"></div></button>
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>いいえ<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}