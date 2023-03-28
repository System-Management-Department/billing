<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\Validator;
use Model\Session;
use Model\BasicInfo;

class BasicInfoController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		$v = new View();
		$db = Session::getDB();
		
		$data = [];
		$query = $db->select("ASSOC")
			->setTable("basic_info")
			->setField("`key`,`value`");
		$tempData = $query();
		
		if(!empty($tempData)){
			foreach($tempData as $k => $val){
				$data[$k] = $val["value"];
			}
		}
		$v["data"] = $data;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = BasicInfo::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			BasicInfo::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
}