<?php
namespace Model;

class SQLite{
	public $db;
	public $tempData;
	public static $tables = [
		"divisions" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"teams" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"managers" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"payment_categories" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"summaries" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"clients" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"apply_clients" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
		"categories" => ["excludes" => ["created", "modified", "delete_flag"], "where" => "delete_flag=0"],
	];
	
	/**
	 * コンストラクタ テーブル出力用の関数を登録
	 */
	function __construct(){
		$this->db = new \SQLite3(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3");
		$this->db->createFunction("func", [$this, "func"]);
		$this->tempData = [];
	}
	
	/**
	 * マスターの有効なデータをSQLiteにキャッシュ
	 */
	public function cache($db, $target){
		if($target == "*"){
		}else if(array_key_exists($target, SQLite::$tables)){
			$table = $target;
			$options = SQLite::$tables[$table];
			$query = $db->select("ALL")->setTable($table)->setWhere($options["where"]);
			$fields = $db->getColumnNames($table);
			$exports = [];
			$funcs = [];
			foreach($fields as $field){
				if(in_array($field, $options["excludes"])){
					continue;
				}
				$query->addField("`{$field}`");
				$exports[] = $field;
				$funcs[] = sprintf("func(i, '%s') as `%s`", $field, $field);
			}
			$this->tempData = $query();
			$stmt = $this->db->prepare("create table `{$table}` as with recursive t as (select 0 as i UNION ALL select i+1 from t limit :limit) select " . implode(",", $funcs) . " from t");
			$stmt->bindParam(":limit", count($this->tempData), SQLITE3_INTEGER);
			foreach($exports as $i => $field){
				$stmt->bindParam(":c{$i}", $field, SQLITE3_TEXT);
			}
			$stmt->execute();
		}
	}
	public function func($i, $c){
		return $this->tempData[$i][$c];
	}
}