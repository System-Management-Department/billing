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
						.then(fetchJson).then(result => {
							if(result.success){
								this.reload();
							}
							Toaster.show(result.messages.map(m => {
								return {
									"class": m[1],
									message: m[0],
									title: "承認"
								};
							}));
						});
				}else if((e.dialog == "request") && (e.trigger == "submit")){
					// 申請
					fetch(`/Committed/request/${e.result}`)
						.then(fetchJson).then(result => {
							if(result.success){
								this.reload();
							}
							Toaster.show(result.messages.map(m => {
								return {
									"class": m[1],
									message: m[0],
									title: "申請"
								};
							}));
						});
				}else if((e.dialog == "withdraw") && (e.trigger == "submit")){
					// 申請取下
					fetch(`/Committed/withdraw/${e.result}`)
						.then(fetchJson).then(result => {
							if(result.success){
								this.reload();
							}
							Toaster.show(result.messages.map(m => {
								return {
									"class": m[1],
									message: m[0],
									title: "申請取下"
								};
							}));
						});
				}else if((e.dialog == "delete_slip") && (e.trigger == "submit")){
					// 案件削除
					fetch(`/Committed/deleteSlip/${e.result}`)
						.then(fetchJson).then(result => {
							if(result.success){
								this.reload();
							}
							Toaster.show(result.messages.map(m => {
								return {
									"class": m[1],
									message: m[0],
									title: "案件削除"
								};
							}));
						});
				}
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/Committed#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Committed#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/Committed/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
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
						.addField("sales_workflow.release_datetime")
						.apply(),
					(row, data) => {
						const apply_client = row.querySelector('[slot="apply_client"]');
						const manager = row.querySelector('[slot="manager"]');
						const request = row.querySelector('[slot="request"] show-dialog');
						const approval = row.querySelector('[slot="approval"]');
						const edit = row.querySelector('[slot="edit"]');
						const status = row.querySelector('[slot="status"]');
						let delete_slip = row.querySelector('[slot="delete_slip"]');
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
								request.classList.remove("btn-primary");
								request.classList.add("btn-warning");
							}
							if(edit != null){
								edit.parentNode.removeChild(edit);
							}
							if(delete_slip != null){
								delete_slip.parentNode.removeChild(delete_slip);
								delete_slip = null;
							}
							if(status != null){
								status.classList.add("text-danger");
								status.innerHTML = '<i class="bi bi-reply-fill text-red"></i>申請中';
							}
						}else{
							if(approval != null){
								approval.parentNode.removeChild(approval);
							}
							if(status != null){
								status.textContent = "";
							}
						}
						if(data.release_datetime != null){
							if(delete_slip != null){
								delete_slip.parentNode.removeChild(delete_slip);
							}
						}
					}
				);
			});
		}
	});
{/literal}