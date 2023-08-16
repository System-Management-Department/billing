{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript">
new VirtualPage("/", class{
	constructor(vp){
		document.querySelector('[data-trigger="submit"]').addEventListener("click", e => { close(); });
	}
});
(function(){
	let master = new SQLite();
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			master.use("master").then(master => {
				fetch("/Default/master").then(res => res.arrayBuffer()).then(buffer => {
					master.import(buffer, "master");
					resolve();
				});
			});
		});
	}).then(() => {
		SinglePage.location = "/";
	});
})();
</script>
{/literal}{/block}
{block name="body"}
	<div id="spmain">
		<template shadowroot="closed">
			<div part="body">
				<header part="header">
					<nav part="nav1">
						<div part="container">
							<div part="title">仕入登録</div>
						</div>
					</nav>
					<nav part="nav2">
						<div part="tools"><slot name="tools"></slot></div>
					</nav>
				</header>
				<slot name="main"></slot>
			</div>
		</template>
		<template data-page="/">
			<div slot="main" class="flex-grow-1">form</div>
			<div slot="main"><button type="button" class="btn btn-success" data-trigger="submit">登録</button></div>
		</template>
	</div>
{/block}