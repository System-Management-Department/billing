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
					const checked = document.querySelectorAll('table-row [slot="checkbox"] [value]:checked');
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
					}).then(res => res.json()).then(result => {
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
				}
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/Billing#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Billing#search").apply()).then(form => { form.submit(); });
			document.querySelector('[data-proc="export"]').addEventListener("click", e => {
				const dt = Date.now();
				const selected = [];
				const checked = document.querySelectorAll('table-row [slot="checkbox"] [value]:checked');
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
					.then(res => res.json()).then(result => {
						for(let message of result.messages){
							if(message[2] == "no"){
								number = message[0];
							}
						}
						if(number != null){
							const selected = [];
							const checked = document.querySelectorAll('table-row [slot="checkbox"] [value]:checked');
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
			}).then(res => res.arrayBuffer()).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Billing#list").apply(),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.apply(),
					(row, data) => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						const checkbox = row.querySelector('[slot="checkbox"] span');
						if(apply_client != null){
							apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
						}
						if(manager != null){
							manager.textContent = SinglePage.modal.manager.query(data.manager);
						}
						if(checkbox != null){
							const input = document.createElement("input");
							input.setAttribute("type", "checkbox");
							input.setAttribute("value", data.slip_number);
							input.checked = true;
							checkbox.parentNode.replaceChild(input, checkbox);
						}
					}
				);
			});
		}
	});
{/literal}