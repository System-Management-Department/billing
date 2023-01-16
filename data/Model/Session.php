<?php
namespace Model;
use App\MySQL as Database;

class Session{
	public static function isLogin(){
		return isset($_SESSION["User.id"]);
	}
	public static function getDB(){
		$role = $_SESSION["User.role"] ?? "default";
		$db = new Database($role);
		$assoc = ["User" => []];
		if(isset($_SESSION["User.id"])){
			foreach($_SESSION as $k => $v){
				if(strncmp($k, "User.", 5) == 0){
					$assoc["User"][substr($k, 5)] = $v;
				}
			}
		}
		User::setDBVariables($db, $assoc["User"]);
		return $db;
	}
	
	/**
		User.*にログインユーザー情報を格納
	*/
	public static function login($db, $user){
		session_regenerate_id();
		foreach($user as $k => $v){
			$_SESSION["User.{$k}"] = $v;
		}
		User::setDBVariables($db, $user);
	}
	public static function logout(){
		unset($_SESSION);
		session_destroy();
	}
}