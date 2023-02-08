<?php
function smarty_modifier_summaryType($code){
	static $summaryAssoc = [
		"1" => "売上伝票",
		"2" => "入金伝票",
		"3" => "請求書",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $summaryAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($summaryAssoc as $k => $v){
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
		if(array_key_exists($code, $summaryAssoc)){
			return $summaryAssoc[$code];
		}else{
			return "";
		}
	}
}
