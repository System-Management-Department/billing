document.addEventListener('DOMContentLoaded', function(e){
	let form = document.querySelector('form[data-form][data-form-success]');
	form.addEventListener("submit", e => {
		e.stopPropagation();
		e.preventDefault();
		let formData = new FormData(form);
		
		fetch(form.getAttribute("action"), {
			method: form.getAttribute("method"),
			body: formData
		}).then(res => res.json()).then(json => {
			if(json.success){
				Storage.pushToast(form.getAttribute("data-form"), json.messages);
				location.href = form.getAttribute("data-form-success");
			}else{
				let messages = json.messages.reduce((a, message) => {
					if(message[1] == 2){
						a[message[2]] = message[0];
					}
					return a;
				}, {});
				let inputs = form.querySelectorAll('[name],[data-form-name]');
				for(let input of inputs){
					let name = input.hasAttribute("name") ? input.getAttribute("name") : input.getAttribute("data-form-name");
					if(name in messages){
						input.classList.add("is-invalid");
						input.parentNode.querySelector('.invalid-feedback').textContent = messages[name];
					}else{
						input.classList.remove("is-invalid");
					}
				}
			}
		});
	});
});
