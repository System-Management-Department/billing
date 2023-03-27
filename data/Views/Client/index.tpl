{block name="title"}得意先クライアント検索{/block}

{block name="styles" append}
<style type="text/css">
[data-search-output="container"]:has([data-search-output="result"] input[type="hidden"]:not([value=""])) [data-search-output="form"],
[data-search-output="container"] [data-search-output="result"]:has(input[type="hidden"][value=""]){
	display: none;
}
</style>
{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",{literal}
	strage: null,
	response: new SQLite(),
	y: null,
	template: new Template(),
	*[Symbol.iterator](){
		const form = document.querySelector('form');
		yield* this.init(form);
		form.querySelector('fieldset:disabled').disabled = false;
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
			this.strage.commit();
			this.search(obj.data).next();
		});

		if(this.y != null){
			const scrollY = document.querySelectorAll('[data-scroll-y]');
			for(let i = scrollY.length - 1; i >= 0; i--){
				let ele = scrollY[i];
				let k = ele.getAttribute("data-scroll-y");
				if(k in this.y){
					ele.scrollTop = this.y[k]
				}
			}
			this.y = null;
		}
	},
	*init(form){
		this.strage = yield* Flow.waitDbUnlock();
		let history = this.strage.select("ROW")
			.addTable("search_histories")
			.andWhere("location=?", form.getAttribute("action"))
			.setOrderBy("time DESC")
			.apply();

		let data, label;
		if(history != null){
			let obj = JSON.parse(history.json);
			data = obj.data;
			label = obj.label;
		}
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		
		yield* this.search(data);
		if(history != null){
			for(let input of form.elements){
				if(!input.hasAttribute("name")){
					continue;
				}
				let name = input.getAttribute("name");
				if((name in data) && (data[name].length > 0)){
					input.value = data[name].shift();
				}
			}
			let searchLabels = document.querySelectorAll('[data-search-label]');
			for(let i = searchLabels.length - 1; i >= 0; i--){
				let key = searchLabels[i].getAttribute("data-search-label");
				if(key in label){
					searchLabels[i].innerHTML = label[key];
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
		let csvKeys = [
			"code", "name", "kana", "short_name", "location_zip", "location_address1", "location_address2", "location_address3",
			"phone", "fax", "email", "homepage", "transactee", "transactee_honorific", "department", "managerial_position", "tax_round", "tax_processing",
			"close_processing", "close_date", "unit_price_type",
			"salse_with_ruled_lines", "delivery_with_ruled_lines", "receipt_with_ruled_lines", "invoice_with_ruled_lines",
			"receivables_balance", "note"
		];
		let csvData = masterData = this.response.select("ALL").addTable("clients").apply();
		csvData.unshift({
			code: "得意先コード",
			name: "得意先名",
			kana: "得意先名カナ",
			short_name: "得意先名称略",
			location_zip: "郵便番号",
			location_address1: "都道府県",
			location_address2: "市区町村・番地",
			location_address3: "建物名",
			phone: "電話番号",
			fax: "FAX",
			email: "メールアドレス",
			homepage: "ホームページ",
			transactee: "得意先担当者",
			transactee_honorific: "担当者敬称",
			department: "部署名",
			managerial_position: "役職名",
			tax_round: "税端数処理",
			tax_processing: "税処理",
			close_processing: "請求方法",
			close_date: "締日指定（28日以降は末日を選択）",
			unit_price_type: "単価種別",
			salse_with_ruled_lines: "売上伝票種別",
			delivery_with_ruled_lines: "納品書種別",
			receipt_with_ruled_lines: "受領書種別",
			invoice_with_ruled_lines: "請求書種別",
			receivables_balance: "期首売掛残高",
			note: "備考"
		});
		let blob = new Blob([
			new Uint8Array([0xef, 0xbb, 0xbf]),
			csvData.map(row => {
				let res = [];
				for(let k of csvKeys){
					let v = row[k];
					if(v == null){
						res.push("");
					}else if(typeof v === "string" && v.match(/[,"\r\n]/)){
						res.push(`"${v.split('"').join('""')}"`);
					}else{
						res.push(`${v}`);
					}
				}
				return res.join(",");
			}).join("\r\n")
		], {type: "text/csv"});
		document.getElementById("export").setAttribute("href", URL.createObjectURL(blob));
		
	},
	*search(parameter){
		let query = this.response.select("ALL")
			.addTable("clients");
		let searchObj = {
			code(q, v){
				if((v != null) && (v != "")){
					q.andWhere("code like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			},
			name(q, v){
				if((v != null) && (v != "")){
					let val = v.replace(/(?=[\\\%\_])/g, "\\");
					q.andWhere("((unique_name like '%' || ? || '%') OR (name like '%' || ? || '%') OR (kana like '%' || ? || '%') OR (short_name like '%' || ? || '%'))", val, val, val, val);
				}
			},
			phone(q, v){
				if((v != null) && (v != "")){
					q.andWhere("phone like '%' || ? || '%'", v.replace(/(?=[\\\%\_])/g, "\\"));
				}
			}
		};
		for(let k in parameter){
			if(k in searchObj){
				searchObj[k](query, ...parameter[k]);
			}
		}
		let table = query.apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
	}
});
{/literal}</script>
{/block}

{block name="tools"}
	<a class="btn btn-success" id="export" download="clients.csv">CSV出力</a>
	<a href="{url action="upload"}" class="btn btn-success me-5">CSV取込</a>
	<a href="{url action="create"}" class="btn btn-success">新しい得意先の追加</a>
{/block}

{block name="body"}
<form action="{url}" class="container border border-secondary rounded p-4 mb-5 bg-white"><fieldset class="row" disabled>
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="code-input">得意先コード</label>
				</th>
				<td>
					<div class="col-3">
						<input type="text" name="code" class="form-control" id="code-input" />
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="name-input">得意先名</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="name" class="form-control" id="name-input">
					</div>
				</td>
			</tr>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="phone-input">電話番号</label>
				</th>
				<td>
					<div class="col-10">
						<input type="text" name="phone" class="form-control" id="phone-input">
					</div>
				</td>
			</tr>
		</tbody>
	</table>
	<div class="col-12 text-center">
		<button type="submit" class="btn btn-success">検　索</button>
		<button type="reset" class="btn btn-outline-success">リセット</button>
	</div>
</fieldset></form>
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">得意先コード</th>
				<th class="w-20">得意先名</th>
				<th class="w-20">電話番号</th>
				<th class="w-20">部署名</th>
				<th class="w-10">得意先担当者名</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" assign="obj"}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>{$obj.department}</td>
				<td>{$obj.transactee}</td>
				<td>
					<a href="{url action="detail"}/{$obj.code}" class="btn btn-sm btn-info">詳細</a>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}