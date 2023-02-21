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
var data = JSON.parse("{$table|escape:"javascript"}");{literal}
document.addEventListener("DOMContentLoaded", function(e){
	let form = document.getElementById("outputlist");
	let eelement = document.createElement("a");
	let HTMLEscape = v => (v == null) ? "" : Object.assign(eelement, {textContent: v}).innerHTML;
	for(let id in data){
		let item = data[id];
		item.detail[Symbol.iterator] = detailIterator;
		let template = {/literal}`{call name="item_template"}`{literal};
		form.insertAdjacentHTML("beforeend", template);
	}
	form.addEventListener("submit", e => {
		e.stopPropagation();
		e.preventDefault();
		let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(new Date());
		let inputs = form.querySelectorAll('[name="id[]"]:checked');
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
		let n = inputs.length;
		for(let i = 0; i < n; i++){
			let id = inputs[i].value;
			let item = data[id];
			let taxRate = 0.1;
			let cols = new Array(37);
			cols[0] = item.accounting_date.split("-").join("/");
			cols[1] = item.slip_number;
			cols[2] = item.billing_destination;
			cols[3] = "----"; /** TODO マスター作成後請求先名称 */
			cols[4] = 0;
			cols[7] = item.payment_date.split("-").join("/");
			cols[8] = item.accounting_date.split("-").join("/");
			cols[13] = item.note;
			cols[14] = "";
			cols[15] = "";
			cols[16] = "";
			cols[17] = "";
			cols[18] = "";
			cols[19] = "----"; /** TODO マスター作成後請求先カナ */
			cols[20] = today;
			cols[22] = item.subject;
			cols[24] = item.header1;
			cols[25] = item.header2;
			cols[26] = item.header3;
			cols[30] = 0;
			cols[34] = "----"; /** TODO マスター作成後担当者氏名 */
			for(let detail of item.detail){
				// 合計
				if(typeof detail.amount === "number"){
					cols[4] += detail.amount;
					cols[30] += detail.amount * taxRate;
				}
			}
			cols[5] = cols[4] * taxRate;
			cols[6] = cols[4] + cols[5];
			cols[21] = cols[6];
			cols[31] = cols[4] + cols[30];
			for(let detail of item.detail){
				cols[9] = detail.itemName;
				cols[10] = detail.quantity;
				cols[11] = detail.unitPrice;
				cols[12] = detail.amount;
				cols[23] = detail.unit;
				cols[27] = detail.data1;
				cols[28] = detail.data2;
				cols[29] = detail.data3;
				if(typeof detail.amount === "number"){
					cols[32] = detail.amount * taxRate;
					cols[33] = detail.amount + cols[32];
				}else{
					cols[32] = "";
					cols[33] = "";
				}
				cols[35] = detail.circulation;
				cols[36] = detail.unitPrice;
				csvData.push(new Uint8Array(Encoding.convert(Encoding.stringToCode(cols.map(v => {
					if(v == null){
						return "";
					}else if(typeof v === "string" && v.match(/[,"\r\n]/)){
						return `"${v.split('"').join('""')}"`;
					}
					return `${v}`;
				}).join(",") + "\r\n"), {to: "SJIS", from: "UNICODE"})));
			}
		}
		let blob = new Blob(csvData, {type: "text/csv"});
		let download = (messages) => {
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "output.csv");
			a.click();
			Storage.pushToast("請求締データ", messages);
			location.reload()
		};
		let formData = new FormData(form);
		
		fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: formData
		}).then(res => res.json()).then(json => {
			if(json.success){
				download(json.messages);
			}else{
			}
		});
	});
	
	function* detailIterator(){
		let keys = Object.keys(this).filter(k => k != "length");
		for(let i = 0; i < this.length; i++){
			yield keys.reduce((obj, k) => {
				obj[k] = this[k][i];
				return obj;
			}, {});
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form action="{url action="close"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">締め</button>
	{function name="item_template"
		id="$\x7bid\x7d"
		item=["slip_number" => "$\x7bitem.slip_number\x7d", "subject" => "$\x7bitem.subject\x7d"]
		ldetail="$\x7bArray.from(item.detail).map(detail => `"
		rdetail="`).join(\"\")\x7d"
		detail=[
			"categoryCode"=> "$\x7bHTMLEscape(detail.categoryCode)\x7d",
			"itemName"    => "$\x7bHTMLEscape(detail.itemName)\x7d",
			"unit"        => "$\x7bHTMLEscape(detail.unit)\x7d",
			"quantity"    => "$\x7bHTMLEscape(detail.quantity)\x7d",
			"unitPrice"   => "$\x7bHTMLEscape(detail.unitPrice)\x7d",
			"amount"      => "$\x7bHTMLEscape(detail.amount)\x7d",
			"data1"       => "$\x7bHTMLEscape(detail.data1)\x7d",
			"data2"       => "$\x7bHTMLEscape(detail.data2)\x7d",
			"data3"       => "$\x7bHTMLEscape(detail.data3)\x7d",
			"circulation" => "$\x7bHTMLEscape(detail.circulation)\x7d"
		]
	}
	<div class="mb-3">
		<label>
		<input type="checkbox" name="id[]" value="{$id}" />{$item.slip_number}|{$item.subject}
		<table>
		{$ldetail}<tr>
			<td>{$detail.categoryCode}</td>
			<td>{$detail.itemName}</td>
			<td>{$detail.unit}</td>
			<td>{$detail.quantity}</td>
			<td>{$detail.unitPrice}</td>
			<td>{$detail.amount}</td>
			<td>{$detail.data1}</td>
			<td>{$detail.data2}</td>
			<td>{$detail.data3}</td>
			<td>{$detail.circulation}</td>
		</tr>{$rdetail}
		</table>
		</label>
	</div>
	{/function}
</form>
{/block}