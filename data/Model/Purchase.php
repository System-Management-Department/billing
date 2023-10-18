<?php
namespace Model;
use App\Validator;
use App\Smarty\SelectionModifiers;
use Model\Result;

class Purchase{
	public static function getJsonQuery($db){
		list($jsonField, $keys) = $db->getTable2JsonField(["purchases", null], null, [
			"id" => null,
			"created" => null,
			"modified" => null
		]);
		$query = $db->select("ONE")
			->addTable("purchases")
			->addField("JSON_OBJECTAGG(id,{$jsonField})", ...$keys);
		return $query;
	}
	
	
	public static function checkInsert($db, $q, $masterData){
		$result = new Result();
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
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$detailTable = $db->getJsonArray2Tabel([
				"purchases" => [
					"pu"           => "$.pu",
					"supplier"     => "$.supplier",
					"payment_date" => "$.payment_date",
					"detail"       => "$.detail",
					"quantity"     => "$.quantity",
					"unit"         => "$.unit",
					"unit_price"   => "$.unit_price",
					"amount_exc"   => "$.amount_exc",
					"amount_tax"   => "$.amount_tax",
					"amount_inc"   => "$.amount_inc",
					"note"         => "$.note",
					"taxable"      => "$.taxable",
					"tax_rate"     => "$.tax_rate",
				]
			], "t");
			$updateQuery = $db->updateSet("purchases`,`detail", [], [
				"purchases`.`payment_date" => "detail.payment_date",
				"purchases`.`detail"       => "detail.detail",
				"purchases`.`quantity"     => "detail.quantity",
				"purchases`.`unit"         => "detail.unit",
				"purchases`.`unit_price"   => "detail.unit_price",
				"purchases`.`amount_exc"   => "detail.amount_exc",
				"purchases`.`amount_tax"   => "detail.amount_tax",
				"purchases`.`amount_inc"   => "detail.amount_inc",
				"purchases`.`note"         => "detail.note",
				"purchases`.`taxable"      => "detail.taxable",
				"purchases`.`tax_rate"     => "detail.tax_rate",
			])->addWith("detail AS (SELECT * FROM {$detailTable})", $q["detail"])
			->andWhere("purchases.pu=detail.pu");
			$updateQuery();
			
			$updateQuery = $db->updateSet("purchase_workflow`,`detail", [], [
				"update_datetime" => "NOW()",
			])->addWith("detail AS (SELECT * FROM {$detailTable})", $q["detail"])
			->andWhere("purchase_workflow.pu=detail.pu");
			$updateQuery();
			
			$purchaseRelations = [];
			$selectQuery = $db->select("ALL")
				->setWith("rel AS (SELECT DISTINCT ss FROM purchase_relations WHERE sd=?)", $q["sd"])
				->setTable("rel")
				->leftJoin("purchase_relations USING(ss)")
				->setField("purchase_relations.ss,purchase_relations.sd,JSON_ARRAYAGG(purchase_relations.pu) AS pu")
				->setGroupBy("purchase_relations.ss,purchase_relations.sd");
			$relations = $selectQuery();
			$ss = null;
			foreach($relations as $rel){
				if($rel["sd"] == $q["sd"]){
					$detail = json_decode($q["detail"], true);
					foreach($detail as &$row){
						if(is_null($row["pu"])){
							$insertQuery = $db->insertSet("purchases", [
								"supplier"     => $row["supplier"],
								"payment_date" => $row["payment_date"],
								"detail"       => $row["detail"],
								"quantity"     => $row["quantity"],
								"unit"         => $row["unit"],
								"unit_price"   => $row["unit_price"],
								"amount_exc"   => $row["amount_exc"],
								"amount_tax"   => $row["amount_tax"],
								"amount_inc"   => $row["amount_inc"],
								"note"         => $row["note"],
								"taxable"      => $row["taxable"],
								"tax_rate"     => $row["tax_rate"],
							], []);
							$insertQuery($row["pu"]);
							$insertQuery = $db->insertSet("purchase_workflow", [
								"pu"          => $row["pu"],
								"regist_user" => $_SESSION["User.id"],
							], [
								"regist_datetime" => "NOW()",
								"update_datetime" => "NOW()",
							]);
							$insertQuery();
						}
						$purchaseRelations[] = ["ss" => $rel["ss"], "sd" => $rel["sd"], "pu" => $row["pu"]];
					}
					if(empty($detail)){
						$purchaseRelations[] = ["ss" => $rel["ss"], "sd" => $rel["sd"], "pu" => null];
					}
					$ss = $rel["ss"];
				}else{
					$purchaseId = json_decode($rel["pu"], true);
					foreach($purchaseId as $pu){
						$purchaseRelations[] = ["ss" => $rel["ss"], "sd" => $rel["sd"], "pu" => $pu];
					}
				}
			}
			if(!is_null($ss)){
				$deleteQuery = $db->delete("purchase_relations")->andWhere("ss=?", $ss);
				$deleteQuery();
				
				$relationTable = $db->getJsonArray2Tabel([
					"dual" => [
						"ss INT" => "$.ss",
						"sd INT" => "$.sd",
						"pu INT" => "$.pu",
					]
				], "t");
				$insertQuery = $db->insertSelect("purchase_relations", "ss,sd,pu")
					->setTable($relationTable, json_encode($purchaseRelations));
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
	
	public static function execDelete($db, $q, $context, $result){
		$query = $db->select("ROW")
			->addTable("purchases")
			->andWhere("id=?", $q["id"]);
		
		$data = $query();
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("purchases");
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
			@Logger::record($db, "削除", ["purchases" => $data["id"]]);
		}
	}
	
	public static function validateDetail($check, $masterData, $db, $q){
		$check["supplier"]->required("仕入先を入力してください。");
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
		$check["payment_date"]->required("支払日を入力してください。")
			->date("支払日を正しく入力してください。");
	}
	
	public static function payment($db, $q, $context, $result){
		$month = date("ym"); 
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("purchase_workflow", [
				"slip_number" => $q["comment"],
				"payment_user" => $_SESSION["User.id"],
			],[
				"payment" => 1,
				"payment_datetime" => "NOW()",
			]);
			$updateQuery->andWhere("pu=?", $q["id"]);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("受領登録に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("受領登録が完了しました。", "INFO", "");
		}
	}
	
	public static function paymentExecution($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("purchases", [
				"execution_date" => empty($q["execution_date"]) ? null : $q["execution_date"],
			],[]);
			$updateQuery->andWhere("pu=?", $q["id"]);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("支払実行日登録に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("支払実行日登録が完了しました。", "INFO", "");
		}
	}
	
	public static function delete($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$countQuery = $db->select("ONE")
				->setWith("search AS (SELECT DISTINCT sd FROM purchase_relations WHERE pu=?)", $q["id"])
				->setTable("search")
				->leftJoin("purchase_relations using(sd)")
				->setField("COUNT(1)");
			$size = $countQuery();
			if($size == 1){
				$updateQuery = $db->updateSet("purchase_relations", [
					"pu" => NULL,
				],[])->andWhere("pu=?", $q["id"]);
				$updateQuery();
			}else{
				$deleteQuery = $db->delete("purchase_relations")->andWhere("pu=?", $q["id"]);
				$deleteQuery();
			}
			$deleteQuery = $db->delete("purchases")->andWhere("pu=?", $q["id"]);
			$deleteQuery();
			$deleteQuery = $db->delete("purchase_workflow")->andWhere("pu=?", $q["id"]);
			$deleteQuery();
			$deleteQuery = $db->delete("purchases_attributes")->andWhere("pu=?", $q["id"]);
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
		}
	}
	
