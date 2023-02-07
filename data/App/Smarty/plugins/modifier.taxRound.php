<?php
function smarty_modifier_taxRound($code){
	static $taxAssoc = [
		"floor" => "切り捨て",
		"ceil"  => "切り上げ",
		"round" => "四捨五入",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $taxAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($taxAssoc as $k => $v){
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
		if(array_key_exists($code, $taxAssoc)){
			return $taxAssoc[$code];
		}else{
			return "";
		}
	}
}
