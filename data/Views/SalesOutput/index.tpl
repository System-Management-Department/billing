{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>売上伝票出力</div>
	</h2>
</nav>
{/block}

{block name="scripts" append}
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
		let inputs = form.querySelectorAll('[name="id[]"]:checked');
		let n = inputs.length;
		let attrEntries1 = [
			["slip_number", "伝票番号"],
			["accounting_date", "売上日付"],
			["division", "部門"],
			["team", "チーム"],
			["manager", "当社担当者"],
			["billing_destination", "請求先"],
			["delivery_destination", "納品先"],
			["subject", "件名"],
			["note", "備考"],
			["payment_date", "支払期日"]
		];
		let attrEntries2 = [
			["categoryCode", "カテゴリーコード"],
			["itemName", "商品名"],
			["unit", "単位"],
			["quantity", "数量"],
			["unitPrice", "単価"],
			["amount", "金額"],
			["circulation", "発行部数"]
		];
		let xParser = new DOMParser();
		let xSerializer = new XMLSerializer();
		let xDoc = xParser.parseFromString('<?xml version="1.0" encoding="UTF-8"?>\n<売上 xmlns:摘要="/data"/>', "application/xml");
		let xRoot = xDoc.documentElement;
		for(let i = 0; i < n; i++){
			let id = inputs[i].value;
			let item = data[id];
			let xElement1 = xDoc.createElement("伝票");
			for(let [k, attr] of attrEntries1){
				xElement1.setAttribute(attr, item[k]);
			}
			for(let detail of item.detail){
				let xElement2 = xDoc.createElement("明細");
				for(let [k, attr] of attrEntries2){
					xElement2.setAttribute(attr, detail[k]);
				}
				if(item["header1"] != null){
					xElement2.setAttribute("摘要:" + item["header1"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data1"]);
				}
				if(item["header2"] != null){
					xElement2.setAttribute("摘要:" + item["header2"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data2"]);
				}
				if(item["header3"] != null){
					xElement2.setAttribute("摘要:" + item["header3"].replace(/[\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]+/g, "-").replace(/^(?=[0-9\.\-])/, "_"), detail["data3"]);
				}
				xElement1.appendChild(xElement2);
			}
			xRoot.appendChild(xElement1);
		}
		let blob = new Blob([xSerializer.serializeToString(xDoc)], {type: "application/xml"});
		let download = (messages) => {
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "output.xml");
			a.click();
			Storage.pushToast("売上伝票出力", messages);
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
<form action="{url action="output"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">出力</button>
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