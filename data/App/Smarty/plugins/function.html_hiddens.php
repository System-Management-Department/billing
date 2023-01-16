<?php
function smarty_function_html_hiddens($params, $template){
	$data = "";
	foreach($params["data"] as $k => $v){
		smarty_recursion_html_hiddens($v, $data, htmlspecialchars($k));
	}
	return $data;
}
function smarty_recursion_html_hiddens(&$ref, &$data, $name){
	if(is_array($ref)){
		foreach($ref as $k => $v){
			$k2 = htmlspecialchars($k);
			smarty_recursion_html_hiddens($v, $data, "{$name}[{$k2}]");
		}
	}else{
		$v = htmlspecialchars($ref);
		$data .= "<input type=\"hidden\" name=\"{$name}\" value=\"{$v}\" />";
	}
}