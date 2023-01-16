<?php
namespace Controller;
use App\View;
use App\JsonView;
use App\ControllerBase;
use App\MySQL;

class HomeController extends ControllerBase{
	public function index(){
		return new View();
	}
}