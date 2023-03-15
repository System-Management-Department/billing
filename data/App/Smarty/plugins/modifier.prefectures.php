<?php
function smarty_modifier_prefectures($code){
	return \App\Smarty\SelectionModifiers::prefectures($code);
}
