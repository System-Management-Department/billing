class PrintHtml{
	#size; #width; #height; #document; #body; #sheet;
	constructor(size = "A4", orientation = "P", dpi = 600, padding = 50){
		const o = (orientation == "P") ? {w: "s", h: "l"} : {w: "l", h: "s"};
		this.#size = [size.toLocaleLowerCase(), orientation.toLocaleLowerCase()];
		this.#width = Math.round(PrintHtml.paperSizes[size][o.w] * dpi);
		this.#height = Math.round(PrintHtml.paperSizes[size][o.h] * dpi);
		this.#document = PrintHtml.parser.parseFromString(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0,0,${this.#width},${this.#height}"><foreignObject x="0" y="0" width="${this.#width}" height="${this.#height}"><body xmlns="http://www.w3.org/1999/xhtml"><style type="text/css"><![CDATA[ :root{ --rate: calc(${dpi} / 72); font-size: calc(11px * var(--rate)); } body{ padding: calc(${padding}px * var(--rate)); height: 100vh; box-sizing: border-box; } ]]></style></body></foreignObject></svg>`, "application/xml");
		this.#body = this.#document.querySelector("body");
		this.#sheet = this.#document.querySelector("style").sheet;
	}
	get canvas(){
		let cssText = [];
		const n = this.#sheet.cssRules.length;
		for(let i = 0; i < n; i++){
			cssText.push(this.#sheet.cssRules[i].cssText);
		}
		this.#document.querySelector("style").firstChild.nodeValue = cssText.join(" ");
		const canvas = Object.assign(document.createElement("canvas"), {width: this.#width, height: this.#height});
		const blob = new Blob([PrintHtml.serializer.serializeToString(this.#document)], {type: "image/svg+xml"});
		const img = Object.assign(new Image, {
			onload: () => {
				canvas.getContext("2d").drawImage(img, 0, 0, this.#width, this.#height);
				URL.revokeObjectURL(img.src);
			},
			src: URL.createObjectURL(blob)
		});
		return canvas;
	}
	get body(){
		return this.#body;
	}
	printPdf(doc){
		return new Promise((resolve, reject) => {
			let cssText = [];
			const n = this.#sheet.cssRules.length;
			for(let i = 0; i < n; i++){
				cssText.push(this.#sheet.cssRules[i].cssText);
			}
			this.#document.querySelector("style").firstChild.nodeValue = cssText.join(" ");
			const canvas = Object.assign(document.createElement("canvas"), {width: this.#width, height: this.#height});
			const img = Object.assign(new Image, {
				crossOrigin: "Anonymous",
				src: `data:image/svg+xml;charset=utf-8,${encodeURIComponent(PrintHtml.serializer.serializeToString(this.#document))}`,
				onload: () => {
					canvas.getContext("2d").drawImage(img, 0, 0, this.#width, this.#height);
					resolve(canvas.toDataURL("image/png"));
				}
			});
		}).then(dataURL => new Promise((resolve, reject) => {
			doc.addPage(...this.#size);
			const pdfWidth = doc.internal.pageSize.getWidth();
			const pdfHeight = (this.#height * pdfWidth) / this.#width;
			doc.addImage(dataURL, "PNG", 0, 0, pdfWidth, pdfHeight);
			resolve(doc);
		}));
	}
	createElement(tagName, ...props){
		const element = this.#document.createElementNS("http://www.w3.org/1999/xhtml", tagName);
		if(props.length > 1){
			Object.assign(element, props[1]);
		}
		if((props.length > 0) && (props[0] != null)){
			for(let attr in props[0]){
				element.setAttribute(attr, props[0][attr]);
			}
		}
		return element;
	}
	addStyle(selector, style){
		const i = this.#sheet.cssRules.length;
		this.#sheet.insertRule(`${selector}{}`, i);
		Object.assign(this.#sheet.cssRules[i].style, style);
		return this;
	}
	static printPdfAll(htmlList){
		const doc = new jspdf.jsPDF();
		let p = Promise.all([]);
		for(let item of htmlList){
			p = p.then(() => item.printPdf(doc));
		}
		return p.then(() => new Promise((resolve, reject) => {
			doc.deletePage(1);
			resolve(doc.output("blob"));
		}));
	}
	static parser = new DOMParser();
	static serializer = new XMLSerializer();
	static paperSizes = {
		["A4"]: { s: 8.27,  l: 11.69 },
		["A5"]: { s: 5.845, l:  8.27 },
		["B5"]: { s: 6.93,  l:  9.84 },
	};
}