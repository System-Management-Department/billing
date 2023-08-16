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
			vp.addEventListener("modal-close", e => { console.log(e); });
			document.querySelector('table-sticky').columns = dataTableQuery("/Purchase#list").apply().map(row => { return {label: row.label, width: row.width, slot: row.slot, part: row.part}; });
			formTableInit(document.querySelector('search-form'), formTableQuery("/Purchase#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/", {
				method: "POST",
				body: this.#lastFormData
			});
			
			const data = new Array(5).fill({
				slip_number: "230700007",
				regist_datetime: "2023-07-11 09:38:29",
				subject: "プレミア 折込印刷・媒体費（ 6/27 関西エリア ）クリエイティブ８種",
				client_name: "コスメディ製薬株式会社",
				apply_client: "anynext株式会社",
				manager: "細川智子",
				sd: "1",
				supplier: "*****",
				amount_exc: "1,000,000",
				amount_inc: "1,100,000",
				payment: '<button type="button" class="btn btn-sm btn-success bx" onclick="SinglePage.modal.salses_detail.show();">請求書受領</button>'
			});
			setDataTable(document.querySelector('table-sticky'), dataTableQuery("/Purchase#list").apply(), data);
		}
	});
{/literal}