{block name="styles" append}{literal}
<link rel="stylesheet" type="text/css" href="/assets/bootstrap/font/bootstrap-icons.css" />
<link rel="stylesheet" type="text/css" href="/assets/boxicons/css/boxicons.min.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/layout.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/SinglePage.css" />
<link rel="stylesheet" type="text/css" href="/assets/common/PrintPage.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jsuites.css" />
<link rel="stylesheet" type="text/css" href="/assets/jspreadsheet/jspreadsheet.css" />
<style type="text/css">
#spmain::part(d-table){
	display: table;
}
#spmain::part(d-table-column-group){
	display: table-column-group;
}
#spmain::part(d-table-column){
	display: table-column;
}
#spmain::part(d-table-row-group){
	display: table-row-group;
}
#spmain::part(bg-light){
	background-color: rgba(var(--bs-light-rgb),1);
}
.d-table-row{
	border-color: var(--bs-table-border-color)
}
.d-table-cell{
	border-color: inherit;
	border-style: solid;
	border-width: 0;
}
.th{
	text-align: -webkit-match-parent;
	font-weight: bold;
	width: 10em;
}
form{
	display: contents;
}
print-page{
	padding: 24px;
}
edit-table{
	display: block;
	overflow: hidden;
	height: calc(100vh - 10rem);
}
.invalid{
	font-size: 1rem;
	color: #dc3545;
}
</style>
{/literal}{/block}
{block name="scripts"}{literal}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/SQLite.js"></script>
<script type="text/javascript" src="/assets/common/SinglePage.js"></script>
<script type="text/javascript" src="/assets/common/PrintPage.js"></script>
<script type="text/javascript" src="/assets/jspdf/jspdf.umd.min.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jsuites.js"></script>
<script type="text/javascript" src="/assets/jspreadsheet/jspreadsheet.js"></script>
<script type="text/javascript">
class ListButtonElement extends HTMLElement{
	#root;
	constructor(){
		super();
		this.#root = Object.assign(this.attachShadow({mode: "closed"}), {innerHTML: '<span></span>'});
	}
	connectedCallback(){
		queueMicrotask(() => {this.setAttribute("data-result", this.textContent); });
	}
	disconnectedCallback(){}
	attributeChangedCallback(name, oldValue, newValue){
		if(name == "label"){
			const label = this.#root.querySelector('span');
			if(newValue == null){
				label.textContent = "";
			}else{
				label.textContent = newValue;
			}
		}
	}
	static get observedAttributes(){ return ["label"]; }
}
customElements.define("list-button", ListButtonElement);

new VirtualPage("/1", class{
	constructor(vp){
	}
});
new VirtualPage("/2", class{
	constructor(vp){
	}
});
new VirtualPage("/3", class{
	constructor(vp){
	}
});
new VirtualPage("/4", class{
	constructor(vp){
	}
});

