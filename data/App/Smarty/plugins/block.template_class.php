<?php
function smarty_block_template_class($params, $content, Smarty_Internal_Template $template, &$repeat){
	if(is_null($content)){
		$iterators = array_key_exists("iterators", $params) ? $params["iterators"] : [];
		if(is_scalar($params["assign"])){
			$template->assign($params["assign"], new \App\Smarty\TemplateObject($iterators, 0));
		}else{
			$i = 0;
			foreach($params["assign"] as $assign){
				$template->assign($assign, new \App\Smarty\TemplateObject($iterators, $i));
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