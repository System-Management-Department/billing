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
						.then(res => res.json()).then(result => {
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
			document.querySelector('table-sticky').columns = dataTableQuery("/Sales#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Sales#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/Sales/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(res => res.arrayBuffer()).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Sales#list").apply(),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.apply(),
					row => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						apply_client.textContent = SinglePage.modal.apply_client.query(apply_client.textContent);
						manager.textContent = SinglePage.modal.manager.query(manager.textContent);
					}
				);
			});
		}
	});
{/literal}