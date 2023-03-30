<?php
namespace Model;
use App\Validator;

class Category{
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
		$check["name"]->required("カテゴリー名を入力してください。")
			->length("カテゴリー名は-文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ONE")
				->setTable("clients")
				->setField("(code + 1) as max_id")
				->setOrderBy("LENGTH(code) DESC,code DESC")
				->andWhere("code REGEXP ?", "^[1-9][0-9]*\$");
			$max_id = $query();
			if(empty($max_id)){
				$max_id = 1;
			}

			$insertQuery = $db->insertSet("categories", [
				"code" => $max_id,
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
			@SQLite::cache($db, "categories");
			@Logger::record($db, "登録", ["categories" => $max_id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("categories", [
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
			@SQLite::cache($db, "categories");
			@Logger::record($db, "編集", ["categories" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("categories", [
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
			@SQLite::cache($db, "categories");
			@Logger::record($db, "削除", ["categories" => $code]);
		}
	}
	
	public static function execImport($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("categories");
			$deleteQuery();
			$table = $db->getJsonArray2Tabel(["categories" => [
				"code" => "$.code",
				"name" => "$.name",
			]], "t");
			$insertQuery = $db->insertSelect("categories", "code, name, created, modified, delete_flag")
				->addTable($table, $q)
				->addField("code, name")
				->addField("now(), now(), 0");
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("インポートに失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("インポートが完了しました。", "INFO", "");
			@SQLite::cache($db, "categories");
			@Logger::record($db, "インポート", ["categories" => []]);
		}
	}
}