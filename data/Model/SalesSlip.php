<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;

class SalesSlip{
	public static function checkInsert($db, $q, $masterData){
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		
		try{
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$result2 = new Result();
				$result2->onAddMessage(function(&$message, &$status, &$name, $i){
					$name = "detail/{$i}/{$name}";
				}, $i);
				$check = new Validator();
				self::validateDetail($check, $masterData, $db, $detail[$i]);
				$result->mergeMessage($check($result2, $detail[$i]));
			}
		}catch(\Exception $ex){
		}
		return $result;
	}
	
	public static function checkUpdate($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$check["slip_number"]->required("伝票番号を入力してください。");
		$result = $check($q);
		
		try{
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$result2 = new Result();
				$result2->onAddMessage(function(&$message, &$status, &$name, $i){
					$name = "detail/{$i}/{$name}";
				}, $i);
				$check = new Validator();
				self::validateDetail($check, $masterData, $db, $detail[$i]);
				$check["sd"]->required("行を選択してください。");
				$result->mergeMessage($check($result2, $detail[$i]));
			}
		}catch(\Exception $ex){
		}
		return $result;
	}
	
	/**
		登録・更新共通の検証
	*/
	public static function validate($check, $masterData, $db){
		$check["subject"]->required("件名を入力してください。");
		$check["invoice_format"]->required("請求パターンを入力してください。");
		$check["division"]->required("部門を入力してください。");
		$check["leader"]->required("部門長を入力してください。");
		$check["manager"]->required("当社担当者を入力してください。");
		$check["client_name"]->required("納品先を入力してください。")
			->length("納品先は80文字以下で入力してください。", null, 255);
		$check["apply_client"]->required("請求先を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。")
			->date("入金予定日を正しく入力してください。");
		$check["amount_exc"]->required("税抜合計金額を入力してください。");
		$check["amount_tax"]->required("消費税合計金額を入力してください。");
		$check["amount_inc"]->required("税込合計金額を入力してください。");
	}
	
	/**
		登録・更新共通の検証（明細）
	*/
	public static function validateDetail($check, $masterData, $db, $q){
		$check["record"]->required("計上を入力してください。")
			->range("計上を正しく入力してください。", "in", [0, 1]);
		if($q["record"] == 1){
			$check["detail"]->required("内容を入力してください。");
			$check["quantity"]->required("数量を入力してください。");
			$check["unit"]->required("単位を入力してください。");
			$check["unit_price"]->required("単価を入力してください。");
			$check["amount_exc"]->required("税抜金額を入力してください。");
			$check["amount_tax"]->required("消費税金額を入力してください。");
			$check["amount_inc"]->required("税込金額を入力してください。");
			$check["taxable"]->required("課税を入力してください。")
				->range("課税を正しく入力してください。", "in", [0, 1]);
			$check["tax_rate"]->required("税率を入力してください。");
			$check["category"]->required("カテゴリーを入力してください。");
		}
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			// 伝票番号生成
			$sequence = $db->select("ONE")
				->setTable("slip_sequence")
				->setField("seq")
				->andWhere("month=?", $q["sequence"])
				->andWhere("type=1");
			$slipNumber = $sequence() + 1;
			$updateQuery = $db->updateSet("slip_sequence", [],[
				"seq" => "seq+1",
			])
				->andWhere("month=?", $q["sequence"])
				->andWhere("type=1");
			$updateQuery();
			
			// 売上・売上追加情報・売上ワークフロー・売上明細・売上明細追加情報・仕入関係の登録
			$insertQuery = $db->insertSet("sales_slips", [
				"invoice_format" => $q["invoice_format"],
				"slip_number" => sprintf("%s%05d", $q["sequence"], $slipNumber),
				"project" => $q["project"],
				"subject" => $q["subject"],
				"division" => $q["division"],
				"leader" => $q["leader"],
				"manager" => $q["manager"],
				"client_name" => $q["client_name"],
				"apply_client" => $q["apply_client"],
				"payment_date" => $q["payment_date"],
				"note" => $q["note"],
				"amount_exc" => $q["amount_exc"],
				"amount_tax" => $q["amount_tax"],
				"amount_inc" => $q["amount_inc"],
			],[]);
			$insertQuery($id);
			
			if($q["invoice_format"] == 3){
				$insertQuery = $db->insertSet("sales_attributes", [
					"ss" => $id,
					"data" => json_encode(["summary_header" => [
						$q["summary_header1"],
						$q["summary_header2"],
						$q["summary_header3"],
					]]),
				],[]);
				$insertQuery();
			}
			
			$insertQuery = $db->insertSet("sales_workflow", [
				"ss" => $id,
				"regist_user" => $_SESSION["User.id"],
			],[
				"regist_datetime" => "now()",
			]);
			$insertQuery();
			
			$detailIds = [];
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$insertQuery = $db->insertSet("sales_details", [
					"record" => $detail[$i]["record"],
					"detail" => $detail[$i]["detail"],
					"quantity" => $detail[$i]["quantity"],
					"unit" => $detail[$i]["unit"],
					"unit_price" => $detail[$i]["unit_price"],
					"amount_exc" => $detail[$i]["amount_exc"],
					"amount_tax" => $detail[$i]["amount_tax"],
					"amount_inc" => $detail[$i]["amount_inc"],
					"taxable" => $detail[$i]["taxable"],
					"tax_rate" => $detail[$i]["tax_rate"],
					"category" => $detail[$i]["category"],
				],[]);
				$insertQuery($sd);
				
				if($q["invoice_format"] == 2){
					$insertQuery = $db->insertSet("sales_detail_attributes", [
						"sd" => $sd,
						"data" => json_encode(["circulation" => $detail[$i]["attributes"]["circulation"]]),
					],[]);
					$insertQuery();
				}else if($q["invoice_format"] == 3){
					$insertQuery = $db->insertSet("sales_detail_attributes", [
						"sd" => $sd,
						"data" => json_encode(["summary_data" => [
							$detail[$i]["attributes"]["summary_data1"],
							$detail[$i]["attributes"]["summary_data2"],
							$detail[$i]["attributes"]["summary_data3"],
						]]),
					],[]);
					$insertQuery();
				}
				
				$insertQuery = $db->insertSet("purchase_relations", [
					"ss" => $id,
					"sd" => $sd,
				],[]);
				$insertQuery();
			}
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [
				"project" => $q["project"],
				"subject" => $q["subject"],
				"division" => $q["division"],
				"leader" => $q["leader"],
				"manager" => $q["manager"],
				"client_name" => $q["client_name"],
				"apply_client" => $q["apply_client"],
				"payment_date" => $q["payment_date"],
				"note" => $q["note"],
				"amount_exc" => $q["amount_exc"],
				"amount_tax" => $q["amount_tax"],
				"amount_inc" => $q["amount_inc"],
			],[]);
			$updateQuery->andWhere("ss=?", $id);
			$updateQuery();
			
			$detail = json_decode($q["detail"], true);
			$len = count($detail);
			for($i = 0; $i < $len; $i++){
				$updateQuery = $db->updateSet("sales_details", [
					"detail" => $detail[$i]["detail"],
					"quantity" => $detail[$i]["quantity"],
					"unit" => $detail[$i]["unit"],
					"unit_price" => $detail[$i]["unit_price"],
				],[]);
				$updateQuery->andWhere("sd=?", $detail[$i]["sd"]);
				$updateQuery();
			}
			
			$detail = json_decode($q["detail_attribute"], true);
			if(!empty($detail)){
				$len = count($detail);
				for($i = 0; $i < $len; $i++){
					$updateQuery = $db->updateSet("sales_attributes", [
						"data" => $detail[$i]["data"],
					],[]);
					$updateQuery->andWhere("sd=?", $detail[$i]["sd"]);
					$updateQuery();
				}
			}
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
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
				"closing_date" => "CURRENT_DATE()",
				"closed_count" => "closed_count+1",
			]);
			$updateQuery->andWhere("id IN (SELECT id FROM JSON_TABLE(?, '$[*]' COLUMNS(id INT PATH '$.id')) AS t)", json_encode($t));
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
				"approval" => 0,
				"output_processed" => 0,
				"close_processed" => 0,
				"accounting_date" => "NULL",
				"closing_date" => "NULL",
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
	
	public static function checkInsert2($db, $q, $masterData, $context){
		$check = new Validator();
		self::validate2($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	public static function checkUpdate2($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate2($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	/**
		登録・更新共通の検証
	*/
	public static function validate2($check, $masterData, $db){
		$check["delivery_destination"]->required("納品先を入力してください。")
			->length("納品先は80文字以下で入力してください。", null, 255);
		$check["subject"]->required("件名を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。")
			->date("入金予定日を正しく入力してください。");
		$check["invoice_format"]->required("請求書パターンを入力してください。")
			->range("請求書パターンを正しく入力してください。", "in", array_keys(SelectionModifiers::invoiceFormat([])));
	}
	
	public static function execInsert2($db, $q, $context, $result){
		$id = $context->id;
		$month = date("ym"); 
		$db->beginTransaction();
		try{
			$query = $db->select("ONE")
				->setTable("basic_info")
				->setField("`value`")
				->andWhere("`key`=?", "slip_number_seq")
				->andWhere("`value` like ?", "{$month}%");
			$seq = $query();
			$deleteQuery = $db->delete("basic_info")
				->andWhere("`key`=?", "slip_number_seq");
			$deleteQuery();
			if($seq == null){
				$number = sprintf("%04d%05d", $month, 1);
			}else{
				$str = substr($seq, 4);
				$number = sprintf("%04d%05d", $month, intval($str) + 1);
			}
			$insertQuery = $db->insertSet("basic_info", [
				"key"   => "slip_number_seq",
				"value" => $number,
			], []);
			$insertQuery();
			
			$extendFields = ["manager"];
			$overrideFields = [
				"delivery_destination", "subject",
				"note", "header1", "header2", "header3",
				"payment_date", "detail", "invoice_format",
			];
			$nowFields = ["created", "modified"];
			$insertFields = array_merge([
				"slip_number", "project", "billing_destination"
				//"division", "team",
			], $overrideFields, $extendFields, $nowFields);
			$insertQuery = $db->insertSelect("sales_slips", implode(",", $insertFields))
				->addTable("projects")
				->andWhere("projects.code=?", $id);
			foreach($insertFields as $field){
				match(true){
					($field == "slip_number") =>
						$insertQuery->addField("?", $number),
					($field == "project") =>
						$insertQuery->addField("?", $id),
					($field == "billing_destination") =>
						$insertQuery->addField("projects.apply_client"),
					in_array($field, $overrideFields) =>
						$insertQuery->addField("?", $q[$field]),
					in_array($field, $extendFields) =>
						$insertQuery->addField("projects.{$field}"),
					in_array($field, $nowFields) =>
						$insertQuery->addField("now()"),
				};
			}
			$insertQuery();
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
	
	public static function execUpdate2($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [
				"delivery_destination" => $q["delivery_destination"],
				"subject" => $q["subject"],
				"note" => $q["note"],
				"header1" => $q["header1"],
				"header2" => $q["header2"],
				"header3" => $q["header3"],
				"payment_date" => $q["payment_date"],
				"detail" => $q["detail"],
				"invoice_format" => $q["invoice_format"],
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
	
	public static function checkInsert3($db, $q, $masterData, $context){
		$check = new Validator();
		self::validate2($check, $masterData, $db);
		$check["billing_destination"]->required("請求先を入力してください。");
			//->range("請求先を正しく入力してください。", "in", ($db->select("COL")->setTable("apply_clients")->setField("code"))());
		$result = $check($q);
		return $result;
	}
	
	public static function checkUpdate3($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate2($check, $masterData, $db);
		$check["billing_destination"]->required("請求先を入力してください。");
			//->range("請求先を正しく入力してください。", "in", ($db->select("COL")->setTable("apply_clients")->setField("code"))());
		$result = $check($q);
		return $result;
	}
	
	public static function execInsert3($db, $q, $context, $result){
		$id = $q["sid"];
		$month = date("ym"); 
		$db->beginTransaction();
		try{
			$query = $db->select("ONE")
				->setTable("basic_info")
				->setField("`value`")
				->andWhere("`key`=?", "slip_number_seq")
				->andWhere("`value` like ?", "{$month}%");
			$seq = $query();
			$deleteQuery = $db->delete("basic_info")
				->andWhere("`key`=?", "slip_number_seq");
			$deleteQuery();
			if($seq == null){
				$number = sprintf("%04d%05d", $month, 1);
			}else{
				$str = substr($seq, 4);
				$number = sprintf("%04d%05d", $month, intval($str) + 1);
			}
			$insertQuery = $db->insertSet("basic_info", [
				"key"   => "slip_number_seq",
				"value" => $number,
			], []);
			$insertQuery();
			
			$deleteQuery = $db->delete("sales_slips")
				->andWhere("spreadsheet=?", $id);
			$deleteQuery();
			
			$deleteQuery = $db->delete("purchases")
				->andWhere("spreadsheet=?", $id);
			$deleteQuery();
			
			
			$insertQuery = $db->insertSet("sales_slips", [
				"spreadsheet"          => $id,
				"delivery_destination" => $q["delivery_destination"],
				"subject"              => $q["subject"],
				"note"                 => $q["note"],
				"header1"              => $q["header1"],
				"header2"              => $q["header2"],
				"header3"              => $q["header3"],
				"payment_date"         => $q["payment_date"],
				"detail"               => $q["detail"],
				"invoice_format"       => $q["invoice_format"],
				"billing_destination"  => $q["billing_destination"],
				"slip_number"          => $number,
			],[
				"division" => "@division",
				"manager"  => "@manager",
				"created"  => "now()",
				"modified" => "now()",
			]);
			$insertQuery();
			
			$jsonTable = $db->getJsonArray2Tabel([
				"purchases" => [
					"payment_date" => '$.payment_date',
					"unit"         => '$.unit',
					"quantity"     => '$.quantity',
					"unit_price"   => '$.unit_price',
					"amount"       => '$.amount',
					"subject"      => '$.subject',
					"note"         => '$.note',
					"ingest"       => '$.ingest'
				]
			], "json_table");
			$insertQuery = $db->insertSelect("purchases", "spreadsheet,payment_date,unit,quantity,unit_price,amount,subject,note,ingest,created,modified")
				->addField("?", $id)
				->addTable($jsonTable, $q["purchases"])
				->addField("json_table.payment_date,json_table.unit,json_table.quantity,json_table.unit_price,json_table.amount,json_table.subject,json_table.note,json_table.ingest")
				->addField("now(),now()");
			$insertQuery();
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "登録", ["spreadsheet" => $id]);
		}
	}
	
	public static function execUpdate3($db, $q, $context, $result){
		$id = $q["sid"];
		$month = date("ym"); 
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("purchases")
				->andWhere("spreadsheet=?", $id);
			$deleteQuery();
			
			
			$updateQuery = $db->updateSet("sales_slips", [
				"delivery_destination" => $q["delivery_destination"],
				"subject"              => $q["subject"],
				"note"                 => $q["note"],
				"header1"              => $q["header1"],
				"header2"              => $q["header2"],
				"header3"              => $q["header3"],
				"payment_date"         => $q["payment_date"],
				"detail"               => $q["detail"],
				"invoice_format"       => $q["invoice_format"],
				"billing_destination"  => $q["billing_destination"],
			],[
				"modified" => "now()",
			]);
			$updateQuery->andWhere("spreadsheet=?", $id);
			$updateQuery();
			
			$jsonTable = $db->getJsonArray2Tabel([
				"purchases" => [
					"payment_date" => '$.payment_date',
					"unit"         => '$.unit',
					"quantity"     => '$.quantity',
					"unit_price"   => '$.unit_price',
					"amount"       => '$.amount',
					"subject"      => '$.subject',
					"note"         => '$.note',
					"ingest"       => '$.ingest'
				]
			], "json_table");
			$insertQuery = $db->insertSelect("purchases", "spreadsheet,payment_date,unit,quantity,unit_price,amount,subject,note,ingest,created,modified")
				->addField("?", $id)
				->addTable($jsonTable, $q["purchases"])
				->addField("json_table.payment_date,json_table.unit,json_table.quantity,json_table.unit_price,json_table.amount,json_table.subject,json_table.note,json_table.ingest")
				->addField("now(),now()");
			$insertQuery();
			
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "更新", ["spreadsheet" => $id]);
		}
	}
	
	public static function approval($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"approval" => 1,
				"accounting_date" => "CURDATE()",
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("承認に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("承認が完了しました。", "INFO", "");
			@Logger::record($db, "承認", ["sales_slips" => intval($id)]);
		}
	}
	
	public static function disapproval($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"approval" => 0,
				"accounting_date" => "NULL",
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("承認解除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("承認解除が完了しました。", "INFO", "");
			@Logger::record($db, "承認解除", ["sales_slips" => intval($id)]);
		}
	}
}