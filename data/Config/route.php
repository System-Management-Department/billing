<?php
namespace Config;

// リクエスト
$url = parse_url(urldecode($_SERVER['REQUEST_URI']));
$requestStr = ltrim($url["path"], "/");
$controller = "Default";
$action = "index";
$id = null;

// コントローラー
if($url != ""){
	$items = explode("/", $requestStr);
	$cnt = count($items);
	if($cnt > 0 && $items[0] != ""){
		$controller = $items[0];
	}
	if($cnt > 1 && $items[1] != ""){
		$action = $items[1];
	}
	if($cnt > 2){
		$id = implode("/", array_slice($items, 2));
	}
}

// コンテキスト
$requestContext = new \App\RequestContext();
$requestContext->controller = $controller;
$requestContext->action = $action;
$requestContext->id = $id;

// アクション
$controllerClassName = "\\Controller\\{$controller}Controller";
$controllerExists = class_exists($controllerClassName);
if(!$controllerExists){
	$controllerClassName = "\\Controller\\EmptyController";
}
$controllerInstance = new $controllerClassName($requestContext);
session_name("PHPSESSID2");
session_cache_expire(525600);
session_set_cookie_params(31536000, "/");
session_start();
$accept = null;
$ref = new \ReflectionClass($controllerInstance);
if($ref->hasMethod($action)){
	$ref = new \ReflectionMethod($controllerInstance, $action);
	foreach($ref->getAttributes() as $refAttr){
		$attr = $refAttr->newInstance();
		if($attr instanceof \Attribute\AcceptRole){
			$accept = $attr;
		}
	}
}else{
	$accept = new \Attribute\AcceptRole("admin", "entry");
}
if(is_null($accept) || $accept->check()){
	$returnValue = $controllerInstance->$action();
}else{
	$returnValue = new \App\RedirectResponse("", "index");
}

// ビュー
if($returnValue instanceof \App\IView){
	$returnValue($requestContext, false);
}else if($returnValue instanceof \App\IHttpResponse){
	$returnValue($requestContext);
}
