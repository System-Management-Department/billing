<?php
function smarty_function_requestContextExport($params, $template){
	return nl2br(
		str_replace(' ', '&#160;',var_export($template->smarty->requestContext, true))
	);
}