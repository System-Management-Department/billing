<?php
function smarty_block_db_download($params, $content, &$smarty, &$repeat){
	if(!$repeat){
		if(
			empty($_SESSION["SQLite.update"]) ||
			$_SESSION["SQLite.update"] < filemtime(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "{$_SESSION["User.role"]}.sqlite3")
		){
			return "{$content}\n";
		}else{
			return "if({$params["test"]}){ {$content} }\n";
		}
	}
}