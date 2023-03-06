{block name="scripts" append}
<script type="text/javascript" src="/assets/googleAPI/GoogleDrive.js"></script>
<script type="text/javascript">{literal}
Flow.start({{/literal}
	jwt: "{url controller="JWT" action="drive"}",{literal}
	*[Symbol.iterator](){
		this.gd = new GoogleDrive(this.jwt);
		const obj = yield this.gd.getAll("properties+has+{key='access'+and+value='billing'}");
		const select = document.querySelector('select[name="id"]');
		for(let item of obj.files){
			let option = Object.assign(document.createElement("option"), {textContent: item.name});
			option.setAttribute("value", item.id);
			select.appendChild(option);
		}
	}
});
{/literal}</script>
{/block}


{block name="body"}
<div class="container">
	<div class="row row-cols-3 g-4">
	
		<form action="{url controller="Drive" action="index"}" method="GET" class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">売上データ取り込み</h5>
					<p class="card-text">ヨミ表に売上チェック入力がされているものを売上データとして取り込みます</p>
					<div class="input-group">
						<select name="id" class="form-select"><option value="">選択</option></select>
						<button type="submit" class="btn btn-success">取り込み開始</button>
					</div>
				</div>
			</div>
		</form>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">売上データ登録</h5>
					<p class="card-text">売上データを登録します</p>
					<a href="{url controller="Sales" action="create"}" class="btn btn-success">登録・実行</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">売上データ一覧</h5>
					<p class="card-text">売上データを検索・一覧表示します</p>
					<a href="{url controller="Sales" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
	</div>
</div>
{/block}