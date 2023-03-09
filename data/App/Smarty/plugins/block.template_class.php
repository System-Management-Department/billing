<?php
class SmartyBlockTemplateClassObject implements ArrayAccess{
	public $keys;
	public $iterators;
	public function __construct($iterators){
		$this->keys = [];
		$this->iterators = $iterators;
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
		return "\${values{$suf}}";
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
	public function beginRepeat($n, $i){
		if($n instanceof SmartyBlockTemplateClassObject){
			$suf = "";
			foreach($this->keys as $key){
				if(in_array($key, $this->iterators)){
					$suf .= "[{$key}]";
				}else{
					$suf .= is_numeric($key) ? "[{$key}]" : "[\"{$key}\"]";
				}
			}
			$this->keys = [];
			$n = "values{$suf}";
		}
		return "\${{[this.symbol]: new Array({$n}).fill(null).map((_, {$i}) => this.html`";
	}
	public function endRepeat(){
		return "`).join(\"\")}}";
	}
}

function smarty_block_template_class($params, $content, Smarty_Internal_Template $template, &$repeat){
	if(is_null($content)){
		$template->assign($params["assign"], new SmartyBlockTemplateClassObject($params["iterators"]));
		foreach($params["iterators"] as $iterator){
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
	insertBeforeEnd(element, values){
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