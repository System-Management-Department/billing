<template data-page="/Purchase">
	<span slot="title" class="navbar-text text-dark">仕入一覧表</span>
	<search-form slot="main" label="仕入一覧検索"></search-form>
	<div slot="main" class="d-flex flex-row justify-content-end mx-5 gap-2"><button type="button" class="btn btn-success">仕入一覧表出力</button></div>
	<table-sticky slot="main" class="flex-grow-1 mx-5"></table-sticky>
</template>
