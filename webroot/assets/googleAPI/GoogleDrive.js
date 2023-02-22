class GoogleDrive{
	#url;
	constructor(url){
		this.#url = url;
	}
	getAll(){
		return new Promise((resolve, reject) => {
			let headers = {};
			fetch(this.#url).then(res => res.json()).then(jwt => {
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`};
				return fetch(`https://www.googleapis.com/drive/v2/files`, {
					headers: headers
				});
			}).then(res => res.json()).then(dirve => {
				for(let item of dirve.items){
					if("properties" in item){
						let properties = {};
						for(let prop of item.properties){
							properties[prop.key] = prop.value;
						}
						item.properties = properties;
					}else{
						item.properties = {};
					}
				}
				resolve(dirve);
			}).catch(e => {reject(e);});
		});
	}
	delete(id){
		return new Promise((resolve, reject) => {
			let headers = {};
			fetch(this.#url).then(res => res.json()).then(jwt => {
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`};
				return fetch(`https://www.googleapis.com/drive/v2/files/${id}`, {
					method: "DELETE",
					headers: headers
				});
			}).then(res => res.text()).then(text => {resolve(text);}).catch(e => {reject(e);});
		});
	}
	createPermission(id){
		return new Promise((resolve, reject) => {
			let headers = {};
			fetch(this.#url).then(res => res.json()).then(jwt => {
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`, "Content-Type": "application/json"};
				return fetch(`https://www.googleapis.com/drive/v2/files/${id}/permissions`, {
					headers: headers,
					method: "POST",
					body: JSON.stringify({
						role: "writer",
						type: "domain",
						value: "direct-holdings.co.jp"
					})
				});
			}).then(res => res.json()).then(dirve => {resolve(dirve);}).catch(e => {reject(e);});
		});
	}
	setProperty(id, properties){
		return new Promise((resolve, reject) => {
			let headers = {};
			fetch(this.#url).then(res => res.json()).then(jwt => {
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`, "Content-Type": "application/json"};
				return fetch(`https://www.googleapis.com/drive/v3/files/${id}`, {
					headers: headers,
					method: "PATCH",
					body: JSON.stringify({
						properties: properties
					})
				});
			}).then(res => res.json()).then(dirve => {resolve(dirve);}).catch(e => {reject(e);});
		});
	}
}