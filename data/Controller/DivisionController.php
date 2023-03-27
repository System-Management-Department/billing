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
use App\Smarty\SelectionModifiers;
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
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("divisions")
			->andWhere("delete_flag=0")
			->andWhere("code=?", $this->requestContext->id);
		$data = $query();
		
		if(empty($data)){
			// 表示可能な情報がなければ一覧へリダイレクト
			return new RedirectResponse("*", "index");
		}
		
		$v = new View();
		$v["data"] = $data;
		return $v;
	}

	#[\Attribute\AcceptRole("admin")]
	public function detail(){
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("divisions")
			->andWhere("delete_flag=0")
			->andWhere("code=?", $this->requestContext->id);
		$data = $query();
		
		if(empty($data)){
			// 表示可能な情報がなければ一覧へリダイレクト
			return new RedirectResponse("*", "index");
		}
		
		$v = new View();
		$v["data"] = $data;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function upload(){
		$v = new View();
		$v["modifiers"] = [
			"prefectures" => SelectionModifiers::prefectures([]),
		];
		return $v;
	}

	#[\Attribute\AcceptRole("admin")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Division::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Division::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Division::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Division::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Division::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function import(){
		$db = Session::getDB();
		$result = new Result();
		
		Division::execImport($db, $_POST["json"], $this->requestContext, $result);
		
		return new JsonView($result);
	}
}