<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use App\Validator;
use Model\Session;
use Model\Result;
use Model\SalesSlip;
use Model\SQLite;

class CommittedController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function edit(){
		$v = new View();
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function search(){
		$db = Session::getDB();
		$query = $db->select("COL")
			->setTable("sales_slips")
			->setField("id")
			->setLimit(100)
			->andWhere("close_processed=0")
			->andWhere("approval=0");
		if(!empty($_POST)){
			if(!empty($_POST["slip_number"])){
				$query->andWhere("slip_number like concat('%',?,'%')", preg_replace('/(:?[\\\\%_])/', "\\", $_POST["slip_number"]));
			}
			if(!empty($_POST["accounting_date"])){
				if(!empty($_POST["accounting_date"]["from"])){
					$query->andWhere("DATEDIFF(created,?) >= 0", $_POST["accounting_date"]["from"]);
				}
				if(!empty($_POST["accounting_date"]["to"])){
					$query->andWhere("DATEDIFF(created,?) <= 0", $_POST["accounting_date"]["to"]);
				}
			}
			if(!empty($_POST["division"])){
				$query->andWhere("division=?", $_POST["division"]);
			}
			if(!empty($_POST["manager"])){
				$query->andWhere("manager=?", $_POST["manager"]);
			}
			if(!empty($_POST["billing_destination"])){
				$query->andWhere("billing_destination=?", $_POST["billing_destination"]);
			}
		}
		$searchIds = json_encode($query($cnt));
		
		
		$query1 = $db->select("EXPORT")
			->setTable("sales_slips")
			->andWhere("id MEMBER OF(?)", $searchIds);
		$query2 = $db->select("EXPORT")
			->setTable("purchases")
			->addField("purchases.*")
			->leftJoin("sales_slips on purchases.spreadsheet=sales_slips.spreadsheet")
			->andWhere("sales_slips.id MEMBER OF(?)", $searchIds);
		if(($_SESSION["User.role"] == "admin") || ($_SESSION["User.role"] == "entry")){
		}else if($_SESSION["User.role"] == "leader"){
			$divisionQuery = $db->select("ONE")
				->setTable("managers")
				->addField("division")
				->andWhere("code=@manager");
			$division = $divisionQuery();
			$query1->andWhere("division=?", $division);
			$query2->andWhere("sales_slips.division=?", $division);
		}else{
			$query1->andWhere("manager=@manager");
			$query2->andWhere("sales_slips.manager=@manager");
		}
		
		return new FileView(SQLite::memoryData([
			"sales_slips" => $query1(),
			"purchases" => $query2(),
			"_info" => ["columns" => ["key", "value"], "data" => [["key" => "count", "value" => $cnt]]]
		]), "application/vnd.sqlite3");
	}
	
	#[\Attribute\AcceptRole("admin", "manager", "leader")]
	public function update(){
		$db = Session::getDB();
		
		// 検証
		$result = SalesSlip::checkUpdate3($db, $_POST, [], $this->requestContext);
		
		if(!$result->hasError()){
			SalesSlip::execUpdate3($db, $_POST, $this->requestContext, $result);
		}
		
		return new JsonView($result);
	}
	
	#[\Attribute\AcceptRole("admin", "leader")]
	public function approval(){
		$db = Session::getDB();
		
		$result = new Result();
		SalesSlip::approval($db, $_POST, $this->requestContext, $result);
		
		return new JsonView($result);
	}
}