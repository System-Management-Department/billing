{block name="title"}売上データ検索画面{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
class DeleteListItem{
	#url;#id;#db;#pObj;#template;
	constructor(url, id, db, pObj){
		this.#url = url;
		this.#id = id;
		this.#db = db;
		this.#pObj = pObj;
		this.#template = new Template({func: new Intl.NumberFormat(), format(value){ return (typeof value === 'number') ? this.func.format(value) : value; }});
	}
	*[Symbol.iterator](){
		let header = this.#db.select("ROW")
			.addTable("sales_slips")
			.addField("sales_slips.*")
			.andWhere("id=?", Number(this.#id))
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.leftJoin("apply_clients on sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name as apply_client_name")
			.apply();
		let detail = this.#db.select("ALL")
			.addTable("sales_slips")
			.andWhere("sales_slips.id=?", Number(this.#id))
			.addTable("json_each(json_table(sales_slips.detail)) t")
			.addField("json_extract(t.value, '$.unit') as unit")
			.addField("json_extract(t.value, '$.data1') as data1")
			.addField("json_extract(t.value, '$.data2') as data2")
			.addField("json_extract(t.value, '$.data3') as data3")
			.addField("json_extract(t.value, '$.amount') as amount")
			.addField("json_extract(t.value, '$.itemName') as itemName")
			.addField("json_extract(t.value, '$.quantity') as quantity")
			.addField("json_extract(t.value, '$.unitPrice') as unitPrice")
			.addField("json_extract(t.value, '$.circulation') as circulation")
			.leftJoin("categories on cast(json_extract(t.value, '$.categoryCode') as text)=categories.code")
			.addField("categories.name as category")
			.apply();
		document.querySelector('#deleteModal .modal-body').innerHTML = this.#template.deleteModal(header, detail);
		
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
						Flow.DB.insertSet("messages", {title: "売上削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
					}
					Flow.DB.commit().then(res => { location.reload(); });
				}
			});
		}
	}
}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
	deleteURL: "{url action="delete"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
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
		form.querySelector('fieldset:disabled').disabled = false;
	},
	*search(form){
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(form)
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		this.response.attach(Flow.Master, "master");
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
		let tbody = document.getElementById("list");
		tbody.insertAdjacentHTML("beforeend", table.map(row => this.template.listItem(row)).join(""));
	},
	*input(form){
		yield new Promise((resolve, reject) => {
			let tbody = document.getElementById("list");
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
		});
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<datalist id="division"><option value="">選択</option></datalist>
	<datalist id="team"><option value="">選択</option></datalist>
	<div class="d-table table w-50">
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
		<button type="submit" class="btn btn-success">検　索</button>
		<button type="reset" class="btn btn-outline-success">リセット</button>
	</div>
</fieldset></form>
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list" data-scroll-y="list">
		<thead>
			<tr>
				<th class="w-10">伝票番号</th>
				<th class="w-10">伝票日付</th>
				<th class="w-20">請求先名</th>
				<th class="w-10">担当者名</th>
				<th class="w-15">部門</th>
				<th class="w-10">チーム</th>
				<th class="w-20">備考欄</th>
				<th>
					<div class="d-flex">
						<div class="flex-fill text-center">編集</div>
						<div class="flex-fill text-center">赤伝</div>
						<div class="flex-fill text-center">削除</div>
					</div>
				</th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" assign="obj"}
			<tr>
				<td>{$obj.slip_number}</td>
				<td>{$obj.accounting_date}</td>
				<td>{$obj.apply_client_name}</td>
				<td>{$obj.manager_name}</td>
				<td>{$obj.division_name}</td>
				<td>{$obj.team_name}</td>
				<td>{$obj.note}</td>
				<td>
					<div class="d-flex">
						<div class="flex-fill text-center"><a href="{url action="edit"}/{$obj.id}" class="btn btn-sm bx bxs-edit">編集</a></div>
						<div class="flex-fill text-center"><a href="{url action="createRed"}/{$obj.id}" class="btn btn-sm bx bxs-edit">赤伝</a></div>
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
<div class="modal fade" id="deleteModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center text-danger">本当に削除しますか？</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">{predefine name="deleteModal" constructor="numberFormat" assign=["header", "detail"]}
				<table class="table">
					<tbody>
						<tr><th scope="row" class="bg-light align-middle ps-4">伝票番号</th><td>{$header.slip_number}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">伝票日付</th><td>{$header.accounting_date}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">請求先名</th><td>{$header.apply_client_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">担当者名</th><td>{$header.manager_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">部門</th><td>{$header.division_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">チーム</th><td>{$header.team_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">備考欄</th><td>{$header.note}</td></tr>
					</tbody>
				</table>
				<table class="table table_sticky_list" style="height: max(10rem, calc(80vh - 25rem));">
					<thead>
						<tr>
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
					<tbody>{predef_repeat loop=$detail.length index="i"}
						<tr>
							<td>{$detail[$i].category}</td>
							<td>{$detail[$i].itemName}</td>
							<td>{$detail[$i].unit}</td>
							<td class="text-end">{$numberFormat.format|predef_invoke:$detail[$i].quantity}</td>
							<td class="text-end">{$numberFormat.format|predef_invoke:$detail[$i].unitPrice}</td>
							<td class="text-end">{$numberFormat.format|predef_invoke:$detail[$i].amount}</td>
							<td>{$detail[$i].data1}</td>
							<td>{$detail[$i].data2}</td>
							<td>{$detail[$i].data3}</td>
							<td class="text-end">{$numberFormat.format|predef_invoke:$detail[$i].circulation}</td>
						</tr>
					{/predef_repeat}</tbody>
				</table>
				{$header.name}
			{/predefine}</div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal" id="deleteModalYes"><div class="flex-grow-1"></div>はい<div class="flex-grow-1"></div></button>
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>いいえ<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}