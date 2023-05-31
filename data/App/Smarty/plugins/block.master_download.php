<?php
function smarty_block_master_download($params, $content, &$smarty, &$repeat){
	if(!$repeat){
		$fileName = dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3";
		if(
			empty($_SESSION["SQLite.masterUpdate"]) ||
			(!file_exists($fileName)) ||
			$_SESSION["SQLite.masterUpdate"] < filemtime($fileName)
		){
			return "{$content}\n";
		}else{
			return "if({$params["test"]}){ {$content} }\n";
		}
	}
}