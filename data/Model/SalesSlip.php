<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class SalesSlip{
	public static function checkInsert($db, $q, $masterData){
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		
		try{
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$result2 = new Result();
				$result2->onAddMessage(function(&$message, &$status, &$name, $i){
					$name = "detail/{$i}/{$name}";
				}, $i);
				$check = new Validator();
				self::validateDetail($check, $masterData, $db, $detail[$i]);
				$result->mergeMessage($check($result2, $detail[$i]));
			}
		}catch(\Exception $ex){
		}
		return $result;
	}
	
	public static function checkUpdate($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$check["slip_number"]->required("伝票番号を入力してください。");
		$result = $check($q);
		
		try{
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$result2 = new Result();
				$result2->onAddMessage(function(&$message, &$status, &$name, $i){
					$name = "detail/{$i}/{$name}";
				}, $i);
				$check = new Validator();
				self::validateDetail($check, $masterData, $db, $detail[$i]);
				$check["sd"]->required("行を選択してください。");
				$result->mergeMessage($check($result2, $detail[$i]));
			}
		}catch(\Exception $ex){
		}
		return $result;
	}
	
	/**
		登録・更新共通の検証
	*/
	public static function validate($check, $masterData, $db){
		$check["subject"]->required("件名を入力してください。");
		$check["invoice_format"]->required("請求パターンを入力してください。");
		$check["division"]->required("部門を入力してください。");
		$check["leader"]->required("部門長を入力してください。");
		$check["manager"]->required("当社担当者を入力してください。");
		$check["client_name"]->required("納品先を入力してください。")
			->length("納品先は80文字以下で入力してください。", null, 255);
		$check["apply_client"]->required("請求先を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。")
			->date("入金予定日を正しく入力してください。");
		$check["amount_exc"]->required("税抜合計金額を入力してください。");
		$check["amount_tax"]->required("消費税合計金額を入力してください。");
		$check["amount_inc"]->required("税込合計金額を入力してください。");
	}
	
	/**
		登録・更新共通の検証（明細）
	*/
	public static function validateDetail($check, $masterData, $db, $q){
		$check["record"]->required("計上を入力してください。")
			->range("計上を正しく入力してください。", "in", [0, 1]);
		if($q["record"] == 1){
			$check["detail"]->required("内容を入力してください。");
			$check["quantity"]->required("数量を入力してください。");
			$check["unit"]->required("単位を入力してください。");
			$check["unit_price"]->required("単価を入力してください。");
			$check["amount_exc"]->required("税抜金額を入力してください。");
			$check["amount_tax"]->required("消費税金額を入力してください。");
			$check["amount_inc"]->required("税込金額を入力してください。");
			$check["taxable"]->required("課税を入力してください。")
				->range("課税を正しく入力してください。", "in", [0, 1]);
			$check["tax_rate"]->required("税率を入力してください。");
			$check["category"]->required("カテゴリーを入力してください。");
		}
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			// 伝票番号生成
			$sequence = $db->select("ONE")
				->setTable("slip_sequence")
				->setField("seq")
				->andWhere("month=?", $q["sequence"])
				->andWhere("type=1");
			$slipNumber = $sequence() + 1;
			$updateQuery = $db->updateSet("slip_sequence", [],[
				"seq" => "seq+1",
			])
				->andWhere("month=?", $q["sequence"])
				->andWhere("type=1");
			$updateQuery();
			
			// 売上・売上追加情報・売上ワークフロー・売上明細・売上明細追加情報・仕入関係の登録
			$insertQuery = $db->insertSet("sales_slips", [
				"invoice_format" => $q["invoice_format"],
				"slip_number" => sprintf("%s%05d", $q["sequence"], $slipNumber),
				"project" => $q["project"],
				"subject" => $q["subject"],
				"division" => $q["division"],
				"leader" => $q["leader"],
				"manager" => $q["manager"],
				"client_name" => $q["client_name"],
				"apply_client" => $q["apply_client"],
				"payment_date" => $q["payment_date"],
				"note" => $q["note"],
				"amount_exc" => $q["amount_exc"],
				"amount_tax" => $q["amount_tax"],
				"amount_inc" => $q["amount_inc"],
			],[]);
			$insertQuery($id);
			
			if($q["invoice_format"] == 3){
				$insertQuery = $db->insertSet("sales_attributes", [
					"ss" => $id,
					"data" => json_encode(["summary_header" => [
						$q["summary_header1"],
						$q["summary_header2"],
						$q["summary_header3"],
					]]),
				],[]);
				$insertQuery();
			}
			
			$insertQuery = $db->insertSet("sales_workflow", [
				"ss" => $id,
				"regist_user" => $_SESSION["User.id"],
			],[
				"regist_datetime" => "now()",
			]);
			$insertQuery();
			
			$detailIds = [];
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$insertQuery = $db->insertSet("sales_details", [
					"record" => $detail[$i]["record"],
					"detail" => $detail[$i]["detail"],
					"quantity" => $detail[$i]["quantity"],
					"unit" => $detail[$i]["unit"],
					"unit_price" => $detail[$i]["unit_price"],
					"amount_exc" => $detail[$i]["amount_exc"],
					"amount_tax" => $detail[$i]["amount_tax"],
					"amount_inc" => $detail[$i]["amount_inc"],
					"taxable" => $detail[$i]["taxable"],
					"tax_rate" => $detail[$i]["tax_rate"],
					"category" => $detail[$i]["category"],
				],[]);
				$insertQuery($sd);
				
				if($q["invoice_format"] == 2){
					$insertQuery = $db->insertSet("sales_detail_attributes", [
						"sd" => $sd,
						"data" => json_encode(["circulation" => $detail[$i]["attributes"]["circulation"]]),
					],[]);
					$insertQuery();
				}else if($q["invoice_format"] == 3){
					$insertQuery = $db->insertSet("sales_detail_attributes", [
						"sd" => $sd,
						"data" => json_encode(["summary_data" => [
							$detail[$i]["attributes"]["summary_data1"],
							$detail[$i]["attributes"]["summary_data2"],
							$detail[$i]["attributes"]["summary_data3"],
						]]),
					],[]);
					$insertQuery();
				}
				
				$insertQuery = $db->insertSet("purchase_relations", [
					"ss" => $id,
					"sd" => $sd,
				],[]);
				$insertQuery();
			}
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [
				"project" => $q["project"],
				"subject" => $q["subject"],
				"division" => $q["division"],
				"leader" => $q["leader"],
				"manager" => $q["manager"],
				"client_name" => $q["client_name"],
				"apply_client" => $q["apply_client"],
				"payment_date" => $q["payment_date"],
				"note" => $q["note"],
				"amount_exc" => $q["amount_exc"],
				"amount_tax" => $q["amount_tax"],
				"amount_inc" => $q["amount_inc"],
			],[]);
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$updateQuery = $db->updateSet("sales_details", [
					"detail" => $detail[$i]["detail"],
					"quantity" => $detail[$i]["quantity"],
					"unit" => $detail[$i]["unit"],
					"unit_price" => $detail[$i]["unit_price"],
					"category" => $detail[$i]["category"],
				],[]);
				$updateQuery->andWhere("sd=?", $detail[$i]["sd"]);
				$updateQuery();
			}
			
			$detail = json_decode($q["detail_attribute"], true);
			if(!empty($detail)){
				$len = count($detail);
				for($i = 0; $i < $len; $i++){
					$updateQuery = $db->updateSet("sales_attributes", [
						"data" => $detail[$i]["data"],
					],[]);
					$updateQuery->andWhere("sd=?", $detail[$i]["sd"]);
					$updateQuery();
				}
			}
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("close_processed=0")
			->andWhere("id=?", $q["id"]);
		
		$data = $query();
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("sales_slips");
			$deleteQuery->andWhere("id=?", $q["id"])
				->andWhere("close_processed=0");
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
			@Logger::record($db, "削除", ["sales_slips" => $data["id"]]);
		}
	}
	
	public static function execOutput($db, $q, $context, $result){
		$id = $q["id"];
		$t = [];
		foreach($id as $item){
			$t[] = ["id" => $item];
		}
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"output_processed" => 1,
			]);
			$updateQuery->andWhere("id IN (SELECT id FROM JSON_TABLE(?, '$[*]' COLUMNS(id INT PATH '$.id')) AS t)", json_encode($t));
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("出力に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("出力が完了しました。", "INFO", "");
			@Logger::record($db, "出力", ["sales_slips" => $id]);
		}
	}
	
	public static function execClose($db, $q, $context, $result){
		$month = date("ym"); 
		$db->beginTransaction();
		try{
			// 版番号生成
			$sequence = $db->select("ONE")
				->setTable("slip_sequence")
				->setField("seq")
				->andWhere("month=?", $month)
				->andWhere("type=5");
			$slipNumber = $sequence();
			if(empty($slipNumber)){
				$slipNumber = 1;
				$insertQuery = $db->insertSet("slip_sequence", [
					"seq" => 1,
					"month" => $month,
					"type" => 5,
				],[]);
				$insertQuery();
				$db->commit();
			}else{
				$slipNumber++;
				$updateQuery = $db->updateSet("slip_sequence", [],[
					"seq" => "seq+1",
				]);
				$updateQuery->andWhere("month=?", $month);
				$updateQuery->andWhere("type=5");
				$updateQuery();
				$db->commit();
			}
			$version = sprintf("%s%05d", $month, $slipNumber);
			
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"close" => 1,
				"close_version" => $version,
				"close_datetime" => "NOW()",
				"close_user" => $_SESSION["User.id"],
			]);
			$updateQuery->addWith("search AS (SELECT ss FROM JSON_TABLE(?, '$[*]' COLUMNS(slip_number TEXT PATH '$')) AS t LEFT JOIN sales_slips USING(slip_number))", $q["id"]);
			$updateQuery->andWhere("EXISTS(SELECT 1 FROM search WHERE search.ss=sales_workflow.ss)");
			// TODO 検索条件の修正
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("請求締に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("請求締が完了しました。", "INFO", "");
			$result->addMessage($version, "INFO", "no");
		}
	}
	
	public static function execCloseUndo($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"close" => 0,
				"close_version" => "NULL",
				"close_datetime" => "NULL",
				"close_user" => "NULL",
			]);
			$updateQuery->andWhere("close_version=?", $q["id"]);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("更新に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("更新が完了しました。", "INFO", "");
		}
	}
	
	public static function execRelease($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [
				"release_comment" => $q["comment"],
			],[
				"request" => 0,
				"request_datetime" => "NULL",
				"approval" => 0,
				"approval_datetime" => "NULL",
				"approval_user" => "NULL",
				"close" => 0,
				"close_version" => "NULL",
				"close_datetime" => "NULL",
				"close_user" => "NULL",
				"release_datetime" => "NOW()",
			]);
			$updateQuery->addWith("search AS (SELECT ss FROM JSON_TABLE(?, '$[*]' COLUMNS(slip_number TEXT PATH '$')) AS t LEFT JOIN sales_slips USING(slip_number))", $q["id"]);
			$updateQuery->andWhere("EXISTS(SELECT 1 FROM search WHERE search.ss=sales_workflow.ss)");
			// TODO 検索条件の修正
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("請求締解除に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("請求締解除が完了しました。", "INFO", "");
		}
	}
	
	public static function request($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"request" => 1,
				"request_datetime" => "NOW()",
			]);
			$updateQuery->andWhere("request=0");
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("申請に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("申請を行いました。", "INFO", "");
		}
	}
	
	public static function withdraw($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"request" => 0,
				"request_datetime" => "NULL",
			]);
			$updateQuery->andWhere("request=1");
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("取下に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("申請を取り下げました。", "INFO", "");
		}
	}
	
	public static function deleteSlip($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			// TODO検索条件
			$deleteQuery = $db->delete("sales_slips")->andWhere("ss=?", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("sales_attributes")->andWhere("ss=?", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("sales_workflow")->andWhere("ss=?", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("sales_details")->andWhere("sd IN(SELECT sd FROM purchase_relations WHERE ss=?)", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("sales_details")->andWhere("sd IN(SELECT sd FROM purchase_relations WHERE ss=?)", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("sales_detail_attributes")->andWhere("sd IN(SELECT sd FROM purchase_relations WHERE ss=?)", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("purchases")->andWhere("pu IN(SELECT pu FROM purchase_relations WHERE ss=?)", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("purchases_attributes")->andWhere("pu IN(SELECT pu FROM purchase_relations WHERE ss=?)", $id);
			$deleteQuery();
			$deleteQuery = $db->delete("purchase_relations")->andWhere("ss=?", $id);
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("案件削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("案件を削除しました。", "INFO", "");
		}
	}
	
	public static function approval($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"approval" => 1,
				"approval_datetime" => "NOW()",
				"approval_user" => $_SESSION["User.id"],
			]);
			$updateQuery->andWhere("request=1");
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("承認に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("承認が完了しました。", "INFO", "");
		}
	}
	
	public static function disapproval($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_workflow", [],[
				"approval" => 0,
				"approval_datetime" => "NULL",
				"approval_user" => "NULL",
			]);
			$updateQuery->andWhere("approval=1");
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("承認解除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("承認解除が完了しました。", "INFO", "");
		}
	}
}