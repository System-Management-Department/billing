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
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		$query = $db->select("ASSOC")->setTable("basic_info");
		$v["basicInfo"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("EXPORT")->setTable("sales_slips");
		if(isset($_POST["close_processed"])){
			$query->andWhere("close_processed=?", $_POST["close_processed"]);
		}
		if(isset($_POST["output_processed"])){
			$query->andWhere("output_processed=?", $_POST["output_processed"]);
		}
		
		$parameter = false;
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
		
		if(!$parameter){
			$query->setLimit(0);
		}
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query()
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedIndex(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedIndex2(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function close(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execClose($db, $_POST, $this->requestContext, $result);
		
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