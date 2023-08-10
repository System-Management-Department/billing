{literal}
	new VirtualPage("/Committed", class{
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
				{label: "仕入明細", width: "5rem", slot: "purchases_detail"},
				{label: "売上明細", width: "5rem", slot: "salses_detail"},
				{label: "承認解除", width: "5rem", slot: "approval"},
				{label: "伝票番号", width: "8rem", slot: "slip_number"},
				{label: "確定日時", width: "8rem", slot: "regist_datetime"},
				{label: "件名", width: "auto", slot: "subject"},
				{label: "クライアント名", width: "auto", slot: "client_name"},
				{label: "請求先名", width: "auto", slot: "apply_client"},
				{label: "担当者名", width: "auto", slot: "manager"},
				{label: "備考", width: "auto", slot: "note"}
			];
			for(let i = 0; i < 5; i++){
				const values = {
					purchases_detail: '<button type="button" class="btn btn-sm btn-success bx" onclick="SinglePage.modal.purchases_detail.show();">仕入明細</button>',
					salses_detail: '<button type="button" class="btn btn-sm btn-success bx" onclick="SinglePage.modal.salses_detail.show();">売上明細</button>',
					approval: '<button type="button" class="btn btn-sm btn-primary bx bxs-edit">確認承認</button>',
					slip_number: "230700007",
					regist_datetime: "2023-07-11 09:38:29",
					subject: "プレミア 折込印刷・媒体費（ 6/27 関西エリア ）クリエイティブ８種",
					client_name: "コスメディ製薬株式会社",
					apply_client: "anynext株式会社",
					manager: "細川智子",
					note: "お取引条件：月末〆翌月末お支払い",
					edit: '<a href="/Committed/edit" class="btn btn-sm btn-info bx bxs-edit">追加修正</a>'
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
			
			const searchTable = [
				{column: 1, label:"伝票番号", width: 5, name: "slip_number", type: "text", list: "", require: false, placeholder: ""},
				{column: 1, label:"確定日付", width: 12, name: "accounting_date", type: "daterange", list: "", require: false, placeholder: ""},
				{column: 1, label:"部門", width: 10, name: "division", type: "select", list: "division", require: false, placeholder: ""},
				{column: 2, label:"当社担当者", width: 10, name: "manager", type: "keyword", list: "manager", require: false, placeholder: "担当者名・担当者CDで検索"},
				{column: 2, label:"請求先", width: 10, name: "billing_destination", type: "keyword", list: "apply_client", require: false, placeholder: "請求先名・請求先CDで検索"}
			];
			formTableInit(document.querySelector('search-form'), searchTable).then(form => { form.submit(); });
		}
		reload(){
			fetch("/", {
				method: "POST",
				body: this.#lastFormData
			});
		}
	});
{/literal}