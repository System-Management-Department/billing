{block name="title"}仕入れデータ検索画面{/block}

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
		this.#template = new Template({func: new Intl.NumberFormat(), format(value){ return (typeof value === 'number') ? this.func.format(value) : value; }});
	}
	*[Symbol.iterator](){
		let table = this.#db.select("ROW")
			.addTable("purchases")
			.andWhere("id=?", Number(this.#id))
			.addField("purchases.project")
			.addField("purchases.supplier")
			.addField("purchases.payment_date")
			.addField("purchases.unit")
			.addField("purchases.quantity")
			.addField("purchases.unit_price")
			.addField("purchases.amount")
			.addField("purchases.subject")
			.addField("purchases.note")
			.addField("purchases.status")
			.addField("purchases.ingest")
			.leftJoin("master.suppliers as suppliers on purchases.supplier=suppliers.code")
			.addField("suppliers.name as supplier_name,suppliers.kana as supplier_kana")
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
						Flow.DB.insertSet("messages", {title: "仕入れ削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
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
		this.template = new Template();
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
			document.querySelector('input[name="supplier"]').value = "";
			document.querySelector('[data-search-label="supplier"]').textContent = "";
		});
		
		const changeEvent1 = e => {
			let table = this.response.select("ALL")
				.setTable("master.suppliers")
				.orWhere("name like ('%' || ? || '%')", e.currentTarget.value)
				.orWhere("code like ('%' || ? || '%')", e.currentTarget.value)
				.apply();
			document.querySelector('#supplierModal tbody').innerHTML = table.map(row => this.template.supplierList(row)).join("");
		};
		changeEvent1({currentTarget: document.getElementById("supplier-input")});
		document.getElementById("supplier-input").addEventListener("change", changeEvent1);
		document.querySelector('#supplierModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				document.querySelector('input[name="supplier"]').value = e.target.getAttribute("data-search-modal-value");
				document.querySelector('[data-search-label="supplier"]').textContent = e.target.getAttribute("data-search-modal-label");
			}
		}, {useCapture: true});
		document.querySelector('[data-search-output-reset="supplier"]').addEventListener("click", e => {
			document.querySelector('input[name="supplier"]').value = "";
			document.querySelector('[data-search-label="supplier"]').textContent = "";
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
			.addTable("purchases")
			.addField("purchases.id")
			.addField("purchases.project")
			.addField("purchases.supplier")
			.addField("purchases.payment_date")
			.addField("purchases.unit")
			.addField("purchases.quantity")
			.addField("purchases.unit_price")
			.addField("purchases.amount")
			.addField("purchases.subject")
			.addField("purchases.note")
			.addField("purchases.status")
			.addField("purchases.ingest")
			.leftJoin("master.suppliers as suppliers on purchases.supplier=suppliers.code")
			.addField("suppliers.name as supplier_name,suppliers.kana as supplier_kana")
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
					<label class="form-label ls-1" for="project-input">案件番号</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="project" class="form-control" id="project-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="supplier-input">仕入先</label>
				</th>
				<td>
					<div class="col-10" data-search-output="container">
						<div class="input-group" data-search-output="form">
							<input type="search" class="form-control" id="supplier-input" placeholder="仕入先名・仕入先CDで検索">
							<button type="button" class="btn btn-success" data-bs-toggle="modal" data-bs-target="#supplierModal">検 索</button>
						</div>
						<div class="input-group" data-search-output="result">
							<div class="form-control" data-search-label="supplier"></div>
							<input type="hidden" name="supplier" value="" />
							<button type="button" class="btn btn-danger" data-search-output-reset="supplier">取 消</button>
						</div>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="payment_date-input">支払日</label>
				</th>
				<td>
					<div class="col-10">
						<input type="date" name="payment_date" class="form-control" id="payment_date-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="unit-input">単位</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="unit" class="form-control" id="unit-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="quantity-input">数量</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="quantity" class="form-control" id="quantity-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="unit_price-input">単価</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="unit_price" class="form-control" id="unit_price-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="amount-input">支払金額</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="amount" class="form-control" id="amount-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="subject-input">内容</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="subject" class="form-control" id="subject-input" />
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
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="status-input">支払済み</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="status" class="form-control" id="status-input" />
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
				<th class="w-20">仕入先</th>
				<th class="w-20">支払日</th>
				<th class="w-20">単位</th>
				<th class="w-20">数量</th>
				<th class="w-20">単価</th>
				<th class="w-20">支払金額</th>
				<th class="w-20">内容</th>
				<th class="w-20">備考</th>
				<th class="w-20">支払済み</th>
				<th>
					<div class="d-flex">
						<div class="flex-fill text-center">編集</div>
						<div class="flex-fill text-center">削除</div>
					</div>
				</th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" assign="obj"}
			<tr>
				<td>{$obj.project}</td>
				<td>{$obj.supplier_name}</td>
				<td>{$obj.payment_date}</td>
				<td>{$obj.unit}</td>
				<td>{$obj.quantity}</td>
				<td>{$obj.unit_price}</td>
				<td>{$obj.amount}</td>
				<td>{$obj.subject}</td>
				<td>{$obj.note}</td>
				<td>{$obj.status}</td>
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
<div class="modal fade" id="supplierModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">仕入先選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
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
					<tbody>{predefine name="supplierList" assign="obj"}
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
			<div class="modal-body">{predefine name="deleteModal" constructor="numberFormat" assign="obj"}
				<table class="table">
					<tbody>
						<tr><th scope="row" class="bg-light align-middle ps-4">案件番号</th><td>{$obj.project}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">仕入先</th><td>{$obj.supplier_name}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">支払日</th><td>{$obj.payment_date}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">単位</th><td>{$obj.unit}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">数量</th><td>{$obj.quantity}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">単価</th><td>{$obj.unit_price}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">支払金額</th><td>{$obj.amount}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">内容</th><td>{$obj.subject}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">備考</th><td>{$obj.note}</td></tr>
						<tr><th scope="row" class="bg-light align-middle ps-4">支払済み</th><td>{$obj.status}</td></tr>
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