<?php
function smarty_block_predefine($params, $content, Smarty_Internal_Template $template, &$repeat){
	if(is_null($content)){
		if(array_key_exists("assign", $params)){
			if(is_scalar($params["assign"])){
				$template->assign($params["assign"], new \App\Smarty\PredefExpression("values[0]"));
			}else{
				$i = 0;
				foreach($params["assign"] as $assign){
					$template->assign($assign, new \App\Smarty\PredefExpression("values[{$i}]"));
					$i++;
				}
			}
		}
		if(array_key_exists("constructor", $params)){
			if(is_scalar($params["constructor"])){
				$template->assign($params["constructor"], new \App\Smarty\PredefExpression("this.#values[0]"));
			}else{
				$i = 0;
				foreach($params["constructor"] as $assign){
					$template->assign($assign, new \App\Smarty\PredefExpression("this.#values[{$i}]"));
					$i++;
				}
			}
		}
	}else{
		\App\Smarty\PredefExpression::$classes[$params["name"]] = preg_replace("/(?:^|(?<=\\>))[\\s\\n]+|[\\s\\n]+(?:(?=\\<)|\$)/m", "", $content);
	}
	return "";
}