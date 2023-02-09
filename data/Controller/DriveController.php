<?php
namespace Controller;
use Exception;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;
use App\Smarty\SelectionModifiers;
use Model\Result;
use Model\Session;
use Model\SalesSlip;

class DriveController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		
		$v = new View();
		$invoiceFormats = array_values(SelectionModifiers::invoiceFormat([]));
		$t = [
			"SELECT 'divisions' as master,json_arrayagg(name) as `values` FROM `divisions`",
			"SELECT 'teams' as master,json_arrayagg(name) as `values` FROM `teams`",
			"SELECT 'managers' as master,json_arrayagg(name) as `values` FROM `managers`",
			"SELECT 'applyClients' as master,json_arrayagg(unique_name) as `values` FROM `apply_clients`",
			"SELECT 'categories' as master,json_arrayagg(name) as `values` FROM `categories`",
			"SELECT 'invoiceFormats' as master,? as `values`",
		];
		$query = $db->select("ONE")
			->addTable("(" . implode(" UNION ALL ", $t) . ") t", json_encode($invoiceFormats))
			->addField("json_objectagg(master, CAST(`values` AS JSON))");
		$v["master"] = $query();
		$query = $db->select("ONE")
			->addTable("categories")
			->addField("json_objectagg(name, code)");
		$v["categories"] = $query();
		return $v;
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