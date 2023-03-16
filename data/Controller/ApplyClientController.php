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
use Model\ApplyClient;
use Model\Session;
use Model\Result;
use Model\SQLite;

class ApplyClientController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		// return new View();
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("apply_clients")
			->andWhere("code=?", $this->requestContext->id);
		$v["data"] = $query();
		return $v;
	}

	#[\Attribute\AcceptRole("admin")]
	public function list(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function create(){
		return new View();
	}
	
	// #[\Attribute\AcceptRole("admin", "entry")]
	// public function search(){
	// 	$db = Session::getDB();
	// 	$sdb = SQLite::cachedData();
	// 	list($columns, $data) = $db->exportTable("apply_clients", [], "0=1 LIMIT 0");
	// 	$query = $db->select("ALL")
	// 		->setTable("apply_clients")
	// 		->andWhere("delete_flag=0");

	// 	$parameter = false;
	// 	if(!empty($_POST["code"])){
	// 		$parameter = true;
	// 		$query->andWhere("code=?", $_POST["code"]);
	// 	}
	// 	if(!empty($_POST["name"])){
	// 		$parameter = true;
	// 		$query->andWhere("name like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["name"]));
	// 	}
	// 	if(!empty($_POST["phone"])){
	// 		$parameter = true;
	// 		$query->andWhere("phone like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["phone"]));
	// 	}

	// 	// $sdb->createTable("apply_clients", $columns, $parameter ? $query() : []);
	// 	return new FileView($sdb->getFileName(), "application/vnd.sqlite3");
	// }

	#[\Attribute\AcceptRole("admin")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = ApplyClient::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			ApplyClient::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = ApplyClient::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			ApplyClient::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		ApplyClient::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}