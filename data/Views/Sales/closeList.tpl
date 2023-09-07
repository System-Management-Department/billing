{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/common/PrintPage.js"></script>
<script type="text/javascript" src="/assets/jspdf/jspdf.umd.min.js"></script>
<script type="text/javascript">
new VirtualPage("/", class{
	constructor(vp){
		const tbody = document.querySelector("tbody");
		const query = transaction.select("ALL")
			.addWith("relations AS (SELECT DISTINCT ss,sd FROM purchase_relations)")
			.addTable("sales_slips")
			.leftJoin("relations USING(ss)")
			.leftJoin("sales_details USING(sd)")
			.leftJoin("sales_attributes USING(ss)")
			.leftJoin("sales_workflow USING(ss)")
			.leftJoin("sales_detail_attributes USING(sd)")
			.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.apply_client=apply_clients.code")
			.leftJoin("master.leaders AS leaders ON sales_slips.leader=leaders.code")
			.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code");
		const fields = [
			"sales_workflow.approval_datetime",
			"sales_slips.slip_number",
			"sales_slips.apply_client",
			"apply_clients.name",
			"sales_slips.amount_exc",
			"sales_slips.amount_tax",
			"sales_slips.amount_inc",
			"sales_slips.payment_date",
			"sales_workflow.approval_datetime",
			"sales_details.detail",
			"sales_details.quantity",
			"sales_details.unit_price",
			"sales_details.amount_exc",
			"sales_slips.note",
			"NULL",
			"NULL",
			"NULL",
			"NULL",
			"NULL",
			"apply_clients.kana",
			"CURRENT_DATE",
			"sales_slips.amount_inc",
			"sales_slips.subject",
			"sales_details.unit",
			"json_extract(sales_attributes.data, '$.summary_header[0]')",
			"json_extract(sales_attributes.data, '$.summary_header[1]')",
			"json_extract(sales_attributes.data, '$.summary_header[2]')",
			"json_extract(sales_detail_attributes.data, '$.summary_data[0]')",
			"json_extract(sales_detail_attributes.data, '$.summary_data[1]')",
			"json_extract(sales_detail_attributes.data, '$.summary_data[2]')",
			"sales_slips.amount_tax",
			"sales_slips.amount_inc",
			"sales_details.amount_tax",
			"sales_details.amount_inc",
			"(leaders.name || '・' || managers.name)",
			"json_extract(sales_detail_attributes.data, '$.circulation')",
			"sales_details.unit_price",
			"CURRENT_DATE"
		];
		query.addField("DISTINCT sales_slips.invoice_format");
		for(let i = 0; i < fields.length; i++){
			query.addField(`${fields[i]} AS field${i}`);
		}
		const data = query.apply();
		for(let row of data){
			const tr = document.createElement("tr");
			tr.appendChild(Object.assign(document.createElement("td"), {textContent: row.invoice_format}));
			for(let i = 0; i < fields.length; i++){
				tr.appendChild(Object.assign(document.createElement("td"), {textContent: row[`field${i}`]}));
			}
			tbody.appendChild(tr);
		}
	}
});

let master = new SQLite();
let cache = new SQLite();
let transaction = new SQLite();
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	cache.use("cache"),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
		const found = t.match(/^(.*?)=(.*)$/);
		if(found){
			a[found[1]] = decodeURIComponent(found[2]);
		}
		return a;
	},{});
	try{
		const data = cache.select("ONE").setTable("close_data").setField("selected").andWhere("dt=?", Number(search.key)).apply();
		const formData = new FormData();
		formData.append("slip_number_array", data);
		return fetch("/Sales/search", {
			method: "POST",
			body: formData
		}).then(res => res.arrayBuffer());
	}catch(ex){
		Promise.reject(null);
	}
}).then(buffer => {
	transaction.import(buffer, "transaction");
	transaction.attach(master, "master");
	
	SinglePage.location = `/`;
}, () => { close(); });
{/literal}</script>
{/block}
{block name="body"}
	<form>
		<input type="hidden" name="sequence" value="{$sequence}" />
		<div id="spmain">
			<template shadowroot="closed">
				<slot name="print"></slot>
				<div part="body">
					<header part="header">
						<nav part="nav1">
							<div part="container">
								<div part="title">請求締め</div>
							</div>
						</nav>
						<nav part="nav2">
							<div part="tools"><slot name="tools"></slot></div>
						</nav>
					</header>
					<div>
						<div style="display: grid; column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;">
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table1"></slot>
								</div>
							</div>
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table2"></slot>
								</div>
							</div>
						</div>
					</div>
					<slot name="main"></slot>
				</div>
			</template>
			<div>読み込み中</div>
			<template data-page="/">
				<div slot="main" style="overflow-x: auto;">
					<table border="1" style="white-space: nowrap;">
						<thead>
							<tr>
								<th>フォーマット</th>
								<th>対象日付</th>
								<th>帳票No</th>
								<th>顧客コード</th>
								<th>顧客名</th>
								<th>税抜金額</th>
								<th>消費税</th>
								<th>合計金額</th>
								<th>支払期限</th>
								<th>明細日付</th>
								<th>摘要</th>
								<th>数量</th>
								<th>明細単価</th>
								<th>明細金額</th>
								<th>備考(見出し)</th>
								<th>税抜金額(8%)</th>
								<th>税抜金額(10%)</th>
								<th>消費税(8%)</th>
								<th>消費税(10%)</th>
								<th>税率</th>
								<th>顧客名カナ</th>
								<th>請求日</th>
								<th>請求金額</th>
								<th>件名</th>
								<th>単位</th>
								<th>摘要ヘッダー１</th>
								<th>摘要ヘッダー２</th>
								<th>摘要ヘッダー３</th>
								<th>摘要ヘッダー１値</th>
								<th>摘要ヘッダー２値</th>
								<th>摘要ヘッダー３値</th>
								<th>消費税(明細別合計)</th>
								<th>税込金額(明細合計)</th>
								<th>消費税(明細別)</th>
								<th>税込金額(明細別)</th>
								<th>担当者氏名</th>
								<th>発行部数</th>
								<th>明細単価</th>
								<th>売上日</th>
							</tr>
						</thead>
						<tbody>
						</tbody>
					</table>
				</div>
			</template>
		</div>
	</form>
	
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
{/block}