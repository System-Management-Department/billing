<?php
function smarty_modifier_taxProcessing($code){
	return \App\Smarty\SelectionModifiers::taxProcessing($code);
}
