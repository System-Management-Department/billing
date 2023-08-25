<?php
namespace Controller;
use App\ControllerBase;
use App\View;

class EstimateController extends ControllerBase{
	#[\Attribute\AcceptRole("admin", "entry", "manager", "leader")]
	public function index(){
		$v = new View();
		$v["id"] = $this->requestContext->id;
		return $v->setLayout("Shared" . DIRECTORY_SEPARATOR . "_simple_html.tpl");
	}
}