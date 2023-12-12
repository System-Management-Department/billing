{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
{block name="css"}{/block}
<style type="text/css">{literal}
main{
	background: gray;
	display: flex;
	flex-wrap: wrap;
	justify-content: center;
	padding: 1rem;
	gap: 1rem;
}
print-page{
	background: white;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/PrintPage.js"></script>
{jsiife id=$id}{literal}
let master = new SQLite();
let transaction = new SQLite();
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	transaction.use("transaction").then(transaction => fetch(`/Committed/detail/${id}`)).then(res => res.arrayBuffer()),
	new Promise((resolve, reject) => {
		addEventListener("load", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	transaction.import(response[1], "transaction");
	transaction.attach(master, "master");
	transaction.create_function("number_format", {
		apply(thisObj, args){
			const [value, place] = args;
			if(value == null){
				return null;
			}
			return this.nf.format(value).replace(/(?:\..*)?$/, match => Number(`0${match}`).toFixed(place).substring(1));
		},
		nf: new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 3}),
		length: 2
	});
		
	const query1 = transaction.select("ROW")
		.addTable("sales_slips")
		.leftJoin("sales_attributes USING(ss)")
		.leftJoin("sales_workflow USING(ss)")
		.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.apply_client=apply_clients.code")
		.leftJoin("master.leaders AS leaders ON sales_slips.leader=leaders.code")
		.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code");
	const query2 = transaction.select("ALL")
		.addWith("relations AS (SELECT DISTINCT ss,sd FROM purchase_relations)")
		.addTable("sales_slips")
		.leftJoin("relations USING(ss)")
		.leftJoin("sales_details USING(sd)")
		.leftJoin("sales_workflow USING(ss)")
		.leftJoin("sales_detail_attributes USING(sd)");
	const query3 = master.select("ROW")
		.addTable("system_apply_clients")
		.addField("*")
		.addField("(IFNULL(location_address1, '') || IFNULL(location_address2, '') || IFNULL(location_address3, '')) AS address");
	const numberFormat = new Intl.NumberFormat();
	const format = {
		price: value => numberFormat.format(value)
	};
	const setText = (element, value) => {
		if(value == null){
		}else if(element.hasAttribute("data-format")){
			const key = element.getAttribute("data-format");
			if(key in format){
				element.textContent = format[key](value);
			}else{
				element.textContent = value;
			}
		}else{
			element.textContent = value;
		}
	};
	
	const fields = [
		{header: "対象日付",             t: 1, query: "STRFTIME('%Y/%m/%d', sales_workflow.approval_datetime)"},
		{header: "帳票No",               t: 1, query: "sales_slips.slip_number"},
		{header: "顧客コード",           t: 1, query: "apply_clients.apply_client"},
		{header: "顧客名",               t: 1, query: "apply_clients.name"},
		{header: "税抜金額",             t: 1, query: "sales_slips.amount_exc"},
		{header: "消費税",               t: 1, query: "sales_slips.amount_tax"},
		{header: "合計金額",             t: 1, query: "sales_slips.amount_inc"},
		{header: "支払期限",             t: 1, query: "STRFTIME('%Y/%m/%d', sales_slips.payment_date)"},
		{header: "明細日付",             t: 2, query: "STRFTIME('%Y/%m/%d', sales_workflow.approval_datetime)"},
		{header: "摘要",                 t: 2, query: "sales_details.detail"},
		{header: "数量",                 t: 2, query: "sales_details.quantity"},
		{header: "明細単価",             t: 2, query: "sales_details.unit_price"},
		{header: "明細金額",             t: 2, query: "sales_details.amount_exc"},
		{header: "備考(見出し)",         t: 1, query: "sales_slips.note"},
		{header: "税抜金額(8%)",         t: 1, query: "json_extract(sales_attributes.data, '$.tax_rate.\"0.08\".amount_exc')"},
		{header: "税抜金額(10%)",        t: 1, query: "json_extract(sales_attributes.data, '$.tax_rate.\"0.1\".amount_exc')"},
		{header: "消費税(8%)",           t: 1, query: "json_extract(sales_attributes.data, '$.tax_rate.\"0.08\".amount_tax')"},
		{header: "消費税(10%)",          t: 1, query: "json_extract(sales_attributes.data, '$.tax_rate.\"0.1\".amount_tax')"},
		{header: "税率",                 t: 2, query: "(sales_details.tax_rate * 100)"},
		{header: "顧客名カナ",           t: 1, query: "apply_clients.kana"},
		{header: "請求日",               t: 1, query: "STRFTIME('%Y/%m/%d', IFNULL(sales_slips.billing_date, CURRENT_DATE))"},
		{header: "請求金額",             t: 1, query: "sales_slips.amount_inc"},
		{header: "件名",                 t: 1, query: "sales_slips.subject"},
		{header: "単位",                 t: 2, query: "sales_details.unit"},
		{header: "摘要ヘッダー1",        t: 1, query: "json_extract(sales_attributes.data, '$.summary_header[0]')"},
		{header: "摘要ヘッダー2",        t: 1, query: "json_extract(sales_attributes.data, '$.summary_header[1]')"},
		{header: "摘要ヘッダー3",        t: 1, query: "json_extract(sales_attributes.data, '$.summary_header[2]')"},
		{header: "摘要ヘッダー1値",      t: 2, query: "json_extract(sales_detail_attributes.data, '$.summary_data[0]')"},
		{header: "摘要ヘッダー2値",      t: 2, query: "json_extract(sales_detail_attributes.data, '$.summary_data[1]')"},
		{header: "摘要ヘッダー3値",      t: 2, query: "json_extract(sales_detail_attributes.data, '$.summary_data[2]')"},
		{header: "消費税(明細別合計)",   t: 1, query: "sales_slips.amount_tax"},
		{header: "税込金額(明細別合計)", t: 1, query: "sales_slips.amount_inc"},
		{header: "消費税(明細別)",       t: 2, query: "sales_details.amount_tax"},
		{header: "税込金額(明細別)",     t: 2, query: "sales_details.amount_inc"},
		{header: "担当者氏名",           t: 1, query: "(leaders.name || '・' || managers.name)"},
		{header: "発行部数",             t: 2, query: "json_extract(sales_detail_attributes.data, '$.circulation')"},
		{header: "明細単価(文字列)",     t: 2, query: "number_format(sales_details.unit_price,sales_details.price_place)"},
		{header: "売上日",               t: 1, query: "STRFTIME('%Y/%m/%d', CURRENT_DATE)"},
		{header: "明細数量(文字列)",     t: 2, query: "number_format(sales_details.quantity,sales_details.quantity_place)"}
	];
	const fieldMap = {[1]: {}, [2]: {}, [3]: {
		["郵便番号"]: "location_zip",
		["住所1"]: "address",
		["住所2"]: null,
		["顧客名"]: "name",
		["部署名"]: null,
		["担当者名"]: "transactee",
		["敬称"]: "transactee_honorific",
		["振込先金融機関"]: null,
		["振込先金融機関支店"]: null,
		["口座種別"]: null,
		["口座番号"]: null
	}};
	for(let i = 0; i < fields.length; i++){
		let ref = null;
		if(fields[i].t == 1){
			ref = query1;
		}else if(fields[i].t == 2){
			ref = query2;
		}
		ref.addField(`${fields[i].query} AS field${i}`);
		fieldMap[fields[i].t][fields[i].header] = `field${i}`;
	}
	const values = {
		[1]: query1.apply(),
		[2]: query2.apply()
	};
	values[3] = query3.andWhere("apply_client=?", values[1][fieldMap[1]["顧客コード"]]).apply();
	const iteratorMap = new Map();
	const iterators = Array.from(document.querySelectorAll('[data-iterator]'));
	for(let item of iterators){
		const range = document.createRange();
		range.selectNodeContents(item);
		iteratorMap.set(item, range.extractContents());
	}
	const ph = Array.from(document.querySelectorAll('[data-table][data-field]'));
	for(let text of ph){
		const table = text.getAttribute("data-table");
		if(table == "帳票（見出し）"){
			const key = fieldMap[1][text.getAttribute("data-field")];
			setText(text, values[1][key]);
		}else if(table == "顧客"){
			const key = fieldMap[3][text.getAttribute("data-field")];
			if(key != null){
				setText(text, values[3][key]);
			}
		}else if(table == "帳票（明細）"){
			const key = fieldMap[2][text.getAttribute("data-field")];
			setText(text, values[2].reduce((a, b) => a + b[key], 0));
		}
	}
	for(let item of iterators){
		const fragment = iteratorMap.get(item);
		if(item.getAttribute("data-iterator") == "帳票（明細）"){
			for(let row of values[2]){
				const tr = fragment.cloneNode(true);
				const it = Array.from(tr.querySelectorAll('[data-table][data-field]'));
				for(let text of it){
					if(text.getAttribute("data-table") == "帳票（明細）"){
						const key = fieldMap[2][text.getAttribute("data-field")];
						setText(text, row[key]);
					}
				}
				item.appendChild(tr);
			}
		}
	}
	
	const printPage = document.querySelector('print-page');
	printPage.pageBreak(
		printPage.querySelectorAll('[data-page-break]')[Symbol.iterator](),
		sibling => (sibling.nodeType == Node.ELEMENT_NODE) && sibling.hasAttribute("data-clone"),
		(current, next) => { current.insertAdjacentElement("afterend", next); }
	);
});
{/literal}{/jsiife}
{/block}

{block name="body"}
<main>
	<print-page size="A4" orientation="P">
		{block name="preview"}{/block}
	</print-page>
</main>
{/block}