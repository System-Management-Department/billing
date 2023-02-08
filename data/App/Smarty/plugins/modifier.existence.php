<?php
function smarty_modifier_existence($code){
	static $existenceAssoc = [
		"0" => "無",
		"1" => "有",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $existenceAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($existenceAssoc as $k => $v){
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
		if(array_key_exists($code, $existenceAssoc)){
			return $existenceAssoc[$code];
		}else{
			return "";
		}
	}
}
