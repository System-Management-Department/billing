{block name="scripts" append}
<script type="text/javascript" src="/assets/common/search.js"></script>
{/block}

{block name="body"}
<form action="{url action="list"}"><fieldset disabled>
	キーワード<input type="text" name="keyword" />
	<button type="submit">検索</button>
</fieldset></form>
{/block}