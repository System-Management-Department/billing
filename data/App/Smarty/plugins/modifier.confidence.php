<?php
function smarty_modifier_confidence($code){
	return \App\Smarty\SelectionModifiers::confidence($code);
}
