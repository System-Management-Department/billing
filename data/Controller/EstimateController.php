<?php
namespace Controller;
use App\ControllerBase;
use App\View;
use App\JsonView;
use Model\Session;
use Model\SalesSlip;

class EstimateController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function index(){
		$db = Session::getDB();
		$sequence = date("ym");
		$query = $db->select("ROW")
			->setTable("slip_sequence")
			->andWhere("month=?", $sequence)
			->andWhere("type=1");
		if(empty($query())){
			$db->beginTransaction();
			$insertQuery = $db->insertSet("slip_sequence", [
				"month" => $sequence,
				"type" => 1,
				"seq" => 0,
			],[]);
			$insertQuery();
			$db->commit();
		}
		
		$v = new View();
		$v["id"] = $this->requestContext->id;
		$v["sequence"] = $sequence;
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkInsert($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
}