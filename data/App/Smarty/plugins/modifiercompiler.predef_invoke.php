<?php
function smarty_modifiercompiler_predef_invoke($params, Smarty_Internal_TemplateCompilerBase $compiler){
	$t = "(({$params[0]} instanceof \\App\\Smarty\\PredefExpression) ? {$params[0]} : new \\App\\Smarty\\PredefExpression({$params[0]}))";
	$a = implode(",", array_slice($params, 1));
	return "{$t}->setInvoke({$a})";
}
