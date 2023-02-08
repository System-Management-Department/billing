<?php
function smarty_modifier_numberingSystem($code){
	static $numberingAssoc = [
		"1" => "年度",
		"2" => "月度",
		"3" => "手動",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $numberingAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($numberingAssoc as $k => $v){
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
		if(array_key_exists($code, $numberingAssoc)){
			return $numberingAssoc[$code];
		}else{
			return "";
		}
	}
}
