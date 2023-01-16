<?php
namespace App;

class RedirectResponse implements IHttpResponse{
	private $controller;
	private $action;
	private $id;
	private $query;
	
	public function __construct($controller = "*", $action = "*", $id = null, $query = null){
		$this->controller = $controller;
		$this->action = $action;
		$this->id = $id;
		$this->query = $query;
	}
	public function __invoke($requestContext){
		$controller = trim(str_replace("\\", "/",
			($this->controller != "*") ? $this->controller : $requestContext->controller
		), "/");
		$action = ($this->action != "*") ? $this->action : $requestContext->action;
		$id = "";
		$query = is_array($this->query) ? "?" .http_build_query($this->query) : "";
		if(!is_null($this->id)){
			if($this->id == "*"){
				if(!is_null($requestContext->id)){
					$id = "/{$requestContext->id}";
				}
			}else{
				$id = "/{$this->id}";
			}
		}
		if($id == "" && $action == "index"){
			$action = "";
		}else{
			$action = "/{$action}";
		}
		
		header("Location: /{$controller}{$action}{$id}{$query}");
	}
}