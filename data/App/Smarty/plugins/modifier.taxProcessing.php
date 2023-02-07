<?php
function smarty_modifier_taxProcessing($code){
	static $taxAssoc = [
		"1" => "外税/伝票計",
		"2" => "外税/請求時",
		"3" => "内税/伝票計",
		"4" => "内税/請求時",
		"5" => "免税",
		"6" => "外税/手入力",
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
