{block name="title"}得意先クライアント検索{/block}

{block name="styles" append}
<style type="text/css">
[data-search-output="container"]:has([data-search-output="result"] input[type="hidden"]:not([value=""])) [data-search-output="form"],
[data-search-output="container"] [data-search-output="result"]:has(input[type="hidden"][value=""]){
	display: none;
}
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript">
{call name="ListItem"}
{call name="DeleteModal"}{literal}
class DeleteListItem{
	#url;#id;#db;#pObj;#template;
	constructor(url, id, db, pObj){
		this.#url = url;
		this.#id = id;
		this.#db = db;
		this.#pObj = pObj;
		this.#template = new DeleteModal();
	}
	*[Symbol.iterator](){
		let header = this.#db.select("ROW")
			.addTable("apply_clients")
			.addField("apply_clients.name")
			.andWhere("code=?", Number(this.#id))
			.apply();
		let detail = this.#db.select("ALL")
			.addTable("apply_clients")
			.addField("apply_clients.name")
			.andWhere("apply_clients.code=?", Number(this.#id))
			.apply();
		let modalBody = Object.assign(document.querySelector('#deleteModal .modal-body'), {innerHTML: ""});
		this.#template.insertBeforeEnd(modalBody, header);
		
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
	dbDownloadURL: "{url controller="Default" action="master"}",
	deleteURL: "{url action="delete"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	*[Symbol.iterator](){
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
			document.querySelector('input[name="code"]').value = "";
			document.querySelector('input[name="name"]').value = "";
			document.querySelector('input[name="phone"]').value = "";
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
		
		
		const template = new ListItem();
		let table = this.response.select("ALL")
			.addTable("clients")
			.addField("clients.code,clients.name,clients.phone,clients.transactee,clients.transactee_honorific")
			.apply();
		let tbody = document.getElementById("list");
		for(let row of table){
			template.insertBeforeEnd(tbody, row);
		}
		
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
<div class="container grid-colspan-12 text-end p-0 mb-2">
	<a href="{url controller="Client" action="create"}" class="btn btn-success">新しい得意先の追加</a>
</div>
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="code-input">得意先コード</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="code" class="form-control" id="code-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="name-input">得意先名</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="name" class="form-control" id="name-input">
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="phone-input">電話番号</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="phone" class="form-control" id="phone-input">
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
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">得意先コード</th>
				<th class="w-20">得意先名</th>
				<th class="w-20">電話番号</th>
				<th class="w-20">部署名</th>
				<th class="w-10">得意先担当者名</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">
			{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=[]}{strip}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>{$obj.department}</td>
				<td>{$obj.transactee}</td>
				<td>
					<a href="{url action="edit"}/{$obj.code}" class="btn btn-sm bx bxs-edit"></a>
					<button type="button" class="btn btn-sm bi bi-trash3" data-search-delete="{$obj.code}" data-bs-toggle="modal" data-bs-target="#deleteModal" ></button>
				</td>
			</tr>
			{/strip}{/template_class}{/function}
		</tbody>
	</table>
</div>
{/block}

{block name="dialogs" append}
<div class="modal fade" id="deleteModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center text-danger">本当に削除しますか？</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
				{function name="DeleteModal"}{template_class name="DeleteModal" assign=["header", "detail"] iterators=["i"]}{strip}
				<table class="table">
					<tbody>
						<tr><th scope="row" class="bg-light align-middle ps-4">請求先コード</th><td>{$header.name}</td></tr>
					</tbody>
				</table>
				<table class="table table_sticky_list" style="height: max(10rem, calc(80vh - 25rem));">
					<thead>
						<tr>
							<th>請求先コード</th>
						</tr>
					</thead>
				</table>
				{/strip}{/template_class}{/function}
			</div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal" id="deleteModalYes"><div class="flex-grow-1"></div>はい<div class="flex-grow-1"></div></button>
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>いいえ<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}