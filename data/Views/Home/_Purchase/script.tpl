{literal}
	new VirtualPage("/Purchase", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => { console.log(e); });
			document.querySelector('table-sticky').columns = dataTableQuery("/Purchase#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Purchase#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/Purchase/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(res => res.arrayBuffer()).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Purchase#list").apply(),
					this.transaction.select("ALL")
						.setTable("purchase_relations")
						.leftJoin("purchases using(pu)")
						.addField("purchases.*")
						.leftJoin("sales_slips using(ss)")
						.addField("sales_slips.apply_client")
						.addField("sales_slips.client_name")
						.addField("sales_slips.leader")
						.addField("sales_slips.manager")
						.addField("sales_slips.project")
						.addField("sales_slips.slip_number")
						.addField("sales_slips.subject")
						.apply(),
					(row, data) => {
						if(data.pu == null){
							row.querySelector('[slot="payment"]').innerHTML = "";
						}
						const manager = row.querySelector('[slot="manager"]');
						manager.textContent = SinglePage.modal.manager.query(manager.textContent);
					}
				);
			});
		}
	});
{/literal}