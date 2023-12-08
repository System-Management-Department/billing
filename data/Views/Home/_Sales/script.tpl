{literal}
	new VirtualPage("/Sales", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
				if((e.dialog == "disapproval") && (e.trigger == "submit")){
					// 承認解除
					fetch(`/Sales/disapproval/${e.result}`)
						.then(fetchJson).then(result => {
							if(result.success){
								this.reload();
							}
							Toaster.show(result.messages.map(m => {
								return {
									"class": m[1],
									message: m[0],
									title: "承認解除"
								};
							}));
						});
				}
			});
			
			const grid = document.querySelector('[slot="main"] [data-grid]');
			const gridLocation = grid.getAttribute("data-grid");
			const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
			const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
			const gridCallback = (row, data, items) => {
				if(data.hide == 1){
					row.classList.add("table-secondary");
				}
				if("apply_client" in items){
					items.apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
				}
				if("manager" in items){
					items.manager.textContent = SinglePage.modal.manager.query(data.manager);
				}
				if(data.recording_date != null){
					if("recording_date" in items){
						items.recording_date.textContent = data.recording_date.replace(/-[0-9]+$/, "");
					}
				}
			};
			GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
			GridGenerator.init(grid);
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Sales#search").apply()).then(form => {
				const client = form.querySelector('form-control[name="client"]');
				if(client != null){
					const client2 = document.createElement("input");
					const changeEvent = e => {
						const applyClients = master.select("COL").setTable("system_apply_clients").setField("apply_client").andWhere("client=?", client.value).apply();
						client2.value = JSON.stringify(applyClients);
					};
					client.addEventListener("change", changeEvent);
					client.addEventListener("reset", changeEvent);
					client2.setAttribute("type", "hidden");
					client2.setAttribute("name", "client2");
					form.appendChild(client2);
				}
				form.submit();
			});
			document.querySelector('[data-proc="close"]').addEventListener("click", e => {
				let number = null;
				const selected = [];
				const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
				const n = checked.length;
				for(let i = 0; i < n; i++){
					selected.push(checked[i].getAttribute("value"));
				}
				const formData = new FormData();
				formData.append("id", JSON.stringify(selected));
				fetch("/Sales/close", {
					method: "POST",
					body: formData
				}).then(fetchJson).then(result => {
					for(let message of result.messages){
						if(message[2] == "no"){
							number = message[0];
						}
					}
					if(number != null){
						open(`/Sales/closeList?channel=${CreateWindowElement.channel}&key=${number}`, "_blank", "left=0,top=0,width=1000,height=300");
					}
				});
			});
			document.querySelector('[data-proc="export"]').addEventListener("click", e => {
				const dt = Date.now();
				let number = null;
				fetch("/Sales/genSlipNumber")
					.then(fetchJson).then(result => {
						for(let message of result.messages){
							if(message[2] == "no"){
								number = message[0];
							}
						}
						if(number != null){
							const selected = [];
							const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
							const n = checked.length;
							for(let i = 0; i < n; i++){
								selected.push(checked[i].getAttribute("value"));
							}
							cache.insertSet("sales_data", {
								selected: JSON.stringify(selected),
								slip_number: number,
								dt: dt
							}, {}).apply();
							return cache.commit();
						}else{
							return Promise.reject(null);
						}
					}).then(() => {
						open(`/Sales/exportList?channel=${CreateWindowElement.channel}&key=${number}`, "_blank", "left=0,top=0,width=1200,height=600");
					});
			});
		}
		reload(){
			fetch("/Sales/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				GridGenerator.createTable(
					document.querySelector('[slot="main"] [data-grid]'),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.hide")
						.apply()
				);
			});
		}
	});
{/literal}