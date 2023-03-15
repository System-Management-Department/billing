<?php
namespace Model;
use App\Validator;

class Division{
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
		$check["name"]->required("部門名を入力してください。")
			->length("部門名は-文字以下で入力してください。", null, 255);
		$check["kana"]->required("部門名カナを入力してください。")
			->length("部門名カナは-文字以下で入力してください。", null, 255);
		$check["location_zip"]->required("郵便番号を入力してください。")
			->length("郵便番号はハイフン無しの-文字で入力してください。", null, 7);
		$check["location_address1"]->required("都道府県を選択してください。");
		$check["location_address2"]->required("市区町村・番地を入力してください。")
			->length("市区町村・番地は-文字以下で入力してください。", null, 255);
		$check["location_address3"]->length("市区町村・番地は-文字以下で入力してください。", null, 255);
		$check["phone"]->required("電話番号を入力してください。")
			->tel("電話番号の形式で入力してください。")
			->length("電話番号は-文字以下で入力してください。", null, 255);
		$check["fax"]->tel("FAX番号の形式で入力してください。")
			->length("FAXは-文字以下で入力してください。", null, 255);
		$check["remarks"]->length("備考は-文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ROW")
				->setTable("divisions")
				->addField("(CASE WHEN max(code) is null THEN 1 ELSE max(code) + 1 END) as max_id");
			if($max_id = $query()){
			}else{
				$result->addMessage("編集保存に失敗しました。(max_id)", "ERROR", "");
				return;
			}

			$insertQuery = $db->insertSet("divisions", [
				"code" => $max_id["max_id"],
				"name" => $q["name"],
				"kana" => $q["kana"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
				"print_flag" => isset($q["print_flag"]) ? 1 : 0,
				"note" => $q["note"],
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
			@SQLite::cache($db, "divisions");
			@Logger::record($db, "登録", ["divisions" => $max_id["max_id"]]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("divisions", [
				"name" => $q["name"],
				"kana" => $q["kana"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
				"print_flag" => isset($q["print_flag"]) ? 1 : 0,
				"note" => $q["note"],
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
			@SQLite::cache($db, "divisions");
			@Logger::record($db, "編集", ["divisions" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("divisions", [
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
			@SQLite::cache($db, "divisions");
			@Logger::record($db, "削除", ["divisions" => $code]);
		}
	}
}