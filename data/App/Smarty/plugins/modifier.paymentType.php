<?php
function smarty_modifier_paymentType($code){
	static $paymentAssoc = [
		"1" => "現金",
		"2" => "振込",
		"3" => "手数料",
		"4" => "手形",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $paymentAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($paymentAssoc as $k => $v){
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
		if(array_key_exists($code, $paymentAssoc)){
			return $paymentAssoc[$code];
		}else{
			return "";
		}
	}
}