const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
	const found = t.match(/^(.*?)=(.*)$/);
	if(found){
		a[found[1]] = decodeURIComponent(found[2]);
	}
	return a;
},{});
let master = new SQLite();
let cache = new SQLite();
let transaction = new SQLite();
const objectData = Symbol("objectData");
Promise.all([
	master.use("master").then(master => fetch("/Default/master")).then(res => res.arrayBuffer()),
	cache.use("cache"),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve();
		});
	})
]).then(response => {
	master.import(response[0], "master");
	SinglePage.modal.leader      .querySelector('table-sticky').columns = dataTableQuery("/Modal/Leader#list").setField("label,width,slot,part").apply();
	SinglePage.modal.manager     .querySelector('table-sticky').columns = dataTableQuery("/Modal/Manager#list").setField("label,width,slot,part").apply();
	SinglePage.modal.apply_client.querySelector('table-sticky').columns = dataTableQuery("/Modal/ApplyClient#list").setField("label,width,slot,part").apply();
	
	SinglePage.modal.leader.setQuery(v => master.select("ONE").setTable("leaders").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.leader.querySelector('table-sticky'),
			dataTableQuery("/Modal/Leader#list").apply(),
			master.select("ALL")
				.setTable("leaders")
				.apply(),
			row => {}
		);
	});
	SinglePage.modal.manager.setQuery(v => master.select("ONE").setTable("managers").setField("name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.manager.querySelector('table-sticky'),
			dataTableQuery("/Modal/Manager#list").apply(),
			master.select("ALL")
				.setTable("managers")
				.apply(),
			row => {}
		);
	});
	SinglePage.modal.apply_client.setQuery(v => master.select("ONE").setTable("system_apply_clients").setField("unique_name").andWhere("code=?", v).apply()).addEventListener("modal-open", e => {
		const keyword = e.detail;
		setDataTable(
			SinglePage.modal.apply_client.querySelector('table-sticky'),
			dataTableQuery("/Modal/ApplyClient#list").apply(),
			master.select("ALL")
				.setTable("system_apply_clients")
				.setField("system_apply_clients.code,system_apply_clients.unique_name as name,system_apply_clients.kana")
				.leftJoin("clients on system_apply_clients.client=clients.code")
				.addField("clients.name as client")
				.apply(),
			row => {}
		);
	});
	
	const categories = master.select("ALL")
		.setTable("categories")
		.apply();
	categories.forEach(function(row){
		const option = document.createElement("option");
		option.setAttribute("value", row.code);
		option.textContent = row.name;
		this.appendChild(option);
	}, document.getElementById("category"));
	master.select("ALL")
		.setTable("divisions")
		.apply()
		.forEach(function(row){
			const option = document.createElement("option");
			option.setAttribute("value", row.code);
			option.textContent = row.name;
			this.appendChild(option);
		}, document.getElementById("division"));
	master.select("ALL")
		.setTable("specifications")
		.apply()
		.forEach(function(row){
			const option = document.createElement("option");
			option.setAttribute("value", row.code);
			option.textContent = row.name;
			this.appendChild(option);
		}, document.getElementById("specification"));
	
	SinglePage.modal.number_format.setQuery(v => new Intl.NumberFormat().format(v));
	SinglePage.modal.number_format2.setQuery(v => new Intl.NumberFormat(void(0), {minimumFractionDigits: 2, maximumFractionDigits: 2}).format(v));
	
	const parser = new DOMParser();
	const xmlDoc = parser.parseFromString(cache.select("ONE").setTable("estimate").setField("xml").andWhere("dt=?", Number(search.key)).apply(), "application/xml");
	const root = xmlDoc.documentElement;
	const id = xmlDoc.querySelector('info').getAttribute("type");
	SinglePage.location = `/${id}`;
	const inputElements = document.querySelectorAll('form-control[name]');
	for(let i = inputElements.length - 1; i >= 0; i--){
		const name = inputElements[i].getAttribute("name");
		if(root.hasAttribute(name)){
			inputElements[i].value = root.getAttribute(name);
			inputElements[i].addEventListener("change", e => {
				const target = e.currentTarget;
				const value = (target.getAttribute("type") == "date") ? target.querySelector('input[name]').value : target.value;
				root.setAttribute(name, value);
				cache.updateSet("estimate", {xml: root.outerHTML}, {}).andWhere("dt=?", Number(search.key)).apply();
				cache.commit();
			});
		}
	}
	
	const refDetail = Symbol("refDetail");
	const refAttr = Symbol("refAttr");
	const jse = document.getElementById("detail");
	const taxableObj = {
		taxable: true,
		tax_rate: 0.1
	};
	const untaxableObj = {
		taxable: false,
		tax_rate: null
	};
	const recordObj = {
		quantity: 0,
		unit: "",
		unit_price: 0,
		amount_exc: 0,
		amount_tax: 0,
		amount_inc: 0,
		category: "",
		record: true,
		taxable: true,
		tax_rate: 0.1
	};
	const unrecordObj = {
		quantity: null,
		unit: null,
		unit_price: null,
		amount_exc: null,
		amount_tax: null,
		amount_inc: null,
		category: "",
		record: false,
		taxable: false,
		tax_rate: null
	};
	const toolbarDisplay = top => {
		const data = obj.options.data[top][objectData];
		obj.toolbar.querySelector('.toolbar-record').value = data.record ? "1" : "0";
		if(data.record){
			obj.toolbar.querySelector('.toolbar-taxable').style.display = "block";
		}else{
			obj.toolbar.querySelector('.toolbar-taxable').style.display = "none";
		}
		obj.toolbar.querySelector('.toolbar-taxable').value = data.taxable ? "1" : "0";
		if(data.taxable){
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "block";
			obj.toolbar.querySelector('.toolbar-tax-rate input').value = data.tax_rate * 100;
			
		}else{
			obj.toolbar.querySelector('.toolbar-tax-rate').style.display = "none";
		}
	};
	const toolbar = document.createDocumentFragment();
	toolbar.appendChild(Object.assign(document.createElement("select"), {innerHTML: '<option value="0">見出し行</option><option value="1">通常行</option>', className: 'toolbar-record'}));
	toolbar.appendChild(Object.assign(document.createElement("select"), {innerHTML: '<option value="1">課税</option><option value="0">非課税</option>', className: 'toolbar-taxable'}));
	toolbar.appendChild(Object.assign(document.createElement("div"), {innerHTML: '税率<input type="number" style="width: 7ex" />％', className: 'toolbar-tax-rate'}));
	
	let tableColumns = [
		{ [refDetail]: "detail",     type: 'text', title: '内容', width: 200 },
		{ [refDetail]: "quantity",   type: 'numeric', title: '数量', width: 60, mask:'#,##.00' },
		{ [refDetail]: "unit",       type: 'text', title: '単位', width: 60 },
		{ [refDetail]: "unit_price", type: 'numeric', title: '単価', width: 80, mask:'#,##.00' },
		{ [refDetail]: "amount_exc", type: 'numeric', title: '税抜金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_tax", type: 'numeric', title: '消費税金額', width: 100, mask:'#,##' },
		{ [refDetail]: "amount_inc", type: 'numeric', title: '税込金額', width: 100, mask:'#,##' },
		{ [refDetail]: "category",   type: 'dropdown', title: 'カテゴリー', width: 200, source: categories.map(r => r.name) }
	];
	if(id == "2"){
		tableColumns.push(
			{ [refAttr]: "circulation", type: 'numeric', title: '発行部数', width: 60, mask:'#,##' }
		);
	}else if(id == "3"){
		tableColumns.push(
			{ [refAttr]: "summary_data1", type: 'text', title: '摘要１', width: 200 },
			{ [refAttr]: "summary_data2", type: 'text', title: '摘要２', width: 200 },
			{ [refAttr]: "summary_data3", type: 'text', title: '摘要３', width: 200 }
		);
	}
	const obj = jspreadsheet(jse, {
		minDimensions: [1, 1],
		columns: tableColumns,
		toolbar: toolbar,
		dataProxy(){
			return new Proxy(
				Object.assign({detail: "", attributes: {}}, unrecordObj), {
				get(target, prop, receiver){
					if(prop == "length"){
						return tableColumns.length;
					}
					if(prop == objectData){
						return target;
					}
					if((refDetail in tableColumns[prop]) && (tableColumns[prop][refDetail] == "category")){
						let found = null;
						const searchC = target.category;
						for(let category of categories){
							if(searchC == category.code){
								found = category.name;
							}
						}
						return found;
					}
					if(refAttr in tableColumns[prop]){
						return target.attributes[tableColumns[prop][refAttr]];
					}
					return target[tableColumns[prop][refDetail]];
				},
				set(obj, prop, value){
					if(refAttr in tableColumns[prop]){
						if(tableColumns[prop][refAttr] == "circulation"){
							if(value == ""){
								value = 0;
							}else{
								value = Number(value.replace(/,/g, ""));
							}
						}
						obj.attributes[tableColumns[prop][refAttr]] = value;
					}else if(refDetail in tableColumns[prop]){
						if((tableColumns[prop][refDetail] != "detail") && (value != "") && (!obj.record)){
							Object.assign(obj, recordObj);
						}
						if(tableColumns[prop][refDetail] == "detail"){
							obj[tableColumns[prop][refDetail]] = value;
						}else if(obj.record){
							if((tableColumns[prop][refDetail] == "quantity") || (tableColumns[prop][refDetail] == "unit_price")){
								if(value == ""){
									value = 0;
								}else{
									value = Number(value.replace(/,/g, ""));
								}
							}else if(tableColumns[prop][refDetail] == "category"){
								let found = null;
								for(let category of categories){
									if(value == category.name){
										found = category.code;
									}
								}
								value = found;
							}
							obj[tableColumns[prop][refDetail]] = value;
							obj.amount_exc = Math.floor(obj.quantity * obj.unit_price);
							obj.amount_tax = Math.floor((obj.taxable) ? obj.amount_exc * obj.tax_rate : 0);
							obj.amount_inc = obj.amount_exc + obj.amount_tax;
						}
					}
					return true;
				}
			});
		},
		text: { rowNumber: "項番" },
		onselection: (el, borderLeft, borderTop, borderRight, borderBottom, origin) => {
			toolbarDisplay(borderTop);
		},
		onchange: (el, cell, x, y, value, oldValue) => {
			const fragment = xmlDoc.createDocumentFragment();
			const info = xmlDoc.querySelector('info');
			fragment.appendChild(info);
			const total = obj.options.data.reduce((a, rowProxy) => {
				const row = rowProxy[objectData];
				const detail = xmlDoc.createElement("detail");
				const attributes = ("attributes" in row) ? xmlDoc.createElement("attributes") : null;
				if(attributes != null){
					detail.appendChild(attributes);
				}
				for(let key in row){
					if(key == "attributes"){
						for(let key2 in row.attributes){
							attributes.setAttribute(key2, `${row.attributes[key2]}`);
						}
					}else if(row[key] != null){
						detail.setAttribute(key, `${row[key]}`);
					}
				}
				a.fragment.appendChild(detail);
				if(row.record == 1){
					a.amount_exc += row.amount_exc;
					a.amount_tax += row.amount_tax;
					a.amount_inc += row.amount_inc;
				}
				return a; 
			}, {amount_exc: 0, amount_inc: 0, amount_tax: 0, fragment: fragment});
			document.querySelector('form-control[name="amount_exc"]').value = total.amount_exc;
			document.querySelector('form-control[name="amount_tax"]').value = total.amount_tax;
			document.querySelector('form-control[name="amount_inc"]').value = total.amount_inc;
			root.setAttribute("amount_exc", total.amount_exc);
			root.setAttribute("amount_tax", total.amount_tax);
			root.setAttribute("amount_inc", total.amount_inc);
			info.setAttribute("update", Date.now());
			root.innerHTML = "";
			root.appendChild(fragment);
			cache.updateSet("estimate", {xml: root.outerHTML}, {}).andWhere("dt=?", Number(search.key)).apply();
			cache.commit();
		}
	});
	obj.setData(
		Array.from({
			[Symbol.iterator]: function*(){
				const n = this.details.length;
				for(let i = 0; i < n; i++){
					const row = Array.from(this.details[i].attributes).reduce((a, attr) => {
						if((attr.name == "record") || (attr.name == "taxable")){
							a[attr.name] = (attr.value == "true");
						}else{
							a[attr.name] = attr.value;
						}
						return a;
					}, {});
					const attrElement = this.details[i].querySelector('attributes');
					if(attrElement == null){
						row.attributes = null;
					}else{
						row.attributes = Array.from(attrElement.attributes).reduce((a, attr) => {
							a[attr.name] = attr.value;
							return a;
						}, {});
					}
					yield row;
				}
			},
			details: xmlDoc.querySelectorAll('detail')
		}).map(row => {
			const insert = obj.options.dataProxy();
			Object.assign(insert[objectData], row);
			return insert;
		}),
		true
	);
	obj.toolbar.querySelector('.toolbar-record').addEventListener("change", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			Object.assign(obj.options.data[i][objectData], e.currentTarget.value == "0" ? unrecordObj : recordObj);
			obj.updateRow(null, i, null, null);
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-taxable').addEventListener("change", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			const data = obj.options.data[i][objectData];
			if((e.currentTarget.value == "1") && (!data.record)){
				Object.assign(data, recordObj);
				obj.updateRow(null, i, null, null);
			}
			Object.assign(data, e.currentTarget.value == "0" ? untaxableObj : taxableObj);
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-tax-rate input').addEventListener("input", e => {
		const selected = obj.selectedCell.map(Number);
		const top = Math.min(selected[1], selected[3]);
		const bottom = Math.max(selected[1], selected[3]);
		for(let i = top; i <= bottom; i++){
			const data = obj.options.data[i][objectData];
			const rate = Number(e.currentTarget.value / 100);
			if(!data.record){
				Object.assign(data, recordObj, {taxable: true});
				obj.updateRow(null, i, null, null);
			}
			data.tax_rate = rate;
		}
		toolbarDisplay(top);
	});
	obj.toolbar.querySelector('.toolbar-tax-rate input').addEventListener("keydown", e => {
		e.stopPropagation();
	});
	
	const template = document.querySelector('#spmain [slot="print"] print-page');
	document.querySelector('[data-trigger="print"]').addEventListener("click", e => {
		const slotObj = {
			today: new Intl.DateTimeFormat("ja-JP").format(new Date()),
			subject: document.querySelector('form-control[name="subject"]').value,
			leader: document.querySelector('form-control[name="leader"]').text,
			manager: document.querySelector('form-control[name="manager"]').text,
			client_name: document.querySelector('form-control[name="client_name"]').value,
			amount_exc: document.querySelector('form-control[name="amount_exc"]').text,
			amount_tax: document.querySelector('form-control[name="amount_tax"]').text,
			amount_inc: document.querySelector('form-control[name="amount_inc"]').text,
			specification: document.querySelector('form-control[name="specification"]').text,
			note: document.querySelector('form-control[name="note"]').value
		};
		const printArea = document.querySelector('#spmain [slot="print"]');
		printArea.innerHTML = "";
		printArea.appendChild(template.cloneNode(true));
		const slotElements = printArea.querySelectorAll('[data-slot]');
		for(let i = slotElements.length - 1; i >= 0; i--){
			const attr = slotElements[i].getAttribute("data-slot");
			if(attr in slotObj){
				slotElements[i].textContent = slotObj[attr];
			}
		}
		const tbody = printArea.querySelector('tbody:has([data-table-slot])');
		const tr = tbody.querySelector('tr');
		tbody.removeChild(tr);
		const details = document.getElementById("detail").jspreadsheet.options.data;
		const proc = {
			detail(value){
				if(value == ""){
					return "\u200B";
				}
				return value;
			},
			quantity(value){
				if(value == null){
					return "";
				}
				return SinglePage.modal.number_format2.query(value);
			},
			unit_price(value){
				if(value == null){
					return "";
				}
				return SinglePage.modal.number_format2.query(value);
			},
			amount_exc(value){
				if(value == null){
					return "";
				}
				return SinglePage.modal.number_format.query(value);
			},
			circulation(value){
				if(value == null){
					return "";
				}
				return SinglePage.modal.number_format.query(value);
			}
		};
		for(let rowProxy of details){
			const row = rowProxy[objectData];
			const insertRow = tr.cloneNode(true);
			const slotElements2 = insertRow.querySelectorAll('[data-table-slot]');
			const slotElements3 = insertRow.querySelectorAll('[data-table-slot-attribute]');
			for(let i = slotElements2.length - 1; i >= 0; i--){
				const attr = slotElements2[i].getAttribute("data-table-slot");
				if(attr in row){
					slotElements2[i].textContent = (attr in proc) ? proc[attr](row[attr]) : row[attr];
				}
			}
			for(let i = slotElements3.length - 1; i >= 0; i--){
				const attr = slotElements3[i].getAttribute("data-table-slot-attribute");
				if(attr in row.attributes){
					slotElements3[i].textContent = (attr in proc) ? proc[attr](row.attributes[attr]) : row.attributes[attr];
				}
			}
			tbody.appendChild(insertRow);
		}
		printArea.querySelector('print-page').pageBreak(
			(function*(){
				const elements = document.querySelectorAll('[data-page-break]');
				const n = elements.length;
				for(let i = 0; i < n; i++){
					yield elements[i];
				}
			})(),
			node => ((node.nodeType == Node.ELEMENT_NODE) && node.hasAttribute("data-page-clone")),
			(page, node) => { page.insertAdjacentElement("afterend", node); }
		);
		
		
		let docIds = {};
		const doc = new jspdf.jsPDF({unit: "pt"});
		for(let fontName in PrintPage.font){
			docIds[fontName] = `custom${Object.keys(docIds).length}`;
			doc.addFileToVFS(PrintPage.font[fontName].alias, PrintPage.font[fontName].data);
			doc.addFont(PrintPage.font[fontName].alias, docIds[fontName], 'normal');
		}
		
		const pxPt = 0.75;
		const textOpt = {align: "left", baseline: "top"};
		const printPages = document.querySelectorAll('#spmain [slot="print"] print-page');
		const pageCnt = printPages.length;
		for(let i = 0; i < pageCnt; i++){
			const printData = printPages[i].printData;
			const textLen = printData.text.length;
			let ctx = {};
			doc.addPage(printData.page.size, printData.page.orientation);
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
		//doc.save('output.pdf');
		open(doc.output("bloburi"), "_blank", "left=0,top=0,width=1200,height=600");
	});
	
	document.querySelector('[data-trigger="submit"]').addEventListener("click", e => {
		const form = document.querySelector('form');
		const formData = new FormData(form);
		const details = document.getElementById("detail").jspreadsheet.options.data.map(rowProxy => {
			let res = {};
			const row = rowProxy[objectData];
			for(let key in row){
				if(typeof row[key] == "boolean"){
					res[key] = row[key] ? 1 : 0;
				}else{
					res[key] = row[key];
				}
			}
			return res;
		});
		formData.append("invoice_format",id);
		formData.append("detail", JSON.stringify(details));
		fetch(`/Estimate/regist`, {
			method: "POST",
			body: formData
		}).then(res => res.json()).then(result => {
			if(result.success){
				new BroadcastChannel(search.channel).postMessage(JSON.stringify(result));
				close();
			}else{
				const messages = {};
				const messages2 = document.createDocumentFragment();
				for(let meaasge of result.messages.filter(m => (m[1] == 2))){
					let token = meaasge[2].split("/");
					if(token.length == 1){
						messages[meaasge[2]] = meaasge[0];
					}else if(token.length == 3){
						messages2.appendChild(Object.assign(document.createElement("div"), {textContent: `${Number(token[1]) + 1}行目：${meaasge[0]}`}));
					}
				}
				
				const inputElements = form.querySelectorAll('form-control[name]');
				const n = inputElements.length;
				for(let i = 0; i < n; i++){
					const name = inputElements[i].getAttribute("name");
					inputElements[i].invalid = (name in messages);
					inputElements[i].nextSibling.textContent = (name in messages) ? messages[name] : "";
				}
				const range = document.createRange();
				const tableInvalid = document.querySelector('#detail~.invalid');
				range.selectNodeContents(tableInvalid);
				range.deleteContents();
				tableInvalid.appendChild(messages2);
			}
		});
	});
});

