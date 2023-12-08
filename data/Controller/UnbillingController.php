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

class UnbillingController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("COL")
			->setTable("sales_slips")
			->setField("sales_slips.ss")
			->setLimit(1000)
			->leftJoin("sales_workflow using(ss)")
			->andWhere("close=0");
		if($_SESSION["User.role"] != "admin"){
			// 管理者以外非表示
			$query->andWhere("sales_workflow.hide=0");
		}
		if($_SESSION["User.role"] == "manager"){
			// 担当者　自身の所有するすべて
			$query->andWhere("sales_workflow.regist_user=?", $_SESSION["User.id"]);
		}else if($_SESSION["User.role"] == "leader"){
			// 責任者　自身の所有するすべてと、自身の部署のもの
			$query->andWhere("(sales_workflow.regist_user=? OR JSON_CONTAINS(?, JSON_ARRAY(sales_slips.division), '\$'))", $_SESSION["User.id"], json_encode($_SESSION["User.departmentCode"]));
		}
		if(!empty($_POST)){
			if(!empty($_POST["version_keyword"])){
				$query->andWhere("sales_workflow.close_version like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["version_keyword"]));
			}
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
			if(!empty($_POST["project"])){
				$query->andWhere("project like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["project"]));
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
			if((!empty($_POST["client"])) && (!empty($_POST["client2"]))){
				$query->andWhere("JSON_CONTAINS(?,JSON_QUOTE(sales_slips.apply_client),'$')", $_POST["client2"]);
			}
			if(!empty($_POST["client_name"])){
				$query->andWhere("sales_slips.client_name like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["client_name"]));
			}
			if(!empty($_POST["recording_date"])){
				$query->andWhere("DATE_FORMAT(sales_slips.recording_date,'%Y%m')=DATE_FORMAT(?,'%Y%m')", $_POST["recording_date"]);
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
		
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query1($cnt2),
			"sales_attributes" => $query2(),
			"sales_workflow" => $query3(),
			"purchase_relations" => $query4(),
			"sales_details" => $query5(),
			"sales_detail_attributes" => $query6(),
			"purchases" => $query7(),
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt], ["key" => "display", "value" => $cnt2]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function hide(){
		$db = Session::getDB();
		$result = new Result();
		SalesSlip::hide($db, ["hide" => "[{$this->requestContext->id}]"], $this->requestContext, $result);
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function show(){
		$db = Session::getDB();
		$result = new Result();
		SalesSlip::show($db, ["show" => "[{$this->requestContext->id}]"], $this->requestContext, $result);
		return new JsonView($result);
	}
}