<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class SalesSlip{
	public static function getJsonQuery($db){
		list($jsonField, $keys) = $db->getTable2JsonField(["sales_slips", null], null, [
			"id" => null,
			"output_processed" => null,
			"close_processed" => null,
			"closing_date" => null,
			"created" => null,
			"modified" => null
		]);
		$query = $db->select("ONE")
			->addTable("sales_slips")
			->addField("JSON_OBJECTAGG(id,{$jsonField})", ...$keys);
		return $query;
	}
	
	
	public static function checkInsert($db, $q, $masterData){
		$check = new Validator();
		$check["slip_number"]->required("伝票番号を入力してください。")
			->length("伝票番号は10文字以下で入力してください。", null, 10);
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
		$check["accounting_date"]->required("売上日付を入力してください。")
			->date("売上日付を正しく入力してください。");
		$check["division"]->required("部門を入力してください。")
			->range("部門を正しく入力してください。", "in", ($db->select("COL")->setTable("divisions")->setField("code"))());
		$check["team"]->required("チームを入力してください。")
			->range("チームを正しく入力してください。", "in", ($db->select("COL")->setTable("teams")->setField("code"))());
		$check["manager"]->required("当社担当者を入力してください。")
			->range("当社担当者を正しく入力してください。", "in", ($db->select("COL")->setTable("managers")->setField("code"))());
		$check["billing_destination"]->required("請求先を入力してください。")
			->range("請求先を正しく入力してください。", "in", ($db->select("COL")->setTable("apply_clients")->setField("code"))());
		$check["delivery_destination"]->required("納品先を入力してください。")
			->length("納品先は-文字以下で入力してください。", null, 255);
		//$check["sales_tax_calculation"]->required("税処理を入力してください。")
		//	->range("税処理を正しく入力してください。", "in", [1, 2, 3, 4, 5, 6]);
		$check["subject"]->required("件名を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。")
			->date("入金予定日を正しく入力してください。");
	}
	
	public static function execImport($db, $q, $context, $result){
		$invoiceFormats = [];
		foreach(SelectionModifiers::invoiceFormat([]) as $ak => $av){
			$invoiceFormats[] = [$ak, $av];
		}
		$db->beginTransaction();
		try{
			$tempTable = $db->getJsonArray2Tabel([
				"sales_slips" => [
					"slip_number"          => "$.slip_number",
					"accounting_date"      => "$.accounting_date",
					"division"             => "$.division",
					"team"                 => "$.team",
					"manager"              => "$.manager",
					"billing_destination"  => "$.billing_destination",
					"delivery_destination" => "$.delivery_destination",
					"subject"              => "$.subject",
					"note"                 => "$.note",
					"header1"              => "$.header1",
					"header2"              => "$.header2",
					"header3"              => "$.header3",
					"payment_date"         => "$.payment_date",
					"invoice_format"       => "$.invoice_format",
					"sales_tax"            => "$.sales_tax",
				],
				"dual" => [
					"detail text" => "$.detail"
				]
			], "t");
			$query = $db->insertSelect("sales_slips", "`slip_number`,`accounting_date`,`division`,`team`,`manager`,`billing_destination`,`delivery_destination`,`subject`,`note`,`header1`,`header2`,`header3`,`payment_date`,`invoice_format`,`sales_tax`,`detail`,`created`,`modified`")
				->addTable($tempTable, $q["json"])
				->addField("`slip_number`,`accounting_date`,`division`,`team`,`manager`,`billing_destination`,`delivery_destination`,`subject`,`note`,`header1`,`header2`,`header3`,`payment_date`,`invoice_format`,`sales_tax`,CAST(`detail` AS JSON),now(),now()");
			$query();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("読込に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("読込が完了しました。", "INFO", "");
			@Logger::record($db, "売上取込", ["spreadsheet" => $q["spreadsheets"]]);
		}
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$insertQuery = $db->insertSet("sales_slips", [
				"slip_number" => $q["slip_number"],
				"accounting_date" => $q["accounting_date"],
				"division" => $q["division"],
				"team" => $q["team"],
				"manager" => $q["manager"],
				"billing_destination" => $q["billing_destination"],
				"delivery_destination" => $q["delivery_destination"],
				//"sales_tax_calculation" => $q["sales_tax_calculation"],
				"subject" => $q["subject"],
				"note" => $q["note"],
				"header1" => $q["header1"],
				"header2" => $q["header2"],
				"header3" => $q["header3"],
				"payment_date" => $q["payment_date"],
				"detail" => $q["detail"],
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
			@Logger::record($db, "登録", ["sales_slips" => $id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [
				"accounting_date" => $q["accounting_date"],
				"division" => $q["division"],
				"team" => $q["team"],
				"manager" => $q["manager"],
				"billing_destination" => $q["billing_destination"],
				"delivery_destination" => $q["delivery_destination"],
				//"sales_tax_calculation" => $q["sales_tax_calculation"],
				"subject" => $q["subject"],
				"note" => $q["note"],
				"header1" => $q["header1"],
				"header2" => $q["header2"],
				"header3" => $q["header3"],
				"payment_date" => $q["payment_date"],
				"detail" => $q["detail"],
			],[
				"output_processed" => 0,
				"modified" => "now()",
			]);
			$updateQuery->andWhere("id=?", $id)
				->andWhere("close_processed=0");
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "編集", ["sales_slips" => intval($id)]);
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
		$id = $q["id"];
		$t = [];
		foreach($id as $item){
			$t[] = ["id" => $item];
		}
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"close_processed" => 1,
				"closing_date" => "CURRENT_DATE()"
			]);
			$updateQuery->andWhere("id IN (SELECT id FROM JSON_TABLE(?, '$[*]' COLUMNS(id INT PATH '$.id')) AS t)", json_encode($t))
				->andWhere("output_processed=1");
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("請求締に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("請求締が完了しました。", "INFO", "");
			@Logger::record($db, "請求締", ["sales_slips" => $id]);
		}
	}
	
	public static function execRelease($db, $q, $context, $result){
		$id = $q["id"];
		$t = [];
		foreach($id as $item){
			$t[] = ["id" => $item];
		}
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"close_processed" => 0,
				"closing_date" => "NULL"
			]);
			$updateQuery->andWhere("id IN (SELECT id FROM JSON_TABLE(?, '$[*]' COLUMNS(id INT PATH '$.id')) AS t)", json_encode($t));
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("請求締解除に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("請求締解除が完了しました。", "INFO", "");
			@Logger::record($db, "請求締解除", ["sales_slips" => $id]);
		}
	}
}