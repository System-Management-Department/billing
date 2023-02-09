<?php
function smarty_modifier_invoiceFormat($code){
	return \App\Smarty\SelectionModifiers::invoiceFormat($code);
}
