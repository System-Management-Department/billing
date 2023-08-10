{literal}
	new VirtualPage("/Billing", class{
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
				{"label": "売上明細","width": "5rem","slot": "salses_detail"},
				{"label": "伝票番号","width": "8rem","slot": "slip_number"},
				{"label": "確定日時","width": "8rem","slot": "regist_datetime"},
				{"label": "件名","width": "auto","slot": "subject"},
				{"label": "クライアント名","width": "auto","slot": "client_name"},
				{"label": "請求先名","width": "auto","slot": "apply_client"},
				{"label": "担当者名","width": "auto","slot": "manager"},
				{"label": "備考","width": "auto","slot": "note"}
			];
			for(let i = 0; i < 5; i++){
				const values = {
					salses_detail: '<button type="button" class="btn btn-sm btn-success bx" onclick="SinglePage.modal.salses_detail.show();">売上明細</button>',
					slip_number: "230700007",
					regist_datetime: "2023-07-11 09:38:29",
					subject: "プレミア 折込印刷・媒体費（ 6/27 関西エリア ）クリエイティブ８種",
					client_name: "コスメディ製薬株式会社",
					apply_client: "anynext株式会社",
					manager: "細川智子",
					note: "お取引条件：月末〆翌月末お支払い",
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
			
			formTableInit(document.querySelector('search-form'), formTableQuery("/Billing#search").apply()).then(form => { form.submit(); });
		}
		reload(){
			fetch("/", {
				method: "POST",
				body: this.#lastFormData
			});
		}
	});
{/literal}