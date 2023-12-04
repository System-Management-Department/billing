class CSVSerializer{
	constructor(modifier = null){
		this.modifier = modifier;
		this.delimiter = ",";
		this.separator = "\r\n";
		this.quotChar = "\"";
		let s = `${this.delimiter}${this.separator}${this.quotChar}`;
		let r = "";
		for(let i = s.length - 1; i >= 0; i--){
			let ch = (s.charCodeAt(i) | 0x0100).toString(16).slice(-2);
			r += `\\x${ch}`;
		}
		this.quotPattern = new RegExp(`[${r}]`);
		this.header = null;
		this.converter = null;
		this.validator = null;
		this.filter = null;
	}
	setHeader(values){
		this.header = values;
		return this;
	}
	setConverter(converter){
		this.converter = converter;
		return this;
	}
	setValidator(validator){
		this.validator = validator;
		return this;
	}
	setFilter(filter){
		this.filter = filter;
		return this;
	}
	serializeToString(values){
		let row = 0, col;
		let res = [], rowData;
		if(this.header != null){
			rowData = [];
			for(let value of this.header){
				let val = `${value}`;
				if(val.match(this.quotPattern)){
					val = `"${val.split(this.quotChar).join(this.quotChar + this.quotChar)}"`;
				}
				rowData.push(val);
			}
			res.push(rowData.join(this.delimiter));
		}
		for(let data of values){
			col = 0;
			rowData = [];
			for(let value of data){
				let val = (this.modifier == null) ? value : this.modifier.apply(this, [value, col, row]);
				val = (val == null) ? "" : `${val}`;
				if(val.match(this.quotPattern)){
					val = `"${val.split(this.quotChar).join(this.quotChar + this.quotChar)}"`;
				}
				rowData.push(val);
				col++;
			}
			if((this.filter == null) || this.filter.apply(this, [rowData])){
				res.push(rowData.join(this.delimiter));
				row++;
			}
		}
		const csvStr = res.join(this.separator);
		if(this.converter == null){
			return csvStr;
		}
		if(this.validator != null){
			this.validator.apply(this, [csvStr]);
		}
		return this.converter.apply(this, [csvStr]);
	}
}