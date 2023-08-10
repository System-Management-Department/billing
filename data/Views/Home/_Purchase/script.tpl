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
			
			const table1 = document.querySelector('table-sticky');
			table1.columns = [
				{"label": "仕入登録","width": "5rem","slot": "edit"},
				{"label": "担当者名","width": "auto","slot": "manager"},
				{"label": "伝票番号","width": "8rem","slot": "slip_number"},
				{"label": "確定日時","width": "8rem","slot": "regist_datetime"},
				{"label": "クライアント名","width": "auto","slot": "client_name"},
				{"label": "件名","width": "auto","slot": "subject"},
				{"label": "仕入先","width": "auto","slot": "supplier"},
				{"label": "仕入金額（税抜き）","width": "auto","slot": "amount_exc"},
				{"label": "仕入金額（税込み）","width": "auto","slot": "amount_inc"},
				{"label": "請求書受領","width": "auto","slot": "payment"}
			];
			for(let i = 0; i < 5; i++){
				const values = {
					slip_number: "230700007",
					regist_datetime: "2023-07-11 09:38:29",
					subject: "プレミア 折込印刷・媒体費（ 6/27 関西エリア ）クリエイティブ８種",
					client_name: "コスメディ製薬株式会社",
					apply_client: "anynext株式会社",
					manager: "細川智子",
					edit: '<a href="/Committed/edit" class="btn btn-sm btn-info bx bxs-edit">追加修正</a>',
					supplier: "*****",
					amount_exc: "1,000,000",
					amount_inc: "1,100,000",
					payment: '<button type="button" class="btn btn-sm btn-success bx" onclick="SinglePage.modal.salses_detail.show();">請求書受領</button>'
				};
				const elements = [];
				for(let key in values){
					const div = document.createElement("div");
					div.setAttribute("slot", key);
					div.innerHTML = values[key];
					elements.push(div);
				}
				table1.insertRow(...elements);
			}
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Purchase#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/", {
				method: "POST",
				body: this.#lastFormData
			});
		}
	});
{/literal}