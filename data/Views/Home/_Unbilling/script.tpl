{literal}
	new VirtualPage("/Unbilling", class{
		#lastFormData; #lastApplyClient; #lastSort;
		constructor(vp){
			this.#lastFormData = null;
			this.#lastSort = null;
			this.#lastApplyClient = null;
			vp.addEventListener("search", e => {
				const applyClientSearch = document.querySelector('form-control[name="apply_client"]');
				this.#lastFormData = e.formData;
				if(this.#lastFormData.has("sort[]")){
					this.#lastSort = this.#lastFormData.getAll("sort[]");
				}else{
					this.#lastSort = [];
				}
				this.#lastApplyClient = ((applyClientSearch == null) || (applyClientSearch.value == "")) ? null : applyClientSearch.value;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
			});
			document.querySelector('[slot="main"] [data-grid]').addEventListener("click", e => {
				const gridInfo = GridGenerator.getInfo(e.target);
				if(gridInfo.slot == "hide"){
					const btn = gridInfo.cell.querySelector('[data-row-hide],[data-row-show]');
					if(btn.hasAttribute("data-row-hide")){
						const value = btn.getAttribute("data-row-hide");
						fetch(`/Unbilling/hide/${value}`).then(fetchJson).then(result => {
							if(result.success){
								btn.setAttribute("data-row-show", value);
								btn.removeAttribute("data-row-hide");
								btn.textContent = "表示";
								gridInfo.row.classList.add("table-secondary");
							}
						});
					}else{
						const value = btn.getAttribute("data-row-show");
						fetch(`/Unbilling/show/${value}`).then(fetchJson).then(result => {
							if(result.success){
								btn.setAttribute("data-row-hide", value);
								btn.removeAttribute("data-row-show");
								btn.textContent = "非表示";
								gridInfo.row.classList.remove("table-secondary");
							}
						});
					}
				}
			}, {useCapture: true});
			
			const grid = document.querySelector('[slot="main"] [data-grid]');
			const gridLocation = grid.getAttribute("data-grid");
			const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
			const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
			const gridCallback = (row, data, items) => {
				if(this.#lastApplyClient == null){
					if("checkbox" in items){
						items.checkbox.parentNode.removeChild(items.checkbox);
					}
				}
				if(data.hide == 1){
					row.classList.add("table-secondary");
					if("hide" in items){
						items.hide.textContent = "表示";
						items.hide.setAttribute("data-row-show", data.ss);
					}
				}else{
					if("hide" in items){
						items.hide.textContent = "非表示";
						items.hide.setAttribute("data-row-hide", data.ss);
					}
				}
				if("apply_client" in items){
					items.apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
				}
				if("manager" in items){
					items.manager.textContent = SinglePage.modal.manager.query(data.manager);
				}
				if(data.recording_date != null){
					if("recording_date" in items){
						items.recording_date.textContent = data.recording_date.replace(/-[0-9]+$/, "");
					}
				}
			};
			GridGenerator.define(gridLocation, gridInfo, gridColumns, gridCallback);
			GridGenerator.init(grid);
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Unbilling#search").apply()).then(form => {
				const client = form.querySelector('form-control[name="client"]');
				if(client != null){
					const client2 = document.createElement("input");
					const changeEvent = e => {
						const applyClients = master.select("COL").setTable("system_apply_clients").setField("code").andWhere("client=?", client.value).apply();
						client2.value = JSON.stringify(applyClients);
					};
					client.addEventListener("change", changeEvent);
					client.addEventListener("reset", changeEvent);
					client2.setAttribute("type", "hidden");
					client2.setAttribute("name", "client2");
					form.appendChild(client2);
				}
				form.submit();
			});
			document.querySelector('[data-proc="marge"]').addEventListener("click", e => {
				const dt = Date.now();
				const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
				if(checked.length < 1){
					alert("選択されていません。");
				}else{
					const parser = new DOMParser();
					const xmlDoc = parser.parseFromString(`<estimate />`, "application/xml");
					const estimate = xmlDoc.documentElement;
					const info = xmlDoc.createElement("info");
					const n = checked.length;
					const total = {ss:[], project: [], amount_exc: 0, amount_tax: 0, amount_inc: 0};
					const base = this.transaction.select("ROW").setTable("sales_slips").andWhere("ss=?", Number(checked[0].getAttribute("value"))).apply();
					info.setAttribute("dt", dt);
					info.setAttribute("update", dt);
					info.setAttribute("type", base.invoice_format);
					estimate.setAttribute("estimate_date", new Intl.DateTimeFormat("ja-JP", {dateStyle: "short"}).format(new Date(dt)).split("/").join("-"));
					estimate.setAttribute("subject", "");
					estimate.setAttribute("division", base.division);
					estimate.setAttribute("leader", base.leader);
					estimate.setAttribute("manager", base.manager);
					estimate.setAttribute("client_name", base.client_name);
					estimate.setAttribute("apply_client", base.apply_client);
					estimate.setAttribute("payment_date", base.payment_date);
					estimate.setAttribute("specification", "");
					estimate.setAttribute("note", base.note);
					estimate.appendChild(info);
					for(let i = 0; i < n; i++){
						const ss = Number(checked[i].getAttribute("value"));
						const salesSlips = this.transaction.select("ROW").setTable("sales_slips").andWhere("ss=?", ss).apply();
						const preDetail = xmlDoc.createElement("detail");
						preDetail.setAttribute("detail", salesSlips.subject);
						preDetail.setAttribute("category", "");
						preDetail.setAttribute("record", "false");
						preDetail.setAttribute("taxable", "false");
						estimate.appendChild(preDetail);
						
						total.ss.push(salesSlips.ss);
						total.project.push(salesSlips.project);
						total.amount_exc += salesSlips.amount_exc;
						total.amount_tax += salesSlips.amount_tax;
						total.amount_inc += salesSlips.amount_inc;
						const details = this.transaction.select("ALL")
							.setTable("purchase_relations")
							.leftJoin("sales_details USING(sd)")
							.setField("DISTINCT sales_details.*")
							.leftJoin("sales_detail_attributes USING(sd)")
							.addField("sales_detail_attributes.data")
							.andWhere("purchase_relations.ss=?", ss)
							.apply();
						for(let detail of details){
							const detailElement = xmlDoc.createElement("detail");
							detailElement.setAttribute("detail", detail.detail);
							detailElement.setAttribute("category", detail.category);
							detailElement.setAttribute("record", (detail.record == 1) ? "true" : "false");
							detailElement.setAttribute("taxable", (detail.taxable == 1) ? "true" : "false");
							if(detail.record == 1){
								detailElement.setAttribute("quantity", detail.quantity);
								detailElement.setAttribute("unit", detail.unit);
								detailElement.setAttribute("unit_price", detail.unit_price);
								detailElement.setAttribute("amount_exc", detail.amount_exc);
								detailElement.setAttribute("amount_tax", detail.amount_tax);
								detailElement.setAttribute("amount_inc", detail.amount_inc);
								if(detail.taxable == 1){
									detailElement.setAttribute("tax_rate", detail.tax_rate);
								}
							}
							const attributesElement = xmlDoc.createElement("attributes");
							if(detail.data != null){
								const attributes = JSON.parse(detail.data);
								for(let key in attributes){
									if(Array.isArray(attributes[key])){
										const attrCnt = attributes[key].length;
										for(let j = 0; j < attrCnt; j++){
											attributesElement.setAttribute(`${key}${j + 1}`, attributes[key][j]);
										}
									}else{
										attributesElement.setAttribute(key, attributes[key]);
									}
								}
							}
							detailElement.appendChild(attributesElement);
							estimate.appendChild(detailElement);
						}
					}
					info.setAttribute("ss", total.ss.join(","));
					estimate.setAttribute("project", total.project.join(" / "));
					estimate.setAttribute("amount_exc", total.amount_exc);
					estimate.setAttribute("amount_tax", total.amount_tax);
					estimate.setAttribute("amount_inc", total.amount_inc);
					cache.insertSet("estimate", {
						xml: estimate.outerHTML,
						dt: dt
					}, {}).apply();
					cache.commit().then(() => {
						open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${dt}`, "_blank", "left=0,top=0,width=1200,height=700");
					});
				}
			});
			document.querySelector('[data-proc="aggregation"]').addEventListener("click", e => {
				const dt = Date.now();
				const checked = document.querySelectorAll('[slot="main"] [data-grid] [type="checkbox"][value]:checked');
				if(checked.length < 1){
					alert("選択されていません。");
				}else{
					const parser = new DOMParser();
					const xmlDoc = parser.parseFromString(`<estimate />`, "application/xml");
					const estimate = xmlDoc.documentElement;
					const info = xmlDoc.createElement("info");
					const n = checked.length;
					const total = {ss:[], project: [], amount_exc: 0, amount_tax: 0, amount_inc: 0};
					const base = this.transaction.select("ROW").setTable("sales_slips").andWhere("ss=?", Number(checked[0].getAttribute("value"))).apply();
					info.setAttribute("dt", dt);
					info.setAttribute("update", dt);
					info.setAttribute("type", base.invoice_format);
					estimate.setAttribute("estimate_date", new Intl.DateTimeFormat("ja-JP", {dateStyle: "short"}).format(new Date(dt)).split("/").join("-"));
					estimate.setAttribute("subject", "");
					estimate.setAttribute("division", base.division);
					estimate.setAttribute("leader", base.leader);
					estimate.setAttribute("manager", base.manager);
					estimate.setAttribute("client_name", base.client_name);
					estimate.setAttribute("apply_client", base.apply_client);
					estimate.setAttribute("payment_date", base.payment_date);
					estimate.setAttribute("specification", "");
					estimate.setAttribute("note", base.note);
					estimate.appendChild(info);
					for(let i = 0; i < n; i++){
						const ss = Number(checked[i].getAttribute("value"));
						const salesSlips = this.transaction.select("ROW").setTable("sales_slips").andWhere("ss=?", ss).apply();
						const preDetail = xmlDoc.createElement("detail");
						preDetail.setAttribute("detail", salesSlips.subject);
						preDetail.setAttribute("category", "");
						preDetail.setAttribute("record", "true");
						preDetail.setAttribute("taxable", "true");
						preDetail.setAttribute("quantity", 1);
						preDetail.setAttribute("unit", "式");
						preDetail.setAttribute("unit_price", salesSlips.amount_exc);
						preDetail.setAttribute("amount_exc", salesSlips.amount_exc);
						preDetail.setAttribute("amount_tax", salesSlips.amount_tax);
						preDetail.setAttribute("amount_inc", salesSlips.amount_inc);
						preDetail.setAttribute("tax_rate", 0.1);
						estimate.appendChild(preDetail);
						
						total.ss.push(salesSlips.ss);
						total.project.push(salesSlips.project);
						total.amount_exc += salesSlips.amount_exc;
						total.amount_tax += salesSlips.amount_tax;
						total.amount_inc += salesSlips.amount_inc;
					}
					info.setAttribute("ss", total.ss.join(","));
					estimate.setAttribute("project", total.project.join(" / "));
					estimate.setAttribute("amount_exc", total.amount_exc);
					estimate.setAttribute("amount_tax", total.amount_tax);
					estimate.setAttribute("amount_inc", total.amount_inc);
					cache.insertSet("estimate", {
						xml: estimate.outerHTML,
						dt: dt
					}, {}).apply();
					cache.commit().then(() => {
						open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${dt}`, "_blank", "left=0,top=0,width=1200,height=700");
					});
				}
			});
		}
		reload(){
			const sortQ = this.#lastSort.slice();
			fetch("/Unbilling/search", {
				method: "POST",
				body: this.#lastFormData
			}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const info = this.transaction.select("ALL").setTable("_info").apply().reduce((a, b) => Object.assign(a, {[b.key]: b.value}), {});
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				const query = this.transaction.select("ALL")
					.setTable("sales_slips")
					.addField("sales_slips.*")
					.leftJoin("sales_workflow using(ss)")
					.addField("sales_workflow.regist_datetime")
					.addField("sales_workflow.hide");
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