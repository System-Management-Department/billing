{foreach from=$logs item="log"}{assign var="data" value=$log.data|json_decode:true}
<div class="gridrow">
	<div class="griddata">{$log.datetime|escape:"html"}</div>
	<div class="griddata">{$log.control|escape:"html"}</div>
	<div class="griddata">{if "files"|array_key_exists:$data}{foreach from=$data.files item="file"}
		<div>{$file|escape:"html"}</div>
	{/foreach}{elseif "master"|array_key_exists:$data}
		{$data.master}
	{elseif not empty($data)}
		{$log.data}
	{/if}</div>
	<div class="griddata">{$log.username|escape:"html"}</div>
</div>
{/foreach}
<input type="hidden" name="lastdata" value="{$lastdata|escape:"html"}" />{javascript_notice}