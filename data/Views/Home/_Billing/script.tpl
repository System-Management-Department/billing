{literal}
	new VirtualPage("/Billing", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
				if((e.dialog == "release") && (e.trigger == "submit")){
					// 締め解除
					const selected = [];
					const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
					const n = checked.length;
					for(let i = 0; i < n; i++){
						selected.push(checked[i].getAttribute("value"));
					}
					const formData = new FormData();
					formData.append("id", JSON.stringify(selected));
					formData.append("comment", e.result);
					fetch(`/Billing/release/`,{
						method: "POST",
						body: formData
					}).then(fetchJson).then(result => {
						if(result.success){
							this.reload();
						}
						Toaster.show(result.messages.map(m => {
							return {
								"class": m[1],
								message: m[0],
								title: "締め解除"
							};
						}));
					});
					this.reload();
				}else if((e.dialog == "red_slip") && (e.trigger == "submit")){
					// 赤伝
					const formData = new FormData();
					formData.append("id", e.result.target);
					formData.append("comment", e.result.value);
					fetch(`/Billing/redSlip/`,{
						method: "POST",
						body: formData
					}).then(fetchJson).then(result => {
						if(result.success){
							this.reload();
						}
						Toaster.show(result.messages.map(m => {
							return {
								"class": m[1],
								message: m[0],
								title: "赤伝登録"
							};
						}));
					});
					this.reload();
				}
			});
			
			const grid = document.querySelector('[slot="main"] [data-grid]');
			const gridLocation = grid.getAttribute("data-grid");
			const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
			const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
			const gridCallback = (row, data, items) => {
				if(data.lost == 1){
					if("red_slip" in items){
						items.red_slip.parentNode.removeChild(items.red_slip);
					}
					if("checkbox" in items){
						items.checkbox.parentNode.removeChild(items.checkbox);
					}
				}
				if("apply_client" in items){
					items.apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
				}
				if("manager" in items){
					items.manager.textContent = SinglePage.modal.manager.query(data.manager);
				}
				if(data.slip_number == data.lost_slip_number){
					row.classList.add("table-danger");
					if("salses_detail" in items){
						items.salses_detail.setAttribute("target", "red_salses_detail");
					}
				}
			};
			GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
			GridGenerator.init(grid);
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Billing#search").apply()).then(form => { form.submit(); });
			document.querySelector('[data-proc="export"]').addEventListener("click", e => {
				const dt = Date.now();
				const selected = [];
				const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
				const n = checked.length;
				for(let i = 0; i < n; i++){
					selected.push(checked[i].getAttribute("value"));
				}
				cache.insertSet("close_data", {
					selected: JSON.stringify(selected),
					dt: dt
				}, {}).apply();
				cache.commit().then(() => {
					open(`/Billing/exportList?channel=${CreateWindowElement.channel}&key=${dt}`, "_blank", "left=0,top=0,width=1000,height=300");
				});
			});
			document.querySelector('[data-proc="export2"]').addEventListener("click", e => {
				const dt = Date.now();
				let number = null;
				fetch("/Billing/genSlipNumber")
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
							cache.insertSet("billing_data", {
								selected: JSON.stringify(selected),
								slip_number: number,
								dt: dt
							}, {}).apply();
							return cache.commit();
						}else{
							return Promise.reject(null);
						}
					}).then(() => {
						open(`/Billing/exportList2?channel=${CreateWindowElement.channel}&key=${number}`, "_blank", "left=0,top=0,width=1200,height=600");
					});
			});
		}
		reload(){
			fetch("/Billing/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				GridGenerator.createTable(
					document.querySelector('[slot="main"] [data-grid]'),
					this.generator(
						this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.lost")
						.addField("sales_workflow.lost_slip_number")
						.addField("sales_workflow.lost_comment")
						.addField("sales_workflow.close_version")
						.apply()
					)
				);
			});
		}
		*generator(data){
			for(let row of data){
				yield row;
				if(row.lost == 1){
					yield (Object.assign(row, {slip_number: row.lost_slip_number}));
				}
			}
		}
	});
{/literal}