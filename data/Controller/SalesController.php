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

class SalesController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ALL")
			->addTable("sales_slips")
			->andWhere("close_processed=0");
		$v["table"] = $query();
		
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			SalesSlip::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	
	#[\Attribute\AcceptRole("admin", "entry")]
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
	
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$v["data"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		SalesSlip::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}