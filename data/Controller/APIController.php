<?php
namespace Controller;
use SimpleXMLElement;
use App\ControllerBase;
use App\View;
use App\StreamView;
use App\MySQL as Database;

class APIController extends ControllerBase{
	public function projects(){
		header('Access-Control-Allow-Origin: *');
		
		$v = new View();
		$v->setLayout(null)->setAction("_result");
		$db = $this->auth();
		if($db != null){
			$jsonTable = $db->getJsonArray2Tabel([
				"dual" => [
					"manager_name text " => '$.manager',
					"confidence_name text" => '$.confidence',
					"billing_month_name text" => '$.billing_month',
					"client_name text" => '$.client',
					"apply_client_name text" => '$.apply_client',
					"payment_date_name text" => '$.payment_date',
				],
				"projects" => [
					"code" => '$.code',
					"invoice_delivery" => '$.invoice_delivery',
				]
			], "json_table");
			$query = $db->insertSelect("projects", "code,invoice_delivery,manager,confidence,billing_month,client,apply_client,payment_date,ingest,created,modified")
				->addTable($jsonTable, $_POST["json"])
				->addField("json_table.code,json_table.invoice_delivery")
				->leftJoin("managers on json_table.manager_name=managers.name")
				->addField("managers.code")
				->addField("null,null")
				->leftJoin("clients on json_table.client_name=clients.name")
				->addField("clients.code")
				->leftJoin("apply_clients on json_table.apply_client_name=apply_clients.unique_name")
				->addField("apply_clients.code")
				->addField("null")
				->addField("JSON_OBJECT('manager',json_table.manager_name,'confidence',json_table.confidence_name,'billing_month',json_table.billing_month_name,'client',json_table.client_name,'apply_client',json_table.apply_client_name,'payment_date',json_table.payment_date_name)")
				->addField("now(),now()");
			$query();
			$v["message"] = "<h2>登録が完了しました。</h2>";
		}else{
			$v["message"] = "<h2>認証に失敗しました。</h2>設定から正しいメールアドレスとパスワードの入力してください。";
		}
		
		return $v;
	}
	public function orders(){
		header('Access-Control-Allow-Origin: *');
		$v = new View();
		$v->setLayout(null)->setAction("_result");
		$db = $this->auth();
		if($db != null){
			$db->beginTransaction();
			$jsonTable = $db->getJsonArray2Tabel([
				"dual" => [
					"category_name text " => '$.category',
				],
				"orders" => [
					"project" => '$.project',
					"item_name" => '$.item_name',
					"subject" => '$.subject',
					"amount" => '$.amount',
				]
			], "json_table");
			$query = $db->insertSelect("orders", "project,item_name,amount,subject,category,ingest,created,modified")
				->addTable($jsonTable, $_POST["json"])
				->addField("json_table.project,json_table.item_name,json_table.amount,json_table.subject")
				->leftJoin("categories on json_table.category_name=categories.name")
				->addField("categories.code")
				->addField("JSON_OBJECT('category',json_table.category_name)")
				->addField("now(),now()");
			$query();
			
			$jsonTable = $db->getJsonArray2Tabel([
				"projects" => [
					"code" => '$.project'
				]
			], "json_table");
			$query = $db->updateSet("projects", [], [
				"import_orders" => 1
			])->andWhere("code IN(SELECT code FROM {$jsonTable})", $_POST["json"]);
			$query();
			$db->commit();
			$v["message"] = "<h2>登録が完了しました。</h2>";
		}else{
			$v["message"] = "<h2>認証に失敗しました。</h2>設定から正しいメールアドレスとパスワードの入力してください。";
		}
		
		return $v;
	}
	public function purchases(){
		header('Access-Control-Allow-Origin: *');
		$v = new View();
		$v->setLayout(null)->setAction("_result");
		$db = $this->auth();
		if($db != null){
			$db->beginTransaction();
			$jsonTable = $db->getJsonArray2Tabel([
				"dual" => [
					"supplier_name text " => '$.supplier',
					"status_name text " => '$.status',
				],
				"purchases" => [
					"project" => '$.project',
					"subject" => '$.subject',
					"amount" => '$.amount',
					"note" => '$.note',
					"payment_date" => '$.payment_date',
				]
			], "json_table");
			$query = $db->insertSelect("purchases", "project,payment_date,amount,subject,note,supplier,status,ingest,created,modified")
				->addTable($jsonTable, $_POST["json"])
				->addField("json_table.project,json_table.payment_date,json_table.amount,json_table.subject,json_table.note")
				->leftJoin("suppliers on json_table.supplier_name=suppliers.name")
				->addField("suppliers.code")
				->addField("0")
				->addField("JSON_OBJECT('supplier',json_table.supplier_name,'status',json_table.status_name)")
				->addField("now(),now()");
			$query();
			
			$jsonTable = $db->getJsonArray2Tabel([
				"projects" => [
					"code" => '$.project'
				]
			], "json_table");
			$query = $db->updateSet("projects", [], [
				"import_purchases" => 1
			])->andWhere("code IN(SELECT code FROM {$jsonTable})", $_POST["json"]);
			$query();
			$db->commit();
			$v["message"] = "<h2>登録が完了しました。</h2>";
		}else{
			$v["message"] = "<h2>認証に失敗しました。</h2>設定から正しいメールアドレスとパスワードの入力してください。";
		}
		
		
		return $v;
	}
	public function exist(){
		header('Access-Control-Allow-Origin: *');
		
		$documentElement = new SimpleXMLElement("<root />");
		$db = $this->auth();
		if($db != null){
			$jsonTable = $db->getJsonArray2Tabel([
				"projects" => [
					"code" => '$.code',
				]
			], "json_table");
			
			$query = $db->select("ASSOC")
				->addTable($jsonTable, $_POST["json"])
				->leftJoin("projects on json_table.code=projects.code")
				->addField("json_table.code,CASE WHEN projects.id IS NULL THEN 0 ELSE 1 END AS exist,projects.import_orders,projects.import_purchases");
			$res = $query();
			foreach($res as $code => $row){
				if($row["exist"] == 1){
					$rowElement = $documentElement->addChild("exist");
					$rowElement->addAttribute("code", $code);
					$rowElement->addAttribute("orders", $row["import_orders"]);
					$rowElement->addAttribute("purchases", $row["import_purchases"]);
				}
			}
		}else{
			$documentElement->addAttribute("result", "認証に失敗しました。");
		}
		
		$fp = fopen("php://temp", "r+");
		fwrite($fp, $documentElement->asXML());
		fflush($fp);
		fseek($fp, 0, SEEK_SET);
		$v = new StreamView($fp, "application/xml");
		fclose($fp);
		return $v;
	}
	private function auth(){
		$db = new Database();
		$query = $db
			->select("ROW")
			->setTable("users")
			->addField("*")
			->andWhere("disabled=0")
			->andWhere("email=?", $_POST["email"])
			->andWhere("password=?", $_POST["password"]);
		if($user = $query()){
			$query = $db
				->select("ROW")
				->addField("@user:=?", $user["id"] ?? 0)
				->addField("@username:=?", $user["username"] ?? "");
			$query();
			return $db;
		}
		return null;
	}
}