<?php

function smarty_block_predef_repeat($params, $content, Smarty_Internal_Template $template, &$repeat){
	if(is_null($content)){
		$loop = ($params["loop"] instanceof \App\Smarty\PredefExpression) ? $params["loop"]->getCode() : $params["loop"];
		$args = "";
		if(array_key_exists("index", $params)){
			$expression = new \App\Smarty\PredefExpression($params["index"]);
			$template->assign($params["index"], $expression);
			$args = "_, {$expression->getCode()}";
		}
		return "\${{[Template.#expression]: new Array({$loop}).fill(null).map(({$args}) => Template.#html`";
	}
	return "{$content}`).join(\"\")}}";
}