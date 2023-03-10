{block name="title"}操作履歴検索{/block}

{block name="body"}
<form action="{url action="list"}" class="container border border-secondary rounded p-4 mb-5 bg-white">
	<table class="table w-50">
		<tbody>
			<tr>
				<th scope="row" class="bg-light  align-middle ps-4">
					<label class="form-label ls-1" for="date-input">操作日付</label>
				</th>
				<td>
					<div class="col-5">
						<input type="date" name="date" class="form-control" id="date-input" />
					</div>
				</td>
			</tr>
		</tbody>
	</table>
	<div class="col-12 text-center">
		<button type="submit" class="btn btn-success">検　索</button>
	</div>
</form>
{/block}