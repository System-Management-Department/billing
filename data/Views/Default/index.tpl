{block name="styles" append}
<style type="text/css">{literal}
html,
body {
  height: 100%;
}

body {
  display: flex;
  align-items: center;
  padding-top: 40px;
  padding-bottom: 40px;
  background-color: #f5f5f5;
}

.form-signin {
  width: 100%;
  max-width: 330px;
  padding: 15px;
  margin: auto;
}

.form-signin .checkbox {
  font-weight: 400;
}

.form-signin .form-floating:focus-within {
  z-index: 2;
}

.form-signin input[type="email"] {
  margin-bottom: -1px;
  border-bottom-right-radius: 0;
  border-bottom-left-radius: 0;
}

.form-signin input[type="password"] {
  margin-bottom: 10px;
  border-top-left-radius: 0;
  border-top-right-radius: 0;
}
  .bd-placeholder-img {
    font-size: 1.125rem;
    text-anchor: middle;
    -webkit-user-select: none;
    -moz-user-select: none;
    user-select: none;
  }

  @media (min-width: 768px) {
    .bd-placeholder-img-lg {
      font-size: 3.5rem;
    }
  }
{/literal}</style>
{/block}

{block name="scripts" append}
<script type="text/javascript" src="/assets/bootstrap/js/bootstrap.bundle.min.js"></script>
{jsiife token=$token}{literal}
const search = location.search.replace(/^\?/, "").split("&").reduce((a, t) => {
	const found = t.match(/^(.*?)=(.*)$/);
	if(found){
		a[found[1]] = decodeURIComponent(found[2]);
	}
	return a;
},{});
if("code" in search){
	let modal = null;
	formData = new FormData();
	for(k in token.body){
		formData.append(k, token.body[k]);
	}
	formData.append("code", search.code);
	Promise.all([
		new Promise((resolve, reject) => {
			document.addEventListener("DOMContentLoaded", e => {
				modal = new bootstrap.Modal(document.querySelector('.modal'), {});
				modal.show();
				resolve(null);
			})
		}),
		fetch(token.url, {
			method: "POST",
			body: formData
		}).then(res => res.json())
	]).then(data => fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
		method: "GET",
		headers: {
			Authorization: `Bearer ${data[1].access_token}`
		}
	})).then(res => res.json())
	.then(data => {
		formData = new FormData();
		formData.append("email", data.email);
		return fetch("/Default/login", {
			method: "POST",
			body: formData
		});
	}).then(res => res.json())
	.then(v => {location.reload();});
}else{
	document.addEventListener("DOMContentLoaded", function(e){
		const chromeVersion = /Chrome\/([\d.]+)/.exec(navigator.userAgent);
		if(chromeVersion){
			const version = chromeVersion[1];
			console.log(`Chrome バージョン: ${version}`);
		}else{
			const btn = document.querySelector('[data-id="btn-login"]');
			btn.setAttribute("title", navigator.userAgent);
			btn.style.opacity = "0.5";
		}
	});
}
{/literal}{/jsiife}
{/block}

{block name="body"}
<main class="form-signin">
	<form class="text-center">
		<img class="mb-4" src="/assets/common/image/signin_logo.png" alt="" width="72" height="57">
		<h1 class="h3 mb-3 fw-normal">販売管理システム</h1>
		<a href="{$oauth}" class="btn btn-success" data-id="btn-login">ログイン</a>
		<p class="mt-5 mb-3 text-muted">&copy; Direct-holdings 2023</p>
	</form>
</main>
<div class="modal" tabindex="-1">
	<div class="modal-dialog">
		<div class="modal-content">
			<div class="modal-header">
				<h5 class="modal-title">ログイン</h5>
			</div>
			<div class="modal-body">
				<div>ログイン処理を行っています。</div>
				<div>画面が切り替わるまでお待ちください。</div>
			</div>
		</div>
	</div>
</div>
{/block}