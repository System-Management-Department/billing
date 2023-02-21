<?php
namespace Controller;
use DateTime;
use App\ControllerBase;
use App\View;
use App\RedirectResponse;
use Model\Session;
use Model\Logger;

class LogController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function list(){
		$curdate = null;
		if($_SERVER["REQUEST_METHOD"] == "POST"){
			try{
				$curdate = new DateTime($_POST["date"]);
			}catch(\Exception $ex){
			}
		}
		if(is_null($curdate)){
			$curdate = new DateTime();
		}
		
		$v = new View();
		$v["curdate"] = $curdate->format("Y-m-d");
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function listItem(){
		$db = Session::getDB();
		$query = Logger::getSearchQuery($db, $_POST);
		$logs = $query();
		$lastdata = (count($logs) == Logger::$limit) ? end($logs)["id"] : "";
		
		$v = new View();
		$v["logs"] = $logs;
		$v["lastdata"] = $lastdata;
		return $v->setLayout(null);
	}
}