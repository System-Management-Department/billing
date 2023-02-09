<?php
function smarty_modifier_existence($code){
	return \App\Smarty\SelectionModifiers::existence($code);
}
