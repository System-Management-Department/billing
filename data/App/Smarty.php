<?php
namespace App;
include_once DATA_DIR . 'Smarty' . DIRECTORY_SEPARATOR . 'Smarty.class.php';

class Smarty extends \Smarty{
	public $requestContext;
	public function __construct($context){
		$this->requestContext = $context;
		parent::__construct();
	}
}