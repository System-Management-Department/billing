document.addEventListener("DOMContentLoaded", function(){
	let form = document.getElementById("deleteModal");
	if(form != null){
		let deleteMap = new Map();
		let headers = [];
		let deleteModal = e => {
			let dataList = deleteMap.get(e.currentTarget);
			let body = form.querySelector('.modal-body');
			body.innerHTML = "";
			let n = headers.length;
			for(let i = 0; i < n; i++){
				let header = document.createElement("div");
				let data = document.createElement("div");
				header.textContent = headers[i];
				data.textContent = dataList[i];
				if(i > 0){
					header.setAttribute("class", "fw-bold small mt-3");
				}else{
					header.setAttribute("class", "fw-bold small");
				}
				data.setAttribute("class", "mx-3");
				body.appendChild(header);
				body.appendChild(data);
			}
			form.querySelector('[name="id"]').value = e.currentTarget.getAttribute("data-id");
		};
		let rows = document.querySelectorAll('[data-bs-target="#deleteModal"]');
		for(let row of rows){
			let dataList = [];
			deleteMap.set(row, dataList);
			row.addEventListener("click", deleteModal);
		}
		
		form.addEventListener("submit", e => {
			e.stopPropagation();
			e.preventDefault();
			let formData = new FormData(form);
			
			fetch(form.getAttribute("action"), {
				method: form.getAttribute("method"),
				body: formData
			}).then(res => res.json()).then(json => {
				if(json.success){
					Storage.pushToast(form.getAttribute("data-master"), json.messages);
					location.reload()
				}else{
				}
			});
		});
	}
});