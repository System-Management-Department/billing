<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\Smarty\SelectionModifiers;
use Model\Summary;
use Model\Session;
use Model\Result;

class SummaryController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		$v = new View();
		$v["modifiers"] = [
			"summaryType" => SelectionModifiers::summaryType([]),
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("summaries")
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
			->addTable("summaries")
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
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Summary::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Summary::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Summary::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Summary::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Summary::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}