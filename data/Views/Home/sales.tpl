{block name="body"}
<div class="container">
	<div class="row row-cols-3 g-4">
	
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">売上入力</h5>
					<p class="card-text">売上入力を行います</p>
					<a href="{url action="salesInput"}" class="btn btn-success">売上入力へ</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">売上伝票出力</h5>
					<p class="card-text">売上伝票を出力します</p>
					<a href="{url controller="SalesOutput" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">請求処理</h5>
					<p class="card-text">請求書作成に必要なデータを出力します</p>
					<a href="{url action="billing"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
	</div>
</div>
{/block}