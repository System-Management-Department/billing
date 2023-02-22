{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({
	*[Symbol.iterator](){
		let db = Flow.DB;
		let links = null;
		while(links == null){
			try{
				links = db.select("ALL").addTable("breadcrumbs").apply();
			}catch(ex){
				yield new Promise((resolve, reject) => {
					setTimeout(() => {
						resolve(null);
					}, 100);
				});
			}
		}
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