	public static function request($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$insertQuery = $db->insertSet("purchase_correction_workflow", [
				"pu"         => $q["pu"],
				"quantity"   => $q["quantity"],
				"unit"       => $q["unit"],
				"unit_price" => $q["unit_price"],
				"amount_exc" => $q["amount_exc"],
				"amount_tax" => $q["amount_tax"],
				"amount_inc" => $q["amount_inc"],
				"taxable"    => $q["taxable"],
				"tax_rate"   => ($q["taxable"] != "1") ? null : $q["tax_rate"],
				"comment"    => $q["comment"],
				"request_user" => $_SESSION["User.id"],
			],[
				"request_datetime" => "NOW()",
			]);
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("仕入変更申請に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("仕入変更申請が完了しました。", "INFO", "");
		}
	}
	
	public static function withdraw($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("purchase_correction_workflow")
				->andWhere("pu=?", $q["id"])
				->andWhere("approval=0");
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("仕入変更申請取下に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("仕入変更申請取下が完了しました。", "INFO", "");
		}
	}
	
	public static function approval($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("purchase_correction_workflow`,`find", [
				"purchase_correction_workflow`.`approval" => 1,
				"purchase_correction_workflow`.`approval_user" => $_SESSION["User.id"],
			],[
				"purchase_correction_workflow`.`approval_datetime" => "NOW()",
			])->addWith("find AS (SELECT MAX(request_datetime) AS request_datetime FROM purchase_correction_workflow WHERE pu=?)", $q["id"])
				->andWhere("purchase_correction_workflow.pu=?", $q["id"])
				->andWhere("purchase_correction_workflow.approval=0")
				->andWhere("purchase_correction_workflow.request_datetime=find.request_datetime");
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("仕入変更承認に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("仕入変更承認が完了しました。", "INFO", "");
		}
	}
	
