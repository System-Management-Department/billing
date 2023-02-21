<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;

class BasicInfoController extends ControllerBase{
	#[\Attribute\AcceptRole("admin")]
	public function index(){
		return new View();
	}
}