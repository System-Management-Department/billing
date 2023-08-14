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

class CommittedController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function edit(){
		$v = new View();
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("COL")
			->setTable("sales_slips")
			->setField("sales_slips.ss")
			->setLimit(100)
			->leftJoin("sales_workflow using(ss)")
			->andWhere("approval=0")
			->andWhere("close=0");
		if(!empty($_POST)){
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
			->setTable("sales_slips")
			->andWhere("ss MEMBER OF(?)", $searchIds);
		$query2 = $db->select("EXPORT")
			->setTable("sales_attributes")
			->andWhere("ss MEMBER OF(?)", $searchIds);
		$query3 = $db->select("EXPORT")
			->setTable("sales_workflow")
			->andWhere("ss MEMBER OF(?)", $searchIds);
		$query4 = $db->select("EXPORT")
			->setTable("sales_details")
			->setField("sales_details.*")
			->leftJoin("purchase_relations using(sd)")
			->addField("purchase_relations.ss")
			->andWhere("purchase_relations.ss MEMBER OF(?)", $searchIds);
		$query5 = $db->select("EXPORT")
			->setTable("sales_detail_attributes")
			->setField("sales_detail_attributes.*")
			->leftJoin("purchase_relations using(sd)")
			->andWhere("purchase_relations.ss MEMBER OF(?)", $searchIds);
		$query6 = $db->select("EXPORT")
			->setTable("purchases")
			->setField("purchases.*")
			->leftJoin("purchase_relations using(pu)")
			->addField("purchase_relations.ss")
			->andWhere("purchase_relations.ss MEMBER OF(?)", $searchIds);
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
			"sales_details" => $query4(),
			"sales_detail_attributes" => $query5(),
			"purchases" => $query6(),
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkUpdate3($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execUpdate3($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "leader")]
	public function approval(){
		$db = Session::getDB();
		
		$result = new Result();
		SalesSlip::approval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}