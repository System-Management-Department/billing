class GridGenerator{
	static #container = {};
	static referenceAttribute = "data-grid";
	static resizeAttribute = "data-grid-width";
	static freezeVar = "--freeze";
	static widthVar = "--grid-width";
	static emptyImage = new Image(1, 1);
	static cellSelector = ':scope>*:first-child>*,:scope>*:nth-child(n + 2)';
	static resizeEvent = {
		handleEvent(e){
			this[`${e.type}Event`](e);
		},
		dragstartEvent(e){
			const container = e.target.parentNode;
			this.targetLabel = container;
			this.widthIndex = container.getAttribute(GridGenerator.resizeAttribute);
			this.targetGrid = e.currentTarget;
			e.dataTransfer.effectAllowed = "move";
			e.dataTransfer.setDragImage(GridGenerator.emptyImage, 0, 0);
		},
		dragendEvent(e){
			this.targetLabel = null;
			this.widthIndex = null;
			this.targetGrid = null;
		},
		dragenterEvent(e){
			if(e.target == this.targetGrid){
				const rect = this.targetLabel.getBoundingClientRect();
				const x = e.clientX - rect.left;
				this.targetGrid.style.setProperty(`${GridGenerator.widthVar}${this.widthIndex}`, `${x}px`);
				e.preventDefault();
			}
		},
		dragoverEvent(e){
			if(e.composedPath().includes(this.targetGrid)){
				const rect = this.targetLabel.getBoundingClientRect();
				const x = e.clientX - rect.left;
				this.targetGrid.style.setProperty(`${GridGenerator.widthVar}${this.widthIndex}`, `${x}px`);
				e.preventDefault();
			}
		},
		dragleaveEvent(e){
			if(e.target == this.targetGrid){
				this.targetGrid.style.removeProperty(`${GridGenerator.widthVar}${this.widthIndex}`);
			}
		},
		dropEvent(e){
			this.targetLabel = null;
			this.widthIndex = null;
			this.targetGrid = null;
		},
		gridSet: new WeakSet(),
		targetLabel: null,
		widthIndex: null,
		targetGrid: null
	};
	static wrap(item, w, width){
		if(w){
			return item;
		}
		const cell = document.createElement("div");
		cell.classList.add("gcell");
		if(width == "auto"){
			cell.classList.add("gcell-auto");
		}
		cell.appendChild(item);
		return cell;
	}
	static define(name, options, columns, callback = null){
		const pattern = /<.*?>/g;
		const attrPattern = /([a-zA-Z0-9\-]+)="((?:[^<]|<.*?>)*?)"/g;
		const text = document.createElement("span");
		const matchArr = (str, reg) => {
			const matches = str.match(reg);
			return (matches == null) ? [] : matches;
		};
		const gc = Array.from(columns).map((col, i) => {
			const textRaw = [{raw: col.text.split(pattern).map(str => Object.assign(text, {innerHTML: str}).textContent)}].concat(matchArr(col.text, pattern).map(s => s.slice(1, -1)));
			const attrRaw = {};
			const tokens = matchArr(col.attributes, attrPattern);
			for(let token of tokens){
				const pos = token.indexOf("=");
				const value = token.slice(pos + 2, -1);
				attrRaw[token.slice(0, pos)] = [{raw: value.split(pattern).map(str => Object.assign(text, {innerHTML: str}).textContent)}].concat(matchArr(value, pattern).map(s => s.slice(1, -1)));
			}
			return Object.assign({}, col, {
				freeze: i < options.freeze,
				text: data => String.raw(...textRaw.map((t, i) => (i == 0) ? t : (((t in data) && (data[t] != null)) ? data[t] : ""))),
				attributes: data => {
					const res = {};
					for(let k in attrRaw){
						res[k] = String.raw(...attrRaw[k].map((t, i) => (i == 0) ? t : (((t in data) && (data[t] != null)) ? data[t] : "")))
					}
					return res;
				},
				class_list: (col.class_list == null) ? [] : col.class_list.split(/\s/).filter(v => v != "")
			});
		});
		const ggo = {
			init: grid => {
				const range = document.createRange();
				const ghead = document.createElement("div");
				const ghf = document.createElement("div");
				const gtc = [];
				let i = 0;
				
				range.selectNodeContents(grid);
				range.deleteContents();
				ghead.appendChild(ghf);
				for(let col of gc){
					if(col.width == "auto"){
						(col.freeze ? ghf : ghead).appendChild(Object.assign(document.createElement("div"), {textContent: col.label}));
						gtc.push("auto");
					}else{
						const div = document.createElement("div");
						const resizer = document.createElement("div");
						
						resizer.draggable = true;
						div.setAttribute(GridGenerator.resizeAttribute, i);
						div.appendChild(Object.assign(document.createElement("div"), {textContent: col.label}));
						div.appendChild(resizer);
						(col.freeze ? ghf : ghead).appendChild(div);
						gtc.push(`var(${GridGenerator.widthVar}${i}, ${col.width})`);
						i++;
					}
				}
				grid.style.gridTemplateColumns = gtc.join(" ");
				grid.style.setProperty(GridGenerator.freezeVar, options.freeze);
				if(!GridGenerator.resizeEvent.gridSet.has(grid)){
					GridGenerator.resizeEvent.gridSet.add(grid);
					grid.addEventListener("dragstart", GridGenerator.resizeEvent);
					grid.addEventListener("dragend", GridGenerator.resizeEvent);
					grid.addEventListener("dragenter", GridGenerator.resizeEvent);
					grid.addEventListener("dragover", GridGenerator.resizeEvent);
					grid.addEventListener("dragleave", GridGenerator.resizeEvent);
					grid.addEventListener("drop", GridGenerator.resizeEvent);
				}
				grid.appendChild(ghead);
			},
			build: data => {
				const gbody = document.createElement("div");
				const gbf = document.createElement("div");
				const items = {};
				
				gbody.appendChild(gbf);
				for(let col of gc){
					const item = document.createElement(col.tag_name);
					const attrs = col.attributes(data);
					item.textContent = col.text(data);
					for(let k in attrs){
						item.setAttribute(k, attrs[k]);
					}
					for(let c of col.class_list){
						item.classList.add(c);
					}
					items[col.slot] = item;
					
					(col.freeze ? gbf : gbody).appendChild(GridGenerator.wrap(item, col.cell, col.width));
				}
				if(ggo.callback != null){
					ggo.callback(gbody, data, items);
				}
				return gbody;
			},
			getSlot: index => gc[index].slot,
			callback: callback
		};
		GridGenerator.#container[name] = ggo;
	}
	static init(grid){
		const name = grid.getAttribute(GridGenerator.referenceAttribute);
		if(name in GridGenerator.#container){
			GridGenerator.#container[name].init(grid);
		}
	}
	static createTable(grid, table){
		const name = grid.getAttribute(GridGenerator.referenceAttribute);
		const range = document.createRange();
		const fragment = document.createDocumentFragment();
		for(let data of table){
			fragment.appendChild(GridGenerator.#container[name].build(data));
		}
		range.selectNodeContents(grid);
		range.setStartAfter(grid.querySelector('*'));
		range.deleteContents();
		grid.appendChild(fragment);
	}
	static createRows(grid, dataList){
		const name = grid.getAttribute(GridGenerator.referenceAttribute);
		const fragment = document.createDocumentFragment();
		for(let data of dataList){
			fragment.appendChild(GridGenerator.#container[name].build(data));
		}
		return fragment;
	}
	static getInfo(node){
		let grid = null;
		let row = null;
		let cell = node;
		for(row = node; row != null; cell = row, row = row.parentNode){
			if(GridGenerator.resizeEvent.gridSet.has(row.parentNode)){
				grid = row.parentNode;
				break;
			}
		}
		if(grid == null){
			return null;
		}
		if(cell == row){
			cell = null;
		}
		
		const name = grid.getAttribute(GridGenerator.referenceAttribute);
		let cells = Array.from(row.querySelectorAll(GridGenerator.cellSelector));
		const columnIndex = (cell == null) ? null : cells.indexOf(cell);
		const slot = (cell == null) ? null : GridGenerator.#container[name].getSlot(columnIndex);
		const prev = ((cell == null) || (columnIndex == 0)) ? null : cells[columnIndex - 1];
		const next = ((cell == null) || (cells.length - columnIndex > 1)) ? null : cells[columnIndex + 1];
		
		cells = ((row.previousElementSibling == null) || (row.previousElementSibling == grid.firstElementChild)) ? null : Array.from(row.previousElementSibling.querySelectorAll(GridGenerator.cellSelector));
		const prevRow = ((cell == null) || (cells == null)) ? null : cells[columnIndex];
		
		cells = ((row.nextElementSibling == null) || (row == grid.firstElementChild)) ? null : Array.from(row.nextElementSibling.querySelectorAll(GridGenerator.cellSelector));
		const nextRow = ((cell == null) || (cells == null)) ? null : cells[columnIndex];
		
		return {grid, row, cell, columnIndex, slot, prev, next, prevRow, nextRow};
	}
}