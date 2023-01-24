<?php
namespace App;
use mysqli;

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
class MySQL{
	private $mysqli;
	public function __construct($role = "default"){
		$this->mysqli = new mysqli(...\Config\MySqlConnection::$role());
	}
	public function __destruct(){
		$this->mysqli->close();
	}
	public function select($fetchMode = "ALL"){
		return new MySQLSelectQuery($this->mysqli, $fetchMode);
	}
	public function insertSet($table, $assoc, $placeholder){
		return new MySQLInsertSetQuery($this->mysqli, $table, $assoc, $placeholder);
	}
	public function insertSelect($table, $columns){
		return new MySQLInsertSelectQuery($this->mysqli, $table, $columns);
	}
	public function updateSet($table, $assoc, $placeholder){
		return new MySQLUpdateSetQuery($this->mysqli, $table, $assoc, $placeholder);
	}
	public function delete($table){
		return new MySQLDeleteQuery($this->mysqli, $table);
	}
	public function getJsonTableColumns($table, ...$fields){
		$result = $this->mysqli->query("SHOW FULL COLUMNS FROM `{$table}`");
		$res = [];
		$i = 0;
		while($column = $result->fetch_array(MYSQLI_ASSOC)){
			if(!empty($fields) && !in_array($column["Field"], $fields)){
				continue;
			}
			if(is_null($column["Collation"])){
				$res[] = "`{$column["Field"]}` {$column["Type"]} PATH '\$[{$i}]'";
			}else{
				$res[] = "`{$column["Field"]}` {$column["Type"]} COLLATE {$column["Collation"]} PATH '\$[{$i}]'";
			}
			$i++;
		}
		return "COLUMNS(" . implode(",", $res) . ")";
	}
	public function getTable2JsonField($table, $alias, $fieldAlias){
		$tableName = "";
		$tablePrefix = "";
		if(is_scalar($table)){
			$tableName = $table;
			$tablePrefix = "`{$table}`.";
		}else if(is_null($table[1])){
			$tableName = $table[0];
		}else{
			$tableName = $table[0];
			$tablePrefix = "`{$table[1]}`.";
		}
		$result = $this->mysqli->query("SHOW FULL COLUMNS FROM `{$tableName}`");
		$keys = [];
		$res = [];
		while($column = $result->fetch_array(MYSQLI_ASSOC)){
			$key = $column["Field"];
			if(array_key_exists($column["Field"], $fieldAlias)){
				if(is_null($fieldAlias[$column["Field"]])){
					continue;
				}else{
					$key = $fieldAlias[$column["Field"]];
				}
			}
			$keys[] = $key;
			$res[] = "?,{$tablePrefix}`{$column["Field"]}`";
		}
		return ["JSON_OBJECT(" . implode(",", $res) . ") AS `{$alias}`", $keys];
	}
	
	public function beginTransaction(){
		$this->mysqli->begin_transaction();
	}
	public function commit(){
		$this->mysqli->commit();
	}
	public function rollback(){
		$this->mysqli->rollback();
	}
}

class MySQLSelectQuery{
	protected $mysqli;
	private $prepare;
	private $bindParam;
	private $fetchMode;
	private const WITH = 0;
	private const SELECT = 1;
	private const TABLE = 2;
	private const WHERE = 3;
	private const GROUP_BY = 4;
	private const HAVING = 5;
	private const ORDER_BY = 6;
	private const LIMIT = 7;
	private const OFFSET = 8;
	
	private const FETCH_ALL = 0; // すべての行を連想配列の配列で取得
	private const FETCH_ASSOC = 1; // 1列目をキーとした連想配列で取得
	private const FETCH_COL = 2; // 最初の1列のみ配列で取得
	private const FETCH_ONE = 3; // 最初の1行1列のみスカラーで取得
	private const FETCH_ROW = 4; // 最初の1行のみ連想配列で取得
	
