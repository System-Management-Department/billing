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
			
			const grid = document.querySelector('[slot="main"] [data-grid]');
			const gridLocation = grid.getAttribute("data-grid");
			const gridInfo = master.select("ROW").setTable("grid_infos").andWhere("location=?", gridLocation).apply();
			const gridColumns = master.select("ALL").setTable("grid_columns").andWhere("location=?", gridLocation).apply();
			const gridCallback = (row, data, items) => {
				if("apply_client" in items){
					items.apply_client.textContent = SinglePage.modal.apply_client.query(data.apply_client);
				}
				if("manager" in items){
					items.manager.textContent = SinglePage.modal.manager.query(data.manager);
				}
				if(data.slip_number == data.lost_slip_number){
					row.classList.add("table-danger");
					if("salses_detail" in items){
						items.salses_detail.setAttribute("target", "red_salses_detail");
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
				document.querySelector('search-form').setAttribute("result", `${info.count}件中${info.display}件を表示`);
				
				GridGenerator.createTable(
					document.querySelector('[slot="main"] [data-grid]'),
					this.generator(
						this.transaction.select("ALL")
							.setTable("sales_slips")
							.addField("sales_slips.*")
							.leftJoin("sales_workflow using(ss)")
							.addField("sales_workflow.regist_datetime")
							.addField("sales_workflow.lost")
							.addField("sales_workflow.lost_slip_number")
							.addField("sales_workflow.lost_comment")
							.apply()
					)
				);
			});
		}
		*generator(data){
			for(let row of data){
				yield row;
				if(row.lost == 1){
					yield (Object.assign(row, {slip_number: row.lost_slip_number}));
				}
			}
		}
	});
{/literal}