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

class PurchaseController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("ALL")
			->setTable("purchase_relations")
			->setField("purchase_relations.*")
			->setLimit(1000)
			->leftJoin("sales_slips using(ss)")
			->leftJoin("sales_details using(sd)")
			->andWhere("sales_details.record=1");
		if(!empty($_POST)){
			if(!empty($_POST["slip_number"])){
				$query->andWhere("slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			/*
			if(!empty($_POST["accounting_date"])){
				if(!empty($_POST["accounting_date"]["from"])){
					$query->andWhere("DATEDIFF(regist_datetime,?) >= 0", $_POST["accounting_date"]["from"]);
				}
				if(!empty($_POST["accounting_date"]["to"])){
					$query->andWhere("DATEDIFF(regist_datetime,?) <= 0", $_POST["accounting_date"]["to"]);
				}
			}
			*/
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
}