	public function __construct($mysqli, $fetchMode){
		$this->mysqli = $mysqli;
		$this->prepare = [null, null, null, null, null, null, null, null, null];
		$this->bindParam = [[], [], [], [], [], [], [], [], []];
		
		$fetchMode2 = strtoupper($fetchMode);
		$this->fetchMode = match(true){
			($fetchMode2 == "ROW") => self::FETCH_ROW,
			($fetchMode2 == "ONE") => self::FETCH_ONE,
			($fetchMode2 == "COL") => self::FETCH_COL,
			($fetchMode2 == "ASSOC") => self::FETCH_ASSOC,
			default => self::FETCH_ALL,
		};
		if(($this->fetchMode == self::FETCH_ROW) || ($this->fetchMode == self::FETCH_ONE)){
			$this->prepare[self::LIMIT] = 1;
		}
	}
	public function __invoke(){
		$q = $this->buildQuery();
		$stmt = $this->mysqli->prepare($q["prepare"]);
		$bindVars = [&$types];
		$types = "";
		foreach($q["bind"] as &$bind){
			$types .= $bind["type"];
			$bindVars[] = &$bind["value"];
		}
		if($types != ""){
			$stmt->bind_param(...$bindVars);
		}
		$stmt->execute();
		$result = $stmt->get_result();
		
		if($this->fetchMode == self::FETCH_ASSOC){
			$res = [];
			$currentfield = 0;
			for($i = $result->num_rows - 1; $i >= 0; $i--){
				$k = $result->fetch_column(0);
				$result->data_seek($currentfield);
				$res[$k] = $result->fetch_assoc();
				$currentfield++;
			}
			return $res;
		}else if($this->fetchMode == self::FETCH_COL){
			$res = [];
			for($i = $result->num_rows - 1; $i >= 0; $i--){
				$res[] = $result->fetch_column(0);
			}
			return $res;
		}else if($this->fetchMode == self::FETCH_ONE){
			return $result->fetch_column(0);
		}else if($this->fetchMode == self::FETCH_ROW){
			return $result->fetch_assoc();
		}else{
			return $result->fetch_all(MYSQLI_ASSOC);
		}
	}
	public function setWith($table, ...$bind){
		$this->prepare[self::WITH] = $table;
		$this->bindParam[self::WITH] = $bind;
		return $this;
	}
	public function setField($field, ...$bind){
		$this->prepare[self::SELECT] = $field;
		$this->bindParam[self::SELECT] = $bind;
		return $this;
	}
	public function setTable($table, ...$bind){
		$this->prepare[self::TABLE] = $table;
		$this->bindParam[self::TABLE] = $bind;
		return $this;
	}
	public function setWhere($where, ...$bind){
		$this->prepare[self::WHERE] = $where;
		$this->bindParam[self::WHERE] = $bind;
		return $this;
	}
	public function setGroupBy($field, ...$bind){
		$this->prepare[self::GROUP_BY] = $field;
		$this->bindParam[self::GROUP_BY] = $bind;
		return $this;
	}
	public function setHaving($where, ...$bind){
		$this->prepare[self::HAVING] = $where;
		$this->bindParam[self::HAVING] = $bind;
		return $this;
	}
	public function setOrderBy($field, ...$bind){
		$this->prepare[self::ORDER_BY] = $field;
		$this->bindParam[self::ORDER_BY] = $bind;
		return $this;
	}
	public function setLimit($limit, ...$bind){
		$this->prepare[self::LIMIT] = $limit;
		$this->bindParam[self::LIMIT] = $bind;
		return $this;
	}
	public function setOffset($offset, ...$bind){
		$this->prepare[self::OFFSET] = $offset;
		$this->bindParam[self::OFFSET] = $bind;
		return $this;
	}
	
	
	public function addWith($table, ...$bind){
		if(is_null($this->prepare[self::WITH])){
			$this->prepare[self::WITH] = $table;
			$this->bindParam[self::WITH] = $bind;
		}else{
			$this->prepare[self::WITH] .= "," . $table;
			$this->bindParam[self::WITH] = array_merge($this->bindParam[self::WITH], $bind);
		}
		return $this;
	}
	public function addField($field, ...$bind){
		if(is_null($this->prepare[self::SELECT])){
			$this->prepare[self::SELECT] = $field;
			$this->bindParam[self::SELECT] = $bind;
		}else{
			$this->prepare[self::SELECT] .= "," . $field;
			$this->bindParam[self::SELECT] = array_merge($this->bindParam[self::SELECT], $bind);
		}
		return $this;
	}
	public function addTable($table, ...$bind){
		if(is_null($this->prepare[self::TABLE])){
			$this->prepare[self::TABLE] = $table;
			$this->bindParam[self::TABLE] = $bind;
		}else{
			$this->prepare[self::TABLE] .= "," . $table;
			$this->bindParam[self::TABLE] = array_merge($this->bindParam[self::TABLE], $bind);
		}
		return $this;
	}
	public function leftJoin($table, ...$bind){
		if(is_null($this->prepare[self::TABLE])){
			$this->prepare[self::TABLE] = $table;
			$this->bindParam[self::TABLE] = $bind;
		}else{
			$this->prepare[self::TABLE] .= " LEFT JOIN " . $table;
			$this->bindParam[self::TABLE] = array_merge($this->bindParam[self::TABLE], $bind);
		}
		return $this;
	}
	public function rightJoin($table, ...$bind){
		if(is_null($this->prepare[self::TABLE])){
			$this->prepare[self::TABLE] = $table;
			$this->bindParam[self::TABLE] = $bind;
		}else{
			$this->prepare[self::TABLE] .= " RIGHT JOIN " . $table;
			$this->bindParam[self::TABLE] = array_merge($this->bindParam[self::TABLE], $bind);
		}
		return $this;
	}
	public function innerJoin($table, ...$bind){
		if(is_null($this->prepare[self::TABLE])){
			$this->prepare[self::TABLE] = $table;
			$this->bindParam[self::TABLE] = $bind;
		}else{
			$this->prepare[self::TABLE] .= " INNER JOIN " . $table;
			$this->bindParam[self::TABLE] = array_merge($this->bindParam[self::TABLE], $bind);
		}
		return $this;
	}
	public function andWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " AND " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	public function orWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " OR " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	
	protected function buildQuery(){
		$prepare = "";
		$bind = [];
		if(!is_null($this->prepare[self::WITH])){
			$prepare .= "WITH " . trim($this->prepare[self::WITH]) . " ";
			$this->mergeBindParam($bind, self::WITH);
		}
		$prepare .= "SELECT ";
		if(is_null($this->prepare[self::SELECT])){
			$prepare .= "*";
		}else{
			$prepare .= trim($this->prepare[self::SELECT]);
			$this->mergeBindParam($bind, self::SELECT);
		}
		if(!is_null($this->prepare[self::TABLE])){
			$prepare .= " FROM " . trim($this->prepare[self::TABLE]);
			$this->mergeBindParam($bind, self::TABLE);
		}
		if(!is_null($this->prepare[self::WHERE])){
			$prepare .= " WHERE " . trim($this->prepare[self::WHERE]);
			$this->mergeBindParam($bind, self::WHERE);
		}
		if(!is_null($this->prepare[self::GROUP_BY])){
			$prepare .= " GROUP BY " . trim($this->prepare[self::GROUP_BY]);
			$this->mergeBindParam($bind, self::GROUP_BY);
		}
		if(!is_null($this->prepare[self::HAVING])){
			$prepare .= " HAVING " . trim($this->prepare[self::HAVING]);
			$this->mergeBindParam($bind, self::HAVING);
		}
		if(!is_null($this->prepare[self::ORDER_BY])){
			$prepare .= " ORDER BY " . trim($this->prepare[self::ORDER_BY]);
			$this->mergeBindParam($bind, self::ORDER_BY);
		}
		if(!is_null($this->prepare[self::LIMIT])){
			$prepare .= " LIMIT " . trim($this->prepare[self::LIMIT]);
			$this->mergeBindParam($bind, self::LIMIT);
		}
		if(!is_null($this->prepare[self::OFFSET])){
			$prepare .= " OFFSET " . trim($this->prepare[self::OFFSET]);
			$this->mergeBindParam($bind, self::OFFSET);
		}
		
		return ["prepare" => $prepare, "bind" => $bind];
	}
	private function mergeBindParam(&$bind, $index){
		foreach($this->bindParam[$index] as $tempVal){
			$type = "s";
			$value = $tempVal;
			if(is_int($value)){
				$type = "i";
			}else if(is_float($value)){
				$type = "d";
			}else if($value instanceof \DateTimeInterface){
				$value = $tempVal->format("Y-m-d H:i:s");
			}
			$bind[] = ["type" => $type, "value" => $value];
		}
	}
}

