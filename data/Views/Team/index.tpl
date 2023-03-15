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
</script>
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