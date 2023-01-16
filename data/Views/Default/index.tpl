{block name="styles" append}
<style type="text/css">{literal}
body{
	min-height: 100vh;
	background: var(--bs-light, white);
}
.card{
	width: 320px;
}
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/bootstrap/js/bootstrap.bundle.min.js"></script>
<script type="text/javascript">{literal}
document.addEventListener("DOMContentLoaded", function(){
	const form = document.querySelector('form');
	form.addEventListener("submit", e => {
		e.stopPropagation();
		e.preventDefault();
		let formData = new FormData(form);
		let expires = new Date();
		
		if(document.querySelector('form input[type="checkbox"]:checked') == null){
			expires.setFullYear(expires.getFullYear() - 1);
			document.cookie = `session=0;expires=${expires.toUTCString()}`;
		}else{
			expires.setFullYear(expires.getFullYear() + 1);
			document.cookie = `session=1;expires=${expires.toUTCString()}`;
		}
		fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: formData,
		}).then(res => res.json()).then(json => {
			if(json.success){
				location.reload();
			}else{
				alert(json.messages.reduce((a, msg) => {
					a.push(msg[0]);
					return a;
				}, []).join("\n"));
			}
		});
	});
	new bootstrap.Tooltip(document.querySelector('[data-bs-toggle="tooltip"]'));
});
{/literal}</script>
{/block}

{block name="body"}
<main class="text-center pt-5">
	<div class="text-start card mt-5 mx-auto py-3 px-3">
		<form action="{url action="login"}" method="POST" class="card-body row pb-0">
			<label class="col-12">メールアドレス</label>
			<div class="col-12"><input name="email" type="text" class="form-control" /></div>
			
			<label class="col-12 mt-3">パスワード</label>
			<div class="col-12"><input name="password" type="text" class="form-control" style="-webkit-text-security:disc;" /></div>
			
			<div class="col-12 mt-3 text-center">
				<div class="form-check d-inline-block">
					<input class="form-check-input" type="checkbox" id="checkbox">
					<label class="form-check-label" for="checkbox">ログイン状態を保持する</label>
				</div>
			</div>
			<div class="text-center col-12 my-3"><button type="submit" class="btn btn-success">ログイン</button></div>
		</form>
		<a href="https://docs.google.com/forms/d/e/1FAIpQLSdCVYDHCOvqlJ9ppIw_OUuZogt-LJS4T6fZFXzFaisd5UCbfw/viewform?vc=0&c=0&w=1&flr=0" class="btn text-decoration-underline">パスワードを忘れた方はこちら</a>
	</div>
	<div class="mt-5">推奨ブラウザ：GoogleChrome</div>
</main>
{/block}