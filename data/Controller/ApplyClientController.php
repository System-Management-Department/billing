<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;

class ApplyClientController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function list(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function create(){
		return new View();
	}
	
	#[\Attribute\AcceptRole("admin")]
	public function edit(){
		return new View();
	}
}