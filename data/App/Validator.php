<?php
namespace App;
use ArrayAccess;
use Model\Result;

class Validator implements ArrayAccess{
	private $container;
	private $alias;
	public function __construct(){
		$this->container = [];
		$this->alias = [];
	}
	
	/**
		入力値を検証
	*/
	public function __invoke($a1, $a2 = null){
		if($a1 instanceof Result){
			// Resultへ追加する場合
			$result = &$a1;
			$assoc = &$a2;
		}else{
			// Resultのインスタンスを新しく生成する場合
			$result = new Result();
			$assoc = &$a1;
		}
		foreach($this->container as $k => $v){
			$name = array_key_exists($k, $this->alias) ? $this->alias[$k] : $k;
			$v($result, array_key_exists($k, $assoc) ? $assoc[$k] : null, $name);
		}
		return $result;
	}
	
	#[\ReturnTypeWillChange]
	public function offsetSet($offset, $value){
	}
	
	#[\ReturnTypeWillChange]
	public function offsetExists($offset){
		return isset($this->container[$offset]);
	}
	
	#[\ReturnTypeWillChange]
	public function offsetUnset($offset){
		unset($this->container[$offset]);
	}
	
	#[\ReturnTypeWillChange]
	public function offsetGet($offset){
		$tokens = explode(":", $offset);
		$offset2 = $tokens[0];
		if(count($tokens) > 1){
			$this->alias[$offset2] = $tokens[1];
		}
		if(!array_key_exists($offset2, $this->container)){
			$this->container[$offset2] = new ValidationItem();
		}
		return $this->container[$offset2];
	}
	
	/**
		配列検証
	*/
	public function setArray($offset, $options){
		$tokens = explode(":", $offset);
		$offset2 = $tokens[0];
		if(count($tokens) > 1){
			$this->alias[$offset2] = $tokens[1];
		}
		$this->container[$offset2] = new ValidationArray($options);
	}
}

class ValidationItem{
	protected $emptyMessage;
	protected $pattern;
	protected $ranges;
	protected $length;
	protected $type;
	
	public function __construct(){
		$this->emptyMessage = null;
		$this->pattern = null;
		$this->ranges = [];
		$this->length = null;
		$this->type = null;
	}
	
	/**
		検証
	*/
	public function __invoke($result, $value, $name = ""){
		if(is_null($this->emptyMessage)){
			if(is_null($value) || $value == ""){
				return;
			}
		}else{
			// required
			if(is_null($value) || $value == ""){
				$result->addMessage($this->emptyMessage, "ERROR", $name);
				return;
			}
		}
		foreach($this->ranges as $k => $v){
			$isIn = true;
			if(is_null($v["in"])){
				// 区間
				if(!is_null($v["gt"])){
					$isIn = $isIn && ($value > $v["gt"]);
				}
				if(!is_null($v["ge"])){
					$isIn = $isIn && ($value >= $v["ge"]);
				}
				if(!is_null($v["lt"])){
					$isIn = $isIn && ($value < $v["lt"]);
				}
				if(!is_null($v["le"])){
					$isIn = $isIn && ($value <= $v["le"]);
				}
			}else{
				// 集合
				$isIn = in_array($value, $v["in"]);
			}
			if($v["not"]){
				if($isIn){
					$result->addMessage($v["message"], "ERROR", $name);
					break;
				}
			}else{
				if(!$isIn){
					$result->addMessage($v["message"], "ERROR", $name);
					break;
				}
			}
		}
		if(!is_null($this->length)){
			// 文字数
			$isIn = true;
			$len = strlen($value);
			if(!is_null($this->length["min"])){
				$isIn = $isIn && ($len >= $this->length["min"]);
			}
			if(!is_null($this->length["max"])){
				$isIn = $isIn && ($len <= $this->length["max"]);
			}
			if(!$isIn){
				$result->addMessage($this->length["message"], "ERROR", $name);
				return;
			}
		}
		if(is_null($this->type)){
		}else if($this->type["pattern"] == "password"){
			// 連続する文字のチェック
			$len = strlen($value);
			if($len < 2){
				$result->addMessage($this->type["message"], "ERROR", $name);
				return;
			}
			$alert = true;
			$prev = ord(substr($value, 1));
			$step = ord(substr($value, 0)) - $prev;
			for($pos = 2; $pos < $len; $pos++){
				$ch = ord(substr($value, $pos));
				if($prev - $ch == $step){
					$prev = $ch;
				}else{
					$alert = false;
				}
			}
			if($alert){
				$result->addMessage($this->type["message"], "ERROR", $name);
				return;
			}else if(!preg_match("/^[A-Za-z0-9]+\$/", $value)){
				$result->addMessage($this->type["message"], "ERROR", $name);
				return;
			}
		}else{
			// 形式
			$isMatch = match($this->type["pattern"]){
				"mail" => preg_match("/^[a-z0-9._+^~-]+@[a-z0-9.-]+\$/i", $value),
				"tel" => preg_match("/^0[0-9]{1,4}-[0-9]{1,4}-[0-9]{3,4}\$/", $value),
				"zip" => preg_match("/^[0-9]{3}-[0-9]{4}\$/", $value),
				default => false
			};
			if(!$isMatch){
				$result->addMessage($this->type["message"], "ERROR", $name);
				return;
			}
		}
	}
	
