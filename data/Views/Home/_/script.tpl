{literal}
	new VirtualPage("/", class{
		constructor(vp){
			SinglePage.modal.apply_client.addEventListener("modal-open", e => {
				console.log(e.detail);// 検索処理
			});
			
		}
	});
{/literal}