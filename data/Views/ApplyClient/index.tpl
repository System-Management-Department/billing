{block name="title"}請求先（納品先）検索{/block}

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
{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
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
			.addTable("apply_clients")
			.addField("apply_clients.code,apply_clients.name,apply_clients.phone,apply_clients.transactee,apply_clients.transactee_honorific")
			.apply();
		let tbody = document.getElementById("list");
		for(let row of table){
			template.insertBeforeEnd(tbody, row);
		}
		
		tbody.addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-delete")){
				let formData = new FormData();
				formData.append("id", e.target.getAttribute("data-search-delete"));
				fetch(this.deleteURL, {
					method: "POST",
					body: formData
				})
				.then(response => response.json())
				.then(response => {
					if(response.success){
						// フォーム送信 成功
						for(let message of response.messages){
							Flow.DB.insertSet("messages", {title: "請求先削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
						}
						Flow.DB.commit().then(res => { location.reload(); });
					}
				});
			}
		}, {useCapture: true});
		
		return res;
	}
});
{/literal}</script>
{/block}

{block name="body"}
<div class="container grid-colspan-12 text-end p-0 mb-2">
	<a href="{url controller="ApplyClient" action="create"}" class="btn btn-success">新しい請求先の追加</a>
</div>
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="code-input">請求先コード</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="code" class="form-control" id="code-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="name-input">請求先名</label>
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
		<button type="submit" class="btn btn-outline-success">キャンセル</button>
	</div>
</fieldset></form>
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">請求先コード</th>
				<th class="w-20">請求先名</th>
				<th class="w-20">電話番号</th>
				<th class="w-10">請求先担当者名</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">
			{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=[]}{strip}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>{$obj.transactee}</td>
				<td>
					<a href="{url action="edit"}/{$obj.code}" class="btn btn-sm bx bxs-edit"></a>
					<button type="button" class="btn btn-sm bi bi-trash3" data-search-delete="{$obj.code}"></button>
				</td>
			</tr>
			{/strip}{/template_class}{/function}
		</tbody>
	</table>
</div>
{/block}

{block name="dialogs" append}

{/block}