class MySQLInsertSetQuery{
	private $mysqli;
	private $table;
	private $assoc;
	private $placeholder;
	public function __construct($mysqli, $table, $assoc, $placeholder){
		$this->mysqli = $mysqli;
		$this->table = $table;
		$this->assoc = $assoc;
		$this->placeholder = $placeholder;
	}
	
	public function __invoke(&$id = null){
		$query = sprintf("INSERT INTO `%s` SET ", $this->table );
		$columns = [];
		$bindVars = [&$types];
		$types = "";
		foreach($this->assoc as $k => $v){
			$columns[] = sprintf("`%s`=%s", $k, array_key_exists($k, $this->placeholder) ? $this->placeholder[$k] : "?");
			$type = "s";
			$value = $v;
			if(is_int($value)){
				$type = "i";
			}else if(is_float($value)){
				$type = "d";
			}else if($value instanceof \DateTimeInterface){
				$value = $v->format("Y-m-d H:i:s");
			}
			$types .= $type;
			$bindVars[] = $v;
		}
		foreach($this->placeholder as $k => $v){
			if(array_key_exists($k, $this->assoc)){
				continue;
			}
			$columns[] = sprintf("`%s`=%s", $k, $v);
		}
		$query .= implode(", ", $columns);
		$stmt = $this->mysqli->prepare($query);
		if($types != ""){
			$stmt->bind_param(...$bindVars);
		}
		$stmt->execute();
		if(func_num_args() > 0){
			$id = $stmt->insert_id;
		}
	}
}

