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
use Model\Team;
use Model\Session;
use Model\Result;
use Model\SQLite;

class TeamController extends ControllerBase{
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
			->addTable("teams")
			->andWhere("code=?", $this->requestContext->id);
		$v["data"] = $query();
		return $v;
	}


	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Team::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Team::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Team::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Team::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Team::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}