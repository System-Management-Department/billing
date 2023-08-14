{literal}
	new VirtualPage("/Sales", class{
		#lastFormData;
		constructor(vp){
			this.#lastFormData = null;
			vp.addEventListener("search", e => {
				this.#lastFormData = e.formData;
				this.reload();
			});
			vp.addEventListener("reload", e => { this.reload(); });
			vp.addEventListener("modal-close", e => { console.log(e); });
			document.querySelector('table-sticky').columns = dataTableQuery("/Sales#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Sales#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/", {
				method: "POST",
				body: this.#lastFormData
			});
			
			const data = new Array(5).fill({
				ss: 1,
				slip_number: "230700007",
				regist_datetime: "2023-07-11 09:38:29",
				subject: "プレミア 折込印刷・媒体費（ 6/27 関西エリア ）クリエイティブ８種",
				client_name: "コスメディ製薬株式会社",
				apply_client: "anynext株式会社",
				manager: "細川智子",
				note: "お取引条件：月末〆翌月末お支払い"
			});
			setDataTable(document.querySelector('table-sticky'), dataTableQuery("/Sales#list").apply(), data);
		}
	});
{/literal}