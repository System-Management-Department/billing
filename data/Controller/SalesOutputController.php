<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Logger;
use Model\Session;
use Model\Result;

class SalesOutputController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		
		list($jsonField, $keys) = $db->getTable2JsonField(["sales_slips", null], null, [
			"id" => null,
			"output_processed" => null,
			"close_processed" => null,
			"closing_date" => null,
			"created" => null,
			"modified" => null
		]);
		$query = $db->select("ONE")
			->addTable("sales_slips")
			->addField("JSON_OBJECTAGG(id,{$jsonField})", ...$keys);
		$v["table"] = $query();
		
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function output(){
		$db = Session::getDB();
		$id = $_POST["id"];
		$t = [];
		foreach($id as $item){
			$t[] = ["id" => $item];
		}
		
		$result = new Result();
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"output_processed" => 1,
			]);
			$updateQuery->andWhere("id IN (SELECT id FROM JSON_TABLE(?, '$[*]' COLUMNS(id INT PATH '$.id')) AS t)", json_encode($t));
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("出力に失敗しました。", "ERROR", "");
			$result->setData($ex->getMessage());
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("出力が完了しました。", "INFO", "");
			@Logger::record($db, "出力", ["sales_slips" => $id]);
		}
		
		return new JsonView($result);
	}
}