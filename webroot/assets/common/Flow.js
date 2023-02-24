class Flow{
	static DB = new SQLite();
	static DbName = "";
	static DbLocked = false;
	static #p = null;
	static #i = [];
	static start( ...p){
		if(Flow.#i == null){
			for(let i of p){
				co(i);
			}
		}else if(Flow.#p == null){
			Flow.#p = Promise.all([
				Flow.DB.use(Flow.DbName),
				new Promise((resolve, reject) => { document.addEventListener("DOMContentLoaded", e => { resolve(e) }) })
			]);
			Flow.#i = Flow.#i.concat(p);
			Flow.#p.then(e => {
				for(let i of Flow.#i){
					co(i);
				}
				Flow.#i = null;
			});
		}else{
			Flow.#i = Flow.#i.concat(p);
		}
	}
	static *waitDbUnlock(){
		while(Flow.DbLocked){
			yield new Promise((resolve, reject) => {
				setTimeout(() => {
					resolve(null);
				}, 100);
			});
		}
		return Flow.DB;
	}
}