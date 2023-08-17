<template data-page="/">
	<span slot="title" class="navbar-text text-dark">ホーム</span>
	<a slot="tools" class="btn btn-success my-2" href="/exment/admin/" style="order: 1;">マスター管理</a>
	<main slot="main" class="d-contents">
		<div class="d-flex mx-5 gap-5">
			<div>
				<div class="card mb-4">
					<div class="card-header">見積書フォーム選択</div>
					<div class="card-body d-flex flex-column gap-3">
						<a href="/form.html" class="d-flex gap-3">
							<div style="width:120px;height:40px;line-height:40px;text-align:center;color:white;background:#008db5;">見積書1</div>
							<div class="flex-grow-1 text-center"><form-control type="label" list="invoice_format">1</form-control></div>
						</a>
						<a href="/form.html" class="d-flex gap-3">
							<div style="width:120px;height:40px;line-height:40px;text-align:center;color:white;background:#008db5;">見積書2</div>
							<div class="flex-grow-1 text-center"><form-control type="label" list="invoice_format">2</form-control></div>
						</a>
						<a href="/form.html" class="d-flex gap-3">
							<div style="width:120px;height:40px;line-height:40px;text-align:center;color:white;background:#008db5;">見積書3</div>
							<div class="flex-grow-1 text-center"><form-control type="label" list="invoice_format">3</form-control></div>
						</a>
						<a href="/form.html" class="d-flex gap-3">
							<div style="width:120px;height:40px;line-height:40px;text-align:center;color:white;background:#008db5;">見積書4</div>
							<div class="flex-grow-1 text-center"><form-control type="label" list="invoice_format">4</form-control></div>
						</a>
					</div>
				</div>
				<div class="card">
					<div class="card-header">赤伝票登録</div>
					<div class="card-body d-flex flex-column gap-3">
						<span>売上伝票</span>
						<span>仕入伝票</span>
					</div>
				</div>
			</div>
			<div class="card flex-grow-1">
				<div class="card-header">売上・請求管理</div>
				<div class="card-body d-flex flex-column gap-3 pt-0">
					<table class="table my-0 text-center align-middle"><tbody>
						<tr class="table-info">
							<td><page-link href="/Committed" class="btn btn-info">確定一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>確定案件の確認</div>
								<div>確定案件の修正</div>
								<div>売上の承認</div>
								<div>確定一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-info" href="/x-reports/estimate/">見積書フォルダ</a></td>
						</tr>
						<tr class="table-success">
							<td><page-link href="/Sales" class="btn btn-info">売上一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>売上案件の確認</div>
								<div>売上承認の解除</div>
								<div>請求締めの実施</div>
								<div>売上一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-info" href="/x-reports/sales/">売上一覧表フォルダ</a></td>
						</tr>
						<tr class="table-warning">
							<td><page-link href="/Billing" class="btn btn-info">請求一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>請求案件の確認</div>
								<div>請求締め解除の実施</div>
								<div>請求一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-info" href="/x-reports/billing/">請求一覧表フォルダ</a></td>
						</tr>
						<tr class="table-danger">
							<td><page-link href="/Purchase" class="btn btn-info">仕入一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>仕入情報の確認</div>
								<div>仕入情報の追記・登録</div>
								<div>請求書受領確認</div>
								<div>仕入一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-info" href="/x-reports/purchase/">仕入一覧表フォルダ</a></td>
						</tr>
						<tr class="table-dark">
							<td><page-link href="/Purchase" class="btn btn-info">買掛減損一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
							</div></td>
							<td></td>
						</tr>
					</tbody></table>
				</div>
			</div>
		</div>
		<div></div>
	</main>
</template>
