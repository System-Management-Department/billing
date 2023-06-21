<?php
function smarty_function_predef_call($params, $template){
	$args = "";
	if(array_key_exists("param", $params)){
		if(is_scalar($params["param"])){
			$args = ($params["param"] instanceof \App\Smarty\PredefExpression) ? $params["param"]->getCode() : $params["param"];
		}else{
			$argList = [];
			foreach($params["param"] as $arg){
				$argList[] = ($arg instanceof \App\Smarty\PredefExpression) ? $arg->getCode() : $arg;
			}
			$args = implode(",", $argList);
		}
	}
	return "\${{[Template.#expression]: this.{$params['name']}({$args})}}";
}