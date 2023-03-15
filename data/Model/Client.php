<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class Client{
	public static function checkInsert($db, $q, $masterData){
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	public static function checkUpdate($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	/**
		登録・更新共通の検証
	*/
	public static function validate($check, $masterData, $db){
		$check["name"]->required("得意先名を入力してください。")
			->length("得意先名は-文字以下で入力してください。", null, 255);
		$check["kana"]->required("得意先名カナを入力してください。")
			->length("得意先名カナは-文字以下で入力してください。", null, 255);
		$check["short_name"]->required("得意先名称略を入力してください。")
			->length("得意先名称略は-文字以下で入力してください。", null, 255);
		$check["location_zip"]->required("郵便番号を入力してください。")
			->length("郵便番号はハイフン無しの-文字で入力してください。", null, 7);
		$check["location_address1"]->required("都道府県を選択してください。");
		$check["location_address2"]->required("市区町村・番地を入力してください。")
			->length("市区町村・番地は-文字以下で入力してください。", null, 255);
		$check["location_address3"]->length("市区町村・番地は-文字以下で入力してください。", null, 255);
		$check["phone"]->tel("電話番号の形式で入力してください。")
			->length("電話番号は-文字以下で入力してください。", null, 255);
		$check["fax"]->tel("FAX番号の形式で入力してください。")
			->length("FAXは-文字以下で入力してください。", null, 255);
		$check["email"]->mail("メールアドレスの形式で入力してください。")
			->length("メールアドレスは-文字以下で入力してください。", null, 255);
		$check["homepage"]->length("ホームページは-文字以下で入力してください。", null, 255);
		$check["transactee"]->length("得意先担当者は-文字以下で入力してください。", null, 255);
		$check["transactee_honorific"]->length("得意先担当者は-文字以下で入力してください。", null, 255);
		$check["department"]->length("部署名は-文字以下で入力してください。", null, 255);
		$check["managerial_position"]->length("役職名は-文字以下で入力してください。", null, 255);
		$check["tax_round"]->required("税端数処理を選択してください。");
		$check["tax_processing"]->required("税処理を選択してください。");
		$check["close_processing"]->required("請求方法を選択してください。");
		$check["close_date"]->required("締日指定を選択してください。");
		$check["receivables_balance"]->numeric("期首売掛残高は数値で入力してください。");
		$check["remarks"]->length("備考は-文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ROW")
				->setTable("clients")
				->addField("(CASE WHEN max(code) is null THEN 1 ELSE max(code) + 1 END) as max_id");
			if($max_id = $query()){
			}else{
				$result->addMessage("編集保存に失敗しました。(max_id)", "ERROR", "");
				return;
			}

			$insertQuery = $db->insertSet("clients", [
				"code" => $max_id["max_id"],
				"name" => $q["name"],
				"kana" => $q["kana"],
				"short_name" => $q["short_name"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
				"email" => $q["email"],
				"homepage" => $q["homepage"],
				"transactee" => $q["transactee"],
				"transactee_honorific" => $q["transactee_honorific"],
				"department" => $q["department"],
				"managerial_position" => $q["managerial_position"],
				"unit_price_type" => $q["unit_price_type"],
				"tax_round" => $q["tax_round"],
				"tax_processing" => $q["tax_processing"],
				"close_processing" => $q["close_processing"],
				"close_date" => $q["close_date"],
				"salse_with_ruled_lines" => $q["salse_with_ruled_lines"],
				"delivery_with_ruled_lines" => $q["delivery_with_ruled_lines"],
				"receipt_with_ruled_lines" => $q["receipt_with_ruled_lines"],
				"invoice_with_ruled_lines" => $q["invoice_with_ruled_lines"],
				"receivables_balance" => $q["receivables_balance"] == "" ? 0 : $q["receivables_balance"],
				"location_lat_lng" => $q["location_lat_lng"],
				"remarks" => $q["remarks"],
			],[
				"created" => "now()",
				"modified" => "now()",
				"delete_flag" => "0",
			]);
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@SQLite::cache($db, "clients");
			@Logger::record($db, "登録", ["clients" => $max_id["max_id"]]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("clients", [
				"name" => $q["name"],
				"kana" => $q["kana"],
				"short_name" => $q["short_name"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
				"email" => $q["email"],
				"homepage" => $q["homepage"],
				"transactee" => $q["transactee"],
				"transactee_honorific" => $q["transactee_honorific"],
				"department" => $q["department"],
				"managerial_position" => $q["managerial_position"],
				"unit_price_type" => $q["unit_price_type"],
				"tax_round" => $q["tax_round"],
				"tax_processing" => $q["tax_processing"],
				"close_processing" => $q["close_processing"],
				"close_date" => $q["close_date"],
				"salse_with_ruled_lines" => $q["salse_with_ruled_lines"],
				"delivery_with_ruled_lines" => $q["delivery_with_ruled_lines"],
				"receipt_with_ruled_lines" => $q["receipt_with_ruled_lines"],
				"invoice_with_ruled_lines" => $q["invoice_with_ruled_lines"],
				"receivables_balance" => $q["receivables_balance"] == "" ? 0 : $q["receivables_balance"],
				"location_lat_lng" => $q["location_lat_lng"],
				"remarks" => $q["remarks"],
			],[
				"modified" => "now()",
			]);
			$updateQuery->andWhere("code=?", $code);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@SQLite::cache($db, "clients");
			@Logger::record($db, "編集", ["clients" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("clients", [
			],[
				"delete_flag" => "1",
			]);
			$updateQuery->andWhere("code=?", $code);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
			@SQLite::cache($db, "clients");
			@Logger::record($db, "削除", ["clients" => $code]);
		}
	}
}