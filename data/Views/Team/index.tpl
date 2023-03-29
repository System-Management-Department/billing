{block name="title"}チーム一覧{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/list.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/encoding.js/encoding.min.js"></script>
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
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		this.response.import(buffer, "list");
		
		yield* this.search();
		let csvKeys = [
			"code", "name", "kana", "location_zip", "location_address1", "location_address2", "location_address3", "phone", "fax", "note"
		];
		let csvData = masterData = this.response.select("ALL").addTable("teams").apply();
		csvData.unshift({
			code: "チームコード",
			name: "チーム名",
			kana: "チーム名カナ",
			location_zip: "郵便番号",
			location_address1: "都道府県",
			location_address2: "市区町村・番地",
			location_address3: "建物名",
			phone: "電話番号",
			fax: "FAX",
			note: "備考",
		});
		let blob = new Blob(this.blobData(
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
			}).join("\r\n"),
			"SJIS"
		), {type: "text/csv"});
		document.getElementById("export").setAttribute("href", URL.createObjectURL(blob));
		
	},
	*search(){
		let query = this.response.select("ALL")
			.addTable("teams");
		let table = query.apply();
		document.getElementById("list").innerHTML = table.map(row => this.template.listItem(row)).join("");
	},
	blobData(data, to = null){
		if(to == null){
			return [new Uint8Array([0xef, 0xbb, 0xbf]), data];
		}else{
			return [new Uint8Array(Encoding.convert(Encoding.stringToCode(data), {to: to, from: "UNICODE"}))];
		}
	}
});
{/literal}</script>
{/block}

{block name="tools"}
	<a class="btn btn-success" id="export" download="teams.csv">CSV出力</a>
	<a href="{url action="upload"}" class="btn btn-success me-5">CSV取込</a>
	<a href="{url action="create"}" class="btn btn-success">新しいチームの追加</a>
{/block}

{block name="body"}
<div class="container border border-secondary rounded p-4 bg-white table-responsive">
	<table class="table table_sticky_list">
		<thead>
			<tr>
				<th class="w-10">チームコード</th>
				<th class="w-20">チーム名</th>
				<th class="w-20">電話番号</th>
				<th></th>
			</tr>
		</thead>
		<tbody id="list">{predefine name="listItem" assign="obj"}
			<tr>
				<td>{$obj.code}</td>
				<td>{$obj.name}</td>
				<td>{$obj.phone}</td>
				<td>
					<a href="{url action="detail"}/{$obj.code}" class="btn btn-sm btn-info">詳細</a>
				</td>
			</tr>
		{/predefine}</tbody>
	</table>
</div>
{/block}