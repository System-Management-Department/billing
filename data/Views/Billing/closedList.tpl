{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>請求締データ</div>
	</h2>
</nav>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
<script type="text/javascript">
{call name="ListItem"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
	location: "{url}",{literal}
	form: null,
	y: null,
	*[Symbol.iterator](){
		yield* this.init();
		const db = new SQLite();
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(this.form)
		}).then(response => response.arrayBuffer());
		db.import(buffer, "list");
		const template = new ListItem();
		const form = document.getElementById("outputlist");
		
		let table = db.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.detail")
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.apply();
		for(let row of table){
			row.detail = JSON.parse(row.detail);
			template.insertBeforeEnd(form, row);
		}
		if(this.y != null){
			document.documentElement.scrollTop = this.y;
			this.y = null;
		}
		
		let pObj = {};
		form.addEventListener("submit", e => { pObj.resolve(e); });
		do{
			yield* this.input(pObj, db, form);
		}while(true);
	},
	*init(){
		this.form = document.getElementById("search");
		const db = yield* Flow.waitDbUnlock();
		let history = db.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", this.location)
			.setOrderBy("time DESC")
			.apply();
		if(history != null){
			let {data, label} = JSON.parse(history.json);
			for(let k in data){
				for(let v of data[k]){
					let input = Object.assign(document.createElement("input"), {value: v});
					input.setAttribute("type", "hidden");
					input.setAttribute("name", k);
					this.form.appendChild(input);
				}
			}
			this.y = history.scroll_y;
			addEventListener("beforeunload", e => {
				db.updateSet("search_histories", {
					scroll_y: document.documentElement.scrollTop
				}, {})
					.andWhere("location=?", history.location)
					.andWhere("time=?", history.time)
					.apply();
				db.commit();
			});
		}
	},
	*input(pObj, db, form){
		let p = new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let e = yield p;
		
		e.stopPropagation();
		e.preventDefault();
		
		let json = yield fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: new FormData(form)
		}).then(res => res.json());
		if(json.success){
			for(let message of json.messages){
				Flow.DB.insertSet("messages", {title: "請求締データ", message: message[0], type: message[1], name: message[2]}, {}).apply();
			}
			yield Flow.DB.commit();
			location.reload();
		}else{
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form id="search"></form>
<form action="{url action="release"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">締解除</button>
	{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=["i"]}{strip}
	<div class="mb-3">
		<label>
			<input type="checkbox" name="id[]" value="{$obj.id}" />{$obj.slip_number}|{$obj.subject}|{$obj.division_name}|{$obj.team_name}|{$obj.manager_name}
			<table>
				<tbody>{$obj->beginRepeat($obj.detail.length, "i")}
					<tr>
						<td>{$obj.detail.categoryCode[$i]}</td>
						<td>{$obj.detail.itemName[$i]}</td>
						<td>{$obj.detail.unit[$i]}</td>
						<td>{$obj.detail.quantity[$i]}</td>
						<td>{$obj.detail.unitPrice[$i]}</td>
						<td>{$obj.detail.amount[$i]}</td>
						<td>{$obj.detail.data1[$i]}</td>
						<td>{$obj.detail.data2[$i]}</td>
						<td>{$obj.detail.data3[$i]}</td>
						<td>{$obj.detail.circulation[$i]}</td>
					</tr>
				{$obj->endRepeat()}</tbody>
			</table>
		</label>
	</div>
	{/strip}{/template_class}{/function}
</form>
{/block}