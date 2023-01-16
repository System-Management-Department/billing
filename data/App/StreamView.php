<?php
namespace App;

class StreamView implements IView{
	private $buffer;
	private $type;
	public function __construct($stream, $type){
		$this->buffer = stream_get_contents($stream);
		$this->type = $type;
	}
	
	public function __invoke($requestContext, $return = true){
		if($return){
			return $this->buffer;
		}else{
			header("Content-Type: {$this->type}");
			echo $this->buffer;
		}
	}
}