	public static function disapproval($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("purchase_correction_workflow`,`find", [
				"purchase_correction_workflow`.`approval" => 0,
				"purchase_correction_workflow`.`approval_user" => null,
				"purchase_correction_workflow`.`approval_datetime" => null,
			],[])->addWith("find AS (SELECT MAX(request_datetime) AS request_datetime FROM purchase_correction_workflow WHERE pu=?)", $q["id"])
				->andWhere("purchase_correction_workflow.pu=?", $q["id"])
				->andWhere("purchase_correction_workflow.approval=1")
				->andWhere("purchase_correction_workflow.request_datetime=find.request_datetime");
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("仕入変更承認解除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("仕入変更承認解除が完了しました。", "INFO", "");
		}
	}
	
	public static function reflection($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("purchase_correction_workflow`,`find`,`purchase", [
				"purchase_correction_workflow`.`reflection" => 1,
				"purchase_correction_workflow`.`reflection_user" => $_SESSION["User.id"],
			],[
				"purchase_correction_workflow`.`reflection_datetime" => "NOW()",
				"purchase_correction_workflow`.`old" => "purchase.old",
			])->addWith("find AS (SELECT MAX(request_datetime) AS request_datetime FROM purchase_correction_workflow WHERE pu=?)", $q["id"])
				->addWith("purchase AS (SELECT JSON_OBJECT('quantity',quantity,'unit',unit,'unit_price',unit_price,'amount_exc',amount_exc,'amount_tax',amount_tax,'amount_inc',amount_inc,'taxable',taxable,'tax_rate',tax_rate) AS old FROM purchases WHERE pu=?)", $q["id"])
				->andWhere("purchase_correction_workflow.pu=?", $q["id"])
				->andWhere("purchase_correction_workflow.reflection=0")
				->andWhere("purchase_correction_workflow.request_datetime=find.request_datetime");
			$updateQuery();
			
			$updateQuery = $db->updateSet("purchases`,`find", [],[
				"purchases`.`quantity" => "find.quantity",
				"purchases`.`unit" => "find.unit",
				"purchases`.`unit_price" => "find.unit_price",
				"purchases`.`amount_exc" => "find.amount_exc",
				"purchases`.`amount_tax" => "find.amount_tax",
				"purchases`.`amount_inc" => "find.amount_inc",
				"purchases`.`taxable" => "find.taxable",
				"purchases`.`tax_rate" => "find.tax_rate",
			])->addWith("temp AS (SELECT pu,MAX(request_datetime) AS request_datetime FROM purchase_correction_workflow WHERE pu=? GROUP BY pu)", $q["id"])
				->addWith("find AS (SELECT purchase_correction_workflow.* FROM temp LEFT JOIN purchase_correction_workflow USING(pu, request_datetime))")
				->andWhere("purchases.pu=?", $q["id"]);
			$updateQuery();
			
			$updateQuery = $db->updateSet("purchase_workflow", [],[
				"update_datetime" => "NOW()",
			])->andWhere("pu=?", $q["id"]);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("仕入変更反映に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("仕入変更反映が完了しました。", "INFO", "");
		}
	}
}