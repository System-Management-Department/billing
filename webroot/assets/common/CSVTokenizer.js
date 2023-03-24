class CSVTokenizer{
	static parse(str){
		let i = 0;
		let n = str.length;
		let obj = {
			state: "init",
			c: null,
			d: (n < 1) ? CSVTokenizer.eof : str.charAt(0),
			value: [],
			record: [],
			sb: ""
		};
		do{
			i++;
			CSVTokenizer[obj.state](Object.assign(obj, {
				c: obj.d,
				d: (n <= i) ? CSVTokenizer.eof : str.charAt(i)
			}));
		}while(obj.c != CSVTokenizer.eof);
		return obj.value;
	}
	static init(obj){
		if(obj.c == CSVTokenizer.eof){
			if(obj.record.length > 0 || obj.sb != ""){
				obj.record.push(obj.sb);
				obj.value.push(obj.record);
			}
			return obj;
		}
		if(obj.c == CSVTokenizer.separator){
			obj.value.push(obj.record);
			return Object.assign(obj, {record: []});
		}
		if(obj.c == CSVTokenizer.delimiter){
			obj.record.push("");
			return obj;
		}
		if(obj.c == CSVTokenizer.quotChar){
			return Object.assign(obj, {state: "quot", sb: ""});
		}
		return Object.assign(obj, {state: "noQuot", sb: obj.c});
	}
	static noQuot(obj){
		if(obj.c == CSVTokenizer.eof){
			obj.record.push(obj.sb);
			obj.value.push(obj.record);
			return obj;
		}
		if(obj.c == CSVTokenizer.separator){
			obj.record.push(obj.sb);
			obj.value.push(obj.record);
			return Object.assign(obj, {state: "init", record: [], sb: ""});
		}
		if(obj.c == CSVTokenizer.delimiter){
			obj.record.push(obj.sb);
			return Object.assign(obj, {state: "init", sb: ""});
		}
		if(obj.c == CSVTokenizer.quotChar){
			throw "";
		}
		obj.sb += obj.c;
		return obj;
	}
	static quot(obj){
		if(obj.c == CSVTokenizer.eof){
			throw "";
		}
		if(obj.c == CSVTokenizer.quotChar){
			if(obj.d == CSVTokenizer.eof){
				obj.record.push(obj.sb);
				obj.value.push(obj.record);
				return Object.assign(obj, {c: obj.d});
			}
			if(obj.d == CSVTokenizer.quotChar){
				return Object.assign(obj, {state: "quotEscape"});
			}
			if(obj.d == CSVTokenizer.delimiter){
				return Object.assign(obj, {state: "noQuot"});
			}
			if(obj.d == CSVTokenizer.separator){
				return Object.assign(obj, {state: "noQuot"});
			}
			throw "";
		}
		obj.sb += obj.c;
		return obj;
	}
	static quotEscape(obj){
		if(obj.c == CSVTokenizer.quotChar){
			obj.sb += obj.c;
			return Object.assign(obj, {state: "quot"});
		}
		throw "";
	}
	static delimiter = ",";
	static separator = "\n";
	static quotChar = "\"";
	static eof = Symbol("eof");
}