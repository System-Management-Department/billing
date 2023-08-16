{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<style type="text/css">
edit-table{
	display: contents;
}
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/handsontable/handsontable.full.min.js"></script>
<script type="text/javascript">
class Detail{
	#values;
	constructor(){
		this.#values = {
			detail: "内容",
			quantity: "数量",
			unit: "単位",
			unit_price: "単価",
			amount_exc: "税抜金額",
			amount_tax: "消費税金額",
			amount_inc: "税込金額",
			category: "カテゴリー"
		};
	}
	get detail(){
		return "11";
	}
}
class EditTableElement extends HTMLElement{
	#root; #hot;
	constructor(){
		super();
		this.#root = null;
		this.#hot = null;
	}
	attributeChangedCallback(name, oldValue, newValue){}
	connectedCallback(){
		if(this.#root == null){
			this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: `<link rel="stylesheet" type="text/css" href="/assets/handsontable/handsontable.full.min.css" />
<style type="text/css">
.table{
	background: lightgray;
}
.table,.wtHolder{
	height: calc(50vh - 5rem) !important;
}
.wtHider{
	height: auto !important;
}
</style>
<div class="table"></div>`});
			this.#hot = new Handsontable(this.#root.querySelector('div'), this.detailOption);
		}
	}
	disconnectedCallback(){
	}
	get detailOption(){
		const header = {
			detail: "内容",
			quantity: "数量",
			unit: "単位",
			unit_price: "単価",
			amount_exc: "税抜金額",
			amount_tax: "消費税金額",
			amount_inc: "税込金額",
			category: "カテゴリー"
		};
		return {
			fixedRowsTop: 1,
			columns: [
				{
					data(obj, name){
						console.log(obj, name);
						if(name){
						}else{
							return obj.detail;
						}
					},
					type: "text"
				},
				{data: "quantity", type: "text"},
				{data: "unit", type: "text"},
				{data: "unit_price", type: "text"},
				{data: "amount_exc", type: "text", "readOnly": true},
				{data: "amount_tax", type: "text", "readOnly": true},
				{data: "amount_inc", type: "text", "readOnly": true},
				{data: "category", type: "text"}
			],
			stretchH: "all",
			trimWhitespace: false,
			data: [header].concat(new Array(5).fill(null).map(r => { return new Detail(); })),
			dataSchema(){
				return new Detail()
			},
			afterCreateRow(...amount){
				console.log(amount);
			},
			height: 0,
			minRows: 30,
			cells(row, cols, prop){
				if(row == 0){
					return {
						renderer: "html",
						readOnly: true
					};
				}
				return {type: "text"};
			}
		};
	}
	static observedAttributes = [];
}
customElements.define("edit-table", EditTableElement);

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
							<div part="title">追加修正</div>
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
			<div slot="main" class="flex-grow-1">
				form
			</div>
			<edit-table slot="main"></edit-table>
			<div slot="main"><button type="button" class="btn btn-success" data-trigger="submit">登録</button></div>
		</template>
	</div>
{/block}