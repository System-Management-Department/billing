<?php
function smarty_block_jsiife($params, $content, &$smarty, &$repeat){
	if(!$repeat){
		$keys = array_keys($params);
		$argsStr = implode(", ", $keys);
		$parameters = [];
		foreach($keys as $k){
			$parameters[] = $params[$k];
		}
		$json = str_replace('"', '\\u0022', json_encode($parameters));
		return "<script type=\"text/javascript\">(function({$argsStr}){{$content}}).apply(null, JSON.parse(\"{$json}\"));</script>";
	}
}