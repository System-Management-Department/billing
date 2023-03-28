{block name="title"}入金区分一覧{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	modifiers: JSON.parse("{$modifiers|@json_encode|escape:"javascript"}"),
	dbDownloadURL: "{url controller="Default" action="master"}",{literal}
	strage: null,
	response: new SQLite(),
	template: null,
	*[Symbol.iterator](){
		this.template = new Template(this.modifiers.paymentType);
		const form = document.querySelector('form');
		yield* this.init(form);
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		
		yield* this.search();
	},
	*search(){
		let query = this.response.select("ALL")
			.addTable("payment_categories");
		let table = query.apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
	}
});
{/literal}</script>
{/block}

{block name="tools"}
	<a href="{url action="create"}" class="btn btn-success">新しい入金区分の追加</a>
{/block}

{block name="body"}
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">入金区分コード</th>
				<th class="w-20">入金種別</th>
				<th class="w-20">入金区分名</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" constructor="paymentType" assign="obj"}
			<tr>
				<td>{$obj.code}</td>
				<td>{$paymentType[$obj.type]}</td>
				<td>{$obj.name}</td>
				<td>
					<a href="{url action="detail"}/{$obj.code}" class="btn btn-sm btn-info">詳細</a>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}