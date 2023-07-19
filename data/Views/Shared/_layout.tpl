<!DOCTYPE html>
<html lang="ja" class="h-100">
{capture name="body"}<body class="bg-light h-100">
	<div class="flex-grow-1 overflow-auto d-flex h-100 w-100 flex-column gap-3" data-scroll-y="layout">
		<header class="sticky-top start-0">
			<nav class="navbar ps-4 py-2 bg-white border-bottom border-success border-2 shadow-sm">
				<div class="container-fluid gap-2">
					<div class="navbar-brand flex-grow-1">
						<span class="navbar-text text-dark">{block name="title"}{/block}</span>
					</div>
					<div class="bi bi-person-circle fs-2"></div>
					<div>
						<div class="d-flex gap-3">
							<div>{$smarty.session["User.department"]}</div>
							<div class="flex-grow-1">{$smarty.session["User.username"]}</div>
						</div>
						<div>{$smarty.session["User.email"]}</div>
					</div>
					<div>
						<a href="{url controller="Default" action="logout"}" class="btn btn-primary">ログアウト</a>
					</div>
				</div>
			</nav>
			<nav class="d-flex align-items-center bg-white shadow-sm">
				<div class="px-3">{block name="tools"}{/block}</div>
			</nav>
		</header>
		<main class="d-contents">{block name="body"}{/block}</main>
	</div>
	<div class="position-fixed top-0 bottom-0 start-0 end-0 w-auto h-auto m-0 p-0 d-grid grid-template-toast invisible zindex-toast">
		<div class="position-relative toast-container visible grid-area-2-2"></div>
	</div>
	{block name="dialogs"}{javascript_notice}{/block}
</body>{/capture}
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
<link rel="icon" href="/assets/common/image/favicon.ico" />
{block name="styles"}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/css/bootstrap.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/customElements.css" />
{/block}
{block name="scripts"}
<script type="text/javascript" src="/assets/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/Flow.js"></script>
<script type="text/javascript" src="/assets/common/Toaster.js"></script>
<script type="text/javascript" src="/assets/common/customElements.js"></script>
<script type="text/javascript">
{predef_flash}
Flow.DbName = "{$smarty.session["User.role"]}";{literal}
Flow.DbLocked = true;
Flow.start({{/literal}
	db: Flow.DB,
	dbName: "{$smarty.session["User.role"]}",
	dbDownloadURL: "{url controller="Storage" action="sqlite"}",
	masterDownloadURL: "{url controller="Default" action="master"}",
	location: "{url}",{literal}
	*[Symbol.iterator](){
		{/literal}{db_download test="Object.keys(this.db.tables).length < 1"}yield* this.dbUpdate();{/db_download}
		{master_download test="Object.keys(Flow.Master.tables).length < 1"}yield* this.masterUpdate();{/master_download}{literal}
		Flow.DbLocked = false;
		yield* this.toast();
		let prev = localStorage.getItem("session");
		let pObj = {resolve: null, reject: null};
		setInterval(() => { pObj.resolve(null); }, 60000);
		do{
			let now = Date.now();
			if((prev == null) || (now - prev) >= 60000){
				localStorage.setItem("session", prev = now);
				fetch({/literal}"{url controller="Online" action="update"}"{literal}).then(response => response.json()).then(json =>{
					
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
{/literal}</script>
{/block}
</head>
{$smarty.capture.body}
</html>