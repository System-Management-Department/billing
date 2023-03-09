<!DOCTYPE html>
<html lang="ja" class="h-100">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
<link rel="icon" href="/assets/common/image/favicon.ico" />
{block name="styles"}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/css/bootstrap.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
{/block}
{block name="scripts"}
<script type="text/javascript" src="/assets/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/Flow.js"></script>
<script type="text/javascript">
Flow.DbName = "{$smarty.session["User.role"]}";{literal}
Flow.DbLocked = true;
Flow.start({{/literal}
	db: Flow.DB,
	dbName: "{$smarty.session["User.role"]}",
	dbDownloadURL: "{url controller="Storage" action="sqlite"}",
	location: "{url}",{literal}
	*[Symbol.iterator](){
		{/literal}{db_download test="Object.keys(this.db.tables).length < 1"}yield* this.dbUpdate();{/db_download}{literal}
		Flow.DbLocked = false;
		yield* this.breadcrumbs();
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
	*breadcrumbs(){
		let query = this.db.select("ALL")
			.addWith("recursive t as (select *,1 as active from breadcrumbs where url=? UNION ALL select breadcrumbs.*,0 as active from breadcrumbs,t where breadcrumbs.url=t.parent)", this.location)
			.addTable("t")
			.andWhere("depth>0")
			.setOrderBy("depth");
		let res = query.apply();
		let breadcrumb = document.querySelector("ol.breadcrumb");
		for(let row of res){
			let li = document.createElement("li");
			if(row.active == 0){
				let a = document.createElement("a");
				li.setAttribute("class", "breadcrumb-item");
				a.setAttribute("href", row.url);
				a.textContent = row.title;
				li.appendChild(a);
			}else{
				li.setAttribute("class", "breadcrumb-item active");
				li.textContent = row.title;
			}
			breadcrumb.appendChild(li);
		}
		let firstBread = breadcrumb.querySelector('li');
		if(firstBread != null){
			firstBread.insertAdjacentHTML("afterbegin", '<i class="bi bi-gear-fill pe-2"></i>');
		}else{
			breadcrumb.innerHTML = '<i class="bi bi-gear-fill pe-2"></i>';
		}
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
/*
document.addEventListener("DOMContentLoaded", e => {
	const sidebar = document.querySelector('nav');
	const searchBtn = document.querySelector(".search-box");
	const modeSwitchBtn = document.querySelector(".toggle-switch");
	const modeText = document.querySelector(".mode-text");
	const search = e => {  sidebar.classList.remove("close"); };
	const modeSwitch = e => {
		document.body.classList.toggle("dark");
		modeText.textContent = `${document.body.classList.contains("dark") ? "Light" : "Dark"} mode`;
	};
	
	searchBtn.addEventListener("click", search);
	modeSwitchBtn.addEventListener("click", modeSwitch);
});
*/
class Toaster{
	static show(messages){
		let container = document.querySelector('.toast-container');
		let option = {
			animation: true,
			autohide: false,
			delay: 1000
		};
		for(let message of messages){
			let toast = document.createElement("div");
			let header = document.createElement("div");
			let body = document.createElement("div");
			let title = document.createElement("strong");
			toast.setAttribute("class", message["class"]);
			header.setAttribute("class", "toast-header");
			body.setAttribute("class", "toast-body text-white");
			title.setAttribute("class", "me-auto");
			body.textContent = message.message;
			title.textContent = message.title;
			header.appendChild(title);
			header.insertAdjacentHTML("beforeend", '<button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>');
			toast.appendChild(header);
			toast.appendChild(body);
			container.appendChild(toast);
			new bootstrap.Toast(toast, option);
		}
	}
}
{/literal}</script>
{/block}
</head>
<body class="bg-light h-100">
	<div class="d-flex flex-row h-100 w-100">
		<div class="sidebar flex-shrink-0 py-2">
			<nav class="px-3">
				<header class="mt-1 position-relative">
					<div class="image-text d-flex align-items-center">
						<div class="d-flex align-items-center justify-content-center p-2">
							<img src="/assets/common/image/logo.svg" width="40" height="30" alt="ダイレクト・ホールディングス" />
						</div>
						<div class="text logo-text d-flex flex-column">
							<div class="name">販売管理システム</div>
							<div class="profession">Sales Management</div>
						</div>
					</div>
					<label class="bx bx-chevron-right toggle d-flex align-items-center justify-content-center position-absolute top-50">
						<input type="checkbox" checked />
					</label>
				</header>
			</nav>
			<nav class="px-3 overflow-hidden">
				<div class="menu-bar">
					<ul class="menu-links px-0 py-3">
						<!--
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Dashboard" action="index"}">
								<i class="bx bxs-dashboard icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">Dashboard</span>
							</a>
						</li>
						-->
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Home" action="sales"}">
								<i class="bx bxs-edit icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">売上処理</span>
							</a>
						</li>
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Home" action="billing"}">
								<i class="bx bxs-edit icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">請求処理</span>
							</a>
						</li>
						{if $smarty.session["User.role"] eq "admin"}
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Home" action="master"}">
								<i class="bx bx-cog icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">マスタ設定</span>
							</a>
						</li>
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Drive" action="x_config"}">
								<i class="bx bxl-google-cloud icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">サービスアカウント</span>
							</a>
						</li>
						<li class="nav-link d-flex align-items-center">
							<a class="d-contents" href="{url controller="Log" action="index"}">
								<i class="bx bx-history icon d-flex align-items-center justify-content-center"></i>
								<span class="text nav-text d-flex flex-column">履歴</span>
							</a>
						</li>
						{/if}
					</ul>
				</div>
			</nav>
		</div>
		<div class="flex-grow-1 overflow-auto" data-scroll-y="layout">
			<header class="sticky-top">
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
				<nav aria-label="breadcrumb" class="bg-white shadow-sm">
					<ol class="breadcrumb p-3"></ol>
				</nav>
			</header>
			<main class="py-4">{block name="body"}{/block}</main>
		</div>
	</div>
	<div style="position:fixed;top:0;bottom:0;right:0;left:0;width:auto;height:auto;margin:0;padding:0;display:grid;grid-template:1fr auto 1fr/1fr auto 1fr;visibility:hidden;">
		<div class="toast-container" style="grid-column:2;grid-row:2;visibility:visible;"></div>
	</div>
	{block name="dialogs"}{javascript_notice}{/block}
</body>
</html>