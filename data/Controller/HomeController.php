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
		return new View();
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