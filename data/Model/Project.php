<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class Project{
	public static function getJsonQuery($db){
		list($jsonField, $keys) = $db->getTable2JsonField(["projects", null], null, [
			"id" => null,
			"created" => null,
			"modified" => null
		]);
		$query = $db->select("ONE")
			->addTable("projects")
			->addField("JSON_OBJECTAGG(id,{$jsonField})", ...$keys);
		return $query;
	}
	
	
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
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$insertQuery = $db->insertSet("projects", [
			],[
				"created" => "now()",
				"modified" => "now()",
			]);
			$insertQuery($id);
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "登録", ["projects" => $id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("projects", [
			],[
				"modified" => "now()",
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "編集", ["projects" => intval($id)]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$query = $db->select("ROW")
			->andWhere("id=?", $q["id"]);
		
		$data = $query();
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("projects");
			$deleteQuery->andWhere("id=?", $q["id"]);
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
			@Logger::record($db, "削除", ["projects" => $data["id"]]);
		}
	}
}