<template data-page="/Unbilling">
	<span slot="title" class="navbar-text text-dark">未請求一覧表</span>
	<search-form slot="main" label="未請求一覧検索"></search-form>
	<div slot="main" class="d-flex flex-row justify-content-end mx-5 gap-2"><button type="button" class="btn btn-success" data-proc="marge">合算請求書（明細）作成</button><button type="button" class="btn btn-success" data-proc="aggregation">合算請求書（集計）作成</button></div>
	<div slot="main" class="flex-grow-1 mx-5 overflow-auto"><div data-grid="/Unbilling#list"></div></div>
</template>