	/**
		必須
	*/
	public function required($message){
		$this->emptyMessage = $message;
		return $this;
	}
	
	/**
		有効範囲
		range("{0,1,2,5}に含まれる", "in", [0, 1, 2, 5])
		range("{0,1,2,5}に含まれない", "not in", [0, 1, 2, 5])
		range("0を超える10未満", "(a,b)", ["a" => 0, "b" => 10])
		range("0以上10以下", "[a,b]", ["a" => 0, "b" => 10])
	*/
	public function range($message, $rangeStr, $rangeParams){
		preg_match('/^(?:\\s*(?<not>not))?\\s*(?:(?<in>in)|(?<min>[\\(\\[])\\s*(?<v1>[a-zA-Z][a-zA-Z0-9]*)\\s*,\\s*(?<v2>[a-zA-Z][a-zA-Z0-9]*)\\s*(?<max>[\\)\\]]))\\s*$/', $rangeStr, $matches, PREG_UNMATCHED_AS_NULL);
		if(!empty($matches)){
			$rangeItem = [
				"message" => $message,
				"not" => !is_null($matches["not"]),
				"gt" => null,
				"ge" => null,
				"lt" => null,
				"le" => null,
				"in" => null,
			];
			if(is_null($matches["in"])){
				$k = ($matches["min"] == "(") ? "gt" : "ge";
				$rangeItem[$k] = array_key_exists($matches["v1"], $rangeParams) ? $rangeParams[$matches["v1"]] : null;
				$k = ($matches["max"] == ")") ? "lt" : "le";
				$rangeItem[$k] = array_key_exists($matches["v2"], $rangeParams) ? $rangeParams[$matches["v2"]] : null;
			}else{
				$rangeItem["in"] = $rangeParams;
			}
			$this->ranges[] = $rangeItem;
		}
		return $this;
	}
	
	/**
		文字数
	*/
	public function length($message, $min = null, $max = null){
		$this->length = [
			"message" => $message,
			"min" => $min,
			"max" => $max,
		];
		return $this;
	}
	
	/**
		メールアドレス
	*/
	public function mail($message){
		$this->type = [
			"message" => $message,
			"pattern" => "mail",
		];
		return $this;
	}
	
	/**
		電話番号
	*/
	public function tel($message){
		$this->type = [
			"message" => $message,
			"pattern" => "tel",
		];
		return $this;
	}
	
	/**
		郵便番号
	*/
	public function zip($message){
		$this->type = [
			"message" => $message,
			"pattern" => "zip",
		];
		return $this;
	}
	
	/**
		パスワード
	*/
	public function password($message){
		$this->type = [
			"message" => $message,
			"pattern" => "password",
		];
		return $this;
	}
}

class ValidationArray extends ValidationItem{
	private $options;
	public function __construct($options){
		parent::__construct();
		$this->options = $options;
	}
	public function __invoke($result, $value, $name = ""){
		// 配列の各要素を検証
		$itemCnt = 0;
		if(is_null($value) || !is_array($value)){
			$value = [];
		}
		$alias = array_key_exists("alias", $this->options) ? $this->options["alias"] : [];
		if(!is_null($this->emptyMessage) && array_key_exists("format", $this->options)){
			$keys = array_keys($this->options["format"]);
			foreach($keys as $k){
				if(!array_key_exists($k, $value)){
					$value[$k] = null;
				}
			}
		}
		foreach($value as $k => $v){
			if(array_key_exists("blankFilter", $this->options) && $this->options["blankFilter"] && (is_null($v) || $v == "")){
				continue;
			}
			$resultItem = new Result();
			if(array_key_exists("format", $this->options)){
				$resultItem->onAddMessage([$this, "format"], $k);
			}
			parent::__invoke($resultItem, $v, array_key_exists($k, $alias) ? $alias[$k] : $name);
			if($resultItem->hasError()){
				$result->mergeMessage($resultItem);
				if(array_key_exists("some", $this->options) && $this->options["some"]){
					return;
				}
			}
			$itemCnt++;
		}
		if(($itemCnt == 0) && array_key_exists("empty", $this->options)){
			$result->addMessage($this->options["empty"], "ERROR", $name);
		}
	}
	
	public function format(&$message, &$status, &$name, $k){
		if(array_key_exists("format", $this->options) && array_key_exists($k, $this->options["format"])){
			$message = vsprintf($message, $this->options["format"][$k]);
		}
	}
}