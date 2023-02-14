<?php
namespace Controller;
use App\ControllerBase;
use App\StreamView;

class StorageController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function sqlite(){
		// ログインユーザーの権限毎のデータベースダウンロード
		$fileName = dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "{$_SESSION["User.role"]}.sqlite3";
		$_SESSION["SQLite.update"] = filemtime($fileName);
		$fp = fopen($fileName, "rb");
		$v = new StreamView($fp, "application/vnd.sqlite3");
		fclose($fp);
		return $v;
	}
}