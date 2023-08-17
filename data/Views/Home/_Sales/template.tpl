<template data-page="/Sales">
	<span slot="title" class="navbar-text text-dark">売上一覧表</span>
	<search-form slot="main" label="売上一覧検索"></search-form>
	<div slot="main"><button type="button">請求締め</button><button type="button">売上一覧表出力</button></div>
	<table-sticky slot="main" class="flex-grow-1 mx-5"></table-sticky>
</template>
