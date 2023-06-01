<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\Smarty\SelectionModifiers;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Session;
use Model\Result;
use Model\Purchase;
use Model\SQLite;

class PurchaseController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$v = new View();
		$v["modifiers"] = [
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("purchases")
			->andWhere("id=?", $this->requestContext->id);
		$v["data"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("EXPORT")
			->setTable("purchases");
		$parameter = false;
		if(!empty($_POST)){
			if(!empty($_POST["project"])){
				$parameter = true;
				$query->andWhere("project like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["project"]));
			}
			if(!empty($_POST["supplier"])){
				$parameter = true;
				$query->andWhere("supplier=?", $_POST["supplier"]);
			}
			if(!empty($_POST["payment_date"])){
				$parameter = true;
				$query->andWhere("payment_date=?", $_POST["payment_date"]);
			}
			if(!empty($_POST["unit"])){
				$parameter = true;
				$query->andWhere("unit like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["unit"]));
			}
			if(!empty($_POST["quantity"])){
				$parameter = true;
				$query->andWhere("quantity=?", $_POST["quantity"]);
			}
			if(!empty($_POST["unitPrice"])){
				$parameter = true;
				$query->andWhere("unitPrice=?", $_POST["unitPrice"]);
			}
			if(!empty($_POST["amount"])){
				$parameter = true;
				$query->andWhere("amount=?", $_POST["amount"]);
			}
			if(!empty($_POST["subject"])){
				$parameter = true;
				$query->andWhere("subject like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["subject"]));
			}
			if(!empty($_POST["note"])){
				$parameter = true;
				$query->andWhere("note like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["note"]));
			}
			if(!empty($_POST["status"])){
				$parameter = true;
				$query->andWhere("status=?", $_POST["status"]);
			}
		}
		
		if(!$parameter){
			$query->setLimit(0);
		}
		return new FileView(SQLite::memoryData([
			"purchases" => $query()
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Purchase::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Purchase::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Purchase::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Purchase::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Purchase::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}