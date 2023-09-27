{literal}
	new VirtualPage("/RedSlip", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/RedSlip#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/RedSlip#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/RedSlip/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/RedSlip#list").apply(),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.lost")
						.addField("sales_workflow.lost_slip_number")
						.addField("sales_workflow.lost_comment")
						.apply(),
					(row, data, insert) => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						if(apply_client != null){
							apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
						}
						if(manager != null){
							manager.textContent = SinglePage.modal.manager.query(data.manager);
						}
						if(data.lost == 1){
							const row2 = insert(Object.assign(data, {slip_number: data.lost_slip_number}));
							const apply_client2 = row2.querySelector('[slot="apply_client"]');
							const manager2 = row2.querySelector('[slot="manager"]');
							const salses_detail2 = row2.querySelector('[slot="salses_detail"] show-dialog');
							row2.classList.add("table-danger");
							if(apply_client2 != null){
								apply_client2.textContent = SinglePage.modal.apply_client.query(data.apply_client);
							}
							if(manager2 != null){
								manager2.textContent = SinglePage.modal.manager.query(data.manager);
							}
							if(salses_detail2 != null){
								salses_detail2.setAttribute("target", "red_salses_detail");
							}
						}
					}
				);
			});
		}
	});
{/literal}