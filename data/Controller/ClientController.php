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
use Model\Client;
use Model\Session;
use Model\Result;
use Model\SQLite;

class ClientController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("clients")
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
			->addTable("clients")
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
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function upload(){
		$v = new View();
		$v["modifiers"] = [
			"closeProcessing" => SelectionModifiers::closeProcessing([]),
			"prefectures"     => SelectionModifiers::prefectures([]),
			"invoiceFormat"   => SelectionModifiers::invoiceFormat([]),
			"taxRound"        => SelectionModifiers::taxRound([]),
			"taxProcessing"   => SelectionModifiers::taxProcessing([]),
			"closeDate"       => SelectionModifiers::closeDate([]),
			"monthList"       => SelectionModifiers::monthList([]),
			"unitPriceType"   => SelectionModifiers::unitPriceType([]),
			"existence"       => SelectionModifiers::existence([]),
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Client::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Client::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Client::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Client::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Client::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function import(){
		$db = Session::getDB();
		$result = new Result();
		
		Client::execImport($db, $_POST["json"], $this->requestContext, $result);
		
		return new JsonView($result);
	}
}