<?php
namespace Controller;
use App\ControllerBase;
use App\JsonView;
use App\MySQL as Database;

class APIController extends ControllerBase{
	public function projects(){
		header('Access-Control-Allow-Origin: *');
		$result = json_decode([]);
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
		}
		
		return new JsonView($result);
	}
	public function orders(){
		header('Access-Control-Allow-Origin: *');
		$result = json_decode([]);
		$db = $this->auth();
		if($db != null){
		}
		
		return new JsonView($result);
	}
	public function purchases(){
		header('Access-Control-Allow-Origin: *');
		$result = json_decode([]);
		$db = $this->auth();
		if($db != null){
		}
		
		return new JsonView($result);
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