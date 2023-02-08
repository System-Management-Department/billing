<?php
function smarty_modifier_invoiceFormat($code){
	static $invoiceAssoc = [
		"1" => "通常",
		"2" => "ニッピ様",
		"3" => "加茂繊維",
		"4" => "ダイドー",
	];
	
	if(is_array($code)){
		$res = [];
		foreach($code as $k => $v){
			if(array_key_exists($k, $invoiceAssoc)){
				continue;
			}
			$res[$k] = $v;
		}
		foreach($invoiceAssoc as $k => $v){
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
		if(array_key_exists($code, $invoiceAssoc)){
			return $invoiceAssoc[$code];
		}else{
			return "";
		}
	}
}
