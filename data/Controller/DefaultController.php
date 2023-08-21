<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\FileView;
use App\JsonView;
use App\RedirectResponse;
use Config\OAuth;
use Model\Session;
use Model\User;
use Model\Logger;
use Model\SQLite;

class DefaultController extends ControllerBase{
	public function index(){
		if(Session::isLogin()){
			// ログインされていればリダイレクト
			return new RedirectResponse("Home", "index");
		}else{
			// ログインされていなければフォームを表示
			$v = new View();
			OAuth::setOAuth($v);
			return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
		}
	}
	
	public function login(){
		OAuth::login($_POST["email"]);
		$result = new \Model\Result();
		$result->addMessage("ログインに成功しました。", "INFO", "");
		return new JsonView([$result, OAUTH]);
	}
	
	public function logout(){
		try{
			$db = Session::getDB();
			$deleteQuery = $db
				->delete("useronlinestatuses")
				->andWhere("user=@user");
			$deleteQuery();
			@Logger::record($db, "ログアウト", new stdClass());
		}catch(Exception $ex){
		}
		Session::logout();
		return new RedirectResponse("", "index");
	}
	
	public function master(){
		$fileName = SQLite::getCachedMasterFileName();
		return new FileView($fileName, "application/vnd.sqlite3");
	}
}