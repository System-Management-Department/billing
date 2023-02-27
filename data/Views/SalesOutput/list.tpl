{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4 justify-content-start gap-5">
		<div>売上伝票出力</div>
	</h2>
</nav>
{/block}

{block name="scripts" append}
<script type="text/javascript">
{call name="ListItem"}{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",
	location: "{url}",{literal}
	form: null,
	y: null,
	attrEntries1: [
		["slip_number", "伝票番号"],
		["accounting_date", "売上日付"],
		["division", "部門コード"],
		["division_name", "部門名"],
		["team", "チームコード"],
		["team_name", "チーム名"],
		["manager", "当社担当者コード"],
		["manager_name", "当社担当者名"],
		["manager_kana", "当社担当者カナ"],
		["billing_destination", "請求先"],
		["delivery_destination", "納品先"],
		["subject", "件名"],
		["note", "備考"],
		["payment_date", "支払期日"]
	],
	attrEntries2: [
		["categoryCode", "カテゴリーコード"],
		["itemName", "商品名"],
		["unit", "単位"],
		["quantity", "数量"],
		["unitPrice", "単価"],
		["amount", "金額"],
		["circulation", "発行部数"]
	],
	*[Symbol.iterator](){
		yield* this.init();
		const db = new SQLite();
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(this.form)
		}).then(response => response.arrayBuffer());
		db.import(buffer, "list");
		const form = document.getElementById("outputlist");
		const template = new ListItem();
		
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
		for(let row of table){
			row.detail = JSON.parse(row.detail);
			template.insertBeforeEnd(form, row);
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
		let xParser = new DOMParser();
		let xSerializer = new XMLSerializer();
		let xDoc = xParser.parseFromString('<?xml version="1.0" encoding="UTF-8"?>\n<売上 xmlns:摘要="/data"/>', "application/xml");
		let xRoot = xDoc.documentElement;
		
		let table = db.select("ALL")
			.addTable("sales_slips")
			.addField("sales_slips.*")
			.leftJoin("divisions on sales_slips.division=divisions.code")
			.addField("divisions.name as division_name")
			.leftJoin("teams on sales_slips.team=teams.code")
			.addField("teams.name as team_name")
			.leftJoin("managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name,managers.kana as manager_kana")
			.andWhere("id_filter(sales_slips.id)=1")
			.apply();
		for(let item of table){
			let xElement1 = xDoc.createElement("伝票");
			for(let [k, attr] of this.attrEntries1){
				xElement1.setAttribute(attr, item[k]);
			}
			let detail = JSON.parse(item.detail);
			for(let i = 0; i < detail.length; i++){
				let xElement2 = xDoc.createElement("明細");
				for(let [k, attr] of this.attrEntries2){
					xElement2.setAttribute(attr, detail[k][i]);
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
		
		let json = yield fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: new FormData(form)
		}).then(res => res.json());
		if(json.success){
			let blob = new Blob([xSerializer.serializeToString(xDoc)], {type: "application/xml"});
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "output.xml");
			a.click();
			
			for(let message of json.messages){
				Flow.DB.insertSet("messages", {title: "売上伝票出力", message: message[0], type: message[1], name: message[2]}, {}).apply();
			}
			yield Flow.DB.commit();
			location.reload();
		}else{
		};
	}
});
{/literal}</script>
{/block}

{block name="body"}
<form id="search"></form>
<form action="{url action="output"}" method="post" id="outputlist">
	<button type="submit" class="btn btn-success">出力</button>
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