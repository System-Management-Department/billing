{block name="styles" append}
<style type="text/css">{literal}
html, body{
	margin: 0;
	padding: 0;
	width: 100vw;
}
table{
	border-collapse: collapse;
}
thead{
	position: sticky;
	top: 0;
	background: white;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/googleAPI/GoogleSheets.js"></script>
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript">{literal}
document.addEventListener("DOMContentLoaded", function(e){
	const jwt = {{/literal}spreadsheet: "{url controller="JWT" action="spreadsheet"}", drive: "{url controller="JWT" action="drive"}"{literal}};
	let gd = new GoogleDrive(jwt.drive);
	let gs = null;
	let tableValues = [];
	let detailValues = {};
	let importMap = null;
	let targetId = null;
	let reloadBook = book => {
		let range = book.sheet("売上明細").range.slice(1);
		let tbody = document.querySelector('#spreadsheet tbody');
		tbody.innerHTML = "";
		targetId = book.sheet("取込済").sheetId;
		tableValues = book.sheet("売上").range.slice(1);
		detailValues = {};
		importMap = new Map();
		for(let row of tableValues){
			let disabled = row[0] = !!row[0];
			let tr = document.createElement("tr");
			let checkboxCell = document.createElement("td");
			let checkbox = document.createElement("input");
			checkbox.setAttribute("type", "checkbox");
			checkbox.checked = disabled;
			checkbox.disabled = disabled;
			if(row[2] == null){
				checkbox.disabled = true;
			}
			if(!checkbox.disabled){
				detailValues[row[1]] = {
					length: 0,
					itemCode: [],
					itemName: [],
					unit: [],
					quantity: [],
					unitPrice: [],
					amount: [],
					data1: [],
					data2: [],
					data3: [],
					circulation: []
				};
			}
			checkboxCell.appendChild(checkbox);
			importMap.set(checkbox, row);
			for(let cell of row){
				let data = (cell instanceof Date) ? Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(cell) : cell;
				tr.appendChild(Object.assign(document.createElement("td"), {textContent: data}));
			}
			tr.replaceChild(checkboxCell, tr.firstChild);
			tbody.appendChild(tr);
		}
		for(let row of range){
			let key = row[0]
			if(key in detailValues){
				detailValues[key].length++;
				detailValues[key].itemCode.push(row[1]);
				detailValues[key].itemName.push(row[2]);
				detailValues[key].unit.push(row[3]);
				detailValues[key].quantity.push(row[4]);
				detailValues[key].unitPrice.push(row[5]);
				detailValues[key].amount.push(row[6]);
				detailValues[key].data1.push(row[7]);
				detailValues[key].data2.push(row[8]);
				detailValues[key].data3.push(row[9]);
				detailValues[key].circulation.push(row[10]);
			}
		}
	};
	gd.getAll().then(obj => {
		let tbody = document.querySelector('#drive tbody');
		for(let item of obj.items){
			let tr = document.createElement("tr");
			let a = Object.assign(document.createElement("a"), {textContent: item.title});
			let td1 = document.createElement("td");
			let td2 = document.createElement("td");
			a.setAttribute("target", "_blank");
			a.setAttribute("href", `https://docs.google.com/spreadsheets/d/${item.id}/edit`);
			if(item.userPermission.role == "owner"){
				let button = Object.assign(document.createElement("button"), {textContent: "読込"});
				button.setAttribute("type", "button");
				button.setAttribute("data-id", item.id);
				button.setAttribute("data-action", "load");
				button.setAttribute("data-title", item.title);
				td2.appendChild(button);
				
				button = Object.assign(document.createElement("button"), {textContent: "削除"});
				button.setAttribute("type", "button");
				button.setAttribute("data-id", item.id);
				button.setAttribute("data-action", "delete");
				td2.appendChild(button);
			}
			td1.appendChild(a);
			tr.appendChild(td1);
			tr.appendChild(Object.assign(document.createElement("td"), {textContent: item.mimeType}));
			tr.appendChild(Object.assign(document.createElement("td"), {textContent: item.userPermission.role}));
			tr.appendChild(td2);
			tbody.appendChild(tr);
		}
	});
	document.querySelector('#drive tbody').addEventListener("click", e => {
		if(e.target.hasAttribute("data-id") && e.target.hasAttribute("data-action")){
			if(e.target.getAttribute("data-action") == "delete"){
				gd.delete(e.target.getAttribute("data-id")).then(res => {location.reload();});
			}else{
				gs = new GoogleSheets(jwt.spreadsheet, e.target.getAttribute("data-id"));
				gs.getAll().then(reloadBook);
				
				document.getElementById("title").textContent = e.target.getAttribute("data-title");
				document.getElementById("drive").style.display = "none";
				document.getElementById("spreadsheet").style.display = "table";
				document.getElementById("create").style.display = "none";
				document.getElementById("create2").style.display = "none";
				document.getElementById("import").style.display = "inline-block";
			}
		}
	}, true);
	document.getElementById('create').addEventListener("click", e => {
		let filename = prompt("filename", "");
		if(filename == null || filename == ""){
			return;
		}
		gs = new GoogleSheets(jwt.drive);
		gs.create(filename, [
			GoogleSheets.createSheetJson({index: 0, title: "売上"}, 100, 15, {
				rows: [
					[
						GoogleSheets.formula`BYROW(B:B,LAMBDA(X,IF(ROW(X)=1,"取込済",COUNTIF('取込済'!A:A,X)>0)))`,
						GoogleSheets.formula`BYROW(C:C,LAMBDA(X,IF(ROW(X)=1,"通し番号",TEXT(ROW(X)-1,"00000000"))))`,
						"伝票番号", "売上日付", "部門", "チーム", "当社担当者", "請求先", "納品先", "件名", "備考", "摘要ヘッダー１", "摘要ヘッダー２", "摘要ヘッダー３", "入金予定日"
					]
				],
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 15}
				]
			}),
			GoogleSheets.createSheetJson({index: 1, title: "売上明細"}, 500, 11, {
				rows: [
					["通し番号", "商品コード", "商品名", "単位", "数量", "単価", "金額", "摘要１", "摘要２", "摘要３", "発行部数"]
				],
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 11}
				]
			}),
			GoogleSheets.createSheetJson({index: 2, title: "取込済", hidden: true}, 100, 2, {
				protectedRanges: [{}]
			}),
			GoogleSheets.createSheetJson({index: 3, title: "マスター", hidden: true}, 100, 2, {
				namedRanges: {
					range1: {startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 1},
					range2: {startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 1}
				},
				protectedRanges: [{}]
			})
		]).then(res => gd.createPermission(res.spreadsheetId)).then(res => {
			location.reload();
		});
	}, true);
	document.getElementById('create2').addEventListener("click", e => {
		// ダミーデータ
		let filename = prompt("filename", "");
		if(filename == null || filename == ""){
			return;
		}
		
		let s1 = [
			[
				GoogleSheets.formula`BYROW(B:B,LAMBDA(X,IF(ROW(X)=1,"取込済",COUNTIF('取込済'!A:A,X)>0)))`,
				GoogleSheets.formula`BYROW(C:C,LAMBDA(X,IF(ROW(X)=1,"通し番号",TEXT(ROW(X)-1,"00000000"))))`,
				"伝票番号", "売上日付", "部門", "チーム", "当社担当者", "請求先", "納品先", "件名", "備考", "摘要ヘッダー１", "摘要ヘッダー２", "摘要ヘッダー３", "入金予定日"
			]
		];
		let s2 = [
			["通し番号", "商品コード", "商品名", "単位", "数量", "単価", "金額", "摘要１", "摘要２", "摘要３", "発行部数"]
		];
		let unita = ["kg", "g", "mg", "L", "mL", "個", "ダース", "グロス", "ケース", "枚"];
		let rs = "rehwserjhoyptfwsj rhbjsieryhow ksrbojaer8gu yw5y9hajri owehgq35uyjg8aqer 90w34qagihregw qy934yqt84hgawg9speu tw5ygsuiehgvisetwy4";
		for(let i = 0; i < 500; i++){
			let time = new Date("2022-10-01").setMilliseconds(Math.random() * 8640000000);
			let time2 = new Date(time).setMilliseconds(Math.random() * 8640000000);
			let sno = Math.floor(Math.random() * 10000000);
			let k1 = Math.floor(Math.random() * 8);
			let k2 = Math.floor(Math.random() * 10);
			let k3 = Math.floor(Math.random() * 50);
			let k4 = Math.floor(Math.random() * 300);
			let hs1 = Math.floor(Math.random() * 100);
			let hs2 = Math.floor(Math.random() * 100);
			let hs3 = Math.floor(Math.random() * 100);
			let hs4 = Math.floor(Math.random() * 100);
			let hs5 = Math.floor(Math.random() * 100);
			let he1 = hs1 + Math.floor(Math.random() * 30) + 5;
			let he2 = hs2 + Math.floor(Math.random() * 30) + 5;
			let he3 = hs3 + Math.floor(Math.random() * 30) + 5;
			let he4 = hs4 + Math.floor(Math.random() * 30) + 5;
			let he5 = hs5 + Math.floor(Math.random() * 30) + 5;
			let rn = Math.floor(Math.random() * 10) + 1;
			s1.push([null, null, sno, Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(time), k1, k2, k3, k4, `納品先${i + 1}`, rs.substring(hs1, he1), rs.substring(hs2, he2), rs.substring(hs3, he3), rs.substring(hs4, he4), rs.substring(hs5, he5), Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(time2)]);
			for(let j = 0; j < rn; j ++){
				let cn = Math.floor(Math.random() * 90000) + 10000;
				let unit = unita[Math.floor(Math.random() * 10)];
				let v3 = Math.floor(Math.random() * 200000) / 100;
				let v4 = Math.floor(Math.random() * 100) * 50 + 50;
				let v6 = (Math.floor(Math.random() * 100) * 50 + 50) * (Math.floor(Math.random() * 16) + 1);
				let ss1 = Math.floor(Math.random() * 100);
				let ss2 = Math.floor(Math.random() * 100);
				let ss3 = Math.floor(Math.random() * 100);
				let ss4 = Math.floor(Math.random() * 100);
				let se1 = ss1 + Math.floor(Math.random() * 30) + 5;
				let se2 = ss2 + Math.floor(Math.random() * 30) + 5;
				let se3 = ss3 + Math.floor(Math.random() * 30) + 5;
				let se4 = ss4 + Math.floor(Math.random() * 30) + 5;
				s2.push([`${i + 100000001}`.substring(1), `A${cn}`, rs.substring(ss1, se1), unit, v3, v4, v6, rs.substring(ss2, se2), rs.substring(ss3, se3), rs.substring(ss4, se4)]);
			}
		}
		
		gs = new GoogleSheets(jwt.drive);
		gs.create(filename, [
			GoogleSheets.createSheetJson({index: 0, title: "売上"}, 600, 15, {
				rows: s1,
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 15}
				]}
			),
			GoogleSheets.createSheetJson({index: 1, title: "売上明細"}, s2.length + 100, 11, {
				rows: s2,
				protectedRanges: [
					{startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 11}
				]
			}),
			GoogleSheets.createSheetJson({index: 2, title: "取込済", hidden: true}, 100, 2, {
				protectedRanges: [{}]
			}),
			GoogleSheets.createSheetJson({index: 3, title: "マスター", hidden: true}, 100, 2, {
				namedRanges: {
					range1: {startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 1},
					range2: {startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: 1}
				},
				protectedRanges: [{}]
			})
		]).then(res => gd.createPermission(res.spreadsheetId)).then(res => {
			location.reload();
		});
	}, true);
	
	document.getElementById("import").addEventListener("click", e => {
		let importData = [];
		let checked = document.querySelectorAll('tbody input:checked:not([disabled])');
		let n = checked.length;
		let appendValues = [];
		for(let i = 0; i < n; i++){
			let input = checked[i];
			if(importMap.has(input)){
				let taxRate = 0.1;
				let tempRow = importMap.get(input);
				let data = tempRow.slice(2, 15).map(a => (a instanceof Date) ? Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(a).split("/").join("-") : a);
				data.push(detailValues[tempRow[1]].amount.filter(v => typeof v === "number").reduce((total, v) => total + v, 0) * taxRate);
				data.push(detailValues[tempRow[1]]);
				importData.push(data);
				appendValues.push([tempRow[1], GoogleSheets.now]);
			}
		}
		let formData = new FormData();
		formData.append("json", JSON.stringify(importData));
		fetch("{/literal}{url action="import"}{literal}", {
			method: "POST",
			body: formData
		}).then(res => res.json()).then(data => {
		});
		gs.update({
			[GoogleSheets.requestSymbol]: "appendCells",
			[targetId]: appendValues
		}).then(res => {
			gs.getAll().then(reloadBook);
		});
	});
});

{/literal}</script>
{/block}

{block name="body"}
<button type="button" id="create">新規</button><button type="button" id="create2">ダミー</button><span id="title"></span><button type="button" id="import" style="display: none;">取込</button>
<table border="1" id="drive">
	<thead><th>ファイル名</th><th>種類</th><th>権限</th><th>操作</th></thead>
	<tbody></tbody>
</table>
<table border="1" id="spreadsheet" style="display: none;">
	<thead><th>取込</th><th>通し番号</th><th>伝票番号</th><th>売上日付</th><th>部門</th><th>チーム</th><th>当社担当者</th><th>請求先</th><th>納品先</th><th>件名</th><th>備考</th><th>摘要ヘッダー１</th><th>摘要ヘッダー２</th><th>摘要ヘッダー３</th><th>入金予定日</th></thead>
	<tbody></tbody>
</table>
{/block}