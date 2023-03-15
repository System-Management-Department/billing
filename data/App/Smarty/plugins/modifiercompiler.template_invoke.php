<?php
function smarty_modifiercompiler_template_invoke($params, Smarty_Internal_TemplateCompilerBase $compiler){
	$p = [];
	foreach($params as $param){
		$p[] = "(({$param} instanceof \\App\\Smarty\\TemplateObject) ? {$param}->getCode() : {$param})";
	}
	$a = implode(",", array_slice($p, 1));
	return <<<HERE
("\\\${" . {$p[0]} . "(" . {$a} . ")}")
HERE;
}
