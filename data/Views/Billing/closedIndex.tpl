{block name="scripts" append}
<script type="text/javascript" src="/assets/common/search.js"></script>
{/block}

{block name="body"}
<form action="{url action="closedList"}"><fieldset disabled>
	<input type="hidden" name="close_processed" value="1" />
	キーワード<input type="text" name="keyword" />
	<button type="submit">検索</button>
</fieldset></form>
{/block}