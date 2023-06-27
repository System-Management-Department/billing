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

class SalesDetailController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function createRed(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$data = $query();
		$detail = json_decode($data["detail"], true);
		for($i = 0; $i < $detail["length"]; $i++){
			if(is_numeric($detail["quantity"][$i])){
				$detail["quantity"][$i] = -$detail["quantity"][$i];
			}
			if(is_numeric($detail["amount"][$i])){
				$detail["amount"][$i] = -$detail["amount"][$i];
			}
			if(is_numeric($detail["circulation"][$i])){
				$detail["circulation"][$i] = -$detail["circulation"][$i];
			}
		}
		$data["detail"] = json_encode($detail);
		$v["data"] = $data;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$sdb = SQLite::cachedData();
		$query1 = $db->select("EXPORT")
			->setTable("projects")
			->addField("projects.*")
			->leftJoin("sales_slips on projects.code=sales_slips.project")
			->addField("sales_slips.id AS sales_slip")
			->andWhere("(sales_slips.close_processed=0 OR sales_slips.close_processed IS NULL)");
		$query2 = $db->select("EXPORT")
			->setTable("orders")
			->addField("orders.*")
			->leftJoin("sales_slips on orders.project=sales_slips.project")
			->andWhere("(sales_slips.close_processed=0 OR sales_slips.close_processed IS NULL)");
		$query3 = $db->select("EXPORT")
			->setTable("sales_slips")
			->andWhere("sales_slips.close_processed=0");
		if($_SESSION["User.role"] == "admin"){
		}else if($_SESSION["User.role"] == "leader"){
			$division = $db->select("ONE")
				->setTable("managers")
				->addField("division")
				->andWhere("code=@manager");
			$query1->andWhere("projects.manager IN(SELECT code FORM managers WHERE division=?)", $division());
		}else{
			$query1->andWhere("projects.manager=@manager");
		}
		
		return new FileView(SQLite::memoryData([
			"projects" => $query1(),
			"orders"   => $query2(),
			"sales_slips" => $query3()
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkInsert2($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execInsert2($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkUpdate2($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execUpdate2($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "leader")]
	public function approval(){
		$db = Session::getDB();
		
		$result = new Result();
		SalesSlip::approval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "leader")]
	public function disapproval(){
		$db = Session::getDB();
		
		$result = new Result();
		SalesSlip::disapproval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}