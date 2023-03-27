<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use App\ControllerBase;
use Model\Category;
use Model\Session;
use Model\Result;

class CategoryController extends ControllerBase{
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
			->addTable("categories")
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
			->addTable("categories")
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
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Category::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Category::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Category::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Category::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Category::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function import(){
		$db = Session::getDB();
		$result = new Result();
		
		Category::execImport($db, $_POST["json"], $this->requestContext, $result);
		
		return new JsonView($result);
	}
}