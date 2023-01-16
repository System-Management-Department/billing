<?php
use Model\Error;

function smarty_function_javascript_notice($params, $template){
	if(empty(Error::$data)){
		return "";
	}
	return sprintf('<script type="text/javascript" async>(function(a){a.innerHTML="%s";console.table(JSON.parse(a.textContent));})(document.createElement("a"));</script>', htmlspecialchars(str_replace("\\", "\\\\", json_encode(Error::$data))));
}