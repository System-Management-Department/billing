<?php
function smarty_modifier_role($code){
	return \App\Smarty\SelectionModifiers::role($code);
}
