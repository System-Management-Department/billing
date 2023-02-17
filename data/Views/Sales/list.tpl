{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>売上</div>
		<a class="btn btn-sm btn-success" href="{url action="create"}">新規追加</a>
	</h2>
</nav>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/common/list.js"></script>
<script type="text/javascript">
{call name="ListItem"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	*[Symbol.iterator](){
		const db = new SQLite();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		db.import(buffer, "list");
		const template = new ListItem();
		
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
			template.insertBeforeEnd(document.getElementById("list"), row);
		}
	}
});
{/literal}</script>
{/block}


{block name="body"}
<div id="list">
	{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=["i"]}{strip}
	<div class="mb-3">
		<a href="{url action="edit"}/{$obj.id}">
			{$obj.slip_number}|{$obj.subject}|{$obj.division_name}|{$obj.team_name}|{$obj.manager_name}
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
		</a>
		<span class="fst-normal text-decoration-none text-danger" data-bs-toggle="modal" data-bs-target="#deleteModal" data-id="{$obj.id}">削除</span>
		<a href="{url action="createRed"}/{$obj.id}" class="fst-normal text-decoration-none text-danger">赤伝票</a>
	</div>
	{/strip}{/template_class}{/function}
</div>
{/block}

{include file="../Shared/_function_delete_modal.tpl"}
{block name="dialogs" append}
{call name="shared_deleteModal" title="売上"}
{/block}