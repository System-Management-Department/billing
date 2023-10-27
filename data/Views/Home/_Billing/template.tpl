<template data-page="/Billing">
	<span slot="title" class="navbar-text text-dark">請求一覧表</span>
	<search-form slot="main" label="請求一覧検索"></search-form>
	<div slot="main" class="d-flex flex-row justify-content-end mx-5 gap-2"><show-dialog target="release" class="btn btn-success">請求締め解除</show-dialog><button type="button" class="btn btn-success" data-proc="export2">請求一覧表出力</button><button type="button" class="btn btn-success" data-proc="export">請求データ出力</button></div>
	<div slot="main" class="flex-grow-1 mx-5 overflow-auto"><div data-grid="/Billing#list"></div></div>
</template>
