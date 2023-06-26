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

class SalesController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$v["data"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function createRed(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$data = $query();
		$detail = json_decode($data["detail"], true);
		for($i = 0; $i < $detail["length"]; $i++){
			if(is_numeric($detail["quantity"][$i])){
				$detail["quantity"][$i] = -$detail["quantity"][$i];
			}
			if(is_numeric($detail["amount"][$i])){
				$detail["amount"][$i] = -$detail["amount"][$i];
			}
			if(is_numeric($detail["circulation"][$i])){
				$detail["circulation"][$i] = -$detail["circulation"][$i];
			}
		}
		$data["detail"] = json_encode($detail);
		$v["data"] = $data;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$sdb = SQLite::cachedData();
		$query = $db->select("EXPORT")
			->setTable("sales_slips")
			->andWhere("close_processed=0");
		$parameter = false;
		if(!empty($_POST)){
			if(!empty($_POST["slip_number"])){
				$parameter = true;
				$query->andWhere("slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			if(!empty($_POST["accounting_date"])){
				if(!empty($_POST["accounting_date"]["from"])){
					$parameter = true;
					$query->andWhere("DATEDIFF(accounting_date,?) BETWEEN 0 AND 365", $_POST["accounting_date"]["from"]);
				}
				if(!empty($_POST["accounting_date"]["to"])){
					$parameter = true;
					$query->andWhere("DATEDIFF(accounting_date,?) BETWEEN -365 AND 0", $_POST["accounting_date"]["to"]);
				}
			}
			if(!empty($_POST["division"])){
				$parameter = true;
				$query->andWhere("division=?", $_POST["division"]);
			}
			if(!empty($_POST["team"])){
				$parameter = true;
				$query->andWhere("team=?", $_POST["team"]);
			}
			if(!empty($_POST["manager"])){
				$parameter = true;
				$query->andWhere("manager=?", $_POST["manager"]);
			}
			if(!empty($_POST["billing_destination"])){
				$parameter = true;
				$query->andWhere("billing_destination=?", $_POST["billing_destination"]);
			}
			if(!empty($_POST["itemName"])){
				$parameter = true;
				$query->addTable("JSON_TABLE(detail, '\$.itemName[*]' COLUMNS(item_name TEXT PATH '\$')) AS t")
					->setField("DISTINCT sales_slips.*")
					->andWhere("item_name like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["itemName"]));
			}
		}
		
		if(!$parameter){
			$query->setLimit(0);
		}
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query()
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			SalesSlip::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}