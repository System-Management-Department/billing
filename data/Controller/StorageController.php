<?php
namespace Controller;
use App\ControllerBase;
use App\FileView;

class StorageController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "leader", "manager")]
	public function sqlite(){
		// ログインユーザーの権限毎のデータベースダウンロード
		$fileName = dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "{$_SESSION["User.role"]}.sqlite3";
		$_SESSION["SQLite.update"] = filemtime($fileName);
		$v = new FileView($fileName, "application/vnd.sqlite3");
		return $v;
	}
}