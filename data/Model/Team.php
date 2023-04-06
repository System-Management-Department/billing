<?php
namespace Model;
use App\Validator;

class Team{
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
		$check["name"]->required("チーム名を入力してください。")
			->length("チーム名は80文字以下で入力してください。", null, 255);
		$check["kana"]->required("チーム名カナを入力してください。")
			->length("チーム名カナは80文字以下で入力してください。", null, 255);
		$check["location_zip"]->required("郵便番号を入力してください。")
			->length("郵便番号はハイフン無しの7文字で入力してください。", null, 7);
		$check["location_address1"]->required("都道府県を選択してください。");
		$check["location_address2"]->required("市区町村・番地を入力してください。")
			->length("市区町村・番地は80文字以下で入力してください。", null, 255);
		$check["location_address3"]->length("市区町村・番地は80文字以下で入力してください。", null, 255);
		$check["phone"]->required("電話番号を入力してください。")
			->tel("電話番号の形式で入力してください。")
			->length("電話番号は80文字以下で入力してください。", null, 255);
		$check["fax"]->tel("FAX番号の形式で入力してください。")
			->length("FAXは80文字以下で入力してください。", null, 255);
		$check["remarks"]->length("備考は80文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ONE")
				->setTable("teams")
				->setField("(code + 1) as max_id")
				->setOrderBy("LENGTH(code) DESC,code DESC")
				->andWhere("code REGEXP ?", "^[1-9][0-9]*\$");
			$max_id = $query();
			if(empty($max_id)){
				$max_id = 1;
			}

			$insertQuery = $db->insertSet("teams", [
				"code" => $max_id,
				"name" => $q["name"],
				"kana" => $q["kana"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
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
			@SQLite::cache($db, "teams");
			@Logger::record($db, "登録", ["teams" => $max_id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("teams", [
				"name" => $q["name"],
				"kana" => $q["kana"],
				"location_zip" => $q["location_zip"],
				"location_address1" => $q["location_address1"],
				"location_address2" => $q["location_address2"],
				"location_address3" => $q["location_address3"],
				"phone" => $q["phone"],
				"fax" => $q["fax"],
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
			@SQLite::cache($db, "teams");
			@Logger::record($db, "編集", ["teams" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("teams", [
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
			@SQLite::cache($db, "teams");
			@Logger::record($db, "削除", ["teams" => $code]);
		}
	}
	
	public static function execImport($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("teams");
			$deleteQuery();
			$table = $db->getJsonArray2Tabel(["teams" => [
				"code" => "$.code",
				"name" => "$.name",
				"kana" => "$.kana",
				"location_zip" => "$.location_zip",
				"location_address1" => "$.location_address1",
				"location_address2" => "$.location_address2",
				"location_address3" => "$.location_address3",
				"phone" => "$.phone",
				"fax" => "$.fax",
				"note" => "$.note",
			]], "t");
			$insertQuery = $db->insertSelect("teams", "code, name, kana, location_zip, location_address1, location_address2, location_address3, phone, fax, note, created, modified, delete_flag")
				->addTable($table, $q)
				->addField("code, name, kana, location_zip, location_address1, location_address2, location_address3, phone, fax, note")
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
			@SQLite::cache($db, "teams");
			@Logger::record($db, "インポート", ["teams" => []]);
		}
	}
}