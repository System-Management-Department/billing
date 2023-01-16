<?php
namespace Config;

class MySqlConnection{
	public static function __callStatic($name, $arguments){
		return ['localhost', '(ユーザ名)', '（パスワード）', '売上請求管理'];
	}
	
	public static function auth(){
		/** ユーザー認証 */
		return ['localhost', '', '', '売上請求管理'];
	}
	
	public static function admin(){
		/** 管理者 */
		return ['localhost', '', '', '売上請求管理'];
	}
	
	public static function entry(){
		/** 編集 */
		return ['localhost', '', '', '売上請求管理'];
	}
}