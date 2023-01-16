<?php
function smarty_function_url($params, $template){
	$controller = trim(str_replace("\\", "/",
		array_key_exists("controller", $params) && ($params["controller"] != "*") ? $params["controller"] : $template->smarty->requestContext->controller
	), "/");
	$action = array_key_exists("action", $params) && ($params["action"] != "*") ? $params["action"] : $template->smarty->requestContext->action;
	$id = "";
	$query = array_key_exists("query", $params) && is_array($params["query"]) ? "?" .http_build_query($params["query"]) : "";
	$fragment = array_key_exists("fragment", $params) && ($params["fragment"] != "") ? "#{$params['fragment']}" : "";
	if(array_key_exists("id", $params)){
		if($params["id"] == "*"){
			if(!is_null($template->smarty->requestContext->id)){
				$id = "/{$template->smarty->requestContext->id}";
			}
		}else{
			$id = "/{$params['id']}";
		}
	}
	if($id == "" && $action == "index"){
		$action = "";
	}else{
		$action = "/{$action}";
	}
	
	$url = "/{$controller}{$action}{$id}{$query}{$fragment}";
	return array_key_exists("plain", $params) ? $url : htmlspecialchars($url);
}