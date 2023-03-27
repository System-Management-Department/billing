{block name="title"}得意先CSV取込{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/common/CSVTokenizer.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	dbDownloadURL: "{url controller="Default" action="master"}",
	success: "{url action="index"}",{literal}
	template: null,
	response: new SQLite(),
	*[Symbol.iterator](){
		this.template = new Template();
		let fileElement = document.getElementById("file-input");
		let tbody = document.getElementById("list");
		let form = document.querySelector('form');
		let submitBtn = form.querySelector('button[type="submit"]');
		let reader = new FileReader();
		const buffer = yield fetch(this.dbDownloadURL).then(response => response.arrayBuffer());
		let pObj = {};
		
		fileElement.addEventListener("change", e => {
			if(fileElement.files.length > 0){
				reader.readAsText(fileElement.files[0]);
			}
		});
		reader.addEventListener("load", e => {
			let data = CSVTokenizer.parse(reader.result.replace(/\r\n?/mg, "\n"));
			this.response.import(buffer, "list");
			this.response.createTable("csv", [
				"code","name"
			], data.slice(1));
			let table = this.response.select("ALL")
				.setTable("csv")
				.apply();
			tbody.innerHTML = table.map(row => this.template.listItem(row)).join("");
			submitBtn.disabled = false;
		});
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			
			let formData = new FormData();
			let table = this.response.select("ALL")
				.setTable("csv")
				.apply();
			formData.append("json", JSON.stringify(table));
			pObj.resolve(formData);
		});
		
		do{
			let res = yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
			if(res instanceof FormData){
				submitBtn.disabled = true;
				let response = yield fetch(form.getAttribute("action"), {
					method: form.getAttribute("method"),
					body: res
				}).then(res => res.json());
				if(response.success){
					// メッセージをpushしてリダイレクト
					for(let message of response.messages){
						Flow.DB.insertSet("messages", {title: "商品カテゴリーCSV取込", message: message[0], type: message[1], name: message[2]}, {}).apply();
					}
					Flow.DB.commit().then(res => { location.href = this.success; });
				}
				submitBtn.disabled = false;
			}
			
		}while(true);
	}
});
{/literal}</script>
{/block}

{block name="body"}
<div class="container border border-secondary rounded p-4 mb-5 bg-white">
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light align-middle ps-4">
					<label class="form-label ls-1" for="file-input">CSVファイル選択</label>
				</th>
				<td>
					<div class="col-3">
						<input type="file" class="form-control" id="file-input" />
					</div>
				</td>
			</tr>
		</tbody>
	</table>
</div>
<form action="{url action="import"}" method="POST">
	<div class="container border border-secondary rounded p-4 bg-white table-responsive">
		<table class="table table_sticky_list text-nowrap">
			<thead>
				<tr>
					<th>カテゴリーコード</th>
					<th>カテゴリー名</th>
				</tr>
			</thead>
			<tbody id="list">{predefine name="listItem" assign="obj"}
				<tr>
					<td>{$obj.code}</td>
					<td>{$obj.name}</td>
				</tr>
			{/predefine}</tbody>
		</table>
	</div>
	<div class="grid-colspan-12 text-center mt-3">
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex" disabled><div class="flex-grow-1"></div>取込<div class="flex-grow-1"></div></button>
	</div>
</form>
{/block}