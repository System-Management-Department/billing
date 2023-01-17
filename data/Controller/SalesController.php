<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use Model\Session;

class SalesController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ALL")
			->addTable("sales_slips");
		$v["table"] = $query();
		
		return $v;
	}
}