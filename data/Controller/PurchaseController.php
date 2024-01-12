<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Session;
use Model\Result;
use Model\Purchase;
use Model\SQLite;

class PurchaseController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("ALL")
			->setTable("purchase_relations")
			->setField("purchase_relations.*")
			->setLimit(1000)
			->leftJoin("sales_slips using(ss)")
			->leftJoin("sales_workflow using(ss)")
			->leftJoin("sales_details using(sd)")
			->andWhere("sales_details.record=1")
			->leftJoin("purchases using(pu)")
			->leftJoin("purchase_workflow using(pu)");
		if($_SESSION["User.role"] == "manager"){
			// 担当者　自身の所有するすべて
			$query->andWhere("EXISTS(SELECT 1 FROM sales_workflow WHERE sales_workflow.regist_user=? AND sales_workflow.ss=purchase_relations.ss)", $_SESSION["User.id"]);
		}else if($_SESSION["User.role"] == "leader"){
			// 責任者　自身の所有するすべてと、自身の部署のもの
			$query->andWhere("(EXISTS(SELECT 1 FROM sales_workflow WHERE sales_workflow.regist_user=? AND sales_workflow.ss=purchase_relations.ss) OR JSON_CONTAINS(?, JSON_ARRAY(sales_slips.division), '\$'))", $_SESSION["User.id"], json_encode($_SESSION["User.departmentCode"]));
		}
		if(!empty($_POST)){
			if(!empty($_POST["pu_array"])){
				$query->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(pu TEXT PATH '$')) AS t)", $_POST["pu_array"]);
				$query->andWhere("EXISTS(SELECT 1 FROM find WHERE find.pu=purchase_relations.pu)");
			}
			if(!empty($_POST["sd"])){
				$query->andWhere("purchase_relations.sd=?", $_POST["sd"]);
			}
			if(!empty($_POST["slip_number"])){
				$query->andWhere("sales_slips.slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			if(!empty($_POST["project"])){
				$query->andWhere("sales_slips.project like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["project"]));
			}
			if(!empty($_POST["supplier"])){
				$query->andWhere("purchases.supplier=?", $_POST["supplier"]);
			}
			if(!empty($_POST["accounting_date"])){
				if(!empty($_POST["accounting_date"]["from"])){
					$query->andWhere("DATEDIFF(sales_workflow.regist_datetime,?) >= 0", $_POST["accounting_date"]["from"]);
				}
				if(!empty($_POST["accounting_date"]["to"])){
					$query->andWhere("DATEDIFF(sales_workflow.regist_datetime,?) <= 0", $_POST["accounting_date"]["to"]);
				}
			}
			if(!empty($_POST["update_date"])){
				if(!empty($_POST["update_date"]["from"])){
					$query->andWhere("DATEDIFF(purchase_workflow.update_datetime,?) >= 0", $_POST["update_date"]["from"]);
				}
				if(!empty($_POST["update_date"]["to"])){
					$query->andWhere("DATEDIFF(purchase_workflow.update_datetime,?) <= 0", $_POST["update_date"]["to"]);
				}
			}
			if(!empty($_POST["execution_date"])){
				if(!empty($_POST["execution_date"]["from"])){
					$query->andWhere("DATEDIFF(purchases.execution_date,?) >= 0", $_POST["execution_date"]["from"]);
				}
				if(!empty($_POST["execution_date"]["to"])){
					$query->andWhere("DATEDIFF(purchases.execution_date,?) <= 0", $_POST["execution_date"]["to"]);
				}
			}
			if(!empty($_POST["division"])){
				$query->andWhere("division=?", $_POST["division"]);
			}
			if(!empty($_POST["manager"])){
				$query->andWhere("manager=?", $_POST["manager"]);
			}
			if(!empty($_POST["apply_client"])){
				$query->andWhere("apply_client=?", $_POST["apply_client"]);
			}
			if(!empty($_POST["sort"])){
				foreach($_POST["sort"] as $sortq){
					if(preg_match('/^(recording_date|billing_date)(\\s+(ASC|DESC))?$/i', $sortq)){
						$query->setOrderBy($sortq);
					}
				}
			}
		}
		$searchTable = json_encode($query($cnt));
		
		
		$query1 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$.ss')) AS t)", $searchTable)
			->setTable("sales_slips")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_slips.ss)");
		$query2 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$.ss')) AS t)", $searchTable)
			->setTable("sales_attributes")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_attributes.ss)");
		$query3 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$.ss')) AS t)", $searchTable)
			->setTable("sales_workflow")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_workflow.ss)");
		$query4 = $db->select("EXPORT")
			->setTable("JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$.ss',sd INT PATH '$.sd',pu INT PATH '$.pu')) AS t", $searchTable);
		if(!empty($_POST["supplier"])){
			$query4->setField("t.*")
				->leftJoin("purchases using(pu)")
				->andWhere("purchases.supplier=?", $_POST["supplier"]);
		}
		$query5 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(sd INT PATH '$.sd')) AS t)", $searchTable)
			->setTable("sales_details")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.sd=sales_details.sd)");
		$query6 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(sd INT PATH '$.sd')) AS t)", $searchTable)
			->setTable("sales_detail_attributes")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.sd=sales_detail_attributes.sd)");
		$query7 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(pu INT PATH '$.pu')) AS t)", $searchTable)
			->setTable("purchases")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.pu=purchases.pu)");
		$query8 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(pu INT PATH '$.pu')) AS t)", $searchTable)
			->setTable("purchase_workflow")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.pu=purchase_workflow.pu)");
		$query9 = $db->select("EXPORT")
			->addWith("temp AS (SELECT DISTINCT * FROM JSON_TABLE(?,'$[*]' COLUMNS(pu INT PATH '$.pu')) AS t)", $searchTable)
			->addWith("find AS (SELECT pu,MAX(request_datetime) AS request_datetime FROM purchase_correction_workflow WHERE EXISTS(SELECT 1 FROM temp WHERE temp.pu=purchase_correction_workflow.pu) GROUP BY pu)")
			->setTable("purchase_correction_workflow")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.pu=purchase_correction_workflow.pu AND find.request_datetime=purchase_correction_workflow.request_datetime)");
		
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query1(),
			"sales_attributes" => $query2(),
			"sales_workflow" => $query3(),
			"purchase_relations" => $query4($cnt2),
			"sales_details" => $query5(),
			"sales_detail_attributes" => $query6(),
			"purchases" => $query7(),
			"purchase_workflow" => $query8(),
			"purchase_correction_workflow" => $query9(),
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt], ["key" => "display", "value" => $cnt2]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function edit(){
		$v = new View();
		$v["id"] = $this->requestContext->id;
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Purchase::checkInsert($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Purchase::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function genSlipNumber(){
		$db = Session::getDB();
		$month = date("ym"); 
		$result = new Result();
		$db->beginTransaction();
		try{
			// 伝票番号生成
			$sequence = $db->select("ONE")
				->setTable("slip_sequence")
				->setField("seq")
				->andWhere("month=?", $month)
				->andWhere("type=4");
			$slipNumber = $sequence();
			if(empty($slipNumber)){
				$slipNumber = 1;
				$insertQuery = $db->insertSet("slip_sequence", [
					"seq" => 1,
					"month" => $month,
					"type" => 4,
				],[]);
				$insertQuery();
				$db->commit();
			}else{
				$slipNumber++;
				$updateQuery = $db->updateSet("slip_sequence", [],[
					"seq" => "seq+1",
				]);
				$updateQuery->andWhere("month=?", $month);
				$updateQuery->andWhere("type=4");
				$updateQuery();
				$db->commit();
			}
		}catch(Exception $ex){
			$result->addMessage("伝票番号生成に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage(sprintf("%s%05d", $month, $slipNumber), "INFO", "no");
		}
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function exportList(){
		$v = new View();
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function payment(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::payment($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function paymentExecution(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::paymentExecution($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::delete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function request(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::request($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function withdraw(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::withdraw($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "leader")]
	public function approval(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::approval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "leader")]
	public function disapproval(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::disapproval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function reflection(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::reflection($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}