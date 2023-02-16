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
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	*[Symbol.iterator](){
		const db = new SQLite();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		db.import(buffer, "list");
		console.log(
			db.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.detail")
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.apply()
		);
	}
});
{/literal}</script>
{/block}


{block name="body"}
{foreach from=$table item="salse" name="loop"}
<div class="mb-3">
	<a href="{url action="edit" id=$salse.id}">
	{$salse.slip_number}|{$salse.subject}
	<table>
	{assign var="detail" value=$salse.detail|json_decode:true}{section name="detail" loop=$detail.length}
	<tr>
		<td>{$detail.categoryCode[$smarty.section.detail.index]}</td>
		<td>{$detail.itemName[$smarty.section.detail.index]}</td>
		<td>{$detail.unit[$smarty.section.detail.index]}</td>
		<td>{$detail.quantity[$smarty.section.detail.index]}</td>
		<td>{$detail.unitPrice[$smarty.section.detail.index]}</td>
		<td>{$detail.amount[$smarty.section.detail.index]}</td>
		<td>{$detail.data1[$smarty.section.detail.index]}</td>
		<td>{$detail.data2[$smarty.section.detail.index]}</td>
		<td>{$detail.data3[$smarty.section.detail.index]}</td>
		<td>{$detail.circulation[$smarty.section.detail.index]}</td>
	</tr>
	{/section}
	</table>
	</a><span class="fst-normal text-decoration-none text-danger" data-bs-toggle="modal" data-bs-target="#deleteModal" data-id="{$salse.id|escape:"html"}">削除</span>
	<a href="{url action="createRed" id=$salse.id}" class="fst-normal text-decoration-none text-danger">赤伝票</a>
</div>
{/foreach}
{/block}

{include file="../Shared/_function_delete_modal.tpl"}
{block name="dialogs" append}
{call name="shared_deleteModal" title="売上"}
{/block}