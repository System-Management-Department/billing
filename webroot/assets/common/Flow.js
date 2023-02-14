class Flow{
	static DB = new SQLite();
	static #p = null;
	static #i = [];
	static start(dbName, ...p){
		if(Flow.#i == null){
			for(let i of p){
				co(i);
			}
		}else if(Flow.#p == null){
			Flow.#p = Promise.all([
				Flow.DB.use(dbName),
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
}