class MySQLInsertSelectQuery extends MySQLSelectQuery{
	private $table;
	private $columns;
	public function __construct($mysqli, $table, $columns){
		parent::__construct($mysqli, "ALL");
		$this->table = $table;
		$this->columns = $columns;
	}
	
	public function __invoke(&$id = null){
		$query = ($this->columns == "*") ? sprintf("INSERT INTO `%s` ", $this->table) : sprintf("INSERT INTO `%s`(%s) ", $this->table, $this->columns);
		$q = $this->buildQuery();
		$stmt = $this->mysqli->prepare($query . $q["prepare"]);
		$bindVars = [&$types];
		$types = "";
		foreach($q["bind"] as &$bind){
			$types .= $bind["type"];
			$bindVars[] = &$bind["value"];
		}
		if($types != ""){
			$stmt->bind_param(...$bindVars);
		}
		$stmt->execute();
	}
}

class MySQLUpdateSetQuery{
	private $mysqli;
	private $table;
	private $assoc;
	private $placeholder;
	private $prepare;
	private $bindParam;
	
	private const WHERE = 0;
	public function __construct($mysqli, $table, $assoc, $placeholder){
		$this->mysqli = $mysqli;
		$this->table = $table;
		$this->assoc = $assoc;
		$this->placeholder = $placeholder;
		$this->prepare = [null];
		$this->bindParam = [[]];
	}
	
