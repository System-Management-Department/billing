<?php
namespace App;

class RequestContext{
	public $controller;
	public $action;
	public $id;
	public function getFiles($name){
		if(array_key_exists($name, $_FILES)){
			$arrayData = [];
			if(is_scalar($_FILES[$name]["size"])){
				$arrayData[] = $_FILES[$name];
			}else{
				$n = count($_FILES[$name]["size"]);
				for($i = 0; $i < $n; $i++){
					$arrayData[] = [
						"name" => $_FILES[$name]["name"][$i],
						"type" => $_FILES[$name]["type"][$i],
						"tmp_name" => $_FILES[$name]["tmp_name"][$i],
						"error" => $_FILES[$name]["error"][$i],
						"size" => $_FILES[$name]["size"][$i],
					];
				}
			}
			return $arrayData;
		}else{
			return [];
		}
	}
	
	
	
	
}
