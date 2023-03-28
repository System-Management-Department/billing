<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\FileView;
use App\RedirectResponse;
use App\ControllerBase;
use App\Smarty\SelectionModifiers;
use Model\User;
use Model\Session;
use Model\Result;
use Model\SQLite;

class UserController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		$v = new View();
		$v["modifiers"] = [
			"role" => SelectionModifiers::role([]),
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$sdb = SQLite::cachedData();
		list($columns, $data) = $db->exportTable("users", ["created" => null, "modified" => null, "disabled" => null], "disabled=0");
		$sdb->createTable("users", $columns, $data);
		return new FileView($sdb->getFileName(), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("users")
			->andWhere("disabled=0")
			->andWhere("id=?", $this->requestContext->id);
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
			->addTable("users")
			->andWhere("disabled=0")
			->andWhere("id=?", $this->requestContext->id);
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
			"role" => SelectionModifiers::role([]),
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = User::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			User::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = User::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			User::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		User::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function import(){
		$db = Session::getDB();
		$result = new Result();
		
		User::execImport($db, $_POST["json"], $this->requestContext, $result);
		
		return new JsonView($result);
	}
}