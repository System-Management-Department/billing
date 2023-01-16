<?php
namespace App;

interface IView{
	public function __invoke($requestContext, $return);
}