<?php
function smarty_modifier_monthList($code){
	return \App\Smarty\SelectionModifiers::monthList($code);
}
