<?php
namespace Controller;
use Exception;
use DateTime;
use App\ControllerBase;
use App\JsonView;
use Model\Session;
use Model\Result;
use Model\SQLite;

class UploadController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function estimate(){
		$db = Session::getDB();
		$now = new DateTime();
		$month = $now->format("ym"); 
		$result = new Result();
		$db->beginTransaction();
		try{
			// 伝票番号生成
			$sequence = $db->select("ONE")
				->setTable("slip_sequence")
				->setField("seq")
				->andWhere("month=?", $month)
				->andWhere("type=6");
			$slipNumber = $sequence();
			if(empty($slipNumber)){
				$slipNumber = 1;
				$insertQuery = $db->insertSet("slip_sequence", [
					"seq" => 1,
					"month" => $month,
					"type" => 6,
				],[]);
				$insertQuery();
				$db->commit();
			}else{
				$slipNumber++;
				$updateQuery = $db->updateSet("slip_sequence", [],[
					"seq" => "seq+1",
				]);
				$updateQuery->andWhere("month=?", $month);
				$updateQuery->andWhere("type=6");
				$updateQuery();
				$db->commit();
			}
		}catch(Exception $ex){
			$result->addMessage("伝票番号生成に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$path = sprintf("/x-reports/estimate/%s/%s/%08d.pdf", $now->format("Y"), $now->format("m"), $slipNumber);
			$info = sprintf("/x-reports/estimate/%s/%s/info.csv", $now->format("Y"), $now->format("m"));
			$updir = $_SERVER["DOCUMENT_ROOT"] . $path;
			if(!is_dir(dirname($updir))){
				mkdir(dirname($updir), 0777, true);
			}
			move_uploaded_file($_FILES["pdf"]["tmp_name"], $updir);
			file_put_contents($_SERVER["DOCUMENT_ROOT"] . $info, sprintf("%08d.pdf,%s\n", $slipNumber, $_SESSION["User.id"]), FILE_APPEND | LOCK_EX);
			$result->addMessage($path, "INFO", "path");
		}
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function billing(){
		$now = new DateTime();
		$result = new Result();
		$path = sprintf("/x-reports/billing/%s/%s/%09d.pdf", $now->format("Y"), $now->format("m"), $_POST["name"]);
		$updir = $_SERVER["DOCUMENT_ROOT"] . $path;
		if(!is_dir(dirname($updir))){
			mkdir(dirname($updir), 0777, true);
		}
		move_uploaded_file($_FILES["pdf"]["tmp_name"], $updir);
		$result->addMessage($path, "INFO", "path");
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function purchase(){
		$now = new DateTime();
		$result = new Result();
		$path = sprintf("/x-reports/purchase/%s/%s/%09d.pdf", $now->format("Y"), $now->format("m"), $_POST["name"]);
		$updir = $_SERVER["DOCUMENT_ROOT"] . $path;
		if(!is_dir(dirname($updir))){
			mkdir(dirname($updir), 0777, true);
		}
		move_uploaded_file($_FILES["pdf"]["tmp_name"], $updir);
		$result->addMessage($path, "INFO", "path");
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function sales(){
		$now = new DateTime();
		$result = new Result();
		$path = sprintf("/x-reports/sales/%s/%s/%09d.pdf", $now->format("Y"), $now->format("m"), $_POST["name"]);
		$updir = $_SERVER["DOCUMENT_ROOT"] . $path;
		if(!is_dir(dirname($updir))){
			mkdir(dirname($updir), 0777, true);
		}
		move_uploaded_file($_FILES["pdf"]["tmp_name"], $updir);
		$result->addMessage($path, "INFO", "path");
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function info(){
		$result = [];
		if(($fp = fopen($_SERVER["DOCUMENT_ROOT"] . "/" . $this->requestContext->id, "r")) !== FALSE){
			while(($data = fgetcsv($fp, 1000, ",")) !== FALSE){
				if($data[1] == $_SESSION["User.id"]){
					$result[] = $data[0];
				}
			}
			fclose($fp);
		}
		return new JsonView($result);
	}
}