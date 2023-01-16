<?php
namespace App;

interface IHttpResponse{
	public function __invoke($requestContext);
}