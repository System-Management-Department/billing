<?php
namespace Controller;
use Exception;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;
use Model\Result;
use Model\Session;

class DriveController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function import(){
		$result = new Result();
		try{
			$db = Session::getDB();
			$columns = $db->getJsonTableColumns("sales_slips", "slip_number", "accounting_date", "division", "team", "manager", "billing_destination", "delivery_destination", "sales_tax_calculation", "price_kind", "detail");
			$query = $db->insertSelect("sales_slips", "`slip_number`,`accounting_date`,`division`,`team`,`manager`,`billing_destination`,`delivery_destination`,`sales_tax_calculation`,`price_kind`,`detail`,`created`,`modified`")
				->addTable("json_table(?, '$[*]' {$columns}) as t", $_POST["json"])
				->addField("t.*,now(),now()");
			$query();
			$result->addMessage("読込が完了しました。", "INFO", "");
		}catch(Exception $ex){
			$result->addMessage("読込に失敗しました。", "ERROR", "");
		}
		return new JsonView($result);
	}
}