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

class SalesController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ALL")
			->addTable("sales_slips")
			->andWhere("close_processed=0");
		$v["table"] = $query();
		
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$check = new Validator();
		$check["slip_number"]->required("伝票番号を入力してください。")
			->length("伝票番号は10文字以下で入力してください。", null, 10);
		$check["accounting_date"]->required("売上日付を入力してください。");
			//->date("売上日付を正しく入力してください。")
		$check["division"]->required("部門を入力してください。");
			// ->range("部門を正しく入力してください。", "in", [])
		$check["team"]->required("チームを入力してください。");
			// ->range("チームを正しく入力してください。", "in", [])
		$check["manager"]->required("当社担当者を入力してください。");
			// ->range("当社担当者を正しく入力してください。", "in", [])
		$check["billing_destination"]->required("請求先を入力してください。");
			// ->range("請求先を正しく入力してください。", "in", [])
		$check["delivery_destination"]->required("納品先を入力してください。")
			->length("納品先は-文字以下で入力してください。", null, 255);
		//$check["sales_tax_calculation"]->required("税処理を入力してください。")
		//	->range("税処理を正しく入力してください。", "in", [1, 2, 3, 4, 5, 6]);
		$check["subject"]->required("件名を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。");
			//->date("入金予定日を正しく入力してください。")
		
		
		$result = $check($_POST);
		
		$id = null;
		if(!$result->hasError()){
			$db->beginTransaction();
			try{
				$insertQuery = $db->insertSet("sales_slips", [
					"slip_number" => $_POST["slip_number"],
					"accounting_date" => $_POST["accounting_date"],
					"division" => $_POST["division"],
					"team" => $_POST["team"],
					"manager" => $_POST["manager"],
					"billing_destination" => $_POST["billing_destination"],
					"delivery_destination" => $_POST["delivery_destination"],
					//"sales_tax_calculation" => $_POST["sales_tax_calculation"],
					"subject" => $_POST["subject"],
					"note" => $_POST["note"],
					"header1" => $_POST["header1"],
					"header2" => $_POST["header2"],
					"header3" => $_POST["header3"],
					"payment_date" => $_POST["payment_date"],
					"detail" => $_POST["detail"],
				],[
					"created" => "now()",
					"modified" => "now()",
				]);
				$insertQuery($id);
				$db->commit();
			}catch(Exception $ex){
				$result->addMessage("編集保存に失敗しました。", "ERROR", "");
				$result->setData($ex);
				$db->rollback();
			}
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "登録", ["sales_slips" => $id]);
		}
		
		return new JsonView($result);
	}
	
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function createRed(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$data = $query();
		$detail = json_decode($data["detail"], true);
		for($i = 0; $i < $detail["length"]; $i++){
			if(is_numeric($detail["quantity"][$i])){
				$detail["quantity"][$i] = -$detail["quantity"][$i];
			}
			if(is_numeric($detail["amount"][$i])){
				$detail["amount"][$i] = -$detail["amount"][$i];
			}
			if(is_numeric($detail["circulation"][$i])){
				$detail["circulation"][$i] = -$detail["circulation"][$i];
			}
		}
		$data["detail"] = json_encode($detail);
		$v["data"] = $data;
		return $v;
	}
	
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $this->requestContext->id)
			->andWhere("close_processed=0");
		$v["data"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		$id = $this->requestContext->id;
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $id)
			->andWhere("close_processed=0");
		$data = $query();
		
		// 検証
		$check = new Validator();
		$check["accounting_date"]->required("売上日付を入力してください。");
			//->date("売上日付を正しく入力してください。")
		$check["division"]->required("部門を入力してください。");
			// ->range("部門を正しく入力してください。", "in", [])
		$check["team"]->required("チームを入力してください。");
			// ->range("チームを正しく入力してください。", "in", [])
		$check["manager"]->required("当社担当者を入力してください。");
			// ->range("当社担当者を正しく入力してください。", "in", [])
		$check["billing_destination"]->required("請求先を入力してください。");
			// ->range("請求先を正しく入力してください。", "in", [])
		$check["delivery_destination"]->required("納品先を入力してください。")
			->length("納品先は-文字以下で入力してください。", null, 255);
		//$check["sales_tax_calculation"]->required("税処理を入力してください。")
		//	->range("税処理を正しく入力してください。", "in", [1, 2, 3, 4, 5, 6]);
		$check["subject"]->required("件名を入力してください。");
		$check["payment_date"]->required("入金予定日を入力してください。");
			//->date("入金予定日を正しく入力してください。")
		$result = $check($_POST);
		
		if(!$result->hasError()){
			$db->beginTransaction();
			try{
				$updateQuery = $db->updateSet("sales_slips", [
					"accounting_date" => $_POST["accounting_date"],
					"division" => $_POST["division"],
					"team" => $_POST["team"],
					"manager" => $_POST["manager"],
					"billing_destination" => $_POST["billing_destination"],
					"delivery_destination" => $_POST["delivery_destination"],
					//"sales_tax_calculation" => $_POST["sales_tax_calculation"],
					"subject" => $_POST["subject"],
					"note" => $_POST["note"],
					"header1" => $_POST["header1"],
					"header2" => $_POST["header2"],
					"header3" => $_POST["header3"],
					"payment_date" => $_POST["payment_date"],
					"detail" => $_POST["detail"],
				],[
					"output_processed" => 0,
					"modified" => "now()",
				]);
				$updateQuery->andWhere("id=?", $id)
					->andWhere("close_processed=0");
				$updateQuery();
				$db->commit();
			}catch(Exception $ex){
				$result->addMessage("編集保存に失敗しました。", "ERROR", "");
				$result->setData($ex);
				$db->rollback();
			}
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "編集", ["sales_slips" => $data["id"]]);
		}
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$id = $_POST["id"];
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("close_processed=0")
			->andWhere("id=?", $id);
		$data = $query();
		
		$result = new Result();
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("sales_slips");
			$deleteQuery->andWhere("id=?", $id)
				->andWhere("close_processed=0");
			$deleteQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
			@Logger::record($db, "削除", ["sales_slips" => $data["id"]]);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function output(){
		$db = Session::getDB();
		$id = $_POST["id"];
		
		$query = $db->select("ROW")
			->addTable("sales_slips")
			->andWhere("id=?", $id);
		$data = $query();
		
		$result = new Result();
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("sales_slips", [],[
				"output_processed" => 1,
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("出力に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("出力が完了しました。", "INFO", "");
			@Logger::record($db, "出力", ["sales_slips" => $data["id"]]);
		}
		
		return new JsonView($result);
	}
}