<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class ApplyClient{
	public static $delimiter = "-";
	
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
		$check["client"]->required("得意先を入力してください。")
			->range("得意先を正しく入力してください。", "in", ($db->select("COL")->setTable("clients")->setField("code"))());
		$check["name"]->required("請求先名を入力してください。")
			->length("請求先名は-文字以下で入力してください。", null, 255);
		$check["kana"]->required("請求先名カナを入力してください。")
			->length("請求先名カナは-文字以下で入力してください。", null, 255);
		$check["short_name"]->required("請求先名称略を入力してください。")
			->length("請求先名称略は-文字以下で入力してください。", null, 255);
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
		$check["transactee"]->length("請求先担当者は-文字以下で入力してください。", null, 255);
		$check["transactee_honorific"]->length("請求先担当者は-文字以下で入力してください。", null, 255);
		$check["tax_round"]->required("税端数処理を選択してください。");
		$check["tax_processing"]->required("税処理を選択してください。");
		$check["close_processing"]->required("請求方法を選択してください。");
		$check["close_date"]->required("締日指定を選択してください。");
		$check["payment_cycle"]->required("入金サイクルを選択してください。");
		$check["payment_date"]->required("入金予定日を選択してください。");
		$check["invoice_format"]->required("請求書パターンを選択してください。");
		$check["receivables_balance"]->numeric("期首売掛残高は数値で入力してください。");
		$check["note"]->length("備考は-文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$query = $db
				->select("ONE")
				->setTable("apply_clients")
				->setField("(SUBSTRING_INDEX(code,?,1) + 1) as max_id", self::$delimiter)
				->setOrderBy("LENGTH(SUBSTRING_INDEX(code,?,1)) DESC,SUBSTRING_INDEX(code,?,1) DESC", self::$delimiter, self::$delimiter)
				->andWhere("code REGEXP ?", "^[1-9][0-9]*" . self::$delimiter);
			$max_id = $query();
			if(empty($max_id)){
				$max_id = 1;
			}

			$insertQuery = $db->insertSet("apply_clients", [
				"client" => $q["client"],
				"code" => $max_id . self::$delimiter . $q["client"],
				"unique_name" => $q["name"],
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
				//"location_lat_lng" => $q["location_lat_lng"],
				"note" => $q["note"],
				"payment_date" => $q["payment_date"],
				"payment_cycle" => $q["payment_cycle"],
				"invoice_format" => $q["invoice_format"],
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
			@SQLite::cache($db, "apply_clients");
			@Logger::record($db, "登録", ["apply_clients" => $max_id . self::$delimiter . $q["client"]]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$code = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("apply_clients", [
				"client" => $q["client"],
				"unique_name" => $q["name"],
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
				//"location_lat_lng" => $q["location_lat_lng"],
				"note" => $q["note"],
				"payment_date" => $q["payment_date"],
				"payment_cycle" => $q["payment_cycle"],
				"invoice_format" => $q["invoice_format"],
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
			@SQLite::cache($db, "apply_clients");
			@Logger::record($db, "編集", ["apply_clients" => $code]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$code = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("apply_clients", [
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
			@SQLite::cache($db, "apply_clients");
			@Logger::record($db, "削除", ["apply_clients" => $code]);
		}
	}
	
	public static function execImport($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("apply_clients");
			$deleteQuery();
			$table = $db->getJsonArray2Tabel(["apply_clients" => [
				"code" => "$.code",
				"client" => "$.client",
				"unique_name" => "$.name",
				"name" => "$.name",
				"kana" => "$.kana",
				"short_name" => "$.short_name",
				"location_zip" => "$.location_zip",
				"location_address1" => "$.location_address1",
				"location_address2" => "$.location_address2",
				"location_address3" => "$.location_address3",
				"phone" => "$.phone",
				"fax" => "$.fax",
				"email" => "$.email",
				"homepage" => "$.homepage",
				"transactee" => "$.transactee",
				"transactee_honorific" => "$.transactee_honorific",
				"unit_price_type" => "$.unit_price_type",
				"tax_round" => "$.tax_round",
				"tax_processing" => "$.tax_processing",
				"close_processing" => "$.close_processing",
				"close_date" => "$.close_date",
				"salse_with_ruled_lines" => "$.salse_with_ruled_lines",
				"delivery_with_ruled_lines" => "$.delivery_with_ruled_lines",
				"receipt_with_ruled_lines" => "$.receipt_with_ruled_lines",
				"invoice_with_ruled_lines" => "$.invoice_with_ruled_lines",
				"receivables_balance" => "$.receivables_balance",
				"note" => "$.note",
				"payment_date" => "$.payment_date",
				"payment_cycle" => "$.payment_cycle",
				"invoice_format" => "$.invoice_format",
			]], "t");
			$insertQuery = $db->insertSelect("apply_clients", "code, client, unique_name, name, kana, short_name, location_zip, location_address1, location_address2, location_address3, phone, fax, email, homepage, transactee, transactee_honorific, unit_price_type, tax_round, tax_processing, close_processing, close_date, salse_with_ruled_lines, delivery_with_ruled_lines, receipt_with_ruled_lines, invoice_with_ruled_lines, receivables_balance, note, payment_date, payment_cycle, invoice_format, created, modified, delete_flag")
				->addTable($table, $q)
				->addField("code, client, unique_name, name, kana, short_name, location_zip, location_address1, location_address2, location_address3, phone, fax, email, homepage, transactee, transactee_honorific, unit_price_type, tax_round, tax_processing, close_processing, close_date, salse_with_ruled_lines, delivery_with_ruled_lines, receipt_with_ruled_lines, invoice_with_ruled_lines, receivables_balance, note, payment_date, payment_cycle, invoice_format")
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
			@SQLite::cache($db, "apply_clients");
			@Logger::record($db, "インポート", ["apply_clients" => []]);
		}
	}
}