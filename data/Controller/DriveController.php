<?php
namespace Controller;
use Exception;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\ControllerBase;
use App\MySQL;
use App\Smarty\SelectionModifiers;
use Model\Result;
use Model\Session;
use Model\SalesSlip;
use Model\SQLite;

class DriveController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		if(empty($_GET["id"])){
			return new RedirectResponse("Home", "salesInput");
		}
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function master(){
		$sdb = SQLite::cachedData();
		$table = [];
		$assoc = SelectionModifiers::invoiceFormat([]);
		foreach($assoc as $k => $v){
			$table[] = ["id" => $k, "name" => $v];
		}
		$sdb->createTable("invoice_formats", ["id", "name"], $table);
		$sdb->createTable("info", ["key", "value"], [["key" => "update", "value" => $sdb->getFilemtime()]]);
		return new FileView($sdb->getFileName(), "application/vnd.sqlite3");
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