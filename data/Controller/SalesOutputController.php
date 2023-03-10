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

class SalesOutputController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$sdb = SQLite::cachedData();
		$query = $db->select("ALL")
			->setTable("sales_slips");
		$parameter = false;
		if(!empty($_POST)){
			if(!empty($_POST["slip_number"])){
				$parameter = true;
				$query->andWhere("slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			if(!empty($_POST["accounting_date"])){
				$parameter = true;
				$query->andWhere("accounting_date=?", $_POST["accounting_date"]);
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
		list($columns, $data) = $db->exportTable("sales_slips", [], "1=0 limit 0");
		$sdb->createTable("sales_slips", $columns, $parameter ? $query() : []);
		return new FileView($sdb->getFileName(), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function output(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execOutput($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}