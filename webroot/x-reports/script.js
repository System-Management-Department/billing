document.addEventListener("DOMContentLoaded", function(e){
	let elementList = [];
	const anchor = e => {
		location.replace(e.currentTarget.getAttribute("data-href"));
	};
	const fileOpen = e => {
		open(e.currentTarget.getAttribute("data-href"));
	};
	const filter = e => {
		if(e.currentTarget.hasAttribute("data-filter")){
			const icons = Array.from(document.querySelectorAll('[data-href]'));
			for(let a of icons){
				const href = a.getAttribute("data-href");
				if(href.match(/^\/Upload\/info|\/$/)){
					continue;
				}
				a.hidden = false;
			}
			e.currentTarget.removeAttribute("data-filter");
		}else{
			fetch(e.currentTarget.getAttribute("data-href")).then(res => res.json()).then(res => {
				const icons = Array.from(document.querySelectorAll('[data-href]'));
				for(let a of icons){
					const href = a.getAttribute("data-href");
					if(href.match(/^\/Upload\/info|\/$/)){
						continue;
					}
					const filename = href.split("/").pop();
					a.hidden = !(res.includes(filename));
				}
			});
			e.currentTarget.setAttribute("data-filter", "on");
		}
	};
	const anchorElements = document.querySelectorAll('a[href]');
	const n = anchorElements.length;
	for(let i = 0; i < n; i++){
		const href = anchorElements[i].pathname;
		if((location.pathname.length >= href.length) || (anchorElements[i].search != "") || (href.indexOf("/.") >= 0)){
			continue;
		}
		const a = document.createElement("div");
		a.setAttribute("data-href", href);
		if(href.match(/\/$/)){
			a.addEventListener("click", anchor);
		}else if(href.match(/\/info\.csv$/)){
			a.setAttribute("data-href", `/Upload/info${href}`);
			a.addEventListener("click", filter);
			a.textContent = "マイフィルタ";
			elementList.unshift(a);
			continue;
		}else{
			a.addEventListener("click", fileOpen);
		}
		a.textContent = anchorElements[i].textContent.replace(/^[\s\/]|[\s/]$/g, "");
		elementList.push(a);
	}
	let pos = -1;
	let name = "フォルダ";
	if((pos = location.pathname.indexOf("/x-reports/estimate/")) >= 0){
		pos += 19;
		name = "見積書フォルダ";
	}else if((pos = location.pathname.indexOf("/x-reports/sales/")) >= 0){
		pos += 16;
		name = "売上一覧表フォルダ";
	}else if((pos = location.pathname.indexOf("/x-reports/billing/")) >= 0){
		pos += 18;
		name = "請求一覧表フォルダ";
	}else if((pos = location.pathname.indexOf("/x-reports/purchase/")) >= 0){
		pos += 19;
		name = "仕入一覧表フォルダ";
	}
	document.body.innerHTML = "";
	fetch("/x-reports/header.html").then(res => res.text()).then(html => {
		const parser = new DOMParser();
		const doc = parser.parseFromString(html, "text/html");
		const body = doc.querySelector("body");
		document.body.innerHTML = body.innerHTML;
		document.body.className = body.className;
		const title = document.getElementById("title");
		const main = document.querySelector("main");
		title.textContent = name + location.pathname.substring(pos);
		if(location.pathname.length - pos > 1){
			const a = document.createElement("div");
			a.setAttribute("data-href", "../");
			a.addEventListener("click", anchor);
			main.appendChild(a);
		}
		for(let a of elementList){
			main.appendChild(a);
		}
	});
});