<?php
function smarty_function_predef_flash(){
	if(empty(\App\Smarty\PredefExpression::$classes)){
		return "";
	}
	ob_start();
?>
class Template{
	#values;
	static #expression = Symbol("Expression");
	static #a = document.createElement("a");
	constructor(...values){
		this.#values = values;
	}
	static #html(callSite, ...substitutions){
		let substitutions2 = [];
		for(let substitution of substitutions){
			if(substitution == null){
				substitutions2.push("");
			}else if((typeof substitution === "object") && (Template.#expression in substitution)){
				substitutions2.push(substitution[Template.#expression]);
			}else{
				substitutions2.push(Object.assign(Template.#a, {textContent: substitution}).innerHTML);
			}
		}
		return String.raw(callSite, ...substitutions2);
	}
<?php foreach(\App\Smarty\PredefExpression::$classes as $name => $literal): ?>
	<?= $name ?>(...values){ return Template.#html`<?= $literal ?>`; }
<?php endforeach; ?>
}
<?php
	$contents = ob_get_clean();
	return $contents;
}