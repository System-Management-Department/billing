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
		$db = Session::getDB();
		
		$query = $db->select("ROW")
			->addTable("apply_clients")
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
			->addTable("apply_clients")
			->addField("apply_clients.*")
			->andWhere("apply_clients.delete_flag=0")
			->andWhere("apply_clients.code=?", $this->requestContext->id)
			->leftJoin("clients on apply_clients.client=clients.code")
			->addField("clients.name as client_name");
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
	
	#[\Attribute\AcceptRole("admin")]
	public function import(){
		$db = Session::getDB();
		$result = new Result();
		
		ApplyClient::execImport($db, $_POST["json"], $this->requestContext, $result);
		
		return new JsonView($result);
	}
}