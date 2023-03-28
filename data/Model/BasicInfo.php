<?php
namespace Model;
use stdClass;
use App\Validator;

class BasicInfo{
	public static function checkUpdate($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		$result = $check($q);
		return $result;
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$data = [];
			foreach($q as $k => $v){
				$data[] = ["key" => $k, "value" => $v];
			}
			$json = json_encode($data);
			
			$deleteQuery = $db->delete("basic_info");
			$deleteQuery();
			$table = $db->getJsonArray2Tabel(["basic_info" => [
				"key" => "$.key",
				"value" => "$.value",
			]], "t");
			$insertQuery = $db->insertSelect("basic_info", "`key`,`value`")
				->addTable($table, $json)
				->addField("`key`,`value`");
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "基本情報編集", new stdClass());
		}
	}
}