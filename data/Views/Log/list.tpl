{block name="title"}操作履歴{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/flatpickr/flatpickr.min.css" />
<style type="text/css">{literal}
#mainlist{
	overflow-y: auto;
}
#headergrid,#datagrid{
	display: grid;
	grid-template-columns: 3fr 2fr 5fr 4fr;
	grid-auto-rows: auto;
}
#headergrid{
	position: sticky;
	top: 0;
	background: white;
	border: 1px solid #c7d0d7;
}
#headergrid *{
	padding: 6px;
}
#datagrid{
	border-left: 1px solid #c7d0d7;
	border-right: 1px solid #c7d0d7;
	border-bottom: 1px solid #c7d0d7;
}
#datagrid [data-loading]{
	transition: opacity 0.2s;
	grid-column: 1 / -1;
	height: 10px;
}
#datagrid [data-loading="0"]{
	opacity: 0;
}
#datagrid [data-loading="1"]{
	opacity: 1;
}
#datagrid .gridrow{
	display: contents;
}
#datagrid .gridrow:nth-child(odd){
	--row-color: #f0f3f5;
}
#datagrid .gridrow:nth-child(even){
	--row-color: white;
}
#datagrid .gridrow:hover{
	--row-color: #fffcd6;
}
#datagrid .griddata{
	background: var(--row-color);
	padding: 6px;
	word-break: break-all;
}
#datagrid .griddata:first-child{
	grid-column: 1;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/flatpickr/flatpickr.min.js"></script>
<script type="text/javascript">{literal}
document.addEventListener("DOMContentLoaded", function(){
	let current = null;
	let lastBlob = null;
	let form = document.getElementById("searchformdata");
	let loading = document.createElement("div");
	let observer = new IntersectionObserver(() => {
		// 画面内に入ったら更新
		loading.setAttribute("data-loading", loading.getAttribute("data-loading") == "0" ? "1" : "0");
	}, {root: document.getElementById("mainlist")});
	loading.setAttribute("data-loading", "0");
	observer.observe(loading);
	
	loading.addEventListener("transitionend", () => {
		if(loading.getAttribute("data-loading") == "0"){
			return;
		}
		
		// 一覧の続きを表示
		let list = loading.parentNode;
		list.removeChild(loading);
		fetch(form.getAttribute("action"), {
			method: 'POST',
			body: new FormData(form)
		}).then(response => response.text()).then(html => {
			// 履歴表示・検索条件の更新
			list.insertAdjacentHTML("beforeend", html);
			let oldInput = form.querySelector('[name="lastdata"]');
			let parent = oldInput.parentNode;
			let newInput = list.querySelector('[name="lastdata"]');
			parent.replaceChild(newInput, oldInput);
			
			if(newInput.value != ""){
				loading.setAttribute("data-loading", "0");
				list.appendChild(loading);
			}
		});
	});
	setTimeout(() => {
		// 最初-件のデータ読み取り
		loading.setAttribute("data-loading", "1");
	}, 200);
	document.getElementById("datagrid").appendChild(loading);
	
});
{/literal}</script>
{/block}

{block name="body"}
<form id="searchformdata" action="{url action="listItem"}" method="POST">
<input type="hidden" name="lastdata" value="" />
<input type="hidden" name="date" value="{$curdate|escape:"html"}" />
</form>
<div class="pt-4">
	<div id="mainlist">
		<div id="headergrid">
			<div>操作日時</div>
			<div>操作</div>
			<div></div>
			<div>ユーザー名</div>
		</div>
		<div id="datagrid">
		</div>
	</div>
</div>
{/block}