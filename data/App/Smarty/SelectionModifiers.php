<?php
namespace App\Smarty;

class SelectionModifiers{
	private static $closeProcessing = [
		"0" => "都度請求",
		"1" => "締め請求",
	];
	private static $existence = [
		"0" => "無",
		"1" => "有",
	];
	private static $invoiceFormat = [
		"1" => "通常請求書",
		"2" => "ニッピ用請求書",
		"3" => "加茂繊維用請求書",
		"4" => "ダイドー用請求書",
	];
	private static $numberingSystem = [
		"1" => "年度",
		"2" => "月度",
		"3" => "手動",
	];
	private static $paymentType = [
		"1" => "現金",
		"2" => "振込",
		"3" => "手数料",
		"4" => "手形",
	];
	private static $summaryType = [
		"1" => "売上伝票",
		"2" => "入金伝票",
		"3" => "請求書",
	];
	private static $taxProcessing = [
		"1" => "外税/伝票計",
		"2" => "外税/請求時",
		"3" => "内税/伝票計",
		"4" => "内税/請求時",
		"5" => "免税",
		"6" => "外税/手入力",
	];
	private static $taxRound = [
		"floor" => "切り捨て",
		"ceil"  => "切り上げ",
		"round" => "四捨五入",
	];
	private static $unitPriceType = [
		"1" => "売上単価1",
		"2" => "売上単価2",
		"3" => "売上単価3",
		"4" => "売上単価4",
		"5" => "売上単価5",
	];
	public static function __callStatic($target, $args){
		$assoc = self::$$target;
		$code = $args[0];
		
		if(is_array($code)){
			$res = [];
			foreach($code as $k => $v){
				if(array_key_exists($k, $assoc)){
					continue;
				}
				$res[$k] = $v;
			}
			foreach($assoc as $k => $v){
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
			if(array_key_exists($code, $assoc)){
				return $assoc[$code];
			}else{
				return "";
			}
		}
	}
}