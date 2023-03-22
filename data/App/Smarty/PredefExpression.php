<?php
namespace App\Smarty;

class PredefExpression implements \ArrayAccess{
	public static $classes = [];
	public $code;
	public function __construct($code){
		$this->code = $code;
	}
	public function __toString(){
		return sprintf('${%s}', $this->code);
	}
	public function getCode(){
		return $this->code;
	}
	public function setInvoke(...$offset){
		return new TemplateMethod($this->code, $offset);
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
		return new TemplateMethod($this->code, $offset);
	}
}

class TemplateMethod extends PredefExpression implements \ArrayAccess{
	public function __construct($code, $offset){
		parent::__construct($code);
		is_array($offset) ? $this->setInvoke(...$offset) : $this[$offset];
	}
	public function setInvoke(...$offset){
		$args = [];
		foreach($offset as $arg){
			if($arg instanceof PredefExpression){
				$args[] = $arg->getCode();
			}else{
				$args[] = json_encode($arg);
			}
		}
		$this->code .= sprintf("(%s)", implode(",", $args));
		return $this;
	}
	#[\ReturnTypeWillChange]
	public function offsetGet($offset){
		if($offset instanceof PredefExpression){
			$this->code .= "[{$offset->getCode()}]";
		}else if(is_numeric($offset)){
			$this->code .= "[{$offset}]";
		}else if(preg_match("/^[\\\$_a-zA-Z][\\\$_a-zA-Z0-9]*\$/", $offset)){
			$this->code .= ".{$offset}";
		}else{
			$this->code .= "[\"{$offset}\"]";
		}
		return $this;
	}
}