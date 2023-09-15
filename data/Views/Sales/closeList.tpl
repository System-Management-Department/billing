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
<script type="text/javascript" src="/assets/common/SJISEncoder.js"></script>
<script type="text/javascript" src="/assets/common/CSVSerializer.js"></script>
<script type="text/javascript">
new VirtualPage("/", class{
	constructor(vp){
		const body = document.querySelector('[slot="main"]');
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
		let csvHeader = [];
		const fields = [
			{header: "対象日付",           query: "STRFTIME('%Y/%m/%d', sales_workflow.approval_datetime)"},
			{header: "帳票No",             query: "sales_slips.slip_number"},
			{header: "顧客コード",         query: "sales_slips.apply_client"},
			{header: "顧客名",             query: "apply_clients.name"},
			{header: "税抜金額",           query: "sales_slips.amount_exc"},
			{header: "消費税",             query: "sales_slips.amount_tax"},
			{header: "合計金額",           query: "sales_slips.amount_inc"},
			{header: "支払期限",           query: "STRFTIME('%Y/%m/%d', sales_slips.payment_date)"},
			{header: "明細日付",           query: "STRFTIME('%Y/%m/%d', sales_workflow.approval_datetime)"},
			{header: "摘要",               query: "sales_details.detail"},
			{header: "数量",               query: "sales_details.quantity"},
			{header: "明細単価",           query: "sales_details.unit_price"},
			{header: "明細金額",           query: "sales_details.amount_exc"},
			{header: "備考(見出し)",       query: "sales_slips.note"},
			{header: "税抜金額(8%)",       query: "NULL"},
			{header: "税抜金額(10%)",      query: "NULL"},
			{header: "消費税(8%)",         query: "NULL"},
			{header: "消費税(10%)",        query: "NULL"},
			{header: "税率",               query: "NULL"},
			{header: "顧客名カナ",         query: "apply_clients.kana"},
			{header: "請求日",             query: "STRFTIME('%Y/%m/%d', CURRENT_DATE)"},
			{header: "請求金額",           query: "sales_slips.amount_inc"},
			{header: "件名",               query: "sales_slips.subject"},
			{header: "単位",               query: "sales_details.unit"},
			{header: "摘要ヘッダー１",     query: "json_extract(sales_attributes.data, '$.summary_header[0]')"},
			{header: "摘要ヘッダー２",     query: "json_extract(sales_attributes.data, '$.summary_header[1]')"},
			{header: "摘要ヘッダー３",     query: "json_extract(sales_attributes.data, '$.summary_header[2]')"},
			{header: "摘要ヘッダー１値",   query: "json_extract(sales_detail_attributes.data, '$.summary_data[0]')"},
			{header: "摘要ヘッダー２値",   query: "json_extract(sales_detail_attributes.data, '$.summary_data[1]')"},
			{header: "摘要ヘッダー３値",   query: "json_extract(sales_detail_attributes.data, '$.summary_data[2]')"},
			{header: "消費税(明細別合計)", query: "sales_slips.amount_tax"},
			{header: "税込金額(明細合計)", query: "sales_slips.amount_inc"},
			{header: "消費税(明細別)",     query: "sales_details.amount_tax"},
			{header: "税込金額(明細別)",   query: "sales_details.amount_inc"},
			{header: "担当者氏名",         query: "(leaders.name || '・' || managers.name)"},
			{header: "発行部数",           query: "json_extract(sales_detail_attributes.data, '$.circulation')"},
			{header: "明細単価",           query: "sales_details.unit_price"},
			{header: "売上日",             query: "STRFTIME('%Y/%m/%d', CURRENT_DATE)"}
		];
		query.addField("DISTINCT sales_slips.invoice_format");
		for(let i = 0; i < fields.length; i++){
			query.addField(`${fields[i].query} AS field${i}`);
			csvHeader.push(fields[i].header);
		}
		const csvFormats = [{key: 1, label: "通常請求書"}, {key: 2, label: "ニッピ用請求書"}, {key: 3, label: "加茂繊維用請求書"}, {key: 4, label: "ダイドー用請求書"}];
		const csvData = {
			[1]: [],
			[2]: [],
			[3]: [],
			[4]: []
		};
		const data = query.apply();
		for(let row of data){
			if(row.invoice_format in csvData){
				let rowData = [];
				for(let i = 0; i < fields.length; i++){
					if(row[`field${i}`] == null){
						rowData.push("");
					}else{
						rowData.push(row[`field${i}`]);
					}
				}
				csvData[row.invoice_format].push(rowData);
			}
		}
		if("cacheOpen" in opener){
			let sendData = [];
			for(let {key, label} of csvFormats){
				if(csvData[key].length <= 0){
					continue;
				}
				sendData.push({
					json: {
						reportTypeId: key,
						isNewIssues: "1",
						importProcessName: `${label} 取込`,
						skipFirst: "1",
						isImmApproval: "0"
					},
					csv: csvData[key],
					filename: `${label}.csv`
				});
			}
			const fileReader = new FileReader();
			const readerEvent = {
				reader: fileReader,
				resolve: null,
				reject: null,
				handleEvent(e){
					this.resolve(this.reader.result);
				}
			};
			fileReader.addEventListener("load", readerEvent);
			new Blob([`export function run(config){
	const importDatas = ${jsEncode(sendData)};
	const serializer = new CSVSerializer().setConverter(text => SJISEncoder.createBlob(text, {type: "text/csv"}));
	const requestHeaders = new Headers();
	requestHeaders.append("X-WB-apitoken", config.apiToken);
	return Promise.all(importDatas.map(importObj => {
		const formData = new FormData();
		formData.append("json", JSON.stringify(importObj.json));
		formData.append("files[0]", serializer.serializeToString(importObj.csv), importObj.filename);
		return fetch(\`\${config.endpoint}/reports/imports\`, {
			method: "POST",
			headers: requestHeaders,
			body: formData
		}).then(res => res.text());
	})).then(res => \`[\${res.join(",")}]\`);
}`], {type: "application/javascript"})
				.arrayBuffer()
				.then(buffer => {
					let p = opener.cacheOpen();
					const n = buffer.byteLength;
					//1kBチャンクに分割
					for(let i = 0; i < n; i += 1024){
						const chunk = buffer.slice(i, i + 1024);
						p = p.then(fd => {
							return new Promise((resolve, reject) => {
								readerEvent.resolve = resolve;
								readerEvent.reject = reject;
								fileReader.readAsDataURL(new Blob([chunk], {type: "text/plain"}));
							}).then(data => opener.cacheWrite(fd, data));
						});
					}
					p.then(fd => opener.cacheRun(fd, `${location.origin}/assets/common/CSVSerializer.js`, `${location.origin}/assets/common/SJISEncoder.js`)).then(json => { console.log(json); });
				});
			function jsEncode(value){
				if(value == null){
					return "null";
				}else if(Array.isArray(value)){
					return `[${value.map(v => jsEncode(v)).join(",")}]`;
				}else if(typeof value == "object"){
					let res = [];
					for(let k in value){
						res.push(`${k}:${jsEncode(value[k])}`);
					}
					return `{${res.join(",")}}`;
				}
				return JSON.stringify(value);
			}
		}
		const serializer = new CSVSerializer().setHeader(csvHeader).setConverter(text => SJISEncoder.createBlob(text, {type: "text/csv"}));
		for(let {key, label} of csvFormats){
			if(csvData[key].length <= 0){
				continue;
			}
			const blob = serializer.serializeToString(csvData[key]);
			const a = document.createElement("a");
			a.textContent = `${label} ダウンロード`;
			a.className = "btn btn-success";
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", `請求データ（${label}）_${search.key}.csv`);
			body.appendChild(a);
		}
		
		const undoBtn = document.createElement("button");
		undoBtn.textContent = `取り消し`;
		undoBtn.className = "btn btn-warning";
		undoBtn.setAttribute("type", "button");
		body.appendChild(undoBtn);
		undoBtn.addEventListener("click", e => {
			const formData = new FormData();
			formData.append("id", search.key);
			fetch("/Billing/closeUndo", {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(result => {
				if(result.success){
					close();
				}
			});
		});
	}
});

let master = new SQLite();
let transaction = new SQLite();
let search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
	found = t.match(/^(.*?)=(.*)$/);
	if(found){
		a[found[1]] = decodeURIComponent(found[2]);
	}
	return a;
},{});
const searchQuery = new FormData();
searchQuery.append("version", search.key);
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	fetch("/Billing/search", {method: "POST", body: searchQuery}).then(res => res.arrayBuffer()),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	transaction.import(response[1], "transaction");
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
			<template data-page="/">
				<div slot="main" class="d-flex flex-row gap-3 mx-3">
				</div>
			</template>
		</div>
	</form>
{/block}