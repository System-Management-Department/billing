<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\JsonView;
use App\MySQL;
use Model\Session;

class JWTController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry")]
	public function spreadsheet(){
		$db = Session::getDB();
		return new JsonView(self::getJWT($db, "https://www.googleapis.com/auth/spreadsheets"));
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function drive(){
		$db = Session::getDB();
		return new JsonView(self::getJWT($db, "https://www.googleapis.com/auth/drive"));
	}
	
	
	private static function getJWT($db, ...$scope){
		$now = time();
		$query = $db->select("ONE")
			->addTable("基本情報")
			->addField("`値`")
			->andWhere("`項目`=?", "サービスアカウントキー");
		$data = json_decode($query(), true);
		$header = ["alg" => "RS256", "typ" => "JWT"];
		$payload = [
			"iss" => $data["client_email"],
			"scope" => implode(",", $scope),
			"aud" => "https://oauth2.googleapis.com/token",
			"iat" => $now,
			"exp" => $now + 3600
		];
		$message = self::encode($header) . "." . self::encode($payload);
		$signature = "";
		$private_key = openssl_pkey_get_private($data["private_key"]);
		openssl_sign($message, $signature, $private_key, "SHA256");
		return ["assertion" => "{$message}." . rtrim(strtr(base64_encode($signature), "+/", "-_"), "="), "now" => microtime(true) * 1000];
	}
	
	private static function encode($data){
		$json = json_encode($data);
		return rtrim(strtr(base64_encode($json), "+/", "-_"), "=");
	}
}