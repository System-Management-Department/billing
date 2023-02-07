<?php
function smarty_modifier_closeProcessing($code){
	static $closeAssoc = [
		"0" => "都度請求",
		"1" => "締め請求",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $closeAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($closeAssoc as $k => $v){
			if(array_key_exists($k, $code)){
				if(!is_null($code[$k])){
					$res[$k] = $code[$k];
				}
			}else{
				$res[$k] = $v;
			}
		}
		return $res;
	}else{
		if(array_key_exists($code, $closeAssoc)){
			return $closeAssoc[$code];
		}else{
			return "";
		}
	}
}
