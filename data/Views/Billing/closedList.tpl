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
		let formData = new FormData(form);
		
		fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: formData
		}).then(res => res.json()).then(json => {
			if(json.success){
				Storage.pushToast("請求締データ", json.messages);
				location.reload()
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
<form action="{url action="release"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">締解除</button>
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