{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({
	*[Symbol.iterator](){
		let db = Flow.DB;
		let links = db.select("ALL").addTable("breadcrumbs").apply();
		for(let link of links){
			let a = document.createElement("a");
			a.textContent = link.title;
			a.setAttribute("class", "btn btn-sm btn-success m-2");
			a.setAttribute("href", link.url);
			document.body.appendChild(a);
		}
	}
});
{/literal}</script>
{/block}