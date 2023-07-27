{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/customElements.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<style type="text/css">
.table_sticky{
	border-color: var(--bs-border-color);
}
#error{
	color: #dc3545;
}
</style>
{/block}
{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/Flow.js"></script>
<script type="text/javascript" src="/assets/common/customElements.js"></script>
<script type="text/javascript">
{predefine name="listItem1" constructor="categories" assign="detail"}{predef_repeat loop=$detail.length index="i"}
	<tr>
		<td class="table-group-row-no align-middle"></td>
		<td><select name="category[]" class="form-select form-select-sm">
			<option value="">選択</option>
		{predef_repeat loop=$categories.length index="j"}
			<option value="{$categories[$j].code}">{$categories[$j].name}</option>
		{/predef_repeat}</select></td>
		<td>{$detail[$i][0]}</td>
		<td>{$detail[$i][1]}</td>
		<td>{$detail[$i][2]}</td>
		<td>{$detail[$i][3]}</td>
		<td>{$detail[$i][4]}</td>
		<td data-visible="v3">{$detail[$i][6]}</td>
		<td data-visible="v3">{$detail[$i][7]}</td>
		<td data-visible="v3">{$detail[$i][8]}</td>
		<td data-visible="v2">{$detail[$i][5]}</td>
	</tr>
{/predef_repeat}{/predefine}
{predefine name="listItem2" constructor="categories" assign="detail"}{predef_repeat loop=$detail.length index="i"}
	<tr>
		<td class="table-group-row-no align-middle"></td>
		<td>{$detail[$i][0]}</td>
		<td>{$detail[$i][1]}</td>
		<td>{$detail[$i][2]}</td>
		<td>{$detail[$i][3]}</td>
		<td>{$detail[$i][4]}</td>
		<td><input type="text" name="supplier[]" class="form-control form-control-sm" /></td>
		<td><input type="date" name="payment_date[]" class="form-control form-control-sm" /></td>
	</tr>
{/predef_repeat}{/predefine}
{predefine name="applyClientList" assign="obj"}
	<tr>
		<td>{$obj.code}</td>
		<td>{$obj.client_name}</td>
		<td>{$obj.name}</td>
		<td>{$obj.kana}</td>
		<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}">選択</button></td>
	</tr>
{/predefine}
{predef_flash}{literal}
Flow.DbLocked = true;
Flow.start({{/literal}
	masterDownloadURL: "{url controller="Default" action="master"}",{literal}
	template: null,
	data: null,
	dataPort: null,
	contentPort: null,
	*[Symbol.iterator](){
		{/literal}{master_download test="Object.keys(Flow.Master.tables).length < 1"}yield* this.masterUpdate();{/master_download}{literal}
		Flow.DbLocked = false;
		let categories = Flow.Master.select("ALL")
			.addTable("categories")
			.apply();
		this.template = new Template(categories);
		const channel = new MessageChannel();
		this.dataPort = channel.port1;
		channel.port1.addEventListener("message", this);
		channel.port1.start();
		const channel2 = new MessageChannel();
		this.contentPort = channel2.port1;
		channel2.port1.addEventListener("message", this);
		channel2.port1.start();
		opener.postMessage("port", "*", [channel.port2, channel2.port2]);
		
		
		// ダイアログ初期化
		const applyClientModal = new bootstrap.Modal(document.getElementById("applyClientModal"));
		const applyClientForm = document.querySelector('row-form[name="billing_destination"]');
		const applyClientSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("system_apply_clients")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				applyClientSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("system_apply_clients as apply_clients")
					.addField("apply_clients.*")
					.leftJoin("clients on apply_clients.client=clients.code")
					.addField("clients.name as client_name")
					.orWhere("apply_clients.name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.unique_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.short_name like ('%' || ? || '%')", keyword)
					.orWhere("apply_clients.code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#applyClientModal tbody').innerHTML = table.map(row => this.template.applyClientList(row)).join("");
			},
			showModal: () => { applyClientModal.show(); },
			resetValue: () => { applyClientForm.value = ""; }
		});
		applyClientSearch.syncAttribute(applyClientForm);
		applyClientForm.bind(applyClientSearch, applyClientSearch.valueProperty);
		document.querySelector('#applyClientModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				applyClientForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
		
		
		document.getElementById("res").addEventListener("submit", this);
	},
	*masterUpdate(){
		yield new Promise((resolve, reject) => {
			fetch(this.masterDownloadURL).then(response => response.arrayBuffer()).then(buffer => {
				Flow.Master.import(buffer, "master");
				Flow.Master.commit().then(res => {resolve(res);});
			});
		});
	},
	handleEvent(e){
		if(e.type == "message" && (e.currentTarget == this.dataPort)){
			const dateFormat = val => {
				const i = new Intl.DateTimeFormat("ja-JP", {dateStyle: "short"});
				try{
					const v = new Date(val);
					return i.format(v).replace(/\//g, "-");
				}catch(ex){
					return "";
				}
			};
			const data = JSON.parse(e.data);
			const res = document.getElementById("res");
			let reportMap = {};
			for(let row of data.values["見積"]){
				reportMap[row[0]] = row[1];
			}
			document.getElementById("project").value = data.sid;
			document.getElementById("date").value = dateFormat(reportMap["見積年月日"]);
			document.getElementById("subject").value = reportMap["件名"];
			document.getElementById("client").value = reportMap["クライアント名"];
			document.getElementById("note").value = reportMap["備考"];
			document.querySelector('#apply_client modal-select').keyword = reportMap["クライアント名"];
			document.getElementById("header1").textContent = reportMap["摘要ヘッダ１"];
			document.getElementById("header2").textContent = reportMap["摘要ヘッダ２"];
			document.getElementById("header3").textContent = reportMap["摘要ヘッダ３"];
			document.getElementById("list1").innerHTML = this.template.listItem1(data.values["明細"]);
			document.getElementById("list2").innerHTML = this.template.listItem2(data.values["仕入明細"]);
			const visible = document.querySelectorAll('[data-visible]');
			for(let i = visible.length - 1; i >= 0; i--){
				if(visible[i].getAttribute("data-visible").indexOf(`v${reportMap["見積書フォーマット"]}`) < 0){
					visible[i].style.display = "none";
				}
			}
			this.data = data;
			console.log(data);
		}else if(e.type == "message" && (e.currentTarget == this.contentPort)){
			const blob = new Blob([e.data], {type: "application/pdf"});
			const slot = Object.assign(document.createElement("a"), {textContent: "ダウンロード"});
			slot.setAttribute("href", URL.createObjectURL(blob));
			slot.setAttribute("slot", "content");
			slot.setAttribute("download", "見積書.pdf");
			slot.setAttribute("class", "btn btn-info");
			document.getElementById("pdf").appendChild(slot);
		}else if(e.type == "submit"){
			e.stopPropagation();
			e.preventDefault();
			const form = e.currentTarget;
			const formData = new FormData();
			let reportMap = {};
			for(let row of this.data.values["見積"]){
				reportMap[row[0]] = row[1];
			}
			let detail = {
				length: 0,
				itemName: [],
				quantity: [],
				unit: [],
				unitPrice: [],
				amount: [],
				circulation: [],
				data1: [],
				data2: [],
				data3: [],
				categoryCode: []
			};
			const categoryCode = document.querySelectorAll('#list1 [name="category[]"]');
			for(let row of this.data.values["明細"]){
				const i = detail.length;
				detail.length++;
				detail.itemName.push(row[0]);
				detail.quantity.push(row[1]);
				detail.unit.push(row[2]);
				detail.unitPrice.push(row[3]);
				detail.amount.push(row[4]);
				detail.circulation.push(row[5]);
				detail.data1.push(row[6]);
				detail.data2.push(row[7]);
				detail.data3.push(row[8]);
				detail.categoryCode.push(categoryCode[i].value);
			}
			const purchases = [];
			const paymentDate = document.querySelectorAll('#list2 [name="payment_date[]"]');
			const supplier = document.querySelectorAll('#list2 [name="supplier[]"]');
			for(let row of this.data.values["仕入明細"]){
				const i = purchases.length;
				purchases.push({
					subject: row[0],
					quantity: row[1],
					unit: row[2],
					unit_price: row[3],
					amount: row[4],
					payment_date: paymentDate[i].value,
					ingest: {
						supplier: supplier[i].value
					}
				});
			}
			formData.append("billing_destination", form.querySelector('[name="billing_destination"]').value);
			formData.append("delivery_destination", form.querySelector('[name="delivery_destination"]').value);
			formData.append("subject", form.querySelector('[name="subject"]').value);
			formData.append("note", form.querySelector('[name="note"]').value);
			formData.append("header1", reportMap["摘要ヘッダ１"]);
			formData.append("header2", reportMap["摘要ヘッダ２"]);
			formData.append("header3", reportMap["摘要ヘッダ３"]);
			formData.append("payment_date", form.querySelector('[name="payment_date"]').value);
			formData.append("invoice_format", reportMap["見積書フォーマット"]);
			formData.append("detail", JSON.stringify(detail));
			formData.append("purchases", JSON.stringify(purchases));
			formData.append("email", this.data.email);
			formData.append("password", this.data.password);
			formData.append("sid", this.data.sid);
			fetch(form.getAttribute("action"), {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(response => {
				if(response.success){
					// フォーム送信 成功
					
					close();
				}else{
					// フォーム送信 失敗
					
					// エラーメッセージをオブジェクトへ変更
					let messages = response.messages.reduce((a, message) => {
						if(message[1] == 2){
							a[message[2]] = message[0];
						}
						return a;
					}, {});
					
					// エラーメッセージの表示切替
					let inputs = form.querySelectorAll('[name],[data-form-name]');
					for(let input of inputs){
						let name = input.hasAttribute("name") ? input.getAttribute("name") : input.getAttribute("data-form-name");
						if(name in messages){
							if(input.tagName == "ROW-FORM"){
								input.setAttribute("invalid", messages[name]);
							}
							input.classList.add("is-invalid");
							let feedback = input.parentNode.querySelector('.invalid-feedback');
							if(feedback != null){
								feedback.textContent = messages[name];
							}
						}else{
							if(input.tagName == "ROW-FORM"){
								input.removeAttribute("invalid");
							}
							input.classList.remove("is-invalid");
						}
					}
					if("" in messages){
						document.getElementById("error").textContent = messages[""];
					}else{
						document.getElementById("error").textContent = "";
					}
				}
			});
		}
	}
});
{/literal}</script>
{/block}


{block name="body"}
<header class="sticky-top">
	<nav class="navbar p-0 bg-white border-bottom border-success border-2 shadow-sm">
		<div class="container-fluid gap-2">
			<div class="navbar-brand flex-grow-1">
				<span class="navbar-text text-dark fs-6">見積登録</span>
			</div>
		</div>
	</nav>
</header>
<form id="res" action="{url action="regist"}" class="py-4">
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>見積</div>
		<div class="row gap-4 align-items-start">
			<div class="d-table col table">
				<row-form label="見積番号" col="12" name="project" id="project"></row-form>
				<row-form label="見積年月日" col="5" name="date" type="date" id="date"></row-form>
				<row-form label="請求書件名" col="10" name="subject" type="text" id="subject" require></row-form>
				<row-form label="入金予定日" col="5" name="payment_date" type="date" require></row-form>
			</div>
			<div class="d-table col table">
				<row-form label="請求先" col="10" name="billing_destination" placeholder="請求先CD、会社名で検索" id="apply_client" require></row-form>
				<row-form label="納品先" col="10" name="delivery_destination" type="text" id="client" require></row-form>
				<row-form label="備考" col="10" name="note" type="textarea" id="note"></row-form>
				<row-form label="PDF" col="10" id="pdf"></row-form>
			</div>
		</div>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>明細</div>
		<table class="table table-md table_sticky">
			<thead>
				<tr>
					<th>No</th>
					<th>商品カテゴリー</th>
					<th>内容（摘要）</th>
					<th>数量</th>
					<th>単位</th>
					<th>単価</th>
					<th>金額</th>
					<th id="header1" data-visible="v3"></th>
					<th id="header2" data-visible="v3"></th>
					<th id="header3" data-visible="v3"></th>
					<th data-visible="v2">発行部数</th>
				</tr>
			</thead>
			<tbody id="list1"></tbody>
		</table>
	</div>
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div>仕入</div>
		<table class="table table-md table_sticky">
			<thead>
				<tr>
					<th>No</th>
					<th>内容</th>
					<th>数量</th>
					<th>単位</th>
					<th>単価</th>
					<th>金額</th>
					<th>仕入先</th>
					<th>支払日</th>
				</tr>
			</thead>
			<tbody id="list2"></tbody>
		</table>
	</div>
	<div class="d-flex p-0 mx-5 gap-5">
		<div id="error" class="flex-grow-1"></div>
		<button type="submit" class="btn btn-success">登録</button>
	</div>
</form>
{/block}

{block name="dialogs" append}
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center">請求先選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">
				<table class="table table_sticky_list">
					<thead>
						<tr>
							<th>コード</th>
							<th>得意先名</th>
							<th>請求先名</th>
							<th>カナ</th>
							<th></th>
						</tr>
					</thead>
					<tbody></tbody>
				</table>
			</div>
		</div>
	</div>
</div>
{/block}