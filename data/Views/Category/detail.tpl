{block name="title"}商品カテゴリー編集画面{/block}

{block name="scripts" append}
<script type="text/javascript">{literal}
Flow.start({{/literal}
	deleteUrl: "{url action="delete"}",
	success: "{url action="index"}",{literal}
	*[Symbol.iterator](){
		let deleteBtn = document.querySelector('[data-delete]');
		let pObj = {};
		
		deleteBtn.addEventListener("click", e => {
			pObj.resolve(null);
		});
		
		yield new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let formData = new FormData();
		formData.append("id", deleteBtn.getAttribute("data-delete"));
		fetch(this.deleteUrl, {
			method: "POST",
			body: formData
		})
		.then(response => response.json())
		.then(response => {
			if(response.success){
				// フォーム送信 成功
				for(let message of response.messages){
					Flow.DB.insertSet("messages", {title: "商品カテゴリー削除", message: message[0], type: message[1], name: message[2]}, {}).apply();
				}
				Flow.DB.commit().then(res => { location.href = this.success; });
			}
		});
		
	}
});
{/literal}</script>
{/block}

{block name="tools"}
<a href="{url action="edit" id="*"}" class="btn btn-success">編集</a>
<button type="button" class="btn btn-danger" data-bs-toggle="modal" data-bs-target="#deleteModal">削除</button>
{/block}

{block name="body"}
<form action="{url action="edit" id=$data.code}" method="POST" class="form-grid-12">
	<div class="container border border-secondary rounded p-4 mb-5 bg-white">
		<div class="row">
			<table class="table w-50">
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="code-input">カテゴリーコード</label>
					</th>
					<td>
						<div class="col-3">{$data.code|escape:"html"}</div>
					</td>
				</tr>
				<tr>
					<th scope="row" class="bg-light align-middle ps-4">
						<label class="form-label ls-1" for="name-input">カテゴリー名</label>
					</th>
					<td>
						<div class="col-10">{$data.name|escape:"html"}</div>
					</td>
				</tr>
			</table>
		</div>
	</div>
</form>
{/block}

{block name="dialogs"}
<div class="modal fade" id="deleteModal" tabindex="-1">
	<div class="modal-dialog modal-dialog-centered modal-lg">
		<div class="modal-content">
			<div class="modal-header flex-row">
				<div class="text-center text-danger">本当に削除しますか？</div><i class="bi bi-x" data-bs-dismiss="modal"></i>
			</div>
			<div class="modal-body"></div>
			<div class="modal-footer justify-content-evenly">
				<button type="button" class="btn btn-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal" data-delete="{$data.code}"><div class="flex-grow-1"></div>はい<div class="flex-grow-1"></div></button>
				<button type="button" class="btn btn-outline-success rounded-pill w-25 d-inline-flex" data-bs-dismiss="modal"><div class="flex-grow-1"></div>いいえ<div class="flex-grow-1"></div></button>
			</div>
		</div>
	</div>
</div>
{/block}
