<?php
namespace App;

class JsonView implements IView{
	private $data;
	public function __construct($data){
		$this->data = $data;
	}
	
	public function __invoke($requestContext, $return = true){
		if($return){
			return json_encode($this->data);
		}else{
			header('Content-Type: application/json');
			echo json_encode($this->data);
		}
	}
}