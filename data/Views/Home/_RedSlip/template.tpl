<template data-page="/RedSlip">
	<span slot="title" class="navbar-text text-dark">赤伝一覧表</span>
	<search-form slot="main" label="赤伝一覧検索"></search-form>
	<div slot="main" class="flex-grow-1 mx-5 overflow-auto"><div data-grid="/RedSlip#list"></div></div>
</template>
