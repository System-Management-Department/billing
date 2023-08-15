{literal}
	new VirtualPage("/Committed", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
				if((e.dialog == "approval") && (e.trigger == "submit")){
					console.log(e.result);
				}
				console.log(e);
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/Committed#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Committed#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/Committed/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(res => res.arrayBuffer()).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				console.log(this.transaction.tables);
				console.log(this.transaction.select("ALL").setTable("sales_slips").apply());
				console.log(this.transaction.select("ALL").setTable("sales_attributes").apply());
				console.log(this.transaction.select("ALL").setTable("sales_workflow").apply());
				console.log(this.transaction.select("ALL").setTable("sales_details").apply());
				console.log(this.transaction.select("ALL").setTable("sales_detail_attributes").apply());
				console.log(this.transaction.select("ALL").setTable("purchases").apply());
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Committed#list").apply(),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.apply().map(r => Object.assign(
							r,
							master.select("ROW")
								.setField("'ar' AS apply_client,'ue' AS manager")
								.apply()
						)),
					row => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						apply_client.textContent = `apply_client${apply_client.textContent}`;
						manager.textContent = `manager${manager.textContent}`;
					}
				);
			});
		}
	});
{/literal}