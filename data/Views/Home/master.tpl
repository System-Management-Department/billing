{block name="body"}
<div class="container">
	<div class="row row-cols-4 g-4">
	
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">基本情報登録</h5>
					<p class="card-text">会社の基本情報を登録します</p>
					<a href="{url controller="BasicInfo" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">部門マスター登録</h5>
					<p class="card-text">部門マスターを登録します</p>
					<a href="{url controller="Division" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">チームマスター登録</h5>
					<p class="card-text">チームを登録します</p>
					<a href="{url controller="Team" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>

		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">担当者マスター登録</h5>
					<p class="card-text">担当者を登録します</p>
					<a href="{url controller="Manager" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">入金区分マスター登録</h5>
					<p class="card-text">入金区分を登録します</p>
					<a href="{url controller="PaymentCategory" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">摘要マスター登録</h5>
					<p class="card-text">請求書の摘要を登録します</p>
					<a href="{url controller="Summary" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">得意先クライアントマスター登録</h5>
					<p class="card-text">得意先クライアントを登録します</p>
					<a href="{url controller="Client" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">請求先（納品先）マスター登録</h5>
					<p class="card-text">請求先を登録します</p>
					<a href="{url controller="ApplyClient" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">商品カテゴリマスター登録</h5>
					<p class="card-text">商品カテゴリを登録します</p>
					<a href="{url controller="Category" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
		<div class="col">
			<div class="card h-100">
				<div class="card-body p-3">
					<h5 class="card-title">商品マスター登録</h5>
					<p class="card-text">商品を登録します</p>
					<a href="{url controller="Category" action="index"}" class="btn btn-success">実行する</a>
				</div>
			</div>
		</div>
		
	</div>
</div>
{/block}