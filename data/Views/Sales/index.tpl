{block name="title"}売上一覧画面{/block}
{block name="tools"}<a class="btn btn-success my-2" href="{url controller="Home" action="index"}">メインメニュー</a>{/block}
{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
<style type="text/css">
.modal-form{
	--bs-modal-width: calc(100% - var(--bs-modal-margin) * 2);
}
body [data-visible]{
	display: none;
}
body:has(input[name="invoice_format"][value="2"]) [data-visible="v2"],
body:has(input[name="invoice_format"][value="3"]) [data-visible="v3"]{
	display: table-cell;
}


.card:has(#search-header :checked) .card-body,.card:has(#search-header :checked) .card-footer{
	display: none;
}
#detailModal .modal-header select{
	appearance: none;
	border: none;
	padding: 0;
	margin: 0;
	font: inherit;
}
#detailModal:has(.modal-header select [value="1"]:checked) [data-detail-modal="1"],
#detailModal:has(.modal-header select [value="2"]:checked) [data-detail-modal="2"],
#detailModal:has(.modal-header select [value="1"]:checked) [data-detail-modal="3"],
#detailModal:has(.modal-header select [value="2"]:checked) [data-detail-modal="3"]{
	display: none;
}

[data-colosed="1"]{
	--bs-table-bg: #cceced;
}
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
<script type="text/javascript" src="/assets/common/CSVSerializer.js"></script>
<script type="text/javascript">{literal}
class SalesClose{{/literal}
	static account = "{$basicInfo.rakurakumeisai_account.value}";
	static apitoken = "{$basicInfo.rakurakumeisai_apitoken.value}";{literal}
	static csvHeader = [
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
		"明細単価",
		"売上日"
	];
	static csvHeader2 = [
		"売上日付",
		"帳票No",
		"顧客コード",
		"顧客名",
		"税抜金額",
		"消費税",
		"合計金額",
		"支払期限",
		"備考",
		"件名"
	];
	constructor(db){
		this.response = db;
		this.isChecked = {
			length: 1,
			apply: function(dummy, args){
				let id = args[0].toString();
				return this.values.includes(id) ? 1 : 0;
			},
			values: null,
			reset: function(checked){
				this.values = [];
				let n = checked.length;
				for(let i = 0; i < n; i++){
					this.values.push(checked[i].value);
				}
			}
		};
		this.response.create_function("is_checked", this.isChecked);
		this.response.create_function("detail_each", {
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
	}
	getQuery(){
		return this.response.select("ALL")
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
			.leftJoin("master.managers as managers on sales_slips.manager=managers.code")
			.addField("managers.name as manager_name")
			.leftJoin("master.system_apply_clients as apply_clients on sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name as client_name,apply_clients.kana as client_kana,apply_clients.close_date as client_close");
	}
	getSerializer(){
		return new CSVSerializer((val, col) => {
			if(col == 2){
				return (typeof val === 'string') ? val.replace(/-.*$/, "") : val;
			}
			if(
				(col == 4) || (col == 5) || (col == 6) ||
				(col == 12) || (col == 21) || (col == 30) ||
				(col == 31) || (col == 32) || (col == 33)){
				return (typeof val === "number") ? Math.floor(val) : "";
			}
			if((col == 7) || (col == 8)){
				return (typeof val === "string") ? val.split("-").join("/") : val;
			}
			if(col == 37){
				if(Array.isArray(val)){
					let date = new Date(val[0]);
					if(val[1] == 99){
						date.setMonth(date.getMonth() + 1);
						date.setDate(-1);
					}else{
						date.setDate(val[1]);
					}
					return Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(date);
				}
			}
			return val;
		}).setHeader(SalesClose.csvHeader)
		.setFilter(data => data[6] > 0)
		.setConverter(data => new Blob([new Uint8Array(Encoding.convert(Encoding.stringToCode(data), {to: "SJIS", from: "UNICODE"}))], {type: "text/csv"}));
	}
	getSerializer2(){
		return new CSVSerializer((val, col) => {
			if(col == 2){
				return (typeof val === 'string') ? val.replace(/-.*$/, "") : val;
			}
			if(
				(col == 4) || (col == 5) || (col == 6)){
				const formater = new Intl.NumberFormat();
				return (typeof val === "number") ? formater.format(Math.floor(val)) : "";
			}
			if(col == 7){
				return (typeof val === "string") ? val.split("-").join("/") : val;
			}
			return val;
		}).setHeader(SalesClose.csvHeader2)
		.setConverter(data => new Blob([new Uint8Array(Encoding.convert(Encoding.stringToCode(data), {to: "SJIS", from: "UNICODE"}))], {type: "text/csv"}));
	}
	*export(){
		let reportTypes = this.response.select("COL")
			.addTable("sales_slips")
			.setField("distinct invoice_format")
			.andWhere("is_checked(id)=1")
			.andWhere("invoice_format is not null")
			.apply();
		let vSerializer = this.getSerializer();
		let now = new Date();
		let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(now);
		let csvData = {};
		for(let type of reportTypes){
			csvData[type] = [[], []];
		}
		
		let table = this.getQuery().andWhere("is_checked(sales_slips.id)=1").apply();
		for(let item of table){
			if(!(item.invoice_format in csvData)){
				continue;
			}
			item.detail = JSON.parse(item.detail);
			let taxRate = 0.1;
			csvData[item.invoice_format][item.closed_count == 0 ? 1 : 0].push([
				item.accounting_date.split("-").join("/"),
				item.slip_number,
				item.billing_destination,
				item.client_name,
				item.total_amount,
				item.total_amount_s,
				item.total_amount + item.total_amount_s,
				item.payment_date,
				item.accounting_date,
				item.item_name,
				item.quantity,
				item.unit_price,
				item.amount,
				item.note,
				"",
				"",
				"",
				"",
				"",
				item.client_kana,
				today,
				item.total_amount + item.total_amount_s,
				item.subject,
				item.unit,
				item.header1,
				item.header2,
				item.header3,
				item.data1,
				item.data2,
				item.data3,
				item.total_amount_p,
				item.total_amount + item.total_amount_p,
				(typeof item.amount === "number") ? item.amount * taxRate : "",
				(typeof item.amount === "number") ? (item.amount + item.amount * taxRate) : "",
				item.manager_name,
				item.circulation,
				item.unit_price,
				(item.client_close == null) ? today : [now, item.client_close]
			]);
		}
		
		let apiPL = [];
		let apiHeader = new Headers();
		apiHeader.set("X-WB-apitoken", SalesClose.apitoken);
		for(let type of reportTypes){
			for(let isNewIssues = 0; isNewIssues <= 1; isNewIssues++){
				if(csvData[type][isNewIssues].length < 1){
					continue;
				}
				let blob = vSerializer.serializeToString(csvData[type][isNewIssues]);
				let apiBody = new FormData();
				apiBody.append("json", JSON.stringify({
					reportTypeId: type,
					isNewIssues: isNewIssues,
					importProcessName: `取込`,
					skipFirst: 1,
					isImmApproval: 0
				}));
				apiBody.append("files[0]", blob, "data.csv");
				apiPL.push(fetch(`https://${SalesClose.account}/api/v1/reports/imports`, {
					method: "POST",
					mode: 'cors',
					headers: apiHeader,
					body: apiBody
				}).then(res => {
					return res.json();
				}));
			}
		}
		let apiRes = yield Promise.all(apiPL);
		if(apiRes.length > 0 && apiRes[0].code == "200"){
			let formData = new FormData();
			this.isChecked.values.forEach(v => { formData.append("id[]", v); });
			let response = yield fetch(document.getElementById("close").getAttribute("data-close"), {
				method: "POST",
				body: formData
			}).then(res => res.json());
			if(response.success){
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "請求締データ", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				yield Flow.DB.commit();
				location.reload();
			}else{
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "請求締データ", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				let messages = Flow.DB
					.select("ALL")
					.addTable("messages")
					.leftJoin("toast_classes using(type)")
					.apply();
				if(messages.length > 0){
					Toaster.show(messages);
					Flow.DB.delete("messages").apply();
				}
			}
		}
	}
}

Flow.start({{/literal}
	dbDownloadURL: "{url action="search"}",{literal}
	strage: null,
	response: new SQLite(),
	detail: null,
	detailModal: null,
	template: null,
	close: null,
	*[Symbol.iterator](){
		const form = document.querySelector('form');
		yield* this.init(form);
		yield* this.search(form);
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		
		let categories = Flow.Master.select("OBJECT")
			.setTable("categories")
			.setField("code,name")
			.apply();
		this.template = new Template({
			equals(a, b){
				return (a == b) ? 1 : 0;
			},
			getName(object){
				if(object == null){
					return "";
				}else{
					return ("name" in object) ? object.name : "";
				}
			},
			date(datetime){
				return datetime.split(" ")[0];
			},
			numberFormat(value){
				if(typeof value === "number"){
					return new Intl.NumberFormat().format(Math.round(value));
				}
				return value;
			},
			numberFormat2(value){
				if(typeof value === "number"){
					return new Intl.NumberFormat().format(Math.round(value)) + value.toFixed(2).slice(-3);
				}
				return value;
			}
		}, categories);
		
		// datalist初期化
		let datalist = document.getElementById("division");
		let mastarData = Flow.Master.select("ALL")
			.addTable("divisions")
			.addField("code,name")
			.apply();
		for(let division of mastarData){
			let option = Object.assign(document.createElement("option"), {textContent: division.name});
			option.setAttribute("value", division.code);
			datalist.appendChild(option);
		}
		
		// ダイアログ初期化
		const managerModal = new bootstrap.Modal(document.getElementById("managerModal"));
		const managerForm = document.querySelector('row-form[name="manager"]');
		const managerSearch = Object.assign(document.createElement("modal-select"), {
			getTitle: code => {
				const value = Flow.Master.select("ONE")
					.addTable("managers")
					.addField("name")
					.andWhere("code=?", code)
					.apply();
				managerSearch.showTitle(value); 
			},
			searchKeyword: keyword => {
				const table = Flow.Master.select("ALL")
					.setTable("managers")
					.orWhere("name like ('%' || ? || '%')", keyword)
					.orWhere("code like ('%' || ? || '%')", keyword)
					.apply();
				document.querySelector('#managerModal tbody').innerHTML = table.map(row => this.template.managerList(row)).join("");
			},
			showModal: () => { managerModal.show(); },
			resetValue: () => { managerForm.value = ""; }
		});
		managerSearch.syncAttribute(managerForm);
		managerForm.bind(managerSearch, managerSearch.valueProperty);
		document.querySelector('#managerModal tbody').addEventListener("click", e => {
			if(e.target.hasAttribute("data-search-modal-value")){
				managerForm.value = e.target.getAttribute("data-search-modal-value");
			}
		}, {capture: true});
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
		
		// 検索履歴
		let history = this.strage.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", form.getAttribute("action"))
			.setOrderBy("time DESC")
			.apply();
		if(history != null){
			let {data, label} = JSON.parse(history.json);
			const searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
				}
			}
			const rowForms = document.querySelectorAll('row-form[name]');
			for(let i = rowForms.length - 1; i >= 0; i--){
				let name = rowForms[i].getAttribute("name");
				if((name in data) && (data[name].length > 0)){
					rowForms[i].value = data[name].shift();
				}
			}
			
			this.y = JSON.parse(history.scroll_y);
			addEventListener("beforeunload", e => {
				let sy = {};
				const scrollY = document.querySelectorAll('[data-scroll-y]');
				for(let i = scrollY.length - 1; i >= 0; i--){
					let ele = scrollY[i];
					sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
				}
				this.strage.updateSet("search_histories", {
					scroll_y: JSON.stringify(sy)
				}, {})
					.andWhere("location=?", history.location)
					.andWhere("time=?", history.time)
					.apply();
				this.strage.commit();
			});
		}
		
		// イベントを設定
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let formData = new FormData(form);
			let obj = {data:{}, label:{}};
			for(let k of formData.keys()){
				if(k in obj.data){
					continue;
				}
				obj.data[k] = formData.getAll(k);
			}
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				obj.label[key] = searchLabels[i].innerHTML;
			}
			let sy = {};
			const scrollY = document.querySelectorAll('[data-scroll-y]');
			for(let i = scrollY.length - 1; i >= 0; i--){
				let ele = scrollY[i];
				sy[ele.getAttribute("data-scroll-y")] = ele.scrollTop;
			}
			this.strage.insertSet("search_histories", {
				location: form.getAttribute("action"),
				json: JSON.stringify(obj),
				time: Date.now(),
				scroll_y: JSON.stringify(sy)
			}, {}).apply();
			this.strage.commit().then(e => {
				location.href = form.getAttribute("action");
				location.reload();
			});
		});
		form.addEventListener("reset", e => {
			const rowForms = document.querySelectorAll('row-form');
			for(let i = rowForms.length - 1; i >= 0; i--){
				rowForms[i].reset();
			}
		});
		
		this.detailModal = new bootstrap.Modal(document.getElementById("detailModal"));
		document.getElementById("closeDetailModal").addEventListener("click", e => { this.detailModal.hide(); });
		document.getElementById("approval").addEventListener("click", this);
		document.getElementById("close").addEventListener("click", this);
		document.getElementById("output").addEventListener("click", this);
		
		// フォームを有効化
		form.querySelector('fieldset').disabled = false;
	},
	*search(form){
		const buffer = yield fetch(this.dbDownloadURL, {
			method: "POST",
			body: new FormData(form)
		}).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		this.response.attach(Flow.Master, "master");
		this.close = new SalesClose(this.response);
		let table = this.listItemQuery("ALL").apply();
		const tbody = document.getElementById("list");
		tbody.innerHTML = table.map(row => this.template.listItem(row)).join("");
		let trElements = tbody.querySelectorAll('[data-range][data-colosed]');
		for(let i = trElements.length - 1; i >= 0; i--){
			trElements[i].addEventListener("click", this, {capture: true});
			const colsed = trElements[i].getAttribute("data-colosed");
			if(colsed == "1"){
				const checkbox = trElements[i].querySelector('input[type="checkbox"]');
				checkbox.parentNode.removeChild(checkbox);
				const disapproval = trElements[i].querySelector('[data-detail="3"]');
				disapproval.parentNode.removeChild(disapproval);
			}
		}
	},
	listItemQuery(mode){
		return this.response.select(mode)
			.setTable("sales_slips")
			.addField("sales_slips.*")
			.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
			.addField("managers.name AS manager_name")
			.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
			.addField("apply_clients.name AS apply_client_name");
	},
	handleEvent(e){
		if(e.currentTarget.hasAttribute("data-range")){
			const id = Number(e.currentTarget.getAttribute("data-range"));
			if(e.target.hasAttribute("data-detail")){
				this.detail = id;
				let data = this.response.select("ROW")
					.addTable("sales_slips")
					.addField("sales_slips.*")
					.andWhere("sales_slips.id=?", id)
					.leftJoin("master.managers AS managers ON sales_slips.manager=managers.code")
					.addField("managers.name AS manager_name")
					.leftJoin("master.system_apply_clients AS apply_clients ON sales_slips.billing_destination=apply_clients.code")
					.addField("apply_clients.name AS apply_client_name")
					.apply();
				let values = JSON.parse(data.detail);
				let keys = Object.keys(values).filter(k => Array.isArray(values[k]));
				let detail = [];
				let detail2 = this.response.select("ALL")
					.addTable("purchases")
					.andWhere("spreadsheet=?", data.spreadsheet)
					.apply();
				for(let i = 0; i < values.length; i++){
					let obj = {};
					for(let k of keys){
						let key = k.replace(/[A-Z]/g, function(ch){
							return `_${ch.toLowerCase()}`;
						});
						obj[key] = values[k][i];
					}
					detail.push(obj);
				}
				document.querySelector('#detailModal .modal-header select').value = e.target.getAttribute("data-detail");
				document.querySelector('#detailModal .modal-body').innerHTML = this.template.detailView(data, detail, detail2);
				this.detailModal.show();
			}
		}else if(e.currentTarget == document.getElementById("approval")){
			const url = document.querySelector('#detailModal [data-approval]').getAttribute("data-approval");
			const formData = new FormData();
			fetch(url, {
				method: "POST",
				body: formData
			}).then(res => res.json()).then(response => {
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "売上登録", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				Flow.DB.commit().then(e => { location.reload(); });
			});
			this.detailModal.hide();
		}else if(e.currentTarget == document.getElementById("close")){
			this.close.isChecked.reset(document.querySelectorAll('#list input[type="checkbox"]'));
			co(this.close.export());
		}else if(e.currentTarget == document.getElementById("output")){
			let vSerializer = this.close.getSerializer2();
			let now = new Date();
			let today = Intl.DateTimeFormat("ja-JP", {dateStyle: 'short'}).format(now);
			let csvData = [];
			let table = this.response.select("ALL")
				.addTable("sales_slips")
				.addTable("json_each(detail_each(sales_slips.detail)) as d")
				.addField("distinct sales_slips.*")
				.addField("json_extract(d.value, '$.amount') as total_amount")
				.addField("json_extract(d.value, '$.amountPt') as total_amount_p")
				.addField("json_extract(d.value, '$.amountSt') as total_amount_s")
				.leftJoin("master.system_apply_clients as apply_clients on sales_slips.billing_destination=apply_clients.code")
				.addField("apply_clients.name as client_name").apply();
			for(let item of table){
				let taxRate = 0.1;
				csvData.push([
					item.accounting_date.split("-").join("/"),
					item.slip_number,
					item.billing_destination,
					item.client_name,
					item.total_amount,
					item.total_amount_s,
					item.total_amount + item.total_amount_s,
					item.payment_date,
					item.note,
					item.subject
				]);
			}
			let blob = vSerializer.serializeToString(csvData);
			let a = document.createElement("a");
			a.setAttribute("href", URL.createObjectURL(blob));
			a.setAttribute("download", "売上伝票.csv");
			a.click();
		}
	}
});
{/literal}</script>
{/block}

