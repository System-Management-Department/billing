<?php
function smarty_modifier_taxRound($code){
	return \App\Smarty\SelectionModifiers::taxRound($code);
}
