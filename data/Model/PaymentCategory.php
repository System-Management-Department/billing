<?php
namespace Model;
use App\Validator;

class PaymentCategory{
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
		$check["name"]->required("入金区分名を入力してください。")
			->length("入金区分名は-文字以下で入力してください。", null, 255);
		$check["type"]->required("	入金種別を選択してください。");
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ONE")
				->setTable("payment_categories")
				->setField("(code + 1) as max_id")
				->setOrderBy("LENGTH(code) DESC,code DESC")
				->andWhere("code REGEXP ?", "^[1-9][0-9]*\$");
			$max_id = $query();
			if(empty($max_id)){
				$max_id = 1;
			}
			
			$insertQuery = $db->insertSet("payment_categories", [
				"code" => $max_id,
				"type" => $q["type"],
				"name" => $q["name"],
			],[
				"created" => "now()",
				"modified" => "now()",
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
			@SQLite::cache($db, "payment_categories");
			@Logger::record($db, "登録", ["payment_categories" => $max_id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("payment_categories", [
				"type" => $q["type"],
				"name" => $q["name"],
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
			@SQLite::cache($db, "payment_categories");
			@Logger::record($db, "編集", ["payment_categories" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("payment_categories", [
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
			@SQLite::cache($db, "payment_categories");
			@Logger::record($db, "削除", ["payment_categories" => $q["id"]]);
		}
	}
}