{block name="body"}
<datalist id="invoice_format">{foreach from=[]|invoiceFormat item="text" key="value"}
	<option value="{$value}">{$text}</option>
{/foreach}</datalist>
<datalist id="division"><option value="">選択</option></datalist>
<form method="POST" action="{url}" class="card position-sticky mx-5">
	<label id="search-header" class="card-header"><input type="checkbox" class="d-contents" />売上一覧検索</label>
	<fieldset class="card-body row" disabled>
		<div class="d-table table w-50">
			<row-form label="伝票番号" col="5" name="slip_number" type="text"></row-form>
			<row-form label="売上日付（開始日）" col="8" name="accounting_date[from]" type="date">{"first day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
			<row-form label="売上日付（終了日）" col="8" name="accounting_date[to]" type="date">{"last day of this month"|strtotime|date_format:"%Y-%m-%d"}</row-form>
			{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}
			<row-form label="部門" col="10" name="division" type="select" list="division"></row-form>
			<row-form label="当社担当者" col="10" name="manager" placeholder="担当者名・担当者CDで検索"></row-form>
			{/if}
			<row-form label="請求先" col="10" name="billing_destination" placeholder="請求先名・請求先CDで検索"></row-form>
		</div>
	</fieldset>
	<div class="card-footer">
		<div class="col-12 text-center">
			<button type="submit" class="btn btn-success">検　索</button>
			<button type="reset" class="btn btn-outline-success">リセット</button>
		</div>
	</div>
</form>

<div class="mx-5 text-end">
	<button type="button" class="btn btn-dark me-3" id="output">売上伝票出力</button>
	<button type="button" class="btn btn-primary" id="close" data-close="{url action="close"}">請求締</button>
</div>

<div class="flex-grow-1 mx-5 position-relative">
	<div class="position-absolute h-100 w-100 overflow-auto">
		<table class="table bg-white table_sticky_list" data-scroll-y="list">
			<thead>
				<tr>
					<th></th>
					<th class="w-10">仕入明細</th>
					<th class="w-10">売上明細</th>
					{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<th class="w-10">承認解除</th>{/if}
					<th class="w-10">伝票番号</th>
					<th class="w-10">確定日時</th>
					<th class="w-10">件名</th>
					<th class="w-10">クライアント名</th>
					<th class="w-20">請求先名</th>
					{if $smarty.session["User.role"] ne "manager"}<th class="w-10">担当者名</th>{/if}
					<th class="w-20">備考</th>
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" constructor="sales" assign="obj"}
				<tr data-range="{$obj.id}" data-colosed="{$obj.close_processed}">
					<td><input type="checkbox" value="{$obj.id}" checked /></td>
					<td data-purchases="{$obj.import_purchases}"><button type="button" data-detail="1" class="btn btn-sm btn-success bx">仕入明細</button></td>
					<td><button type="button" data-detail="2" class="btn btn-sm btn-success bx">売上明細</button></td>
					{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}
						<td><button type="button" data-detail="3" class="btn btn-sm btn-primary bx bxs-edit">承認解除</button></td>
					{/if}
					<td>{$obj.slip_number}</td>
					<td>{$obj.created}</td>
					<td>{$obj.subject}</td>
					<td>{$obj.delivery_destination}</td>
					<td>{$obj.apply_client_name}</td>
					{if $smarty.session["User.role"] ne "manager"}<td>{$obj.manager_name}</td>{/if}
					<td>{$obj.note}</td>
				</tr>
			{/predefine}</tbody>
		</table>
	</div>
</div>
{/block}


{block name="dialogs" append}
<div class="modal fade" id="managerModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg flex-column">
		<div class="modal-content flex-grow-1">
			<div class="modal-header flex-row">
				<div class="text-center">当社担当者選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body position-relative me-4 mb-4">
				<div class="position-absolute h-100 w-100 overflow-auto">
					<table class="table table_sticky_list">
						<thead>
							<tr>
								<th>コード</th>
								<th>担当者名</th>
								<th>カナ</th>
								<th></th>
							</tr>
						</thead>
						<tbody>{predefine name="managerList" assign="obj"}
							<tr>
								<td>{$obj.code}</td>
								<td>{$obj.name}</td>
								<td>{$obj.kana}</td>
								<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
							</tr>
						{/predefine}</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>
<div class="modal fade" id="applyClientModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg flex-column">
		<div class="modal-content flex-grow-1">
			<div class="modal-header flex-row">
				<div class="text-center">請求先選択</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body position-relative me-4 mb-4">
				<div class="position-absolute h-100 w-100 overflow-auto">
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
						<tbody>{predefine name="applyClientList" assign="obj"}
							<tr>
								<td>{$obj.code}</td>
								<td>{$obj.client_name}</td>
								<td>{$obj.name}</td>
								<td>{$obj.kana}</td>
								<td><button class="btn btn-success btn-sm" data-bs-dismiss="modal" data-search-modal-value="{$obj.code}" data-search-modal-label="{$obj.name}">選択</button></td>
							</tr>
						{/predefine}</tbody>
					</table>
				</div>
			</div>
		</div>
	</div>
</div>
<div class="modal fade" id="detailModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-form">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<select tabindex="-1"><option value="1">仕入明細</option><option value="2">売上明細</option>{if ($smarty.session["User.role"] eq "leader") or ($smarty.session["User.role"] eq "admin")}<option value="3">承認解除</option>{/if}</select><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body">{predefine name="detailView" constructor=["sales", "categories"] assign=["obj", "detail", "detail2"]}
				<div class="container border border-secondary rounded p-4 mb-5 bg-white" data-approval="{url action="disapproval"}/{$obj.id}">
					<div class="row gap-4 align-items-start">
						<div class="d-table col table">
							<row-form label="伝票番号" col="5">{$obj.slip_number}</row-form>
							<row-form label="確定日時" col="5">{$obj.created}</row-form>
							<row-form label="売上日付" col="5">{$obj.accounting_date}</row-form>
							<row-form label="当社担当者" col="10">{$obj.manager_name}</row-form>
							<row-form label="請求書件名" col="10">{$obj.subject}</row-form>
							<row-form label="入金予定日" col="5">{$obj.payment_date}</row-form>
						</div>
						<div class="d-table col table">
							<row-form label="請求書パターン" type="hidden" col="6">{$obj.invoice_format}<div slot="content">{foreach from=[]|invoiceFormat item="text" key="value"}{predef_repeat loop=$sales.equals|predef_invoke:$value:$obj.invoice_format}{$text}{/predef_repeat}{/foreach}</div></row-form>
							<row-form label="請求先" col="10">{$obj.apply_client_name}</row-form>
							<row-form label="納品先" col="10">{$obj.delivery_destination}</row-form>
							<row-form label="備考" col="10">{$obj.note}</row-form>
						</div>
					</div>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive" data-detail-modal="1">
					<div>売上明細</div>
					<table class="table table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>商品カテゴリー</th>
								<th>内容（摘要）</th>
								<th>数量</th>
								<th>単位</th>
								<th>単価</th>
								<th>金額</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header1}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header2}</th>
								<th class="py-0 align-middle" data-visible="v3">{$obj.header3}</th>
								<th data-visible="v2">発行部数</th>
							</tr>
						</thead>
						<tbody>
							{predef_repeat loop=$detail.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{$sales.getName|predef_invoke:$categories[$detail[$i].category_code]}</td>
								<td>{$detail[$i].itemName}{$detail[$i].item_name}</td>
								<td class="text-end">{$sales.numberFormat2|predef_invoke:$detail[$i].quantity}</td>
								<td>{$detail[$i].unit}</td>
								<td class="text-end">{$sales.numberFormat2|predef_invoke:$detail[$i].unit_price}</td>
								<td class="text-end">{$sales.numberFormat|predef_invoke:$detail[$i].amount}</td>
								<td data-visible="v3">{$detail[$i].data1}</td>
								<td data-visible="v3">{$detail[$i].data2}</td>
								<td data-visible="v3">{$detail[$i].data3}</td>
								<td class="text-end" data-visible="v2">{$sales.numberFormat|predef_invoke:$detail[$i].circulation}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
				<div class="container border border-secondary rounded p-4 mb-5 bg-white table-responsive" data-detail-modal="2">
					<div>仕入明細</div>
					<table class="table table-md table_sticky_list">
						<thead>
							<tr>
								<th>No</th>
								<th>内容</th>
								<th>金額</th>
								<th>支払日</th>
							</tr>
						</thead>
						<tbody>
							{predef_repeat loop=$detail2.length index="i"}
							<tr>
								<td class="table-group-row-no align-middle"></td>
								<td>{$detail2[$i].subject}</td>
								<td class="text-end">{$sales.numberFormat|predef_invoke:$detail2[$i].amount}</td>
								<td>{$detail2[$i].payment_date}</td>
							</tr>
							{/predef_repeat}
						</tbody>
					</table>
				</div>
			{/predefine}</div>
			<div class="modal-footer flex-row">
				<button type="button" class="btn btn-success" id="closeDetailModal">閉じる</button>
				<button type="button" class="btn btn-success" id="approval" data-detail-modal="3">承認解除</button>
			</div>
		</div>
	</div>
</div>
{/block}