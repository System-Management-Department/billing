{block name="body"}
<div class="container">
	<div class="row row-cols-3 g-4">
	
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">請求データ検索</h5>
					<p class="card-text"></p>
					<a href="{url controller="Billing" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">請求締データ検索</h5>
					<p class="card-text"></p>
					<a href="{url controller="Billing" action="closedIndex"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-4">
					<h5 class="card-title">請求データ再出力検索</h5>
					<p class="card-text"></p>
					<a href="{url controller="Billing" action="closedIndex2"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
	</div>
</div>
{/block}