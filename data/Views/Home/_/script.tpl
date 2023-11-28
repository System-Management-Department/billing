{literal}
	new VirtualPage("/", class{
		constructor(vp){
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => {
				if(e.dialog == "estimate"){
					if(e.trigger == "list"){
						open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${e.result}`, "_blank", "left=0,top=0,width=1200,height=700");
					}
					if(e.trigger == "export"){
						const xml = cache.select("ONE").setTable("estimate").setField("xml").andWhere("dt=?", Number(e.result)).apply();
						const a = document.createElement("a");
						a.setAttribute("href", URL.createObjectURL(new Blob([xml], {type: "application/xml"})));
						a.setAttribute("download", `${e.result}.xml`);
						a.click();
					}
					if(e.trigger == "delete"){
						cache.delete("estimate").andWhere("dt=?", Number(e.result)).apply();
						cache.commit();
					}
				}else if(e.dialog == "salses_export"){
					if((e.trigger == "submit") && (e.result != null)){
						let number = null;
						fetch("/Sales/genSlipNumber")
							.then(fetchJson).then(result => {
								for(let message of result.messages){
									if(message[2] == "no"){
										number = message[0];
									}
								}
								if(number != null){
									return Promise.resolve(null);
								}else{
									return Promise.reject(null);
								}
							}).then(() => {
								open(`/Sales/exportList2?channel=${CreateWindowElement.channel}&key=${number}&month=${e.result}`, "_blank", "left=0,top=0,width=1200,height=700");
							});
					}
				}
			});
			vp.addEventListener("modal-action", e => {
				if(e.dialog == "estimate"){
					if(e.trigger == "export"){
						const xml = cache.select("ONE").setTable("estimate").setField("xml").andWhere("dt=?", Number(e.result)).apply();
						const a = document.createElement("a");
						a.setAttribute("href", URL.createObjectURL(new Blob([xml], {type: "application/xml"})));
						a.setAttribute("download", `${e.result}.xml`);
						a.click();
					}
					if(e.trigger == "delete"){
						cache.delete("estimate").andWhere("dt=?", Number(e.result)).apply();
						cache.commit().then(() => { SinglePage.modal.estimate.dispatchEvent(new CustomEvent("modal-open", {bubbles: true, composed: true, detail: {}})); });
					}
				}
			});
			const estimates = document.querySelectorAll('[data-estimate]');
			const n = estimates.length;
			for(let i = 0; i < n; i++){
				estimates[i].addEventListener("click", e => {
					const dt = Date.now();
					const type = Number(e.currentTarget.getAttribute("data-estimate"));
					let attrAttr = '';
					let attrElement = '';
					if(type == 2){
						attrElement = '<attributes />';
					}else if(type == 3){
						attrAttr = ' summary_header1="" summary_header2="" summary_header3=""';
						attrElement = '<attributes />';
					}
					cache.insertSet("estimate", {
						xml: `<estimate estimate_date="${new Intl.DateTimeFormat("ja-JP", {dateStyle: "short"}).format(new Date()).split("/").join("-")}" project="" subject="" division="" leader="" manager="" client_name="" apply_client="" payment_date="" specification="" note="" amount_exc="0" amount_tax="0" amount_inc="0"${attrAttr}><info dt="${dt}" update="${dt}" type="${type}" /><detail detail="" record="false" taxable="false" category="">${attrElement}</detail></estimate>`,
						dt: dt
					}, {}).apply();
					cache.commit();
					open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${dt}`, "_blank", "left=0,top=0,width=1200,height=600");
				});
			}
			this.reload();
		}
		reload(){
			fetch("/Home/search", {}).then(fetchArrayBuffer).then(buffer => {
				this.transaction = new SQLite();
				this.transaction.import(buffer, "transaction");
				const countBadge = document.querySelector('page-link[href="/Committed"] span');
				const countValue = this.transaction.select("ONE").setTable("_info").setField("value").andWhere("key=?", "count").apply();
				if((countValue != null) || (countValue > 0)){
					countBadge.textContent = countValue;
				}else{
					countBadge.textContent = "";
				}
			});
		}
	});
{/literal}