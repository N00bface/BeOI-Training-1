/*
	Some JS elements used in HTML
*/

function spoiler_click(id)
{
	var element = document.getElementById("spoiler_num" + id)
	var button = document.getElementById("spoiler_button_num" + id);
	if(element.getAttribute("data-down") == "true")
	{
		// Let's close other spoilers inside of this spoiler
		var others = element.getElementsByClassName("spoiler");
		for(var i = 0; i < others.length; ++i)
		{
			if(others[i].getAttribute("data-down") == "true")
			{
				spoiler_click(parseInt(others[i].getAttribute("id").substring(11)));
			}
		}
		element.style.visibility = "hidden";
		element.style.position = "absolute";
		element.setAttribute("data-down", "false");
		button.innerHTML = "Show spoiler";
	}
	else
	{
		element.style.visibility = "visible";
		element.style.position = "relative";
		element.setAttribute("data-down", "true");
		button.innerHTML = "Hide spoiler";
	}
}

function cursor_insert(before_text, after_text, elem_id)
{
	var element = document.getElementById(elem_id);
	if(document.selection)
	{
		element.focus();
		
		var sel = document.selection.createRange();
		if(after_text != "")
		{
			sel.text = before_text + sel.text + after_text;
		}
		else
		{
			sel.text = sel.text + before_text;
		}
	}
	// Radu magic (please contact us if you know what this means !!)
	else if(element.selectionStart | element.selectionEnd == 0)
	{
		if(element.selectionEnd > element.value.length)
		{
			element.selectionEnd = element.value.length;
		}
		
		var first = element.selectionStart;
		var second = element.selectionEnd + before_text.length;
		
		element.value = element.value.slice(0, first) + before_text + element.value.slice(first);
		element.value = element.value.slice(0, second) + after_text + element.value.slice(second);
		
		element.selectionStart = first + before_text.length;
		element.selectionEnd = second;
		element.focus();
	}
	else
	{
		var poivre = document.hop.elem_id;
		var instances = countInstances(before_text, after_text);
		if(instances%2 != 0 && after_text != "")
		{
			poivre.value = poivre.value + after_text;
		}
		else
		{
			poivre.value = poivre.value + before_text;
		}
	}
}