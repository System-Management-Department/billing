<template data-page="/Sales">
	<span slot="title" class="navbar-text text-dark">売上一覧表</span>
	<search-form slot="main" label="売上一覧検索"></search-form>
	<div slot="main" class="d-flex flex-row justify-content-end mx-5 gap-2"><button type="button" class="btn btn-success" data-proc="close">請求締め</button><button type="button" class="btn btn-success" data-proc="export">売上一覧表出力</button></div>
	<div slot="main" class="flex-grow-1 mx-5 overflow-auto"><div data-grid="/Sales#list"></div></div>
</template>
