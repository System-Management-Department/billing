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

use stdClass;
use Model\Logger;

class DriveController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		if(empty($_GET["id"])){
			return new RedirectResponse("Home", "salesInput");
		}
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function x_config(){
		$db = Session::getDB();
		$v = new View();
		$query = $db->select("ONE")->setTable("basic_info")->setField("value")->andWhere("`key`=?", "gserviceaccount");
		$value = $query();
		if(!empty($value)){
			$v["value"] = json_decode($value, true);
		}
		return $v;
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
	
	#[\Attribute\AcceptRole("admin")]
	public function x_update(){
		$db = Session::getDB();
		
		// 取込
		$result = new Result();
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("basic_info")
				->andWhere("`key`=?", "gserviceaccount");
			$deleteQuery();
			$insertQuery = $db->insertSet("basic_info", [
				"key" => "gserviceaccount",
				"value" => $_POST["value"],
			],[]);
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("サービスアカウントの登録に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("サービスアカウントの登録が完了しました。", "INFO", "");
			@Logger::record($db, "サービスアカウントの登録", new stdClass());
		}
		
		return new JsonView($result);
	}
	
}