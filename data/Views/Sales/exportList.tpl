{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
<style type="text/css">
print-page{
	background-color: white;
	padding: 24px;
}
print-page table th{
	font-weight: normal;
	border-left: calc(1rem / 12) solid black;
	text-align: center;
	font-size: 10px;
}
print-page table td{
	border-left: calc(1rem / 12) solid black;
	border-bottom: calc(1rem / 12) dotted black;
	font-size: 10px;
}
print-page table td:nth-of-type(1),
print-page table td:nth-of-type(8),
print-page table td:nth-of-type(9),
print-page table td:nth-of-type(10),
print-page table td:nth-of-type(11),
print-page table td:nth-of-type(12),
print-page table td:nth-of-type(13){
	text-align: right;
}
.tfoot td{
	border-top: calc(1rem / 12) solid black;
}
</style>
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
		const now = new Date();
		document.querySelector('[data-slot="year"]').textContent = now.getFullYear();
		document.querySelector('[data-slot="month"]').textContent = now.getMonth() + 1;
		document.querySelector('[data-slot="date"]').textContent = now.getDate();
		const tbody = document.querySelector('tbody');
		const fragment = document.createDocumentFragment();
		const query = transaction.select("ALL")
			.addWith("temppurchases AS (SELECT ss,sum(amount_inc) AS amount_inc FROM purchases LEFT JOIN purchase_relations USING(pu) GROUP BY ss)")
			.addTable("sales_slips")
			.leftJoin("sales_workflow USING(ss)")
			.leftJoin("temppurchases USING(ss)")
			.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.apply_client=apply_clients.code")
			.leftJoin("master.clients AS clients ON apply_clients.client=clients.code");
		const fields = [
			"STRFTIME('%Y-%m',sales_workflow.approval_datetime)",
			"sales_slips.project",
			"STRFTIME('%Y-%m-%d %H:%M',sales_workflow.regist_datetime)",
			"clients.name",
			"sales_slips.subject",
			"apply_clients.name",
			"sales_slips.amount_inc",
			"sales_slips.amount_exc",
			"ifnull(temppurchases.amount_inc, 0)",
			"(sales_slips.amount_inc - ifnull(temppurchases.amount_inc, 0))"
		];
		for(let i = 0; i < fields.length; i++){
			query.addField(`${fields[i]} AS field${i}`);
		}
		let total = new Array(fields.length).fill(0);
		query.setLimit("3001");
		const data = query.apply();
		const memover = data.length > 3000;
		let rowno = 1;
		for(let row of data){
			const tr = document.createElement("tr");
			tr.appendChild(Object.assign(document.createElement("td"), {textContent: rowno}));
			for(let i = 0; i < fields.length; i++){
				tr.appendChild(Object.assign(document.createElement("td"), {textContent: row[`field${i}`]}));
				if(typeof row[`field${i}`] == "number"){
					total[i] += row[`field${i}`];
				}
			}
			rowno++;
			fragment.appendChild(tr);
		}
		tbody.appendChild(fragment);
		if(memover){
			const tfoot = document.querySelector('tbody.tfoot');
			tfoot.innerHTML = `<td colspan="${fields.length + 1}" class="text-start text-danger">エラー　出力可能な売上一覧表の上限を超過しています。</td>`;
			alert("出力可能な売上一覧表の上限を超過しています。");
		}else{
			const tfoot = document.querySelectorAll('tbody.tfoot td');
			for(let i = 0; i < fields.length; i++){
				if(tfoot[i + 1].textContent == ""){
					tfoot[i + 1].textContent = total[i];
				}
			}
		}
		
		document.querySelector('print-page').pageBreak(
			(function*(){
				const elements = document.querySelectorAll('tbody tr');
				const n = elements.length;
				for(let i = 0; i < n; i++){
					yield elements[i];
				}
			})(),
			node => ((node.nodeType == Node.ELEMENT_NODE) && node.hasAttribute("data-page-clone")),
			(page, node) => { page.insertAdjacentElement("afterend", node); }
		);
		
		const btn = document.createElement("button");
		btn.setAttribute("type", "button");
		btn.setAttribute("slot", "tools");
		btn.setAttribute("class", "btn btn-success my-2");
		btn.textContent = "ダウンロード";
		document.getElementById("spmain").appendChild(btn);
		btn.addEventListener("click", e => {
			let docIds = {};
			const doc = new jspdf.jsPDF({unit: "pt"});
			for(let fontName in PrintPage.font){
				docIds[fontName] = `custom${Object.keys(docIds).length}`;
				doc.addFileToVFS(PrintPage.font[fontName].alias, PrintPage.font[fontName].data);
				doc.addFont(PrintPage.font[fontName].alias, docIds[fontName], 'normal');
			}
			
			const pxPt = 0.75;
			const textOpt = {align: "left", baseline: "top"};
			const printPages = document.querySelectorAll('#spmain print-page');
			const pageCnt = printPages.length;
			for(let i = 0; i < pageCnt; i++){
				const printData = printPages[i].printData;
				const textLen = printData.text.length;
				let ctx = {};
				doc.addPage(printData.page.size, printData.page.orientation);
				for(let fill of printData.fill){
					const colorParts = fill.color.match(/\d+/g);
					doc.setFillColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
					doc.rect(fill.x1 * pxPt, fill.y1 * pxPt, (fill.x2 - fill.x1) * pxPt, (fill.y2 - fill.y1) * pxPt, "F");
				}
				for(let line of printData.line){
					const colorParts = line.color.match(/\d+/g);
					doc.setDrawColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
					doc.setLineWidth(line.width * pxPt);
					console.log(line);
					if(line.style == "solid"){
						doc.setLineDashPattern([], 0);
					}else if(line.style == "dashed"){
						doc.setLineDashPattern([2, 1], 0);
					}else if(line.style == "dotted"){
						doc.setLineDashPattern([1, 1], 0);
					}
					doc.line(line.x1 * pxPt, line.y1 * pxPt, line.x2 * pxPt, line.y2 * pxPt);
				}
				doc.setLineDashPattern([], 0);
				for(let pos = 0; pos < textLen; pos++){
					if(pos in printData.style){
						let changeFont = false;
						if("fontFamily" in printData.style[pos]){
							changeFont = true;
							ctx.fontFamily = docIds[printData.style[pos].fontFamily];
						}
						if("fontWeight" in printData.style[pos]){
							changeFont = true;
							ctx.fontWeight = printData.style[pos].fontWeight ? "bold" : null;
						}
						if(changeFont){
							doc.setFont(ctx.fontFamily);
						}
						if("fontColor" in printData.style[pos]){
							const colorParts = printData.style[pos].fontColor.match(/\d+/g);
							doc.setTextColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
						}
						if("fontSize" in printData.style[pos]){
							doc.setFontSize(printData.style[pos].fontSize * pxPt);
						}
						if("line" in printData.style[pos]){
							for(let line of printData.style[pos].line){
								const colorParts = line.color.match(/\d+/g);
								doc.setDrawColor(parseInt(colorParts[0]), parseInt(colorParts[1]), parseInt(colorParts[2]));
								doc.setLineWidth(line.width * pxPt);
								doc.line(line.x1 * pxPt, line.y1 * pxPt, line.x2 * pxPt, line.y2 * pxPt);
							}
						}
					}
					const textData = printData.text[pos];
					doc.text(textData.ch, textData.x * pxPt, textData.y * pxPt, textOpt);
				}
			}
			doc.deletePage(1);
			const formData = new FormData();
			const w = open("about:blank", "_blank", "left=0,top=0,width=1200,height=600");
			formData.append("pdf", doc.output("blob"), "print.pdf");
			formData.append("name", search.key);
			fetch("/Upload/sales", {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(result => {
				if(result.success){
					let path = "about:blank";
					for(let meaasge of result.messages){
						if(meaasge[2] == "path"){
							path = meaasge[0];
							break;
						}
					}
					w.location = path;
				}else{
					alert(result.messages[0][0]);
				}
			});
		});
	}
});

