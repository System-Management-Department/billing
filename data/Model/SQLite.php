<?php
namespace Model;

class SQLite{
	/**
	 * マスターの有効なデータをSQLiteにキャッシュ
	 */
	public static function cache($db, $target){
		static $tables = [
			"divisions"          => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"teams"              => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"managers"           => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"payment_categories" => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"summaries"          => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"clients"            => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"apply_clients"      => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
			"categories"         => ["alias" => ["created" => null, "modified" => null, "delete_flag" => null], "where" => "delete_flag=0"],
		];
		$sqlite = new \SQLite3(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3");
		$builder = new SQLiteTableBuilder($sqlite);
		if($target == "*"){
			foreach($tables as $table => $options){
				list($columns, $data) = $db->exportTable($table, $options["alias"], $options["where"]);
				$builder->createTable($table, $columns, $data);
			}
		}else if(array_key_exists($target, $tables)){
			$table = $target;
			$options = $tables[$table];
			list($columns, $data) = $db->exportTable($table, $options["alias"], $options["where"]);
			$builder->createTable($table, $columns, $data);
		}
	}
	
	public static function cachedData(){
		return new SQLiteCachedData();
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
class SQLiteCachedData{
	private $fileName;
	private $db;
	private $data;
	public function __construct(){
		$this->fileName = tempnam(sys_get_temp_dir(), "sqlite");
		copy(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3", $this->fileName);
		$this->db = $sqlite = new \SQLite3($this->fileName);
		$this->data = null;
		$this->db->createFunction("reference", [$this, "reference"], 2);
	}
	public function __destruct(){
		$this->db->close();
		unlink($this->fileName);
	}
	public function getFileName(){
		return $this->fileName;
	}
	public function getFilemtime(){
		return filemtime(dirname(DATA_DIR) . DIRECTORY_SEPARATOR . "cache" . DIRECTORY_SEPARATOR . "sqlite" . DIRECTORY_SEPARATOR . "master.sqlite3");
	}
	public function createTable($table, $columns, $data){
		$this->data = $data;
		$ref = [];
		foreach($columns as $i => $field){
			$ref[] = sprintf("reference(i, :c%d) as `%s`", $i, $field);
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