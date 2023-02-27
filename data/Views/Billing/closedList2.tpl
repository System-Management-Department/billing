{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>請求締データ</div>
	</h2>
</nav>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
<script type="text/javascript">
{call name="ListItem"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
	location: "{url}",{literal}
	form: null,
	y: null,
	*[Symbol.iterator](){
		yield* this.init();
		const db = new SQLite();
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(this.form)
		}).then(response => response.arrayBuffer());
		db.import(buffer, "list");
		const template = new ListItem();
		const form = document.getElementById("outputlist");
		
		let table = db.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.id,sales_slips.slip_number,sales_slips.subject,sales_slips.detail")
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.apply();
			
		// SQLiteにチェックされている項目があれば1、なければ0を返す関数id_filterを追加
		db.create_function("id_filter", (id) => {
			return ((document.querySelector(`input[name="id[]"][value="${id}"]:checked`) == null) ? 0 : 1);
		});
		db.create_function("detail_each", {
			length: 1,
			apply(dummy, args){
				let taxRate = 0.1;
				let obj = JSON.parse(args[0]);
				let values = {amount: 0, amountPt: 0, amountSt: 0};
				for(let i = 0; i < obj.length; i++){
					if(typeof obj.amount[i] === "number"){
						values.amount += obj.amount[i];
						values.amountPt += obj.amount[i] * taxRate;
					}
				}
				values.amountSt = values.amount * taxRate;
				let res = new Array(obj.length).fill(values);
				return JSON.stringify(res);
			}
		});
		for(let row of table){
			row.detail = JSON.parse(row.detail);
			template.insertBeforeEnd(form, row);
		}
		if(this.y != null){
			document.documentElement.scrollTop = this.y;
			this.y = null;
		}
		
		let pObj = {};
		form.addEventListener("submit", e => { pObj.resolve(e); });
		do{
			yield* this.input(pObj, db, form);
		}while(true);
	},
	*init(){
		this.form = document.getElementById("search");
		const db = yield* Flow.waitDbUnlock();
		let history = db.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", this.location)
			.setOrderBy("time DESC")
			.apply();
		if(history != null){
			let {data, label} = JSON.parse(history.json);
			for(let k in data){
				for(let v of data[k]){
					let input = Object.assign(document.createElement("input"), {value: v});
					input.setAttribute("type", "hidden");
					input.setAttribute("name", k);
					this.form.appendChild(input);
				}
			}
			this.y = history.scroll_y;
			addEventListener("beforeunload", e => {
				db.updateSet("search_histories", {
					scroll_y: document.documentElement.scrollTop
				}, {})
					.andWhere("location=?", history.location)
					.andWhere("time=?", history.time)
					.apply();
				db.commit();
			});
		}
	},
	*input(pObj, db, form){
		let p = new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let e = yield p;
		
		e.stopPropagation();
		e.preventDefault();
		let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(new Date());
		let csvData = [new Uint8Array(Encoding.convert(Encoding.stringToCode([
			"対象日付",
			"帳票No",
			"顧客コード",
			"顧客名",
			"税抜金額",
			"消費税",
			"合計金額",
			"支払期限",
			"明細日付",
			"摘要",
			"数量",
			"明細単価",
			"明細金額",
			"備考(見出し)",
			"税抜金額(8%)",
			"税抜金額(10%)",
			"消費税(8%)",
			"消費税(10%)",
			"税率",
			"顧客名カナ",
			"請求日",
			"請求金額",
			"件名",
			"単位",
			"摘要ヘッダー１",
			"摘要ヘッダー２",
			"摘要ヘッダー３",
			"摘要ヘッダー１値",
			"摘要ヘッダー２値",
			"摘要ヘッダー３値",
			"消費税(明細別合計)",
			"税込金額(明細合計)",
			"消費税(明細別)",
			"税込金額(明細別)",
			"担当者氏名",
			"発行部数",
			"明細単価"
		].join(",") + "\r\n"), {to: "SJIS", from: "UNICODE"}))];
		
		
		
		let table = db.select("ALL")
			.addTable("sales_slips")
			.addTable("json_each(detail_each(sales_slips.detail)) as d")
			.addField("sales_slips.*")
			.addField("json_extract(sales_slips.detail, '$.amount[' || d.key || ']') as amount")
			.addField("json_extract(sales_slips.detail, '$.itemName[' || d.key || ']') as item_name")
			.addField("json_extract(sales_slips.detail, '$.quantity[' || d.key || ']') as quantity")
			.addField("json_extract(sales_slips.detail, '$.unitPrice[' || d.key || ']') as unit_price")
			.addField("json_extract(sales_slips.detail, '$.unit[' || d.key || ']') as unit")
			.addField("json_extract(sales_slips.detail, '$.data1[' || d.key || ']') as data1")
			.addField("json_extract(sales_slips.detail, '$.data2[' || d.key || ']') as data2")
			.addField("json_extract(sales_slips.detail, '$.data3[' || d.key || ']') as data3")
			.addField("json_extract(d.value, '$.amount') as total_amount")
			.addField("json_extract(d.value, '$.amountPt') as total_amount_p")
			.addField("json_extract(d.value, '$.amountSt') as total_amount_s")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name")
			.leftJoin("apply_clients on sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name as client_name,apply_clients.kana as client_kana")
			.andWhere("id_filter(sales_slips.id)=1")
			.apply();
		for(let item of table){
			item.detail = JSON.parse(item.detail);
			let taxRate = 0.1;
			let cols = new Array(37);
			cols[0] = item.accounting_date.split("-").join("/");
			cols[1] = item.slip_number;
			cols[2] = item.billing_destination;
			cols[3] = item.client_name;
			cols[4] = item.total_amount;
			cols[5] = item.total_amount_s;
			cols[6] = item.total_amount + item.total_amount_s;
			cols[7] = item.payment_date.split("-").join("/");
			cols[8] = item.accounting_date.split("-").join("/");
			cols[9] = item.item_name;
			cols[10] = item.quantity;
			cols[11] = item.unit_price;
			cols[12] = item.amount;
			cols[13] = item.note;
			cols[14] = "";
			cols[15] = "";
			cols[16] = "";
			cols[17] = "";
			cols[18] = "";
			cols[19] = item.client_kana;
			cols[20] = today;
			cols[21] = item.total_amount + item.total_amount_s;
			cols[22] = item.subject;
			cols[23] = item.unit;
			cols[24] = item.header1;
			cols[25] = item.header2;
			cols[26] = item.header3;
			cols[27] = item.data1;
			cols[28] = item.data2;
			cols[29] = item.data3;
			cols[30] = item.total_amount_p;
			cols[31] = item.total_amount + item.total_amount_p;
			cols[32] = (typeof item.amount === "number") ? item.amount * taxRate : "";
			cols[33] = (typeof item.amount === "number") ? (item.amount + item.amount * taxRate) : "";
			cols[34] = item.manager_name;
			cols[35] = item.circulation;
			cols[36] = item.unit_price;
			
			csvData.push(new Uint8Array(Encoding.convert(Encoding.stringToCode(cols.map(v => {
				if(v == null){
					return "";
				}else if(typeof v === "string" && v.match(/[,"\r\n]/)){
					return `"${v.split('"').join('""')}"`;
				}
				return `${v}`;
			}).join(",") + "\r\n"), {to: "SJIS", from: "UNICODE"})));
		}
		
		let blob = new Blob(csvData, {type: "text/csv"});
		let a = document.createElement("a");
		a.setAttribute("href", URL.createObjectURL(blob));
		a.setAttribute("download", "output.csv");
		a.click();
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form id="search"></form>
<form action="{url}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">再出力</button>
	{function name="ListItem"}{template_class name="ListItem" assign="obj" iterators=["i"]}{strip}
	<div class="mb-3">
		<label>
			<input type="checkbox" name="id[]" value="{$obj.id}" />{$obj.slip_number}|{$obj.subject}|{$obj.division_name}|{$obj.team_name}|{$obj.manager_name}
			<table>
				<tbody>{$obj->beginRepeat($obj.detail.length, "i")}
					<tr>
						<td>{$obj.detail.categoryCode[$i]}</td>
						<td>{$obj.detail.itemName[$i]}</td>
						<td>{$obj.detail.unit[$i]}</td>
						<td>{$obj.detail.quantity[$i]}</td>
						<td>{$obj.detail.unitPrice[$i]}</td>
						<td>{$obj.detail.amount[$i]}</td>
						<td>{$obj.detail.data1[$i]}</td>
						<td>{$obj.detail.data2[$i]}</td>
						<td>{$obj.detail.data3[$i]}</td>
						<td>{$obj.detail.circulation[$i]}</td>
					</tr>
				{$obj->endRepeat()}</tbody>
			</table>
		</label>
	</div>
	{/strip}{/template_class}{/function}
</form>
{/block}