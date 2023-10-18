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
				}
			});
			document.querySelector('table-sticky').columns = dataTableQuery("/Purchase#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
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
							const checked = document.querySelectorAll('table-row [slot="checkbox"] [value]:checked');
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
			fetch("/Purchase/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				setDataTable(
					document.querySelector('table-sticky'),
					dataTableQuery("/Purchase#list").apply(),
					this.transaction.select("ALL")
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
						.leftJoin("sales_workflow using(ss)")
						.addField("sales_workflow.regist_datetime")
						.addField("sales_workflow.request")
						.addField("sales_workflow.close")
						.apply(),
					(row, data) => {
						let edit = row.querySelector('[slot="edit"]');
						let payment = row.querySelector('[slot="payment"] show-dialog');
						let delete1 = row.querySelector('[slot="delete"] show-dialog');
						const manager = row.querySelector('[slot="manager"]');
						const supplier = row.querySelector('[slot="supplier"]');
						const checkbox = row.querySelector('[slot="checkbox"] span');
						const status = row.querySelector('[slot="status"]');
						const request = row.querySelector('[slot="request"] show-dialog');
						const approval = row.querySelector('[slot="approval"] show-dialog');
						const reflection = row.querySelector('[slot="reflection"] show-dialog');
						if(data.close == 1){
							if(edit != null){
								edit.parentNode.removeChild(edit);
								edit = null;
							}
							if(delete1 != null){
								delete1.parentNode.removeChild(delete1);
								delete1 = null;
							}
						}
						if(data.request == 1){
							if(edit != null){
								// edit.parentNode.removeChild(edit);
							}
						}
						if(data.payment == 1){
							if(payment != null){
								const slot = payment.parentNode;
								slot.removeChild(payment);
								slot.innerHTML = '<span class="text-danger">受領済</span>';
								payment = null;
							}
						}
						if(data.pu == null){
							if(payment != null){
								payment.parentNode.removeChild(payment);
							}
							if(delete1 != null){
								delete1.parentNode.removeChild(delete1);
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
						if((data.pu == null) || (data.close != 1)){
							if(request != null){
								request.parentNode.removeChild(request);
							}
							if(approval != null){
								approval.parentNode.removeChild(approval);
							}
							if(reflection != null){
								reflection.parentNode.removeChild(reflection);
							}
							if(status != null){
								status.textContent = "";
							}
							
						}else if(data.reflection == 1){
							if(approval != null){
								approval.parentNode.removeChild(approval);
							}
							if(reflection != null){
								reflection.parentNode.removeChild(reflection);
							}
							if(status != null){
								status.textContent = "反映済み";
							}
						}else if(data.approval == 1){
							if(request != null){
								request.parentNode.removeChild(request);
							}
							if(approval != null){
								approval.setAttribute("label", "承認解除");
								approval.setAttribute("target", "disapproval2");
								approval.classList.remove("btn-primary");
								approval.classList.add("btn-warning");
							}
							if(status != null){
								status.textContent = "承認済み";
							}
						}else if(data.prequest){
							if(request != null){
								request.setAttribute("label", "取下");
								request.setAttribute("target", "withdraw2");
								request.classList.remove("btn-primary");
								request.classList.add("btn-warning");
							}
							if(reflection != null){
								reflection.parentNode.removeChild(reflection);
							}
							if(status != null){
								status.textContent = "申請中";
							}
						}else{
							if(approval != null){
								approval.parentNode.removeChild(approval);
							}
							if(reflection != null){
								reflection.parentNode.removeChild(reflection);
							}
							if(status != null){
								status.textContent = "";
							}
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