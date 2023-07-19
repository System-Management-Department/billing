{block name="title"}ホーム{/block}
{block name="styles" append}
<style type="text/css">
.table{
	border-collapse: separate;
	border-spacing: 0 1rem;
}
.table td{
	border-bottom-width: 1px;
	border-top-width: 1px;
}
.table td:first-child{
	border-left-width: 1px;
	border-radius: var(--bs-card-inner-border-radius) 0 0 var(--bs-card-inner-border-radius);
}
.table td:last-child{
	border-right-width: 1px;
	border-radius: 0 var(--bs-card-inner-border-radius) var(--bs-card-inner-border-radius) 0;
}
</style>
{/block}
{block name="body"}
<div class="mb-5">
	<div class="d-flex mx-5 gap-5">
		<div class="card">
			<div class="card-header">見積書フォーム選択</div>
			<div class="card-body d-flex flex-column gap-3">
				{foreach from=[]|invoiceFormat item="format" key="key"}
				<div class="d-flex gap-3">
					<div style="width:120px;height:40px;line-height:40px;text-align:center;color:white;background:#008db5;">見積書{$key}</div>
					<div class="flex-grow-1 text-center">{$format}</div>
				</div>
				{/foreach}
			</div>
		</div>
		<div class="card flex-grow-1">
			<div class="card-header">売上・請求管理</div>
			<div class="card-body d-flex flex-column gap-3 pt-0">
				<table class="table my-0 text-center align-middle"><tbody>
					<tr class="table-info">
						<td><a href="{url controller="Committed" action="index"}" class="btn btn-info">確定一覧表</a></td>
						<td><div class="flex-grow-1 text-center">
						<div>確定案件の確認</div>
						<div>確定案件の修正</div>
						<div>売上の承認</div>
						<div>確定一覧表の印刷</div>
					</div></td>
						<td><a class="btn btn-info">見積書フォルダ</a></td>
					</tr>
					<tr class="table-success">
						<td><a href="{url controller="Sales" action="index"}" class="btn btn-info">売上一覧表</a></td>
						<td><div class="flex-grow-1 text-center">
						<div>売上案件の確認</div>
						<div>売上承認の解除</div>
						<div>請求締めの実施</div>
						<div>売上一覧表の印刷</div>
					</div></td>
						<td><a class="btn btn-info">売上一覧表フォルダ</a></td>
					</tr>
					<tr class="table-warning">
						<td><a href="{url controller="Billing" action="index"}" class="btn btn-info">請求一覧表</a></td>
						<td><div class="flex-grow-1 text-center">
						<div>請求案件の確認</div>
						<div>請求締め解除の実施</div>
						<div>請求一覧表の印刷</div>
					</div></td>
						<td><a class="btn btn-info">請求一覧表フォルダ</a></td>
					</tr>
				</tbody></table>
			</div>
		</div>
	</div>
</div>
<div>
<div class="card mx-5">
	<div class="card-header">マスター管理</div>
	<div class="card-body">
		<a class="btn btn-info">管理画面</a>
	</div>
</div>
</div>
{/block}