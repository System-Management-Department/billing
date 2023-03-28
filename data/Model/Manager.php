<?php
namespace Model;
use App\Validator;

class Manager{
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
		$check["name"]->required("担当者名を入力してください。")
			->length("担当者名は-文字以下で入力してください。", null, 255);
		$check["kana"]->required("担当者名カナを入力してください。")
			->length("担当者名カナは-文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ROW")
				->setTable("managers")
				->addField("(CASE WHEN max(code) is null THEN 1 ELSE max(code) + 1 END) as max_id");
			if($max_id = $query()){
			}else{
				$result->addMessage("編集保存に失敗しました。(max_id)", "ERROR", "");
				return;
			}
			
			$insertQuery = $db->insertSet("managers", [
				"code" => $max_id["max_id"],
				"name" => $q["name"],
				"kana" => $q["kana"],
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
			@SQLite::cache($db, "managers");
			@Logger::record($db, "登録", ["managers" => $q["code"]]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("managers", [
				"name" => $q["name"],
				"kana" => $q["kana"],
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
			@SQLite::cache($db, "managers");
			@Logger::record($db, "編集", ["managers" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("managers", [
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
			@SQLite::cache($db, "managers");
			@Logger::record($db, "削除", ["managers" => $q["id"]]);
		}
	}
}