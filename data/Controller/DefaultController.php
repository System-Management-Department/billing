<?php
namespace Controller;
use Exception;
use stdClass;
use App\ControllerBase;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use Model\Session;
use Model\User;
use Model\Logger;

class DefaultController extends ControllerBase{
	public function index(){
		if(Session::isLogin()){
			// ログインされていればリダイレクト
			return new RedirectResponse("Home", "index");
		}else{
			// ログインされていなければフォームを表示
			$v = new View();
			return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
		}
	}
	
	public function login(){
		$result = User::login();
		return new JsonView($result);
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
}