function formTableInit(parent, data){
	return new Promise((resolve, reject) => {
		let tableList = {};
		for(let row of data){
			if(!(row.column in tableList)){
				tableList[row.column] = {
					table: Object.assign(document.createElement("table"), {className: "table my-0"}),
					tbody: document.createElement("tbody")
				};
				const colgroup = document.createElement("colgroup");
				colgroup.appendChild(Object.assign(document.createElement("col"), {className: "bg-light"}));
				colgroup.appendChild(document.createElement("col"));
				tableList[row.column].table.appendChild(colgroup)
				tableList[row.column].table.appendChild(tableList[row.column].tbody);
			}
			const tr = document.createElement("tr");
			const th = document.createElement("th");
			const td = document.createElement("td");
			const formControl = document.createElement("form-control");
			const invalid = Object.assign(document.createElement("div"), {className: "invalid"});
			th.textContent = row.label;
			th.className = "align-middle ps-4";
			formControl.setAttribute("fc-class", `col-${row.width}`);
			formControl.setAttribute("name", row.name);
			formControl.setAttribute("type", row.type);
			if((row.list != null) && (row.list != "")){
				formControl.setAttribute("list", row.list);
			}
			if((row.placeholder != null) && (row.placeholder != "")){
				formControl.setAttribute("placeholder", row.placeholder);
			}
			
			td.appendChild(formControl);
			td.appendChild(invalid);
			tr.appendChild(th);
			tr.appendChild(td);
			tableList[row.column].tbody.appendChild(tr);
		}
		const tableColumns = Object.keys(tableList).sort();
		for(let tableNo of tableColumns){
			if(parent.tagName == "SEARCH-FORM"){
				tableList[tableNo].table.setAttribute("slot", "body");
			}
			parent.appendChild(tableList[tableNo].table);
		}
		queueMicrotask(() => { resolve(parent); });
	});
}
function formTableQuery(location){
	return master.select("ALL").setTable("form_datas").andWhere("location=?", location).setOrderBy("CAST(no AS INTEGER)");
}
function dataTableQuery(location){
	return master.select("ALL").setTable("table_datas").andWhere("location=?", location).setOrderBy("CAST(no AS INTEGER)");
}
function setDataTable(parent, columns, data, callback = null){
	return new Promise((resolve, reject) => {
		parent.innerHTML = "";
		const text = document.createElement("span");
		for(let row of data){
			const elements = [];
			for(let col of columns){
				const div = document.createElement("div");
				const dataElement = document.createElement(col.tag_name);
				const classList = (col.class_list == null) ? [] : col.class_list.split(/\s/).filter(v => v != "");
				let attrStr = (col.attributes == null) ? "" : col.attributes;
				do{
					const nextStr = attrStr.replace(/^\s*([a-zA-Z0-9\-]+)="([^"]*?)"/, (str, name, value) => {
						if(name != ""){
							dataElement.setAttribute(name, Object.assign(text, {innerHTML: value}).textContent);
						}
						return "";
					});
					if(attrStr == nextStr){
						break;
					}
					attrStr = nextStr;
				}while(true);
				div.setAttribute("slot", col.slot);
				dataElement.textContent = row[col.property];
				if(classList.length > 0){
					dataElement.classList.add(...classList);
				}
				div.appendChild(dataElement);
				elements.push(div);
			}
			const dataRow = parent.insertRow(...elements);
			if(callback != null){
				callback(dataRow, row);
			}
		}
		queueMicrotask(() => { resolve(parent); });
	});
}
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
								<div part="title">見積作成</div>
							</div>
						</nav>
						<nav part="nav2">
							<div part="tools"><slot name="tools"></slot></div>
						</nav>
					</header>
					<div>
						<div style="display: grid; column-gap: 0.75rem; grid-template: 1fr/1fr 1fr; grid-auto-columns: 1fr; grid-auto-flow: column; align-items: start;">
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table1"></slot>
								</div>
							</div>
							<div part="d-table">
								<div part="d-table-column-group">
									<div part="d-table-column bg-light"></div>
								</div>
								<div part="d-table-row-group">
									<slot name="table2"></slot>
								</div>
							</div>
						</div>
					</div>
					<slot name="main"></slot>
				</div>
			</template>
			<template data-page="/1">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1">
										<div>合計金額</div>
										<div class="price">\<span data-slot="amount_inc">0,000,000</span>-</div>
										<div>（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" style="width: 80px;" />
										<col class="tw3" style="width: 55px;" />
										<col class="tw4" style="width: 80px;" />
										<col class="tw5" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);">
										<tr>
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="4">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/2">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1">
										<div>合計金額</div>
										<div class="price">\<span data-slot="amount_inc">0,000,000</span>-</div>
										<div>（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" />
										<col class="tw3" style="width: 80px;" />
										<col class="tw4" style="width: 55px;" />
										<col class="tw5" style="width: 80px;" />
										<col class="tw6" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);">
										<tr>
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">発行部数</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="circulation">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="5">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="5">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="5">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/3">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1">
										<div>合計金額</div>
										<div class="price">\<span data-slot="amount_inc">0,000,000</span>-</div>
										<div>（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" />
										<col class="tw3" />
										<col class="tw4" />
										<col class="tw5" style="width: 80px;" />
										<col class="tw6" style="width: 55px;" />
										<col class="tw7" style="width: 80px;" />
										<col class="tw8" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);">
										<tr>
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot=""></span></th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot=""></span></th>
											<th style="border-left: solid black calc(1rem / 12);"><span data-slot=""></span></th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data1"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data2"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot-attribute="summary_data3"></span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="7">上記計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
										</tr>
										<tr style="border-bottom: dashed black calc(1rem / 12);">
											<td colspan="7">消費税（10％）</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
										</tr>
										<tr>
											<td colspan="7">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page="/4">
				<div slot="print" style="height:0;overflow:hidden;">
					<print-page size="A4" orientation="P">
						<div class="page">
							<div data-page-break="headline" class="d-flex flex-column" style="gap: 20px;">
								<div class="d-flex flex-column">
									<div class="text-end"><span data-slot="today"></span></div>
									<h1 class="text-decoration-underline text-center">御見積書</h1>
									<div class="text-decoration-underline client"><span data-slot="client_name"></span>御中</div>
									<div class="d-flex flex-row"><div class="flex-grow-1"></div><div>
										<div class="co">株式会社ダイレクト・ホールディングス</div>
										<div class="ab">
											<div><span data-slot="leader"></span>・<span data-slot="manager"></span></div>
											<div>〒163-1439</div>
											<div>東京都新宿区西新宿3丁目20番2号</div>
											<div>東京オペラシティタワー39階</div>
											<div>TEL：03-6416-4822</div>
										</div>
									</div></div>
								</div>
								<div class="d-flex flex-row gap-1">
									<div>件名</div>
									<div><span data-slot="subject"></span></div>
								</div>
								<div style="border: solid black calc(1rem / 12);">
									<div class="border-xs border-ts border-bs" style="border-bottom: solid black calc(1rem / 12);">仕様</div>
									<div class="border-xs border-bd" style="border-bottom: dashed black calc(1rem / 12);">&#8203;<span data-slot="specification"></span></div>
									<div class="border-xs border-bs">&#8203;</div>
								</div>
								<div>
									<div class="d-flex flex-row gap-1">
										<div>合計金額</div>
										<div class="price">\<span data-slot="amount_inc">0,000,000</span>-</div>
										<div>（税込）</div>
									</div>
								</div>
							</div>
							<div>
								<table class="w-100" style="border: solid black calc(1rem / 6);">
									<colgroup data-page-clone="1">
										<col class="tw1" />
										<col class="tw2" style="width: 80px;" />
										<col class="tw3" style="width: 55px;" />
										<col class="tw4" style="width: 80px;" />
										<col class="tw5" style="width: 130px;" />
										<col class="tw6" style="width: 130px;" />
										<col class="tw7" style="width: 130px;" />
									</colgroup>
									<thead  data-page-clone="1" style="border-bottom: solid black calc(1rem / 12);">
										<tr>
											<th>摘要</th>
											<th style="border-left: solid black calc(1rem / 12);">数量</th>
											<th style="border-left: solid black calc(1rem / 12);">単位</th>
											<th style="border-left: solid black calc(1rem / 12);">単価</th>
											<th style="border-left: solid black calc(1rem / 12);">金額（税抜）</th>
											<th style="border-left: solid black calc(1rem / 12);">消費税（10％）</th>
											<th style="border-left: solid black calc(1rem / 12);">金額（税込）</th>
										</tr>
									</thead>
									<tbody>
										<tr data-page-break="detail" style="border-bottom: dashed black calc(1rem / 12);">
											<td><span data-table-slot="detail">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="quantity">0,000.00</span></td>
											<td style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit">DATA</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="unit_price">0,000.00</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_exc">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_tax">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-table-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
									<tbody data-page-break="aggregate" style="border-top: solid black calc(1rem / 6);">
										<tr>
											<td colspan="4">合計</td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_exc">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_tax">0,000,000</span></td>
											<td class="text-end" style="border-left: solid black calc(1rem / 12);"><span data-slot="amount_inc">0,000,000</span></td>
										</tr>
									</tbody>
								</table>
							</div>
							<div class="grow-1 flex-column" style="margin-top: 20px;">
								<div>備考</div>
								<div class="grow-1 border-2" style="height: 6em; border: solid black calc(1rem / 6);"><span data-slot="note" style="white-space: pre-wrap;"></span></div>
							</div>
						</div>
					</print-page>
				</div>
			</template>
			<template data-page-share="">
				<div slot="table1" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">見積日付</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="estimate_date" type="date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">案件番号</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="project" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">件名</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="subject" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="division" type="select" list="division"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">部門長</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="leader" type="keyword" list="leader" placeholder="部門長名・部門長CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">営業担当者</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="manager" type="keyword" list="manager" placeholder="担当者名・担当者CDで検索"></form-control><div class="invalid"></div></div>
					</div>
				</div></div>
				<div slot="main">
					<div id="detail"></div>
					<div class="invalid"></div>
				</div>
			</template>
			<template data-page-share="/3">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">納品先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">入金予定日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">仕様</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="specification" type="select" list="specification"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format">0</form-control><div class="invalid"></div></div>
					</div>
				</div></div>
			</template>
			<template data-page="/3">
				<div slot="table2" class="table d-contents"><div class="d-contents">
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">納品先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="client_name" type="text"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">請求先</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="apply_client" type="keyword" list="apply_client" placeholder="請求先名・請求先CDで検索"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">入金予定日</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="payment_date" type="date"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">仕様</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="specification" type="select" list="specification"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">備考</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="note" type="textarea"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">摘要ヘッダ</div>
						<div class="d-table-cell">
							<div class="d-flex col-10 gap-3">
								<form-control name="summary_header1" type="text"></form-control>
								<form-control name="summary_header2" type="text"></form-control>
								<form-control name="summary_header3" type="text"></form-control>
							</div>
							<div class="invalid"></div>
						</div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税抜合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_exc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">消費税合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_tax" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
					<div class="d-table-row">
						<div class="d-table-cell th align-middle ps-4">税込合計金額</div>
						<div class="d-table-cell"><form-control fc-class="col-10" name="amount_inc" type="label" list="number_format"></form-control><div class="invalid"></div></div>
					</div>
				</div></div>
			</template>
			<template data-page-share="">
				<span slot="tools" class="btn btn-primary my-2" data-trigger="print">見積書生成</span>
				<span slot="tools"" class="btn btn-primary my-2" data-trigger="submit">確定登録</span>
			</template>
		</div>
	</form>
	
	<datalist id="category"></datalist>
	<datalist id="division"></datalist>
	<datalist id="invoice_format"><option value="1">通常請求書</option><option value="2">ニッピ用請求書</option><option value="3">加茂繊維用請求書</option><option value="4">ダイドー用請求書</option></datalist>
	<datalist id="specification"></datalist>
	<modal-dialog name="leader" label="部門長選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="manager" label="当社担当者選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="apply_client" label="請求先選択">
		<table-sticky slot="body" style="height: calc(100vh - 20rem);"></table-sticky>
	</modal-dialog>
	<modal-dialog name="number_format"></modal-dialog>
	<modal-dialog name="number_format2"></modal-dialog>
{/block}