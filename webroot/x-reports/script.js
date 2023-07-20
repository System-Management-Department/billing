document.addEventListener("DOMContentLoaded", function(e){
	let elementList = [];
	const anchorElements = document.querySelectorAll('a[href]');
	const n = anchorElements.length;
	for(let i = 0; i < n; i++){
		const href = anchorElements[i].pathname;
		if((location.pathname.length >= href.length) || (anchorElements[i].search != "") || (href.indexOf("/.") >= 0)){
			continue;
		}
		const a = document.createElement("a");
		a.setAttribute("href", href);
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
		for(let a of elementList){
			main.appendChild(a);
		}
	});
});