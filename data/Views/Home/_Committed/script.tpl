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
				if(data.request == 1){
					if("request" in items){
						items.request.textContent = "取下";
						items.request.setAttribute("target", "withdraw");
						items.request.classList.remove("btn-primary");
						items.request.classList.add("btn-warning");
					}
					if("edit" in items){
						items.edit.parentNode.removeChild(items.edit);
					}
					if("delete_slip" in items){
						items.delete_slip.parentNode.removeChild(items.delete_slip);
						delete items.delete_slip;
					}
					if("status" in items){
						items.status.classList.add("text-danger");
						items.status.innerHTML = '<i class="bi bi-reply-fill text-red"></i>申請中';
					}
				}else{
					if("approval" in items){
						items.approval.parentNode.removeChild(items.approval);
					}
					if("status" in items){
						items.status.textContent = "";
					}
				}
				if(data.release_datetime != null){
					if("delete_slip" in items){
						items.delete_slip.parentNode.removeChild(items.delete_slip);
					}
				}
				if(data.recording_date != null){
					if("recording_date" in items){
						items.recording_date.textContent = data.recording_date.replace(/-[0-9]+$/, "");
					}
				}
			};
			GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
			GridGenerator.init(grid);
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
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				GridGenerator.createTable(
					document.querySelector('[slot="main"] [data-grid]'),
					this.transaction.select("ALL")
						.setTable("sales_slips")
						.addField("sales_slips.*")
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.request")
						.addField("sales_workflow.release_datetime")
						.addField("sales_workflow.hide")
						.apply()
				);
			});
		}
	});
{/literal}