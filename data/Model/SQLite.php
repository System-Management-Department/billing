<?php
namespace Model;

class SQLite{
	public $db;
	public static $tables = [
		"divisions"          => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"teams"              => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"managers"           => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"payment_categories" => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"summaries"          => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"clients"            => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"apply_clients"      => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		"categories"         => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
	];
	
	/**
	 * コンストラクタ テーブル出力用の関数を登録
	 */
	public function __construct(){
		$this->db = new \SQLite3(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3");
	}
	
	/**
	 * マスターの有効なデータをSQLiteにキャッシュ
	 */
	public function cache($db, $target){
		$builder = new SQLiteTableBuilder($this->db);
		if($target == "*"){
			foreach(SQLite::$tables as $table => $options){
				list($columns, $data) = $db->exportTable($table, $options["alias"], $options["where"]);
				$builder->createTable($table, $columns, $data);
			}
		}else if(array_key_exists($target, SQLite::$tables)){
			$table = $target;
			$options = SQLite::$tables[$table];
			list($columns, $data) = $db->exportTable($table, $options["alias"], $options["where"]);
			$builder->createTable($table, $columns, $data);
		}
	}
}
class SQLiteTableBuilder{
	private $db;
	private $data;
	private $tables;
	public function __construct($db){
		$this->db = $db;
		$this->data = null;
		$this->tables = [];
		$this->db->createFunction("reference", [$this, "reference"], 2);
		$results = $this->db->query("select name from sqlite_master where type='table'");
		while(list($table)= $results->fetchArray()){
			$this->tables[] = $table;
		}
	}
	public function createTable($table, $columns, $data){
		$this->data = $data;
		$ref = [];
		foreach($columns as $i => $field){
			$ref[] = sprintf("reference(i, :c%d) as `%s`", $i, $field);
		}
		if(in_array($table, $this->tables)){
			$this->db->exec("drop table `{$table}`");
		}
		$stmt = $this->db->prepare("create table `{$table}` as with recursive t as (select 0 as i UNION ALL select i+1 from t limit :limit) select " . implode(",", $ref) . " from t");
		$stmt->bindParam(":limit", count($data), SQLITE3_INTEGER);
		foreach($columns as $i => &$field){
			$stmt->bindParam(":c{$i}", $field, SQLITE3_TEXT);
		}
		$stmt->execute();
	}
	public function reference($i, $c){
		return $this->data[$i][$c];
	}
}