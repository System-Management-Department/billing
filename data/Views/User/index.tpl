{block name="title"}ユーザー検索{/block}

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
	modifiers: JSON.parse("{$modifiers|@json_encode|escape:"javascript"}"),
	dbDownloadURL: "{url action="search"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	template: null,
	*[Symbol.iterator](){
		this.template = new Template(this.modifiers.role);
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
		let csvKeys = [
			"id", "username", "email", "password", "role", "department"
		];
		let csvData = masterData = this.response.select("ALL").addTable("users").apply();
		csvData.unshift({
			id: "ID",
			username: "ユーザー名",
			email: "メールアドレス",
			password: "パスワード",
			role: "権限",
			department: "部署"
		});
		let blob = new Blob([
			new Uint8Array([0xef, 0xbb, 0xbf]),
			csvData.map(row => {
				let res = [];
				for(let k of csvKeys){
					let v = row[k];
					if(v == null){
						res.push("");
					}else if(typeof v === "string" && v.match(/[,"\r\n]/)){
						res.push(`"${v.split('"').join('""')}"`);
					}else{
						res.push(`${v}`);
					}
				}
				return res.join(",");
			}).join("\r\n")
		], {type: "text/csv"});
		document.getElementById("export").setAttribute("href", URL.createObjectURL(blob));
		
	},
	*search(parameter){
		let query = this.response.select("ALL")
			.addTable("users");
		let searchObj = {
			username(q, v){
				if((v != null) && (v != "")){
					q.andWhere("username like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			email(q, v){
				if((v != null) && (v != "")){
					q.andWhere("email like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			role(q, v){
				if((v != null) && (v != "")){
					q.andWhere("role=?", v);
				}
			},
			department(q, v){
				if((v != null) && (v != "")){
					q.andWhere("department like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
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

{block name="tools"}
	<a class="btn btn-success" id="export" download="users.csv">CSV出力</a>
	<a href="{url action="upload"}" class="btn btn-success me-5">CSV取込</a>
	<a href="{url action="create"}" class="btn btn-success">新しいユーザーの追加</a>
{/block}

{block name="body"}
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="username-input">ユーザー名</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="username" class="form-control" id="username-input">
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="email-input">メールアドレス</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="email" class="form-control" id="email-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="role-input">権限</label>
				</th>
				<td>
					<div class="col-10">
						<select name="role" class="form-select" id="role-input">{foreach from=["" => "選択"]|role item="text" key="value"}
							<option value="{$value}">{$text}</option>
						{/foreach}</select>
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="department-input">部署</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="department" class="form-control" id="department-input">
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
				<th class="w-20">ユーザー名</th>
				<th class="w-20">メールアドレス</th>
				<th class="w-8">権限</th>
				<th class="w-20">部署</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" constructor="role" assign="obj"}
			<tr>
				<td>{$obj.username}</td>
				<td>{$obj.email}</td>
				<td>{$role[$obj.role]}</td>
				<td>{$obj.department}</td>
				<td>
					<a href="{url action="detail"}/{$obj.id}" class="btn btn-sm btn-info">詳細</a>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}