<?php
namespace App\Smarty;

class TemplateObject implements \ArrayAccess{
	public $keys;
	public $iterators;
	public $idx;
	public function __construct($iterators, $idx, $offset = null){
		$this->keys = [];
		$this->iterators = $iterators;
		$this->idx = $idx;
		if(!is_null($offset)){
			$this->keys[] = $offset;
		}
	}
	public function __toString(){
		$suf = "";
		foreach($this->keys as $key){
			if(in_array($key, $this->iterators)){
				$suf .= "[{$key}]";
			}else{
				$suf .= is_numeric($key) ? "[{$key}]" : "[\"{$key}\"]";
			}
		}
		return "\${values[{$this->idx}]{$suf}}";
	}
	public function getCode(){
		$suf = "";
		foreach($this->keys as $key){
			if(in_array($key, $this->iterators)){
				$suf .= "[{$key}]";
			}else{
				$suf .= is_numeric($key) ? "[{$key}]" : "[\"{$key}\"]";
			}
		}
		return "values[{$this->idx}]{$suf}";
	}
	#[\ReturnTypeWillChange]
	public function offsetSet($offset, $value){}
	#[\ReturnTypeWillChange]
	public function offsetExists($offset) {
		return true;
	}
	#[\ReturnTypeWillChange]
	public function offsetUnset($offset){}
	#[\ReturnTypeWillChange]
	public function offsetGet($offset){
		if(count($this->keys) < 1){
			return new static($this->iterators, $this->idx, $offset);
		}
		$this->keys[] = $offset;
		return $this;
	}
	public function beginRepeat($n, $i = null){
		if($n instanceof self){
			$suf = "";
			foreach($n->keys as $key){
				if(in_array($key, $n->iterators)){
					$suf .= "[{$key}]";
				}else{
					$suf .= is_numeric($key) ? "[{$key}]" : "[\"{$key}\"]";
				}
			}
			$n->keys = [];
			$n = "values[{$n->idx}]{$suf}";
		}
		if(is_null($i)){
			return "\${{[this.symbol]: new Array({$n}).fill(null).map(() => this.html`";
		}
		return "\${{[this.symbol]: new Array({$n}).fill(null).map((_, {$i}) => this.html`";
	}
	public function endRepeat(){
		return "`).join(\"\")}}";
	}
}