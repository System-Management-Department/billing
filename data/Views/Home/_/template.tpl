<template data-page="/">
	<span slot="title" class="navbar-text text-dark">ホーム</span>
	<a slot="tools" class="btn btn-success my-2" href="/exment/admin/" style="order: 1;">マスター管理</a>
	<show-dialog slot="tools" class="btn btn-success my-2" target="salses_export" style="order: 2;">売上一覧表出力</show-dialog>
	<main slot="main" class="d-contents">
		<div class="d-flex mx-5 gap-5">
			<div>
				<div class="card mb-4">
					<div class="card-header">見積書フォーム選択</div>
					<div class="card-body d-flex flex-column gap-3">
						<div data-estimate="1" class="input-group">
							<div class="btn py-2 text-white shadow-sm" style="width:120px;background:#008db5;">見積書1</div>
							<form-control class="btn btn-light ps-4 py-2 flex-grow-1 text-center shadow-sm" type="label" list="invoice_format">1</form-control>
						</div>
						<div data-estimate="2" class="input-group">
							<div class="btn py-2 text-white shadow-sm" style="width:120px;background:#008db5;">見積書2</div>
							<form-control class="btn btn-light ps-4 py-2 flex-grow-1 text-center shadow-sm" type="label" list="invoice_format">2</form-control>
						</div>
						<div data-estimate="3" class="input-group">
							<div class="btn py-2 text-white shadow-sm" style="width:120px;background:#008db5;">見積書3</div>
							<form-control class="btn btn-light ps-4 py-2 flex-grow-1 text-center shadow-sm" type="label" list="invoice_format">3</form-control>
						</div>
						<div data-estimate="4" class="input-group">
							<div class="btn py-2 text-white shadow-sm" style="width:120px;background:#008db5;">見積書4</div>
							<form-control class="btn btn-light ps-4 py-2 flex-grow-1 text-center shadow-sm" type="label" list="invoice_format">4</form-control>
						</div>
						<div data-estimate="5" class="input-group">
							<div class="btn py-2 text-white shadow-sm" style="width:120px;background:#008db5;">見積書5</div>
							<form-control class="btn btn-light ps-4 py-2 flex-grow-1 text-center shadow-sm" type="label" list="invoice_format">5</form-control>
						</div>
						<show-dialog target="estimate" class="btn btn-success">一時保存された見積一覧</show-dialog>
					</div>
				</div>
			</div>
			<div class="card flex-grow-1">
				<div class="card-header">売上・請求管理</div>
				<div class="card-body d-flex flex-column gap-3 pt-0">
					<table class="table my-0 text-center align-middle"><tbody>
						<tr class="table-info">
							<td><page-link href="/Committed" class="btn btn-info shadow">確定一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>確定案件の確認</div>
								<div>確定案件の修正</div>
								<div>売上の承認</div>
								<div>確定一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-info shadow" href="/x-reports/estimate/">見積書フォルダ</a></td>
						</tr>
						<tr class="table-success">
							<td><page-link href="/Sales" class="btn btn-success shadow">売上一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>売上案件の確認</div>
								<div>売上承認の解除</div>
								<div>請求締めの実施</div>
								<div>売上一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-success shadow" href="/x-reports/sales/">売上一覧表フォルダ</a></td>
						</tr>
						<tr class="table-warning">
							<td><page-link href="/Billing" class="btn btn-warning shadow">請求一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>請求案件の確認</div>
								<div>請求締め解除の実施</div>
								<div>請求一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-warning shadow" href="/x-reports/billing/">請求一覧表フォルダ</a></td>
						</tr>
						<tr class="table-danger">
							<td><page-link href="/Purchase" class="btn btn-danger shadow">仕入一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>仕入情報の確認</div>
								<div>仕入情報の追記・登録</div>
								<div>請求書受領確認</div>
								<div>仕入一覧表の印刷</div>
							</div></td>
							<td><a class="btn btn-danger shadow" href="/x-reports/purchase/">仕入一覧表フォルダ</a></td>
						</tr>
						<tr class="table-secondary">
							<td><page-link href="/RedSlip" class="btn btn-secondary shadow">赤伝一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>赤伝情報の確認</div>
							</div></td>
							<td></td>
						</tr>
						<tr class="table-primary">
							<td><page-link href="/Unbilling" class="btn btn-primary shadow">未請求一覧表</page-link></td>
							<td><div class="flex-grow-1 text-center">
								<div>未請求案件の確認</div>
								<div>合算請求書の登録</div>
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
