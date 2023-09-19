{literal}
	new VirtualPage("/", class{
		constructor(vp){
			vp.addEventListener("modal-close", e => {
				if(e.dialog == "estimate"){
					if(e.trigger == "list"){
						open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${e.result}`, "_blank", "left=0,top=0,width=1200,height=600");
					}
					if(e.trigger == "delete"){
						cache.delete("estimate").andWhere("dt=?", Number(e.result)).apply();
						cache.commit();
					}
				}
			});
			const estimates = document.querySelectorAll('[data-estimate]');
			const n = estimates.length;
			for(let i = 0; i < n; i++){
				estimates[i].addEventListener("click", e => {
					const dt = Date.now();
					const type = Number(e.currentTarget.getAttribute("data-estimate"));
					cache.insertSet("estimate", {
						xml: `<estimate estimate_date="${new Intl.DateTimeFormat("ja-JP", {dateStyle: "short"}).format(new Date()).split("/").join("-")}" project="" subject="" division="" leader="" manager="" client_name="" apply_client="" payment_date="" specification="" note="" amount_exc="0" amount_tax="0" amount_inc="0"><info dt="${dt}" update="${dt}" type="${type}" /><detail detail="" record="false" taxable="false" category="" /></estimate>`,
						dt: dt
					}, {}).apply();
					cache.commit();
					open(`/Estimate/?channel=${CreateWindowElement.channel}&key=${dt}`, "_blank", "left=0,top=0,width=1200,height=600");
				});
			}
		}
	});
{/literal}