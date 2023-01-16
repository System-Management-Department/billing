<?php
namespace Attribute;

#[\Attribute]
class AcceptRole{
	private $accept;
	function __construct(...$args){
		$this->accept = $args;
	}
	function check(){
		return in_array($_SESSION["User.role"], $this->accept);
	}
}