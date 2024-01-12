{literal}
	new VirtualPage("/Purchase", class{
		#lastFormData; #lastSort;
		constructor(vp){
			this.#lastFormData = null;
			this.#lastSort = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				if(this.#lastFormData.has("sort[]")){
					this.#lastSort = this.#lastFormData.getAll("sort[]");
				}else{
					this.#lastSort = [];
				}
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
				if((e.dialog == "payment") && (e.trigger == "submit")){
					// 請求書受領
					const formData = new FormData();
					formData.append("id", e.result.target);
					formData.append("comment", e.result.value);
					fetch(`/Purchase/payment/`,{
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
								title: "請求書受領"
							};
						}));
					});
				}else if((e.dialog == "delete_purchase") && (e.trigger == "submit")){
					// 仕入削除
					const formData = new FormData();
					formData.append("id", e.result);
					fetch(`/Purchase/delete/`,{
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
								title: "仕入削除"
							};
						}));
					});
				}else if((e.dialog == "request2") && (e.trigger == "submit")){
					// 仕入変更申請
					fetch(`/Purchase/request/`,{
						method: "POST",
						body: e.result
					}).then(fetchJson).then(result => {
						if(result.success){
							this.reload();
						}
						Toaster.show(result.messages.map(m => {
							return {
								"class": m[1],
								message: m[0],
								title: "仕入変更申請"
							};
						}));
					});
				}else if((e.dialog == "withdraw2") && (e.trigger == "submit")){
					// 仕入変更申請取下
					const formData = new FormData();
					formData.append("id", e.result);
					fetch(`/Purchase/withdraw/`,{
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
								title: "仕入変更申請取下"
							};
						}));
					});
				}else if((e.dialog == "approval2") && (e.trigger == "submit")){
					// 仕入変更承認
					const formData = new FormData();
					formData.append("id", e.result);
					fetch(`/Purchase/approval/`,{
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
								title: "仕入変更承認"
							};
						}));
					});
				}else if((e.dialog == "disapproval2") && (e.trigger == "submit")){
					// 仕入変更承認解除
					const formData = new FormData();
					formData.append("id", e.result);
					fetch(`/Purchase/disapproval/`,{
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
								title: "仕入変更承認解除"
							};
						}));
					});
				}else if((e.dialog == "reflection2") && (e.trigger == "submit")){
					// 仕入変更反映
					const formData = new FormData();
					formData.append("id", e.result);
					fetch(`/Purchase/reflection/`,{
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
								title: "仕入変更反映"
							};
						}));
					});
				}else if((e.dialog == "payment_execution") && (e.trigger == "submit")){
					// 支払実行日
					const formData = new FormData();
					formData.append("id", e.result.target);
					formData.append("execution_date", e.result.value);
					fetch(`/Purchase/paymentExecution/`,{
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
								title: "支払実行日"
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
				if(data.close == 1){
					if("edit" in items){
						items.edit.parentNode.removeChild(items.edit);
						delete items.edit;
					}
					if("delete" in items){
						items.delete.parentNode.removeChild(items.delete);
						delete items.delete;
					}
				}
				if(data.request == 1){
					if("edit" in items){
						// items.edit.parentNode.removeChild(items.edit);
					}
				}
				if(data.payment == 1){
					if("payment" in items){
						const slot = items.payment.parentNode;
						slot.removeChild(items.payment);
						slot.innerHTML = '<span class="text-danger">受領済</span>';
						delete items.payment;
					}
				}
				if(data.pu == null){
					if("payment" in items){
						items.payment.parentNode.removeChild(items.payment);
					}
					if("delete" in items){
						items.delete.parentNode.removeChild(items.delete);
					}
					if("checkbox" in items){
						items.checkbox.parentNode.removeChild(items.checkbox);
					}
					if("execution_date" in items){
						items.execution_date.parentNode.removeChild(items.execution_date);
					}
				}
				if(data.execution_date != null){
					if("execution_date" in items){
						items.execution_date.insertAdjacentElement("afterend", Object.assign(document.createElement("span"), {textContent: data.execution_date}));
					}
				}
				if((data.pu == null) || (data.close != 1)){
					if("request" in items){
						items.request.parentNode.removeChild(items.request);
					}
					if("approval" in items){
						items.approval.parentNode.removeChild(items.approval);
					}
					if("reflection" in items){
						items.reflection.parentNode.removeChild(items.reflection);
					}
					if("status" in items){
						items.status.textContent = "";
					}
					
				}else if(data.reflection == 1){
					if("approval" in items){
						items.approval.parentNode.removeChild(items.approval);
					}
					if("reflection" in items){
						items.reflection.parentNode.removeChild(items.reflection);
					}
					if("status" in items){
						items.status.textContent = "反映済み";
					}
				}else if(data.approval == 1){
					if("request" in items){
						items.request.parentNode.removeChild(items.request);
					}
					if("approval" in items){
						items.approval.textContent = "承認解除";
						items.approval.setAttribute("target", "disapproval2");
						items.approval.classList.remove("btn-primary");
						items.approval.classList.add("btn-warning");
					}
					if("status" in items){
						items.status.textContent = "承認済み";
					}
				}else if(data.prequest){
					if("request" in items){
						items.request.textContent = "取下";
						items.request.setAttribute("target", "withdraw2");
						items.request.classList.remove("btn-primary");
						items.request.classList.add("btn-warning");
					}
					if("reflection" in items){
						items.reflection.parentNode.removeChild(items.reflection);
					}
					if("status" in items){
						items.status.textContent = "申請中";
					}
				}else{
					if("approval" in items){
						items.approval.parentNode.removeChild(items.approval);
					}
					if("reflection" in items){
						items.reflection.parentNode.removeChild(items.reflection);
					}
					if("status" in items){
						items.status.textContent = "";
					}
				}
				if("manager" in items){
					items.manager.textContent = SinglePage.modal.manager.query(data.manager);
				}
				if("supplier" in items){
					items.supplier.textContent = SinglePage.modal.supplier.query(data.supplier);
				}
				if(data.recording_date != null){
					if("recording_date" in items){
						items.recording_date.textContent = data.recording_date.replace(/-[0-9]+$/, "");
					}
				}
			};
			GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
			GridGenerator.init(grid);
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Purchase#search").apply()).then(form => { form.submit(); });
			document.querySelector('[data-proc="export"]').addEventListener("click", e => {
				const dt = Date.now();
				let number = null;
				fetch("/Purchase/genSlipNumber")
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
							cache.insertSet("purchase_data", {
								selected: JSON.stringify(selected),
								slip_number: number,
								dt: dt
							}, {}).apply();
							return cache.commit();
						}else{
							return Promise.reject(null);
						}
					}).then(() => {
						open(`/Purchase/exportList?channel=${CreateWindowElement.channel}&key=${number}`, "_blank", "left=0,top=0,width=1200,height=600");
					});
			});
		}
		reload(){
			const sortQ = this.#lastSort.slice();
			fetch("/Purchase/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				const query = this.transaction.select("ALL")
					.setTable("purchase_relations")
					.addField("purchase_relations.sd")
					.leftJoin("purchases using(pu)")
					.addField("purchases.*")
					.leftJoin("purchase_workflow using(pu)")
					.addField("purchase_workflow.payment")
					.addField("purchase_workflow.update_datetime")
					.leftJoin("purchase_correction_workflow using(pu)")
					.addField("(purchase_correction_workflow.pu IS NOT NULL) AS prequest")
					.addField("purchase_correction_workflow.approval")
					.addField("purchase_correction_workflow.reflection")
					.leftJoin("sales_slips using(ss)")
					.addField("sales_slips.apply_client")
					.addField("sales_slips.client_name")
					.addField("sales_slips.leader")
					.addField("sales_slips.manager")
					.addField("sales_slips.project")
					.addField("sales_slips.slip_number")
					.addField("sales_slips.subject")
					.addField("sales_slips.recording_date")
					.leftJoin("sales_workflow using(ss)")
					.addField("sales_workflow.regist_datetime")
					.addField("sales_workflow.request")
					.addField("sales_workflow.close");
				for(let sortI of sortQ){
					if(sortI != ""){
						query.setOrderBy(sortI);
					}
				}
				GridGenerator.createTable(
					document.querySelector('[slot="main"] [data-grid]'),
					query.apply()
				);
			});
		}
	});
{/literal}