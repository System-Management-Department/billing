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
		$db = Session::getDB();
		
		$v = new View();
		$t = [
			"SELECT 'divisions' as master,json_arrayagg(name) as `values` FROM `divisions`",
			"SELECT 'teams' as master,json_arrayagg(name) as `values` FROM `teams`",
			"SELECT 'managers' as master,json_arrayagg(name) as `values` FROM `managers`",
			"SELECT 'applyClients' as master,json_arrayagg(unique_name) as `values` FROM `apply_clients`",
			"SELECT 'categories' as master,json_arrayagg(name) as `values` FROM `categories`",
			"SELECT 'invoiceFormats' as master,'[\"通常\",\"ニッピ様\",\"加茂繊維\",\"ダイドー\"]' as `values`",
		];
		$query = $db->select("ONE")
			->addTable("(" . implode(" UNION ALL ", $t) . ") t")
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