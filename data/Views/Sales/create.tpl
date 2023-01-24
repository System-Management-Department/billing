{block name="title"}
<nav class="navbar navbar-light bg-light">
	<h2 class="container-fluid px-4">売上</h2>
</nav>
{/block}

{block name="styles" append}
<link rel="stylesheet" type="text/css" href="/assets/common/form.css" />
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/node_modules/co.min.js"></script>
<script type="text/javascript" src="/assets/common/CoForm.js"></script>
<script type="text/javascript">{literal}
document.addEventListener("DOMContentLoaded", function(e){
	co(new CoForm(document.querySelector('form'), "売上", "{/literal}{url action="regist"}{literal}", "{/literal}{url action="index"}{literal}", {}));
});
{/literal}</script>
{/block}


{block name="body"}
<form action="javascript:void(0)" method="POST" class="form-grid-12">
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">伝票番号<span class="badge bg-danger">必須</span></label>
		<input type="text" name="slip_number" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">売上日付<span class="badge bg-danger">必須</span></label>
		<input type="date" name="accounting_date" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">部門<span class="badge bg-danger">必須</span></label>
		<input type="text" name="division" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">チーム<span class="badge bg-danger">必須</span></label>
		<input type="text" name="team" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">当社担当者<span class="badge bg-danger">必須</span></label>
		<input type="text" name="manager" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">請求先<span class="badge bg-danger">必須</span></label>
		<input type="text" name="billing_destination" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">納品先<span class="badge bg-danger">必須</span></label>
		<input type="text" name="delivery_destination" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">件名<span class="badge bg-danger">必須</span></label>
		<input type="text" name="subject" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">備考<span class="badge bg-secondary">任意</span></label>
		<input type="text" name="note" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">摘要ヘッダー１<span class="badge bg-secondary">任意</span></label>
		<input type="text" name="header1" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">摘要ヘッダー２<span class="badge bg-secondary">任意</span></label>
		<input type="text" name="header2" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">摘要ヘッダー３<span class="badge bg-secondary">任意</span></label>
		<input type="text" name="header3" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">入金予定日<span class="badge bg-danger">必須</span></label>
		<input type="date" name="payment_date" id="e{counter skip=1}" class="form-control" placeholder="入力してください" autocomplete="off" />
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-6 grid-colreset">
		<label for="e{counter skip=0}" class="form-label d-flex gap-2">明細</label>
		<textarea name="detail" id="e{counter skip=1}" class="form-control" placeholder="入力してください"></textarea>
		<div class="invalid-feedback"></div>
	</div>
	<div class="grid-colspan-12 text-center">
		<button type="submit" class="btn btn-success rounded-pill w-25 d-inline-flex"><div class="flex-grow-1"></div>登録・更新<div class="flex-grow-1"></div></button>
	</div>
</form>
{/block}