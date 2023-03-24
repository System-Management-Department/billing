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
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	template: new Template(),
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
			this.strage.commit();
			this.search(obj.data).next();
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

		let data, label;
		if(history != null){
			let obj = JSON.parse(history.json);
			data = obj.data;
			label = obj.label;
		}
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		
		yield* this.search(data);
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
	*search(parameter){
		let query = this.response.select("ALL")
			.addTable("apply_clients");
		let searchObj = {
			code(q, v){
				if((v != null) && (v != "")){
					q.andWhere("code like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			name(q, v){
				if((v != null) && (v != "")){
					let val = v.replace(/(?=[\\\%\_])/g, "\\");
					q.andWhere("((unique_name like '%' || ? || '%') OR (name like '%' || ? || '%') OR (kana like '%' || ? || '%') OR (short_name like '%' || ? || '%'))", val, val, val, val);
				}
			},
			phone(q, v){
				if((v != null) && (v != "")){
					q.andWhere("phone like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			}
		};
		for(let k in parameter){
			if(k in searchObj){
				searchObj[k](query, ...parameter[k]);
			}
		}
		let table = query.apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
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
		<button type="reset" class="btn btn-outline-success">リセット</button>
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
		<tbody id="list">{predefine name="listItem" assign="obj"}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>{$obj.transactee}</td>
				<td>
					<a href="{url action="detail"}/{$obj.code}" class="btn btn-sm btn-info">詳細</a>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}