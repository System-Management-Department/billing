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
	
	public static function checkInsert($db, $q, $masterData){
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	public static function checkUpdate($db, $q, $masterData, $context){
		$id = $context->id;
		$check = new Validator();
		self::validate($check, $masterData, $db);
		$result = $check($q);
		return $result;
	}
	
	/**
		登録・更新共通の検証
	*/
	public static function validate($check, $masterData, $db){
		$check["username"]->required("ユーザ名を入力してください。")
			->length("ユーザ名は80文字以下で入力してください。", null, 255);
		$check["email"]->required("メールアドレスを入力してください。")
			->mail("メールアドレスを正しく入力してください。");
		$check["password"]->required("パスワードを入力してください。")
			->length("パスワードは6～12文字で入力してください。", 6, 12)
			->password("このパスワードは設定できません。");
		$check["role"]->required("権限を入力してください。")
			->range("権限を正しく入力してください。", "in", ["admin", "entry"]);
		$check["department"]->length("部署名は80文字以下で入力してください。", null, 255);
	}
	
	public static function execInsert($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$insertQuery = $db->insertSet("users", [
				"username" => $q["username"],
				"email" => $q["email"],
				"password" => $q["password"],
				"role" => $q["role"],
				"department" => $q["department"],
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
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "登録", ["users" => $id]);
		}
	}
	
	public static function execUpdate($db, $q, $context, $result){
		$id = $context->id;
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("users", [
				"username" => $q["username"],
				"email" => $q["email"],
				"password" => $q["password"],
				"role" => $q["role"],
				"department" => $q["department"],
			],[
				"modified" => "now()",
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("編集保存に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("編集保存が完了しました。", "INFO", "");
			@Logger::record($db, "編集", ["users" => $id]);
		}
	}
	
	public static function execDelete($db, $q, $context, $result){
		$id = $q["id"];
		$db->beginTransaction();
		try{
			$updateQuery = $db->updateSet("users", [
			],[
				"disabled" => "1",
			]);
			$updateQuery->andWhere("id=?", $id);
			$updateQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("削除に失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("削除が完了しました。", "INFO", "");
			@Logger::record($db, "削除", ["users" => $id]);
		}
	}
	
	public static function execImport($db, $q, $context, $result){
		$db->beginTransaction();
		try{
			$deleteQuery = $db->delete("users");
			$deleteQuery();
			$table = $db->getJsonArray2Tabel(["users" => [
				"id" => "$.id",
				"username" => "$.username",
				"email" => "$.email",
				"password" => "$.password",
				"role" => "$.role",
				"department" => "$.department",
			]], "t");
			$insertQuery = $db->insertSelect("users", "id, username, email, password, role, department, created, modified, disabled")
				->addTable($table, $q)
				->addField("id, username, email, password, role, department")
				->addField("now(), now(), 0");
			$insertQuery();
			$db->commit();
		}catch(Exception $ex){
			$result->addMessage("インポートに失敗しました。", "ERROR", "");
			$result->setData($ex);
			$db->rollback();
		}
		if(!$result->hasError()){
			$result->addMessage("インポートが完了しました。", "INFO", "");
			@Logger::record($db, "インポート", ["users" => []]);
		}
	}
}