{block name="title"}チーム一覧{/block}

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
	dbDownloadURL: "{url controller="Default" action="master"}",
	deleteURL: "{url action="delete"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	*[Symbol.iterator](){
		const form = document.querySelector('form');
		yield* this.init(form);
		
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
		let {data, label} = yield* this.search(history);
		if(history != null){
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
				}
			}
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
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		
		
		const template = new ListItem();
		let table = this.response.select("ALL")
			.addTable("teams")
			.addField("teams.code,teams.name,teams.phone")
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
							Flow.DB.insertSet("messages", {title: "得意先削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
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
	<a href="{url controller="Team" action="create"}" class="btn btn-success">新しいチームの追加</a>
</div>
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">チームコード</th>
				<th class="w-20">チーム名</th>
				<th class="w-20">電話番号</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">
			{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=[]}{strip}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>
					<a href="{url action="edit"}/{$obj.code}" class="btn btn-sm bx bxs-edit"></a>
				</td>
			</tr>
			{/strip}{/template_class}{/function}
		</tbody>
	</table>
</div>
{/block}