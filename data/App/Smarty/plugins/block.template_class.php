<?php
class SmartyBlockTemplateClassObject implements ArrayAccess{
	public $keys;
	public $iterators;
	public $idx;
	public function __construct($iterators, $idx){
		$this->keys = [];
		$this->iterators = $iterators;
		$this->idx = $idx;
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
		$this->keys = [];
		return "\${values[{$this->idx}]{$suf}}";
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

function smarty_block_template_class($params, $content, Smarty_Internal_Template $template, &$repeat){
	if(is_null($content)){
		$iterators = array_key_exists("iterators", $params) ? $params["iterators"] : [];
		if(is_scalar($params["assign"])){
			$template->assign($params["assign"], new SmartyBlockTemplateClassObject($iterators, 0));
		}else{
			$i = 0;
			foreach($params["assign"] as $assign){
				$template->assign($assign, new SmartyBlockTemplateClassObject($iterators, $i));
				$i++;
			}
		}
		foreach($iterators as $iterator){
			$template->assign($iterator, $iterator);
		}
		return;
	}
	return <<<HERE
class {$params["name"]}{
	constructor(){
		this.a = document.createElement("a");
		this.symbol = Symbol("raw");
	}
	insertBeforeEnd(element, ...values){
		element.insertAdjacentHTML("beforeend", this.html`{$content}`);
	}
	html(callSite, ...substitutions){
		let substitutions2 = [];
		for(let substitution of substitutions){
			if(substitution == null){
				substitutions2.push("");
			}else if((typeof substitution === "object") && (this.symbol in substitution)){
				substitutions2.push(substitution[this.symbol]);
			}else{
				substitutions2.push(Object.assign(this.a, {textContent: substitution}).innerHTML);
			}
		}
		return String.raw(callSite, ...substitutions2);
	}
}
HERE;
}