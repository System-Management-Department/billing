<?php
namespace Model;

class Error{
	public static $data = [];
	public static function pushData($errno, $errstr, $errfile, $errline){
		if($errno == E_USER_ERROR){
			return false;
		}
		self::$data[] = [
			"no" => $errno,
			"file" => str_replace(DIRECTORY_SEPARATOR, "/", $errfile),
			"line" => $errline,
			"message" => $errstr,
		];
		return true;
	}
}