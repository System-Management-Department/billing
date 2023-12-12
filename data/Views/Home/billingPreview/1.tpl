{block name="css"}{literal}
<style type="text/css">
print-page{
	position: relative;
	padding: calc(14.14px / 0.75);
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
}
table{
	border-collapse: collapse;
}
th{
	font-weight: normal;
	background: lightgrey;
}
td,th{
	border: solid black calc(1em / 12);
}
.grid1{
	display: grid;
	grid-template: auto / 1fr calc(260px / 0.75);
}
.sample{
	position: absolute;
	top: calc(14.14px / 0.75);
	left: calc(30px / 0.75);
	color: red;
	font-size: calc(30px / 0.75);
	line-height: 1;
	border: solid red calc(1.5em / 12);
	border-radius: 0.4em;
	padding: 0.2em 1.5em;
	opacity: 0.5;
}
.flex-end{
	display: flex;
	flex-direction: row;
	justify-content: end;
}
.w100{
	width: 100%;
}
.h40{
	height: calc(40px / 0.75);
}
.col30{
	width: calc(30px / 0.75);
}
.col50{
	width: calc(50px / 0.75);
}
.col55{
	width: calc(55px / 0.75);
}
.col70{
	width: calc(70px / 0.75);
}
.col80{
	width: calc(80px / 0.75);
}
.col150{
	width: calc(150px / 0.75);
}
.col362{
	width: calc(362px / 0.75);
}
.f9{
	font-size: calc(9px / 0.75);
}
.f10{
	font-size: calc(10px / 0.75);
}
.f11{
	font-size: calc(11px / 0.75);
}
.f12{
	font-size: calc(12px / 0.75);
}
.border1{
	border: solid black calc(1em / 12);
}
[data-table][data-field]:empty::before{
	content: "{" attr(data-table) "." attr(data-field) "}";
	color: red;
}
[data-table="帳票（明細）"][data-field]:empty::before{
	content: none;
}
[data-description="ヘッダーエリア"]{
	display: flex;
	flex-direction: column;
	align-items: flex-end;
	font-size: calc(10px / 0.75);
}
[data-description="見出し"]{
	display: contents;
}
[data-description="見出しエリア1"]{
	font-size: calc(11px / 0.75);
}
[data-description="見出しエリア2"]{
	font-size: calc(10px / 0.75);
}
[data-description="タイトル"]{
	background: lightgrey;
	width: calc(143px / 0.75);
	margin-bottom: calc(40px / 0.75);
	font-size: calc(15px / 0.75);
}
[data-description="フッター"]{
	flex-grow: 1;
	display: grid;
	flex-direction: column;
	align-items: end;
	font-size: calc(10px / 0.75);
}
</style>
{/literal}{/block}

{block name="preview"}{literal}
<section data-description="ヘッダー" data-clone="clone">
	<div class="sample">見本</div>
	<div data-description="ヘッダーエリア">
		<div><span data-table="帳票（見出し）" data-field="請求日"></span></div>
		<div>No.<span data-table="帳票（見出し）" data-field="帳票No"></span></div>
		<div>登録番号：T8011001070263</div>
	</div>
</section>

<section data-description="見出し">
	<div class="grid1">
		<div>
			<div data-description="見出しエリア1">
				<div>〒<span data-table="顧客" data-field="郵便番号"></span></div>
				<div><span data-table="顧客" data-field="住所1"></span></div>
				<div><span data-table="顧客" data-field="住所2"></span></div>
				<div><span data-table="顧客" data-field="顧客名"></span> <span data-table="顧客" data-field="敬称"></span></div>
				<div><span data-table="顧客" data-field="部署名"></span> <span data-table="顧客" data-field="敬称"></span></div>
				<div><span data-table="顧客" data-field="担当者名"></span> <span data-table="顧客" data-field="敬称"></span></div>
			</div>
		</div>
		<div>
			<div data-description="タイトル" class="text-center">請求書</div>
			<div data-description="見出しエリア2">
				<div>株式会社ダイレクト・ホールディングス</div>
				<div><span data-table="帳票（見出し）" data-field="担当者氏名"></span></div>
				<div>〒163-1439</div>
				<div>東京都新宿区西新宿3-20-2 東京オペラシティタワー39階</div>
				<div>TEL：03-6416-4822(代表)</div>
				<div>＜振込先＞</div>
				<div><span data-table="顧客" data-field="振込先金融機関"></span>　<span data-table="顧客" data-field="振込先金融機関支店"></span>　<span data-table="顧客" data-field="口座種別"></span>　<span data-table="顧客" data-field="口座番号"></span></div>
				<div>名義：株式会社ダイレクト・ホールディングス</div>
				<div>支払期限：<span data-table="帳票（見出し）" data-field="支払期限"></span></div>
			</div>
		</div>
	</div>

	<div>
		<table class="w100 f12">
			<thead>
				<tr>
					<th>件名</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td><span data-table="帳票（見出し）" data-field="件名"></span></td>
				</tr>
			</tbody>
		</table>
	</div>

	<div class="flex-end">
		<table class="f12">
			<colgroup>
				<col class="col80"></col>
				<col class="col150"></col>
			</colgroup>
			<thead>
				<tr class="text-center">
					<th>消費税(10%)</th>
					<th>合計金額</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td class="text-end">\<span data-table="帳票（見出し）" data-field="消費税" data-format="price"></span>-</td>
					<td class="text-end">\<span data-table="帳票（見出し）" data-field="合計金額" data-format="price"></span>-（税込）</td>
				</tr>
			</tbody>
		</table>
	</div>
</section>

<section data-description="明細">
	<table class="w100">
			<colgroup data-clone="clone">
				<col class="col362"></col>
				<col class="col55"></col>
				<col class="col30"></col>
				<col class="col50"></col>
				<col class="col70"></col>
			</colgroup>
			<thead class="f11" data-clone="clone">
				<tr class="text-center">
					<th>摘要</th>
					<th>数量</th>
					<th>単位</th>
					<th>単価</th>
					<th>金額</th>
				</tr>
			</thead>
			<tbody class="f9" data-iterator="帳票（明細）">
				<tr data-page-break="break">
					<td><span data-table="帳票（明細）" data-field="摘要"></span></td>
					<td class="text-end"><span data-table="帳票（明細）" data-field="明細数量(文字列)"></span></td>
					<td class="text-center"><span data-table="帳票（明細）" data-field="単位"></span></td>
					<td class="text-end"><span data-table="帳票（明細）" data-field="明細単価(文字列)"></span></td>
					<td class="text-end"><span data-table="帳票（明細）" data-field="明細金額" data-format="price"></span></td>
				</tr>
			</tbody>
			<tbody>
				<tr data-page-break="break">
					<td colspan="4" class="f10">上記計（税抜）</td>
					<td class="f9 text-end"><span data-table="帳票（明細）" data-field="明細金額" data-format="price"></span></td>
				</tr>
			</tbody>
	</table>
</section>

<section data-description="フッター">
	<div class="border1 h40" data-page-break="break">
		<div>仕様</div>
		<div><span data-table="帳票（見出し）" data-field="備考(見出し)"></span></div>
	</div>
</section>
{/literal}{/block}