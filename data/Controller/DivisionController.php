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
use Model\Division;
use Model\Session;
use Model\Result;
use Model\SQLite;

class DivisionController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function list(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("divisions")
			->andWhere("code=?", $this->requestContext->id);
		$v["data"] = $query();
		return $v;
	}

	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Division::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Division::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Division::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Division::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Division::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}