	public function __invoke(){
		$query = sprintf("UPDATE `%s` SET ", $this->table);
		$columns = [];
		$bindVars = [&$types];
		$types = "";
		foreach($this->assoc as $k => $v){
			$columns[] = sprintf("`%s`=%s", $k, array_key_exists($k, $this->placeholder) ? $this->placeholder[$k] : "?");
			$type = "s";
			$value = $v;
			if(is_int($value)){
				$type = "i";
			}else if(is_float($value)){
				$type = "d";
			}else if($value instanceof \DateTimeInterface){
				$value = $v->format("Y-m-d H:i:s");
			}
			$types .= $type;
			$bindVars[] = $v;
		}
		foreach($this->placeholder as $k => $v){
			if(array_key_exists($k, $this->assoc)){
				continue;
			}
			$columns[] = sprintf("`%s`=%s", $k, $v);
		}
		$query .= implode(", ", $columns);
		$q = $this->buildQuery();
		$query .= $q["prepare"];
		foreach($q["bind"] as &$bind){
			$types .= $bind["type"];
			$bindVars[] = &$bind["value"];
		}
		$stmt = $this->mysqli->prepare($query);
		if($types != ""){
			$stmt->bind_param(...$bindVars);
		}
		$stmt->execute();
	}
	
	public function setWhere($where, ...$bind){
		$this->prepare[self::WHERE] = $where;
		$this->bindParam[self::WHERE] = $bind;
		return $this;
	}
	public function andWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " AND " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	public function orWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " OR " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	
	protected function buildQuery(){
		$prepare = "";
		$bind = [];
		if(!is_null($this->prepare[self::WHERE])){
			$prepare .= " WHERE " . trim($this->prepare[self::WHERE]);
			$this->mergeBindParam($bind, self::WHERE);
		}
		
		return ["prepare" => $prepare, "bind" => $bind];
	}
	private function mergeBindParam(&$bind, $index){
		foreach($this->bindParam[$index] as $tempVal){
			$type = "s";
			$value = $tempVal;
			if(is_int($value)){
				$type = "i";
			}else if(is_float($value)){
				$type = "d";
			}else if($value instanceof \DateTimeInterface){
				$value = $tempVal->format("Y-m-d H:i:s");
			}
			$bind[] = ["type" => $type, "value" => $value];
		}
	}
}

class MySQLDeleteQuery{
	private $mysqli;
	private $table;
	private $prepare;
	private $bindParam;
	
	private const WHERE = 0;
	public function __construct($mysqli, $table){
		$this->mysqli = $mysqli;
		$this->table = $table;
		$this->prepare = [null];
		$this->bindParam = [[]];
	}
	
	public function __invoke(){
		$query = sprintf("DELETE FROM `%s`", $this->table);
		$bindVars = [&$types];
		$types = "";
		$q = $this->buildQuery();
		$query .= $q["prepare"];
		foreach($q["bind"] as &$bind){
			$types .= $bind["type"];
			$bindVars[] = &$bind["value"];
		}
		$stmt = $this->mysqli->prepare($query);
		if($types != ""){
			$stmt->bind_param(...$bindVars);
		}
		$stmt->execute();
	}
	
	public function setWhere($where, ...$bind){
		$this->prepare[self::WHERE] = $where;
		$this->bindParam[self::WHERE] = $bind;
		return $this;
	}
	public function andWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " AND " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	public function orWhere($where, ...$bind){
		if(is_null($this->prepare[self::WHERE])){
			$this->prepare[self::WHERE] = $where;
			$this->bindParam[self::WHERE] = $bind;
		}else{
			$this->prepare[self::WHERE] .= " OR " . $where;
			$this->bindParam[self::WHERE] = array_merge($this->bindParam[self::WHERE], $bind);
		}
		return $this;
	}
	
	protected function buildQuery(){
		$prepare = "";
		$bind = [];
		if(!is_null($this->prepare[self::WHERE])){
			$prepare .= " WHERE " . trim($this->prepare[self::WHERE]);
			$this->mergeBindParam($bind, self::WHERE);
		}
		
		return ["prepare" => $prepare, "bind" => $bind];
	}
	private function mergeBindParam(&$bind, $index){
		foreach($this->bindParam[$index] as $tempVal){
			$type = "s";
			$value = $tempVal;
			if(is_int($value)){
				$type = "i";
			}else if(is_float($value)){
				$type = "d";
			}else if($value instanceof \DateTimeInterface){
				$value = $tempVal->format("Y-m-d H:i:s");
			}
			$bind[] = ["type" => $type, "value" => $value];
		}
	}
}