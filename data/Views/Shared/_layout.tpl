<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<link rel="icon" href="/assets/common/image/favicon.ico" />
{block name="styles"}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/css/bootstrap.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<style id="additionalStyle">
	#mainGrid{
		display: grid;
		grid-template-columns: auto 1fr;
		grid-template-rows: auto auto 1fr;
		grid-auto-flow: column;
		position: fixed;
		top: 0;
		bottom: 0;
		left: 0;
		right: 0;
		height: auto;
		width: auto;
		margin: 0;
		padding: 0;
	}
	#sidebarToggle{
		display: contents;
	}
	.sidebar-section{
		display: contents;
		--sidebar-width: 12rem;
	}
	#sidebarToggle:checked~.sidebar-section{
		--sidebar-width: 3rem;
	}
	#sidebarToggle:checked~.sidebar-section .sidebar-hidden{
		display: none;
	}
	label[for="sidebarToggle"],#sidebar{
		white-space: nowrap;
		width: var(--sidebar-width);
		transition: width 0.5s;
		overflow: hidden;
		overflow-y: auto;
	}
	#sidebar .bi::before,.card-header .bi::before{
		width: 26px;
		font-size: 18px;
	}
	.grid-rowspan-2{
		grid-row-end: span 2;
	}
	.grid-colspan-2{
		grid-column-end: span 2;
	}
	.grid-colspan-3{
		grid-column-end: span 3;
	}
	.grid-colspan-4{
		grid-column-end: span 4;
	}
	.grid-colspan-5{
		grid-column-end: span 5;
	}
	.grid-colspan-6{
		grid-column-end: span 6;
	}
	.grid-colspan-7{
		grid-column-end: span 7;
	}
	.grid-colspan-8{
		grid-column-end: span 8;
	}
	.grid-colspan-9{
		grid-column-end: span 9;
	}
	.grid-colspan-10{
		grid-column-end: span 10;
	}
	.grid-colspan-11{
		grid-column-end: span 11;
	}
	.grid-colspan-12{
		grid-column-end: span 12;
	}
</style>
{/block}
{block name="scripts"}
<script type="text/javascript" src="/assets/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/Flow.js"></script>
<script type="text/javascript">
Flow.start("{$smarty.session["User.role"]}", {literal}{{/literal}
	db: Flow.DB,
	dbName: "{$smarty.session["User.role"]}",
	dbDownloadURL: "{url controller="Storage" action="sqlite"}",
	location: "{url}",{literal}
	*[Symbol.iterator](){
		{/literal}{db_download test="Object.keys(this.db.tables).length < 1"}yield* this.dbUpdate();{/db_download}{literal}
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
<body>
	<div id="mainGrid">
		<input type="checkbox" id="sidebarToggle" tabindex="-1" />
		<section class="sidebar-section">
			<label for="sidebarToggle" class="bg-dark text-white text-end px-3 py-1">
				<i class="bi bi-list"></i>
			</label>
			<nav id="sidebar" class="grid-rowspan-2 bg-dark text-white sidebar px-3">
				<div class="py-2"><img src="/assets/common/image/logo.svg" alt="logo" style="height:1em;width:1em;" /><span class="sidebar-hidden">売上請求管理システム</span>&nbsp;</div>
				<ul class="nav flex-column">
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="Home" action="index"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">ホーム</span>
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="Drive" action="index"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">売上取込</span>
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="Sales" action="index"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">売上入力</span>
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="SalesOutput" action="index"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">売上伝票出力</span>
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="Billing" action="index"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">請求締データ</span>
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white active" href="{url controller="Billing" action="closedIndex"}">
							<i class="bi bi-house-door"></i><span class="sidebar-hidden">請求締データ</span>
						</a>
					</li>
					{if $smarty.session["User.role"] eq "admin"}
					<li class="nav-item">
						<a class="nav-link text-white" href="{url controller="Home" action="master"}"><i class="bi bi-gear-wide"></i><span class="sidebar-hidden">マスタ管理</span></a>
						<div class="collapse show sidebar-hidden">
							<ul class="ms-3 list-unstyled small">
								<li><a class="nav-link text-white py-1" href="{url controller="UserMaster" action="index"}">ユーザー</a></li>
							</ul>
						</div>
					</li>
					<li class="nav-item">
						<a class="nav-link text-white" href="{url controller="Log" action="index"}">
							<i class="bi bi-hourglass"></i><span class="sidebar-hidden">操作履歴</span>
						</a>
					</li>
					{/if}
				</ul>
			</nav>
		</section>
		<div class="bg-dark text-white text-end px-3 py-1">
			<a href="{url controller="Default" action="logout"}" class="text-white">Logout&ensp;<i class="bi bi-box-arrow-right"></i></a>
		</div>
		<div>
			{block name="title"}{/block}
			<ol class="breadcrumb"></ol>
		</div>
		<div class="overflow-auto px-4 py-4">
			{block name="body"}{/block}
		</div>
	</div>
	<div style="position:fixed;top:0;bottom:0;right:0;left:0;width:auto;height:auto;margin:0;padding:0;display:grid;grid-template:1fr auto 1fr/1fr auto 1fr;visibility:hidden;">
		<div class="toast-container" style="grid-column:2;grid-row:2;visibility:visible;"></div>
	</div>
	{block name="dialogs"}{javascript_notice}{/block}
</body>
</html>