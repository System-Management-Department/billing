{block name="scripts" append}
<script type="text/javascript">{literal}
(function(checkurl){
Promise.all([
	new Promise((resolve, reject) => {
		const channel = new MessageChannel();
		channel.port1.addEventListener("message", e => {
			const data = JSON.parse(e.data);
			const formData = new FormData();
			formData.append("email", data.email);
			formData.append("password", data.password);
			resolve(formData);
		});
		channel.port1.start();
		opener.postMessage("port", "*", [channel.port2]);
	}).then(formData => new Promise((resolve, reject) => {
		fetch(checkurl, {
			method: "POST",
			body: formData
		}).then(res => res.json()).then(resolve);
	})),
	new Promise((resolve, reject) => {
		document.addEventListener("DOMContentLoaded", e => {
			resolve(null);
		});
	})
]).then(result => {
	const main = document.getElementById("main");
	const [response, loaded] = result;
	for(let message of response.messages){
		const slot = document.createElement("span");
		slot.setAttribute("slot", "result");
		slot.textContent = message[0];
		main.appendChild(slot);
	}
});
})({/literal}"{url action="check2"}"{literal});
{/literal}</script>
{/block}


{block name="body"}
<div id="main">
<template shadowroot="closed">
<slot name="result">ユーザー認証をしています。お待ちください。</slot>
</template>
</div>
{/block}