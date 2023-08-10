{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="assets/common/SinglePage.css" />
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="assets/common/SQLite.js"></script>
<script type="text/javascript" src="assets/common/Toaster.js"></script>
<script type="text/javascript" src="assets/common/SinglePage.js"></script>
<script type="text/javascript">
(function(){
{/literal}{foreach from=$includeDir item="path"}{if file_exists("`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl")}
{include file="`$path``$smarty.const.DIRECTORY_SEPARATOR`script.tpl"}
{/if}{/foreach}{literal}
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => { setTimeout(() => { resolve() }, 1000); });
	}).then(() => {
		SinglePage.modal.manager.setQuery(v => `${v}: manager`).querySelector('table-sticky').columns = [
			{label: "コード", width: "6rem", slot: "code"},
			{label: "担当者名", width: "calc(50vw - 6rem)", slot: "name"},
			{label: "カナ", width: "calc(50vw - 6rem)", slot: "kana"},
			{label: "選択", width: "3rem", slot: "select"}
		];
		SinglePage.modal.apply_client.setQuery(v => `${v}: apply_client`).querySelector('table-sticky').columns = [
			{label: "コード", width: "6rem", slot: "code"},
			{label: "得意先名", width: "calc(100vw / 3 - 4rem)", slot: "client"},
			{label: "請求先名", width: "calc(100vw / 3 - 4rem)", slot: "name"},
			{label: "カナ", width: "calc(100vw / 3 - 4rem)", slot: "kana"},
			{label: "選択", width: "3rem", slot: "select"}
		];
		SinglePage.modal.client.setQuery(v => `${v}: client`).querySelector('table-sticky').columns = [
			{label: "コード", width: "6rem", slot: "code"},
			{label: "得意先名", width: "calc(50vw - 6rem)", slot: "name"},
			{label: "カナ", width: "calc(50vw - 6rem)", slot: "kana"},
			{label: "選択", width: "3rem", slot: "select"}
		];
		formTableInit(SinglePage.modal.salses_detail.querySelector('div'), [
			{column: 1, label:"伝票番号", width: 10, name: "slip_number", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"確定日時", width: 10, name: "regist_datetime", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"売上日付", width: 10, name: "approval_datetime", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"当社担当者", width: 10, name: "manager", type: "label", list: "manager", require: false, placeholder: ""},
			{column: 1, label:"請求書件名", width: 10, name: "subject", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"入金予定日", width: 10, name: "payment_date", type: "label", list: "", require: false, placeholder: ""},
			{column: 2, label:"請求書パターン", width: 10, name: "invoice_format", type: "label", list: "invoice_format", require: false, placeholder: ""},
			{column: 2, label:"請求先", width: 10, name: "apply_client", type: "label", list: "apply_client", require: false, placeholder: ""},
			{column: 2, label:"納品先", width: 10, name: "client_name", type: "label", list: "", require: false, placeholder: ""},
			{column: 2, label:"備考", width: 10, name: "note", type: "label", list: "", require: false, placeholder: ""}
		]);
		formTableInit(SinglePage.modal.purchases_detail.querySelector('div'), [
			{column: 1, label:"伝票番号", width: 10, name: "slip_number", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"確定日時", width: 10, name: "regist_datetime", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"売上日付", width: 10, name: "approval_datetime", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"当社担当者", width: 10, name: "manager", type: "label", list: "manager", require: false, placeholder: ""},
			{column: 1, label:"請求書件名", width: 10, name: "subject", type: "label", list: "", require: false, placeholder: ""},
			{column: 1, label:"入金予定日", width: 10, name: "payment_date", type: "label", list: "", require: false, placeholder: ""},
			{column: 2, label:"請求書パターン", width: 10, name: "invoice_format", type: "label", list: "invoice_format", require: false, placeholder: ""},
			{column: 2, label:"請求先", width: 10, name: "apply_client", type: "label", list: "apply_client", require: false, placeholder: ""},
			{column: 2, label:"納品先", width: 10, name: "client_name", type: "label", list: "", require: false, placeholder: ""},
			{column: 2, label:"備考", width: 10, name: "note", type: "label", list: "", require: false, placeholder: ""}
		]);
		
		
		SinglePage.location = "/";
		document.getElementById("reload").addEventListener("click", e => { SinglePage.currentPage.dispatchEvent(new CustomEvent("reload")); });
	});

	function formTableInit(parent, data){
		return new Promise((resolve, reject) => {
			let tableList = {};
			for(let row of data){
				if(!(row.column in tableList)){
					tableList[row.column] = {
						table: Object.assign(document.createElement("table"), {className: "table my-0"}),
						tbody: document.createElement("tbody")
					};
					const colgroup = document.createElement("colgroup");
					colgroup.appendChild(Object.assign(document.createElement("col"), {className: "bg-light"}));
					colgroup.appendChild(document.createElement("col"));
					tableList[row.column].table.appendChild(colgroup)
					tableList[row.column].table.appendChild(tableList[row.column].tbody);
				}
				const tr = document.createElement("tr");
				const th = document.createElement("th");
				const td = document.createElement("td");
				const formControl = document.createElement("form-control");
				th.textContent = row.label;
				th.className = "align-middle ps-4";
				formControl.setAttribute("fc-class", `col-${row.width}`);
				formControl.setAttribute("name", row.name);
				formControl.setAttribute("type", row.type);
				if(row.list != ""){
					formControl.setAttribute("list", row.list);
				}
				if(row.placeholder != ""){
					formControl.setAttribute("placeholder", row.placeholder);
				}
				
				td.appendChild(formControl);
				tr.appendChild(th);
				tr.appendChild(td);
				tableList[row.column].tbody.appendChild(tr);
			}
			const tableColumns = Object.keys(tableList).sort();
			for(let tableNo of tableColumns){
				if(parent.tagName == "SEARCH-FORM"){
					tableList[tableNo].table.setAttribute("slot", "body");
				}
				parent.appendChild(tableList[tableNo].table);
			}
			setTimeout(() => { resolve(parent); }, 0);
		});
	}
})();
</script>
{/literal}{/block}

