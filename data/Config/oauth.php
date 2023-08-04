<?php
try{
$email = "";
$access = file_get_contents("http://{$_SERVER["SERVER_NAME"]}/exment/admin/oauth/token", false, stream_context_create([
	"http" => [
		"method"  => "POST",
		"header"  => implode("\r\n", [
			"Content-Type: application/json",
		]),
		'content' => http_build_query(json_encode([
			"grant_type"    => "api_key",
			"client_id"     => "0d9a71c0-3276-11ee-8bd1-7fae738d65f2",
			"client_secret" => "OHvIZhh2DlEDK0Tp3IG62cLbB5FUxq3k8LsnpBM6",
			"api_key"       => "key_YwxikOlOyIT2heIR8qUPsO7NTPUlaG",
			"scope"         => "value_read",
		]))
	]
]));


$response = file_get_contents("http://{$_SERVER["SERVER_NAME"]}/exment/admin/api/data/user/query-column?q=" . urlencode("email eq {$email}"), false, stream_context_create([
	"http" => [
		"method"  => "GET",
		"header"  => implode("\r\n", [
			"Content-Type: application/json",
			"Authorization: Bearer {$token["access_token"]}",
		])
	]
]));


/*
http(s)://(ExmentのURL)/admin/oauth/token'  POST
Content-Type: application/json

{
    "grant_type": "api_key",
    "client_id": "(コピーしたClient ID)",
    "client_secret": "(コピーしたClient Secret)",
    "api_key": "(コピーしたAPIキー)",
    "scope": "(アクセスを行うスコープ。一覧は下記に記載。複数ある場合はスペース区切り)"
}

{
"token_type": "Bearer",
"expires_in": 31622400,
"access_token": "eyJ0eXAiOiJKV1Q.....",
"refresh_token": "def50200e5f5eb458....."
}


http://localhost/admin/api/data/user GET
ヘッダ値：
Content-Type: application/json  
Authorization: Bearer (取得したアクセストークン) 
*/
}catch(Exception $ex){
}