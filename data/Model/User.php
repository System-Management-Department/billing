<?php
namespace Model;
use stdClass;
use App\Validator;
use App\MySQL as Database;

class User{
	public static function login(){
		$result = new Result();
		if(Session::isLogin()){
			$result->addMessage("すでにログインしています。", "ERROR", "");
			return $result;
		}
		
		$check = new Validator();
		$check["email"]->required("ユーザー名またはメールアドレスを入力してください。");
		$check["password"]->required("パスワードを入力してください。");
		$check($result, $_POST);
		if($result->hasError()){
			return $result;
		}
		
		try{
			$db = new Database();
			$query = $db
				->select("ROW")
				->setTable("users")
				->addField("*")
				->andWhere("disabled=0")
				->andWhere("email=?", $_POST["email"])
				->andWhere("password=?", $_POST["password"]);
			$accept = true;
			if($user = $query()){
				$query = $db
					->select("ROW")
					->setTable("useronlinestatuses")
					->addField("*,(CASE WHEN hold_until > NOW() THEN 0 ELSE 1 END) as accept")
					->andWhere("user=?", $user["id"]);
				if($online = $query()){
					if($online["accept"] == 0){
						$accept = false;
					}else{
						// ログアウト
						$deleteQuery = $db
							->delete("useronlinestatuses")
							->andWhere("user=?", $user["id"]);
						$deleteQuery();
						session_destroy();
						session_id($online["session_id"]);
						session_start();
						Session::logout();
						session_start();
					}
				}
				if($accept){
					Session::login($db, $user);
					$id = session_id();
					$name = session_name();
					$insertQuery = $db
						->insertSet("useronlinestatuses", [
							"user" => $user["id"],
							"hold_until" => 3,
							"session_name" => $name,
							"session_id" => $id,
						],[
							"hold_until" => "NOW() + INTERVAL ? MINUTE",
						]);
					$insertQuery();
					$result->addMessage("ログインに成功しました。", "INFO", "");
					Logger::record($db, "ログイン", new stdClass());
				}
			}else{
				$accept = false;
			}
			if(!$accept){
				$result->addMessage("ログインに失敗しました。", "ERROR", "");
			}
		}catch(Exception $ex){
			$result->addMessage($ex->getMessage(), "ERROR", "");
		}
		return $result;
	}
	
	public static function setDBVariables($db, $assoc){
		$query = $db
			->select("ROW")
			->addField("@user:=?", $assoc["id"] ?? 0)
			->addField("@username:=?", $assoc["username"] ?? "");
		$query();
	}
}