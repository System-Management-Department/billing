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
}