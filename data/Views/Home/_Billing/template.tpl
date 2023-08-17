<template data-page="/Billing">
	<span slot="title" class="navbar-text text-dark">請求一覧表</span>
	<search-form slot="main" label="請求一覧検索"></search-form>
	<div slot="main"><button type="button">請求締め解除</button><button type="button">請求一覧表出力</button><button type="button">請求データ出力</button></div>
	<table-sticky slot="main" class="flex-grow-1 mx-5"></table-sticky>
</template>
