<?php
namespace Controller;
use Exception;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;
use Model\Result;

class DriveController extends ControllerBase{
	public function index(){
		return (new View())->setLayout(null);
	}
	public function import(){
		$result = new Result();
		try{
			$db = new MySQL();
			$columns = $db->getJsonTableColumns("売上伝票", "伝票番号", "売上日付", "部門", "チーム", "当社担当者", "請求先", "納品先", "消費税", "単価種別", "明細");
			$query = $db->insertSelect("売上伝票", "`伝票番号`,`売上日付`,`部門`,`チーム`,`当社担当者`,`請求先`,`納品先`,`消費税`,`単価種別`,`明細`")
				->addTable("json_table(?, '$[*]' {$columns}) as t", $_POST["json"]);
			$query();
			$result->addMessage("読込が完了しました。", "INFO", "");
		}catch(Exception $ex){
			$result->addMessage("読込に失敗しました。", "ERROR", "");
		}
		return new JsonView($result);
	}
}