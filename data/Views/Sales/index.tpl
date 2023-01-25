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
{/block}


{block name="body"}
{foreach from=$table item="salse" name="loop"}
<div class="mb-3">
	<a href="{url action="edit" id=$salse.id}">
	{$salse.slip_number}|{$salse.subject}
	<table>
	{assign var="detail" value=$salse.detail|json_decode:true}{section name="detail" loop=$detail.length}
	<tr>
		<td>{$detail.itemCode[$smarty.section.detail.index]}</td>
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