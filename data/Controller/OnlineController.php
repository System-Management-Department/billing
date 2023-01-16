<?php
namespace Controller;
use Exception;
use App\JsonView;
use App\ControllerBase;
use Model\Session;
use Model\Result;

class OnlineController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		$name = session_name();
		$id = session_id();
		$interval = match($name){
			"PHPSESSID2" => 5,
			default => 3
		};
		$result = new Result();
		try{
			$updateQuery = $db->updateSet("useronlinestatuses", [
				"hold_until" => $interval,
				"session_name" => $name,
			],[
				"hold_until" => "NOW() + INTERVAL ? MINUTE",
			]);
			$updateQuery->andWhere("session_id=?", $id);
			$updateQuery();
		}catch(Exception $ex){
			$result->addMessage("書込に失敗しました。", "ERROR", "");
			$result->setData($ex);
		}
		return new JsonView($result);
	}
}