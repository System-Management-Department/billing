<?php
namespace Controller;
use Exception;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;
use Model\Result;
use Model\Session;
use Model\SalesSlip;

class DriveController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function import(){
		$db = Session::getDB();
		
		// 取込
		$result = new Result();
		SalesSlip::execImport($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}