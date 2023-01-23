class CoForm{
	/**
	 * コンストラクタ
	 * @param form 送信するFORM要素
	 * @param title 成功時に表示するトーストのタイトル
	 * @param action フォームの送信先
	 * @param success 成功時のリダイレクト先
	 * @param inputPromise フォーム入力の追加オブジェクト
	 */
	constructor(form, title, action, success, inputPromise){
		Object.assign(this, {form, title, action, success, inputPromise});
		this.formMap = this.getFormMap(false);
		if("load" in this.inputPromise){
			this.inputPromise.load(this);
		}
	}
	
	/**
	 * フォームの有効無効を保管
	 * @param disabled すべての要素を無効にする
	 * @return 現在の要素,有効無効を格納したMap
	 */
	getFormMap(disabled){
		let res = new Map();
		for(let input of this.form.elements){
			res.set(input, input.disabled);
			if(disabled){
				input.disabled = true;
			}
		}
		return res;
	}
	
	/**
	 * 状態を監視
	 */
	*[Symbol.iterator](){
		// 初期状態 入力待ち
		let target = this, obj = {next: "input", args: []};
		while(target != null){
			obj = yield* target[obj.next](...obj.args);
			if(obj.next in this){
				target = this;
			}else if(obj.next in inputPromise){
				target = inputPromise;
			}else{
				target = null;
			}
		}
	}
	
	/**
	 * 入力待ち
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*input(){
		let pObj = {};
		let listener = e => {
			e.stopPropagation();
			e.preventDefault();
			
			// 次の状態 フォーム送信
			pObj.resolve({next: "submit", args: [new FormData(this.form)]});
		};
		let controller = new AbortController();
		
		// 初期化
		for(let [input, disabled] of this.formMap.entries()){
			input.disabled = disabled;
		}
		this.form.addEventListener("submit", listener, {signal: controller.signal});
		if("inputInit" in this.inputPromise){
			this.inputPromise.inputInit(pObj, controller);
		}
		
		// 入力があるまで待つ
		let p = new Promise((resolve, reject) => {Object.assign(pObj, {resolve, reject})});
		let res = yield p;
		
		// 設定したイベントを一括削除
		controller.abort();
		this.formMap = this.getFormMap(true);
		if("inputFinal" in this.inputPromise){
			this.inputPromise.inputFinal();
		}
		return res;
	}
	
	/**
	 * フォーム送信
	 * @param formData 送信するFormData
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submit(formData){
		let response = yield fetch(this.action, {
			method: "POST",
			body: formData
		}).then(res => res.json());
		if(response.success){
			// フォーム送信 成功
			return yield* this.submitThen(response);
		}
		// フォーム送信 失敗
		return yield* this.submitCatch(response);
	}
	
	/**
	 * フォーム送信 成功
	 * @param response レスポンス
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submitThen(response){
		// メッセージをpushしてリダイレクト
		Storage.pushToast(this.title, response.messages);
		location.href = this.success;
		
		// 次の状態 入力待ち
		return {next: "input", args: []};
	}
	
	/**
	 * フォーム送信 失敗
	 * @param response レスポンス
	 * @return 次に処理するジェネレータのメソッド名と引数のリスト
	 */
	*submitCatch(response){
		// エラーメッセージをオブジェクトへ変更
		let messages = response.messages.reduce((a, message) => {
			if(message[1] == 2){
				a[message[2]] = message[0];
			}
			return a;
		}, {});
		
		// エラーメッセージの表示切替
		let inputs = this.form.querySelectorAll('[name],[data-form-name]');
		for(let input of inputs){
			let name = input.hasAttribute("name") ? input.getAttribute("name") : input.getAttribute("data-form-name");
			if(name in messages){
				input.classList.add("is-invalid");
				input.parentNode.querySelector('.invalid-feedback').textContent = messages[name];
			}else{
				input.classList.remove("is-invalid");
			}
		}
		
		// 次の状態 入力待ち
		return {next: "input", args: []};
	}
}