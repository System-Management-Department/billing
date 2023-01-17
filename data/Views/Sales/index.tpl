{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>売上</div>
		<a class="btn btn-sm btn-success" href="{url action="create"}">新規追加</a>
	</h2>
</nav>
{/block}

{block name="body"}
{foreach from=$table item="salse" name="loop"}
<div>
	<a href="{url action="edit" id=$salse.id}">
	{$salse.slip_number}
	{$salse.detail}
	</a>
</div>
{/foreach}
{/block}