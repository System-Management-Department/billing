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
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Purchase#list").apply(),
					this.transaction.select("ALL")
						.setTable("purchase_relations")
						.addField("purchase_relations.sd")
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
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.request")
						.apply(),
					(row, data) => {
						const edit = row.querySelector('[slot="edit"]');
						const payment = row.querySelector('[slot="payment"] show-dialog');
						const manager = row.querySelector('[slot="manager"]');
						const supplier = row.querySelector('[slot="supplier"]');
						const checkbox = row.querySelector('[slot="checkbox"] span');
						if(data.request == 1){
							if(edit != null){
								// edit.parentNode.removeChild(edit);
							}
						}
						if(data.pu == null){
							if(payment != null){
								payment.parentNode.removeChild(payment);
							}
							if(checkbox != null){
								checkbox.parentNode.removeChild(checkbox);
							}
						}else if(checkbox != null){
							const input = document.createElement("input");
							input.setAttribute("type", "checkbox");
							input.setAttribute("value", data.pu);
							input.checked = true;
							checkbox.parentNode.replaceChild(input, checkbox);
						}
						if(manager != null){
							manager.textContent = SinglePage.modal.manager.query(data.manager);
						}
						if(supplier != null){
							supplier.textContent = SinglePage.modal.supplier.query(data.supplier);
						}
					}
				);
			});
		}
	});
{/literal}