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
use Model\SalesSlip;
use Model\SQLite;

class BillingController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("COL")
			->setTable("sales_slips")
			->setField("sales_slips.ss")
			->setLimit(1000)
			->leftJoin("sales_workflow using(ss)")
			->andWhere("close=1");
		if($_SESSION["User.role"] == "manager"){
			// 担当者　自身の所有するすべて
			$query->andWhere("sales_workflow.regist_user=?", $_SESSION["User.id"]);
		}else if($_SESSION["User.role"] == "leader"){
			// 責任者　自身の所有するすべてと、自身の部署のもの
			$query->andWhere("(sales_workflow.regist_user=? OR sales_slips.division=?)", $_SESSION["User.id"], $_SESSION["User.departmentCode"]);
		}
		if(!empty($_POST)){
			if(!empty($_POST["version"])){
				$query->andWhere("sales_workflow.close_version=?", $_POST["version"]);
			}
			if(!empty($_POST["slip_number_array"])){
				$query->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(slip_number TEXT PATH '$')) AS t)", $_POST["slip_number_array"]);
				$query->andWhere("EXISTS(SELECT 1 FROM find WHERE find.slip_number=sales_slips.slip_number)");
			}
			if(!empty($_POST["slip_number"])){
				$query->andWhere("slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			if(!empty($_POST["accounting_date"])){
				if(!empty($_POST["accounting_date"]["from"])){
					$query->andWhere("DATEDIFF(regist_datetime,?) >= 0", $_POST["accounting_date"]["from"]);
				}
				if(!empty($_POST["accounting_date"]["to"])){
					$query->andWhere("DATEDIFF(regist_datetime,?) <= 0", $_POST["accounting_date"]["to"]);
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
		}
		$searchIds = json_encode($query($cnt));
		
		
		$query1 = $db->select("EXPORT")
			->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t)", $searchIds)
			->setTable("sales_slips")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_slips.ss)");
		$query2 = $db->select("EXPORT")
			->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t)", $searchIds)
			->setTable("sales_attributes")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_attributes.ss)");
		$query3 = $db->select("EXPORT")
			->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t)", $searchIds)
			->setTable("sales_workflow")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=sales_workflow.ss)");
		$query4 = $db->select("EXPORT")
			->addWith("find AS (SELECT * FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t)", $searchIds)
			->setTable("purchase_relations")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.ss=purchase_relations.ss)");
		$query5 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT purchase_relations.sd FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t LEFT JOIN purchase_relations using(ss))", $searchIds)
			->setTable("sales_details")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.sd=sales_details.sd)");
		$query6 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT purchase_relations.sd FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t LEFT JOIN purchase_relations using(ss))", $searchIds)
			->setTable("sales_detail_attributes")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.sd=sales_detail_attributes.sd)");
		$query7 = $db->select("EXPORT")
			->addWith("find AS (SELECT DISTINCT purchase_relations.pu FROM JSON_TABLE(?,'$[*]' COLUMNS(ss INT PATH '$')) AS t LEFT JOIN purchase_relations using(ss))", $searchIds)
			->setTable("purchases")
			->andWhere("EXISTS(SELECT 1 FROM find WHERE find.pu=purchases.pu)");
			/*
		if(($_SESSION["User.role"] == "admin") || ($_SESSION["User.role"] == "entry")){
		}else if($_SESSION["User.role"] == "leader"){
			$divisionQuery = $db->select("ONE")
				->setTable("managers")
				->addField("division")
				->andWhere("code=@manager");
			$division = $divisionQuery();
			$query1->andWhere("division=?", $division);
			$query2->andWhere("sales_slips.division=?", $division);
		}else{
			$query1->andWhere("manager=@manager");
			$query2->andWhere("sales_slips.manager=@manager");
		}
		*/
		
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query1(),
			"sales_attributes" => $query2(),
			"sales_workflow" => $query3(),
			"purchase_relations" => $query4(),
			"sales_details" => $query5(),
			"sales_detail_attributes" => $query6(),
			"purchases" => $query7(),
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closeUndo(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execCloseUndo($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function release(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execRelease($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}