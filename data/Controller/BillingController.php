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
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$sdb = SQLite::cachedData();
		list($columns, $data) = $db->exportTable("sales_slips", [], "0=1 LIMIT 0");
		$query = $db->select("ALL")->setTable("sales_slips");
		if(isset($_POST["close_processed"])){
			$query->andWhere("close_processed=?", $_POST["close_processed"]);
		}
		if(isset($_POST["output_processed"])){
			$query->andWhere("output_processed=?", $_POST["output_processed"]);
		}
		$sdb->createTable("sales_slips", $columns, $query());
		return new FileView($sdb->getFileName(), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function list(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedIndex(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedList(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedIndex2(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedList2(){
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