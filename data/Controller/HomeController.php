<?php
namespace Controller;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\ControllerBase;
use App\MySQL;
use Model\Session;
use Model\SQLite;

class HomeController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function index(){
		$v = new View();
		$includeDir = [];
		$dirName = dirname(__DIR__) . DIRECTORY_SEPARATOR . "Views" . DIRECTORY_SEPARATOR . "Home" . DIRECTORY_SEPARATOR;
		$dh = opendir($dirName);
		while(($fileName = readdir($dh)) !== false){
			if((substr($fileName, 0, 1) == "_") && is_dir($dirName . $fileName)){
				$includeDir[] = $dirName . $fileName;
			}
		}
		$v["includeDir"] = $includeDir;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("COL")
			->setTable("sales_slips")
			->setField("sales_slips.ss")
			->setLimit(1000)
			->leftJoin("sales_workflow using(ss)")
			->andWhere("approval=0")
			->andWhere("close=0");
		if($_SESSION["User.role"] != "admin"){
			// 管理者以外非表示
			$query->andWhere("sales_workflow.hide=0");
		}
		if($_SESSION["User.role"] == "manager"){
			// 担当者　自身の所有するすべて
			$query->andWhere("sales_workflow.regist_user=?", $_SESSION["User.id"]);
		}else if($_SESSION["User.role"] == "leader"){
			// 責任者　自身の所有するすべてと、自身の部署の申請中のもの
			$query->andWhere("(sales_workflow.regist_user=? OR (JSON_CONTAINS(?, JSON_ARRAY(sales_slips.division), '\$') AND sales_workflow.request=1))", $_SESSION["User.id"], json_encode($_SESSION["User.departmentCode"]));
		}
		$query->andWhere("sales_workflow.request=1");
		$searchIds = json_encode($query($cnt));
		
		return new FileView(SQLite::memoryData([
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function sales(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function salesInput(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function billing(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function master(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function billingPreview(){
		$db = Session::getDB();
		$id = $this->requestContext->id;
		$query = $db->select("ONE")
			->setTable("sales_slips")
			->setField("invoice_format")
			->andWhere("ss=?", $id);
		$format = $query();
		$v = new View();
		$v
			->setLayout(
				"Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl|" .
				DATA_DIR . "Views" . DIRECTORY_SEPARATOR . $this->requestContext->controller . DIRECTORY_SEPARATOR . "{$this->requestContext->action}.tpl"
			)
			->setAction($this->requestContext->action . DIRECTORY_SEPARATOR . $format)
			["id"] = $id;
		return $v;
	}
}