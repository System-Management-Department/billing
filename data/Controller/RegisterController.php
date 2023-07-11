<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL as Database;
use Model\SalesSlip;
use Model\Result;

class RegisterController extends ControllerBase{
	public function index(){
		$v = new View();
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
	public function regist(){
		$db = $this->auth();
		if($db != null){
			// 検証
			$result = SalesSlip::checkInsert3($db, $_POST, [], $this->requestContext);
			if(!$result->hasError()){
				SalesSlip::execInsert3($db, $_POST, $this->requestContext, $result);
			}
			return new JsonView($result);
		}else{
			$result = new Result();
			$result->addMessage("認証に失敗しました。", "ERROR", "");
			return new JsonView($result);
		}
	}
	private function auth(){
		$db = new Database();
		$query = $db
			->select("ROW")
			->setTable("users")
			->addField("users.*")
			->andWhere("disabled=0")
			->andWhere("email=?", $_POST["email"])
			->andWhere("password=?", $_POST["password"])
			->leftJoin("managers on users.manager=managers.code")
			->addField("managers.division");
		if($user = $query()){
			$query = $db
				->select("ROW")
				->addField("@user:=?", $user["id"] ?? 0)
				->addField("@manager:=?", $user["manager"] ?? null)
				->addField("@division:=?", $user["division"] ?? null)
				->addField("@username:=?", $user["username"] ?? "");
			$query();
			return $db;
		}
		return null;
	}
}