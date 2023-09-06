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
					// 承認
					fetch(`/Committed/approval/${e.result}`)
						.then(res => res.json()).then(result => {
							if(result.success){
								this.reload();
							}
							const classes = ["toast show bg-success", "toast show bg-warning", "toast show bg-danger"];
							Toaster.show(result.messages.map(m => {
								return {
									"class": classes[m[1]],
									message: m[0],
									title: "承認"
								};
							}));
						});
				}else if((e.dialog == "request") && (e.trigger == "submit")){
					// 申請
					fetch(`/Committed/request/${e.result}`)
						.then(res => res.json()).then(result => {
							if(result.success){
								this.reload();
							}
							const classes = ["toast show bg-success", "toast show bg-warning", "toast show bg-danger"];
							Toaster.show(result.messages.map(m => {
								return {
									"class": classes[m[1]],
									message: m[0],
									title: "申請"
								};
							}));
						});
				}else if((e.dialog == "withdraw") && (e.trigger == "submit")){
					// 申請取下
					fetch(`/Committed/withdraw/${e.result}`)
						.then(res => res.json()).then(result => {
							if(result.success){
								this.reload();
							}
							const classes = ["toast show bg-success", "toast show bg-warning", "toast show bg-danger"];
							Toaster.show(result.messages.map(m => {
								return {
									"class": classes[m[1]],
									message: m[0],
									title: "申請取下"
								};
							}));
						});
				}
				console.log(e);
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/Committed#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
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
				console.log(info);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Committed#list").apply(),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.request")
						.apply(),
					(row, data) => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						const request = row.querySelector('[slot="request"] show-dialog');
						const approval = row.querySelector('[slot="approval"]');
						const edit = row.querySelector('[slot="edit"]');
						const delete_slip = row.querySelector('[slot="delete_slip"]');
						if(apply_client != null){
							apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
						}
						if(manager != null){
							manager.textContent = SinglePage.modal.manager.query(data.manager);
						}
						if(data.request == 1){
							if(request != null){
								request.setAttribute("label", "取下");
								request.setAttribute("target", "withdraw");
							}
							if(edit != null){
								edit.parentNode.removeChild(edit);
							}
							if(delete_slip != null){
								delete_slip.parentNode.removeChild(delete_slip);
							}
						}else{
							if(approval != null){
								approval.parentNode.removeChild(approval);
							}
						}
					}
				);
			});
		}
	});
{/literal}