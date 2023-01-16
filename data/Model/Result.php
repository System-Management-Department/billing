<?php
namespace Model;
use JsonSerializable;

class Result implements JsonSerializable{
	private $success;
	private $messages;
	private $data;
	private $callback;
	private $callbackArguments;
	
	public function __construct(){
		$this->success = true;
		$this->messages = [];
		$this->data = null;
		$this->callback = null;
		$this->callbackArguments = [];
	}
	
	public function setData($data){
		$this->data = $data;
		return $this;
	}
	
	public function addMessage($message, $type = "INFO", $name = ""){
		$type2 = strtoupper($type);
		$status = match(true){
			($type2 == "ERROR") => 2,
			($type2 == "WARN") => 1,
			default => 0,
		};
		if(!is_null($this->callback)){
			call_user_func_array($this->callback, [&$message, &$status, &$name, ...$this->callbackArguments]);
		}
		if(!is_null($message)){
			$this->messages[] = [$message, $status, $name];
		}
		if($status == 2){
			$this->success = false;
		}else if($status == 1 && $this->success !== false){
			$this->success = null;
		}
		return $this;
	}
	
	public function onAddMessage($callback, ...$args){
		$this->callback = $callback;
		$this->callbackArguments = $args;
	}
	
	public function mergeMessage($result){
		$this->messages = array_merge($this->messages, $result->messages);
		if($this->success === true){
			$this->success = $result->success;
		}else if($this->success !== false){
			if($result->success !== true){
				$this->success = $result->success;
			}
		}
	}
	
	public function hasError(){
		return $this->success === false;
	}
	
	#[\ReturnTypeWillChange]
	public function jsonSerialize(){
		$res = [
			"success" => $this->success,
			"messages" => $this->messages,
			"data" => $this->data
		];
		if(!empty(Error::$data)){
			$res["error"] = Error::$data;
		}
		return $res;
	}
}