<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Session;
use Model\Result;
use Model\SalesSlip;

class BillingController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		
		$query = SalesSlip::getJsonQuery($db)
			->andWhere("output_processed=1")
			->andWhere("close_processed=0");
		$v["table"] = $query();
		
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function closedIndex(){
		$db = Session::getDB();
		$v = new View();
		
		$query = SalesSlip::getJsonQuery($db)
			->andWhere("close_processed=1");
		$v["table"] = $query();
		
		return $v;
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