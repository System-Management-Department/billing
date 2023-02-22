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
<main class="form-signin">
	<form action="{url action="login"}" method="POST" class="text-center">
		<img class="mb-4" src="img/signin_logo.png" alt="" width="72" height="57">
		<h1 class="h3 mb-3 fw-normal">販売管理システム</h1>
		<div class="form-floating">
			<input type="email" name="email" class="form-control" placeholder="name@example.com">
			<label for="floatingInput">Email address</label>
		</div>
		<div class="form-floating">
		  <input type="password" name="password" class="form-control" placeholder="Password">
		  <label for="floatingPassword">Password</label>
		</div>
		<div class="checkbox mb-3">
			<label>
				<input type="checkbox" id="checkbox" /> Remember me
			</label>
		</div>
		<button type="submit" class="btn btn-success">ログイン</button>
		<p class="mt-5 mb-3 text-muted">&copy; Direct-holdings 2023</p>
	</form>
</main>
{/block}