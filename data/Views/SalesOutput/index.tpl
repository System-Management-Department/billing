{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>売上伝票出力</div>
	</h2>
</nav>
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
document.addEventListener("DOMContentLoaded", function(e){
	let form = document.getElementById("outputlist");
	form.addEventListener("submit", e => {
		e.stopPropagation();
		e.preventDefault();
		let rows = document.querySelectorAll('[data-output]:has([name="id[]"]:checked)');
		let innerHTML = [];
		let n = rows.length;
		for(let i = 0; i < n; i++){
			innerHTML.push(rows[i].innerHTML);
		}
		let blob = new Blob(innerHTML, {type: "text/plain"});
		let download = (messages) => {
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "output.txt");
			a.click();
			Storage.pushToast("売上伝票出力", messages);
			location.reload()
		};
		let formData = new FormData(form);
		
		fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: formData
		}).then(res => res.json()).then(json => {
			if(json.success){
				download(json.messages);
			}else{
			}
		});
	});
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url action="output"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">出力</button>
	{foreach from=$table item="salse" name="loop"}
	<div class="mb-3" data-output="{$salse.id}">
		<label href="{url action="edit" id=$salse.id}">
		<input type="checkbox" name="id[]" value="{$salse.id}" />{$salse.slip_number}|{$salse.output_processed}
		<table>
		{foreach from=$salse.detail|json_decode:true item="detail"}
		<tr><td>{"</td><td>"|implode:$detail}</td></tr>
		{/foreach}
		</table>
		</label>
	</div>
	{/foreach}
</form>
{/block}