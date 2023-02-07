<?php
function smarty_modifier_invoiceFormat($code){
	static $invoiceAssoc = [
		"1" => "標準",
		"2" => "ニッピ様_発行部数",
		"3" => "加茂繊維様",
		"4" => "ダイドー様",
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
