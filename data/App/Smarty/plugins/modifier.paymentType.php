<?php
function smarty_modifier_paymentType($code){
	return \App\Smarty\SelectionModifiers::paymentType($code);
}