{*
Flow.DbName = "admin";
Flow.DbLocked = true;
Flow.start({
	db: Flow.DB,
	dbName: "admin",
	dbDownloadURL: "/Storage/sqlite",
	masterDownloadURL: "/Default/master",
	location: "/Home",
	*[Symbol.iterator](){
		if(Object.keys(this.db.tables).length < 1){ yield* this.dbUpdate(); }
		if(Object.keys(Flow.Master.tables).length < 1){ yield* this.masterUpdate(); }
		Flow.DbLocked = false;
		yield* this.toast();
		let prev = localStorage.getItem("session");
		let pObj = {resolve: null, reject: null};
		setInterval(() => { pObj.resolve(null); }, 60000);
		do{
			let now = Date.now();
			if((prev == null) || (now - prev) >= 60000){
				localStorage.setItem("session", prev = now);
				fetch("/Online/update").then(response => response.json()).then(json =>{
					
				});
			}
			this.db
				.delete("search_histories")
				.andWhere("time<?", now - 86400000)
				.apply();
			yield new Promise((resolve, reject) => {
				pObj.resolve = resolve;
				pObj.reject = reject;
			});
		}while(true);
	},
	*dbUpdate(){
		yield new Promise((resolve, reject) => {
			fetch(this.dbDownloadURL).then(response => response.arrayBuffer()).then(buffer => {
				this.db.import(buffer, this.dbName);
				this.db.commit().then(res => {resolve(res);});
			});
		});
	},
	*masterUpdate(){
		yield new Promise((resolve, reject) => {
			fetch(this.masterDownloadURL).then(response => response.arrayBuffer()).then(buffer => {
				Flow.Master.import(buffer, "master");
				Flow.Master.commit().then(res => {resolve(res);});
			});
		});
	},
	*toast(){
		let messages = this.db
			.select("ALL")
			.addTable("messages")
			.leftJoin("toast_classes using(type)")
			.apply();
		if(messages.length > 0){
			Toaster.show(messages);
			this.db.delete("messages").apply();
			this.db.commit();
		}
	}
});
*}

{block name="body"}
	<div id="spmain">
	<template shadowroot="closed">
		<div part="body">
			<header part="header">
				<nav part="nav1">
					<div part="container">
						<div part="title">
							<slot name="title"></slot>
						</div>
						<div part="icon"></div>
						<div>
							<div part="account">
								<div>部署</div>
								<div part="name">{$smarty.session["User.username"]}</div>
							</div>
							<div>{$smarty.session["User.email"]}</div>
						</div>
						<div>
							<a href="/Default/logout" part="logout">ログアウト</a>
						</div>
					</div>
				</nav>
				<nav part="nav2">
					<div part="tools"><slot name="tools"></slot></div>
				</nav>
			</header>
			<slot name="main"></slot>
		</div>
		<div part="toast-grid">
			<div part="toast"></div>
		</div>
		<slot name="dialog"></slot>
	</template>
{foreach from=$includeDir item="path"}{if file_exists("`$path``$smarty.const.DIRECTORY_SEPARATOR`template.tpl")}
{include file="`$path``$smarty.const.DIRECTORY_SEPARATOR`template.tpl"}
{/if}{/foreach}
	<template data-page-share="">
		<span slot="tools" href="/" class="btn btn-primary my-2" style="order: 0;" id="reload">更新</span>
	</template>
	<template data-page-share="/">
		<page-link slot="tools" href="/" class="btn btn-success my-2" style="order: 1;">メインメニュー</page-link>
	</template>
		<span slot="title" class="navbar-text text-dark">読込中</span>
		<main slot="main" class="d-contents" data-page="/">
			<div class="card mx-5">
				<div class="card-header">読込中</div>
				<div class="card-body">
					情報を取得しています。<br />読込が完了するまでお待ちください。
				</div>
			</div>
		</main>
	</div>
	
	<datalist id="category"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<modal-dialog name="manager" label="当社担当者選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);">
			<table-row><div slot="code">DATA</div><div slot="name">DATA</div><div slot="kana">DATA</div><div slot="select"><button type="button" class="btn btn-sm btn-success" data-trigger="list" data-result="data">選択</button></div></table-row>
		</table-sticky>
	</modal-dialog>
	<modal-dialog name="apply_client" label="請求先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="client" label="得意先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="salses_detail" label="売上明細">
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			売上明細
		</div>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="purchases_detail" label="仕入明細">
		<div slot="body" class="p-4" style="max-height: 50vh;overflow-y: auto;display: grid;column-gap: 0.75rem;grid-template: 1fr/1fr 1fr;grid-auto-columns: 1fr;grid-auto-flow: column;align-items: start;"></div>
		<div slot="body">
			仕入明細
		</div>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="a1_details" label="承認">
		<button slot="footer" type="button" data-trigger="btn" data-result="1">承認</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="a2_details" label="承認解除">
		<button slot="footer" type="button" data-trigger="btn" data-result="1">承認解除</button>
		<button slot="footer" type="button" data-trigger="btn" class="btn btn-success">閉じる</button>
	</modal-dialog>
	<modal-dialog name="a3_details" label="締め解除">
	</modal-dialog>
{/block}