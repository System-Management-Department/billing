class GoogleSheets{
	#url;#id;
	constructor(url, id){
		this.#url = url;
		this.#id = id;
	}
	getId(){
		return this.#id;
	}
	get(range){
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
				let ranges = [];
				if(Array.isArray(range)){
					for(let r of range){
						ranges.push(`ranges=${encodeURI(r)}`);
					}
				}else{
					ranges.push(`ranges=${encodeURI(range)}`);
				}
				return Promise.all([
					fetch(`https://sheets.googleapis.com/v4/spreadsheets/${this.#id}?${ranges.join("&")}&includeGridData=true&fields=namedRanges,sheets(properties,data.rowData.values(effectiveValue,effectiveFormat.textFormat,userEnteredFormat.numberFormat.type))`, {
						headers: headers
					}),
					fetch(`https://sheets.googleapis.com/v4/spreadsheets/${this.#id}?fields=sheets(properties)`, {
						headers: headers
					})
				]);
			}).then(res => Promise.all([res[0].json(), res[1].json()])).then(spreadsheets => {resolve(new GoogleSheetsBook(spreadsheets[0], spreadsheets[1]));}).catch(e => {reject(e);});
		});
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
				return fetch(`https://sheets.googleapis.com/v4/spreadsheets/${this.#id}?includeGridData=true&fields=namedRanges,sheets(properties,data.rowData.values(effectiveValue,effectiveFormat.textFormat,userEnteredFormat.numberFormat.type))`, {
					headers: headers
				});
			}).then(res => {
				if(res.status == 403){
					reject(res);
				}
				return res.json();
			}).then(spreadsheets => {resolve(new GoogleSheetsBook(spreadsheets));}).catch(e => {reject(e);});
		});
	}
	getRows(sheets){
		let ranges = [];
		for(let sheet in sheets){
			let rows = {};
			let rowList = sheets[sheet].slice(0).sort((a,b) => b - a);
			while(rowList.length > 0){
				let idx = rowList.pop();
				let prev = idx - 1;
				if(prev in rows){
					rows[idx] = rows[prev];
					delete rows[prev];
				}else{
					rows[idx] = idx;
				}
			}
			for(let iLast in rows){
				let iFirst = rows[iLast];
				ranges.push(`ranges=${encodeURI(sheet)}!${iFirst}:${iLast}`);
			}
		}
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
				return fetch(`https://sheets.googleapis.com/v4/spreadsheets/${this.#id}?${ranges.join("&")}&includeGridData=true&fields=sheets(properties,data.rowData.values(effectiveValue,effectiveFormat.textFormat,userEnteredFormat.numberFormat.type))`, {
					headers: headers
				});
			}).then(res => res.json()).then(range => {resolve(GoogleSheets.#rowValues(range));}).catch(e => {reject(e);});
		});
	}
	create(filename, sheets){
		return new Promise((resolve, reject) => {
			let sheetData = {};
			let headers = {};
			let user = "";
			for(let sheet of sheets){
				sheetData[sheet.properties.title] = sheet[GoogleSheets.updateSymbol];
			}
			fetch(this.#url).then(res => res.json()).then(jwt => {
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				user = jwt.iss;
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`, "Content-Type": "application/json"};
				return fetch(`https://sheets.googleapis.com/v4/spreadsheets/`, {
					headers: headers,
					method: "POST",
					body: JSON.stringify({properties:{title:filename,locale:"ja_JP",autoRecalc:"ON_CHANGE",timeZone:"Asia/Tokyo"},sheets:sheets})
				});
			}).then(res => {
				if(res.status == 403){
					reject(res);
				}
				return res.json();
			}).then(spreadsheets => {
				let book = new GoogleSheetsBook(spreadsheets);
				let requests = [];
				let requests2 = [];
				for(let sheet of book){
					if("namedRanges" in sheetData[sheet.name]){
						for(let name in sheetData[sheet.name].namedRanges){
							requests.push({
								addNamedRange: {
									namedRange: {
										name: name,
										range: Object.assign({sheetId:sheet.sheetId}, sheetData[sheet.name].namedRanges[name])
									}
								}
							});
						}
					}
					if("protectedRanges" in sheetData[sheet.name]){
						for(let range of sheetData[sheet.name].protectedRanges){
							requests.push({
								addProtectedRange: {
									protectedRange: {
										range: Object.assign({sheetId:sheet.sheetId}, range),
										editors: {users: [user]},
										requestingUserCanEdit: true
									}
								}
							});
						}
					}
					if("validationRanges" in sheetData[sheet.name]){
						for(let range of sheetData[sheet.name].validationRanges){
							range.range.sheetId = sheet.sheetId;
							requests2.push({
								setDataValidation: range
							});
						}
					}
					if("rows" in sheetData[sheet.name]){
						if("fillRows" in sheetData[sheet.name]){
							let rowData = {values: []};
							for(let i = 0; i < sheetData[sheet.name].columnCount; i++){
								rowData.values.push({userEnteredValue: {}});
							}
							sheetData[sheet.name].fillRows(rowData);
							for(let i = sheetData[sheet.name].rows.length; i < sheetData[sheet.name].rowCount; i++){
								sheetData[sheet.name].rows.push(rowData);
							}
						}
						requests.push({
							appendCells: {
								sheetId: sheet.sheetId,
								rows: sheetData[sheet.name].rows,
								fields: "*"
							}
						});
					}
				}
				return fetch(`https://sheets.googleapis.com/v4/spreadsheets/${spreadsheets.spreadsheetId}:batchUpdate`, {
					headers: headers,
					method: "POST",
					body: JSON.stringify({
						requests: requests.concat(requests2),
						includeSpreadsheetInResponse: false,
						responseIncludeGridData: false
					})
				});
			}).then(res => res.json()).then(spreadsheets => {
				resolve(spreadsheets);
			}).catch(e => {reject(e);});
		});
	}
	update(...request){
		return new Promise((resolve, reject) => {
			let requests = [];
			let headers = {};
			let now = {userEnteredValue: {numberValue: 0}};
			for(let sheets of request){
				if(sheets[GoogleSheets.requestSymbol] == "appendCells"){
					for(let sheet in sheets){
						requests.push({
							appendCells: {
								sheetId: sheet,
								rows: GoogleSheets.encodeRowData(sheets[sheet], now),
								fields: "*"
							}
						});
					}
				}else if(sheets[GoogleSheets.requestSymbol] == "updateCells"){
					for(let sheet in sheets){
						requests.push({
							updateCells: {
								start: {
									sheetId: sheet,
									rowIndex: sheets[sheet].rowIndex,
									columnIndex: sheets[sheet].columnIndex
								},
								rows: GoogleSheets.encodeRowData(sheets[sheet].rowData, now),
								fields: "*"
							}
						});
					}
				}else if(sheets[GoogleSheets.requestSymbol] == "updateNamedRange"){
					for(let sheet in sheets){
						for(let name in sheets[sheet]){
							requests.push({
								updateNamedRange: {
									namedRange: {
										namedRangeId: sheets[sheet][name].namedRangeId,
										name: name,
										range: {
											sheetId: sheet,
											startRowIndex: sheets[sheet][name].startRowIndex,
											endRowIndex: sheets[sheet][name].endRowIndex,
											startColumnIndex: sheets[sheet][name].startColumnIndex,
											endColumnIndex: sheets[sheet][name].endColumnIndex
										}
									},
									fields: "*"
								}
							});
						}
					}
					
				}
			}
			fetch(this.#url).then(res => res.json()).then(jwt => {
				now.userEnteredValue.numberValue = jwt.now;
				let formData = new FormData();
				formData.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
				formData.append("assertion", jwt.assertion);
				return fetch("https://oauth2.googleapis.com/token", {
					method: "POST",
					body: formData
				})
			}).then(res => res.json()).then(token => {
				headers = {Authorization: `Bearer ${token.access_token}`, "Content-Type": "application/json"};
				return fetch(`https://sheets.googleapis.com/v4/spreadsheets/${this.#id}:batchUpdate`, {
					headers: headers,
					method: "POST",
					body: JSON.stringify({
						requests: requests,
						includeSpreadsheetInResponse: false,
						responseIncludeGridData: false
					})
				});
			}).then(res => res.json()).then(result => {resolve(result);}).catch(e => {reject(e);});
		});
	}
	static #baseTime = new Date("1899-12-30T00:00:00.000").getTime();
	static formulaSymbol = Symbol("formula");
	static requestSymbol = Symbol("request");
	static updateSymbol = Symbol("update");
	static now = {};
	static formula(callSite, ...substitutions){
		return {[GoogleSheets.formulaSymbol]: String.raw(callSite, ...substitutions)};
	}
	static createSheetJson(properties, rowCount, columnCount, options = null){
		let json = {properties:Object.assign({sheetType:"GRID",gridProperties:{rowCount:rowCount,columnCount:columnCount}}, properties),[GoogleSheets.updateSymbol]:{}};
		if(options != null){
			if("namedRanges" in options){
				json[GoogleSheets.updateSymbol].namedRanges = options.namedRanges;
			}
			if("rows" in options){
				json[GoogleSheets.updateSymbol].rows = GoogleSheets.encodeRowData(options.rows);
			}
			if("fillRows" in options){
				json[GoogleSheets.updateSymbol].rowCount = rowCount;
				json[GoogleSheets.updateSymbol].columnCount = columnCount;
				json[GoogleSheets.updateSymbol].fillRows = options.fillRows;
			}
			if("protectedRanges" in options){
				json[GoogleSheets.updateSymbol].protectedRanges = options.protectedRanges;
			}
			if("validationRanges" in options){
				json[GoogleSheets.updateSymbol].validationRanges = options.validationRanges;
			}
			if("frozenRowCount" in options){
				json.properties.gridProperties.frozenRowCount = options.frozenRowCount;
			}
			if("frozenColumnCount" in options){
				json.properties.gridProperties.frozenColumnCount = options.frozenColumnCount;
			}
		}
		return json;
	}
	static encodeRowData(data, now){
		let rows = [];
		for(let row of data){
			let values = [];
			for(let column of row){
				let prop = null;
				let value = column;
				if(value == null){
					values.push({userEnteredValue: {}});
					continue;
				}else if(column == GoogleSheets.now){
					values.push(now);
					continue;
				}else if(typeof column === "number"){
					prop = "numberValue";
				}else if(typeof column === "boolean"){
					prop = "boolValue";
				}else if(typeof column === "string"){
					prop = "stringValue";
				}else if(GoogleSheets.formulaSymbol in column){
					value = `=${column[GoogleSheets.formulaSymbol]}`;
					prop = "formulaValue"
				}else{
					value = column.toString();
					prop = "stringValue"
				}
				values.push({userEnteredValue: {[prop]: value}});
			}
			rows.push({values: values});
		}
		return rows;
	}
	static decodeRowData(data, rowCount, columnCount){
		let range = new Array(rowCount);
		for(let r = 0; r < rowCount; r++){
			range[r] = new Array(columnCount);
			if((data.length <= r) || !("values" in data[r])){
				range[r].fill(null);
				continue;
			}
			for(let c = 0; c < columnCount; c++){
				if(data[r].values.length <= c){
					range[r].fill(null, c);
					break;
				}
				let cell = data[r].values[c];
				if(!("effectiveValue" in cell)){
					range[r][c] = null;
				}else if("stringValue" in cell.effectiveValue){
					range[r][c] = cell.effectiveValue.stringValue;
				}else if("numberValue" in cell.effectiveValue){
					if(("userEnteredFormat" in cell) && ("numberFormat" in cell.userEnteredFormat) && (cell.userEnteredFormat.numberFormat.type == "DATE_TIME" || cell.userEnteredFormat.numberFormat.type == "DATE")){
						range[r][c] = new Date(GoogleSheets.#baseTime + cell.effectiveValue.numberValue * 86400000);
					}else{
						range[r][c] = cell.effectiveValue.numberValue;
					}
				}else if("boolValue" in cell.effectiveValue){
					range[r][c] = cell.effectiveValue.boolValue;
				}else if("errorValue" in cell.effectiveValue){
					range[r][c] = cell.effectiveValue.errorValue.message;
				}
			}
		}
		return range;
	}
	static #rowValues(data){
		let res = {};
		for(let sheet of data.sheets){
			res[sheet.properties.title] = [];
			let prop = sheet.properties.gridProperties;
			if(!("data" in sheet)){
				sheet.data = [];
			}
			for(let dataItem of sheet.data){
				if(!("rowData" in dataItem)){
					continue;
				}
				res[sheet.properties.title] = res[sheet.properties.title].concat(GoogleSheets.decodeRowData(dataItem.rowData, dataItem.rowData.length, prop.columnCount));
			}
		}
		return res;
	}
}
class GoogleSheetsBook{
	#sheets;#sheetName;#namedRanges;
	/**
	 * @param {Object} spreadsheets https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets
	 */
	constructor(spreadsheets, info = null){
		this.#sheets = [];
		this.#sheetName = {};
		this.#namedRanges = {};
		for(let range of spreadsheets.namedRanges){
			this.#namedRanges[range.name] = range.namedRangeId;
		}
		for(let sheet of spreadsheets.sheets){
			this.#sheetName[sheet.properties.title] = this.#sheets.length;
			this.#sheets.push(new GoogleSheetsSheet(sheet));
		}
		if(info != null){
			for(let sheet of info.sheets){
				if(sheet.properties.title in this.#sheetName){
					continue;
				}
				this.#sheetName[sheet.properties.title] = this.#sheets.length;
				this.#sheets.push(new GoogleSheetsSheet(sheet));
			}
		}
	}
	*[Symbol.iterator](){
		yield* this.#sheets;
	}
	sheet(key){
		if(typeof key === "number"){
			return this.#sheets[key];
		}else{
			let idx = this.#sheetName[key];
			return this.#sheets[idx];
		}
	}
	getNamedRangeId(name){
		return this.#namedRanges[name];
	}
}
class GoogleSheetsSheet{
	/**
	 * @param {Object} sheet https://developers.google.com/sheets/api/reference/rest/v4/spreadsheets/sheets
	 */
	constructor(sheet){
		let prop = sheet.properties.gridProperties;
		this.name = sheet.properties.title;
		this.sheetId = sheet.properties.sheetId;
		if("data" in sheet){
			if("rowData" in sheet.data[0]){
				this.range = GoogleSheets.decodeRowData(sheet.data[0].rowData, prop.rowCount, prop.columnCount);
			}else{
				let fill = new Array(prop.columnCount).fill(null);
				this.range = new Array(prop.rowCount).fill(fill);
			}
		}
	}
}