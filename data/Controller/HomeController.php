<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\RedirectResponse;
use App\ControllerBase;
use App\MySQL;

class HomeController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function index(){
		$v = new View();
		$includeDir = [];
		$dirName = dirname(__DIR__) . DIRECTORY_SEPARATOR . "Views" . DIRECTORY_SEPARATOR . "Home" . DIRECTORY_SEPARATOR;
		$dh = opendir($dirName);
		while(($fileName = readdir($dh)) !== false){
			if((substr($fileName, 0, 1) == "_") && is_dir($dirName . $fileName)){
				$includeDir[] = $dirName . $fileName;
			}
		}
		$v["includeDir"] = $includeDir;
		return $v;
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function sales(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function salesInput(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin", "entry")]
	public function billing(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function master(){
		return new View();
	}
}