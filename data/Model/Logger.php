<?php
namespace Model;
use DateTime;
use App\Validator;

class Logger{
	public static $limit = 40;
	public static function record($db, $control, $data){
		$insertQuery = $db->insertSet("logs", [
			"control" => $control,
			"data" => json_encode($data),
		],[
			"user" => "@user",
			"username" => "@username",
			"datetime" => "now()",
		]);
		$insertQuery();
	}
	public static function getSearchQuery($db, $q){
		$query = $db->select("ALL")
			->setLimit(self::$limit)
			->addTable("logs")
			->addField("logs.*")
			
			// 読込：IDを降順で取得
			->setOrderBy("logs.id desc");
		
		if(!empty($q["lastdata"])){
			// 途中から読込
			$query->andWhere("logs.id<?", $q["lastdata"]);
		}
		
		// 検索条件
		if(($q["date"] ?? "") != ""){
			// 日付
			$query->andWhere("cast(logs.datetime as date)=cast(? as date)", new DateTime($q["date"]));
		}else{
			$query->andWhere("cast(logs.datetime as date)=curdate()");
		}
		return $query;
	}
}