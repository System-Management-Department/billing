<?php
namespace App;

abstract class ControllerBase{
	protected $requestContext;
	public function __construct($context){
		$this->requestContext = $context;
	}
	public function __call($action, $arguments){
		return new View();
	}
}