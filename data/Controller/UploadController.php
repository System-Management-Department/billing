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
			$updir = $_SERVER["DOCUMENT_ROOT"] . $path;
			if(!is_dir(dirname($updir))){
				mkdir(dirname($updir), '0777', true);
			}
			move_uploaded_file($_FILES["pdf"]["tmp_name"], $updir);
			$result->addMessage($path, "INFO", "path");
		}
		return new JsonView($result);
	}
}