let master = new SQLite();
let cache = new SQLite();
let transaction = new SQLite();
const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
	const found = t.match(/^(.*?)=(.*)$/);
	if(found){
		a[found[1]] = decodeURIComponent(found[2]);
	}
	return a;
},{});
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	cache.use("cache"),
	Promise.all(PrintPage.loading),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	try{
		const data = cache.select("ONE").setTable("sales_data").setField("selected").andWhere("slip_number=?", search.key).apply();
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
								<div part="title">売上一覧表出力</div>
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
				<div slot="main" style="background-color: gray; padding:10px;" class="d-flex flex-column gap-2 overflow-auto">
					<print-page size="A3" orientation="l" class="flex-shrink-0">
						<div class="d-flex justify-content-between"><div style="font-size: 20px;">【 売上一覧表 】</div><div>日付<div class="d-inline-block text-end" style="width: 6em;"><span data-slot="year"></span>年</div><div class="d-inline-block text-end" style="width: 3em;"><span data-slot="month"></span>月</div><div class="d-inline-block text-end" style="width: 3em;"><span data-slot="date"></span>日</div></div></div>
						<div class="d-flex justify-content-end" style="margin-bottom: 20px;">株式会社ダイレクト・ホールディングス</div>
						<table class="w-100" style="border: solid black calc(1rem / 6);white-space: pre;">
							<colgroup data-page-clone="1">
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
								<col />
							</colgroup>
							<thead data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);">
								<tr>
									<th>項番</th>
									<th>月日</th>
									<th>案件番号</th>
									<th>取込日時</th>
									<th>得意先名</th>
									<th>案件名称</th>
									<th>請求先名</th>
									<th>売上金額（税込）</th>
									<th>売上金額（税抜）</th>
									<th>仕入金額（税込）</th>
									<th>利益（税込）</th>
								</tr>
							</thead>
							<tbody></tbody>
							<tbody class="tfoot">
								<tr>
									<td colspan="7" class="text-start">小計</td>
									<td class="d-none"></td>
									<td class="d-none"></td>
									<td class="d-none"></td>
									<td class="d-none"></td>
									<td class="d-none"></td>
									<td class="d-none"></td>
									<td></td>
									<td></td>
									<td></td>
									<td></td>
								</tr>
							</tbody>
						</table>
					</print-page>
				</div>
			</template>
		</div>
	</form>
{/block}