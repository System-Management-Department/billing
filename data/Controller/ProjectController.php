<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\Smarty\SelectionModifiers;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Session;
use Model\Result;
use Model\Project;
use Model\SQLite;

class ProjectController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function index(){
		$v = new View();
		$v["modifiers"] = [
			"confidence" => SelectionModifiers::confidence([]),
			"invoiceFormat" => SelectionModifiers::invoiceFormat([]),
		];
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function edit(){
		$db = Session::getDB();
		$v = new View();
		
		$query = $db->select("ROW")
			->addTable("projects")
			->andWhere("id=?", $this->requestContext->id);
		$v["data"] = $query();
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("ALL")
			->setTable("projects");
		$parameter = false;
		if(!empty($_POST)){
			if(!empty($_POST["code"])){
				$parameter = true;
				$query->andWhere("code like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["code"]));
			}
			if(!empty($_POST["confidence"])){
				$parameter = true;
				$query->andWhere("confidence=?", $_POST["confidence"]);
			}
			if(!empty($_POST["billing_month"])){
				$parameter = true;
				$query->andWhere("DATE_FORMAT(billing_month, '%Y-%m')=?", $_POST["billing_month"]);
			}
			if(!empty($_POST["client"])){
				$parameter = true;
				$query->andWhere("client=?", $_POST["client"]);
			}
			if(!empty($_POST["apply_client"])){
				$parameter = true;
				$query->andWhere("apply_client=?", $_POST["apply_client"]);
			}
			if(!empty($_POST["invoice_delivery"])){
				$parameter = true;
				$query->andWhere("invoice_delivery like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["invoice_delivery"]));
			}
			if(!empty($_POST["payment_date"])){
				$parameter = true;
				$query->andWhere("payment_date=?", $_POST["payment_date"]);
			}
			if(!empty($_POST["subject"])){
				$parameter = true;
				$query->andWhere("subject like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["subject"]));
			}
			if(!empty($_POST["invoice_format"])){
				$parameter = true;
				$query->andWhere("invoice_format=?", $_POST["invoice_format"]);
			}
			if(!empty($_POST["header1"])){
				$parameter = true;
				$query->andWhere("header1 like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["header1"]));
			}
			if(!empty($_POST["header2"])){
				$parameter = true;
				$query->andWhere("header2 like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["header2"]));
			}
			if(!empty($_POST["header3"])){
				$parameter = true;
				$query->andWhere("header3 like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["header3"]));
			}
			if(!empty($_POST["note"])){
				$parameter = true;
				$query->andWhere("note like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["note"]));
			}
			if(!empty($_POST["manager"])){
				$parameter = true;
				$query->andWhere("manager=?", $_POST["manager"]);
			}
		}
		
		list($columns, $data) = $db->exportTable("projects", [], "1=0 limit 0");
		return new FileView(SQLite::memoryData(["projects" => [
			"columns" => $columns,
			"data" => $parameter ? $query() : []
		]])->getFileName(), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function regist(){
		$db = Session::getDB();
		
		// 検証
		$result = Project::checkInsert($db, $_POST, []);
		
		if(!$result->hasError()){
			Project::execInsert($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = Project::checkUpdate($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			Project::execUpdate($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function delete(){
		$db = Session::getDB();
		$result = new Result();
		
		Project::execDelete($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}