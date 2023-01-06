
	function popIn01(overlayId,iframeId,URL) {
	/* this function create a pop-in with the specified url to set*/
		el = document.getElementById(overlayId);	
		
		if(el.style.visibility == "visible"){
			el.style.visibility = "hidden";					
		}
		else{
			if((typeof URL != "undefined")){								
				document.getElementById(iframeId).src = URL;
			}
			el.style.visibility = "visible";									
		}			
	}
	
	function popIn02(overlayId,errorId) {
	/* this function create a pop-in with error set to true if any */
			el = document.getElementById(overlayId);
			er = document.getElementById(errorId);
			er.style.visibility = "hidden";		
							
			if(el.style.visibility == "visible"){
				el.style.visibility = "hidden";					
			}
			else{
				el.style.visibility = "visible";									
			}			
	}
		
	function validateFields(errorId,param1,param2,param3){
		
			var er = document.getElementById(errorId);
			var f1,f2,f3;
								
			if ((typeof param1 != "undefined")) {
				f1 = document.getElementById(param1).value;
				if(f1.length == 0){
					er.style.visibility = "visible";
					return false;
				}				
			}
			if ((typeof param2 != "undefined")) {
				f2 = document.getElementById(param2).value;
				if(f2.length == 0){
					er.style.visibility = "visible";
					return false;
				}				
			}
			if ((typeof param3 != "undefined")) {
				f3 = document.getElementById(param3).value;
				if(f3.length == 0){
					er.style.visibility = "visible";
					return false;
				}				
			}
			else {
				er.style.visibility = "hidden";
				return true;
			}
	}
	function showMsg(overlayId,flag) {
	/* this function create a pop-in with a status message  */
		el = document.getElementById(overlayId);	
		if(flag == 0){
			el.style.visibility = "hidden";					
		}
		else{
			el.style.visibility = "visible";									
		}			
	}
	
	function overlay(overlayId) {
	/* this function close the popin with default refresh */
		el = document.getElementById(overlayId);
		
		if(el.style.visibility == "visible"){
			el.style.visibility = "hidden";
			window.location = document.location.href;		
		}
		else{
			el.style.visibility = "visible";									
		}			
	}
	function overlay(overlayId,refresh) {
	/* this function close the popin -if refresh set to true, it refresh the complete page after closing */
		el = document.getElementById(overlayId);
		
		if(el.style.visibility == "visible"){
			el.style.visibility = "hidden";
			if(refresh == 'true'){
				window.location = document.location.href;	
			}				
		}
		else{
			el.style.visibility = "visible";									
		}			
	}
	
	function createPopIn_dep(url,height,width,refresh){
	/* this function has been deprecated */
		var c = document.getElementById("overlay0");
		if(!c ){
			var newdiv = document.createElement('div');
			newdiv.setAttribute('id', 'overlay0');
			newdiv.setAttribute('class', 'grouping');
			newdiv.style.visibility = "visible";

			var newdiv1 = document.createElement('div');
			newdiv1.setAttribute('id', 'overlay1');
			newdiv1.setAttribute('class', 'overlay1');

			var newdiv2 = document.createElement('div');
			newdiv2.setAttribute('id', 'box');
			newdiv2.setAttribute('class', 'box');
			
			if ((typeof width != "undefined")){
				newdiv2.style.width =  width + 'px';
				newdiv2.style.height =  height + 'px';
				newdiv2.style.marginLeft = (0 - width/2) + 'px';
				newdiv2.style.marginTop = (0 - height/2) + 'px';
			}
			var h = height - 50;
			
			if((typeof refresh != "undefined") && refresh == 1){
				newdiv2.innerHTML = '<img align="right" class="dialogClose" src="/s.gif" onclick="overlay(\'overlay0\',\'true\')">';
			}
			else 
				newdiv2.innerHTML = '<img align="right" class="dialogClose" src="/s.gif" onclick="overlay(\'overlay0\',\'false\')">';
			
			newdiv2.innerHTML += '<iframe id="if1" width="100%" height="' + h + 'px" frameborder="0" title="Content" scrolling="auto" src="' + url + '" name="if1">';		
			document.body.appendChild(newdiv);
			newdiv.appendChild(newdiv1);
			newdiv.appendChild(newdiv2);
		}
		else{
			var c = document.getElementById("overlay0");
			c.style.visibility = " visible";
		}

	}
	function closeMe(overlayId,refresh){
	/* this function delete the pop-in -if refresh set to true, it refresh the complete page after closing */
		try{
			var e1 = document.getElementById(overlayId);
			e1.parentNode.removeChild(e1);
			
			if(refresh == 'true'){
				window.location = document.location.href;	
			}
		}
		catch(e){alert(e);}
	}
	function createPopIn(url,height,width,refresh){
	/* this function create a pop-in and the corresponding div - to be used on standard pages and called by javascript buttons */
		var c = document.getElementById("overlay0");
		if(!c ){
			var newdiv = document.createElement('div');
			newdiv.setAttribute('id', 'overlay0');
			newdiv.setAttribute('class', 'overfront');
			newdiv.style.visibility = "visible";

			var newdiv1 = document.createElement('div');
			newdiv1.setAttribute('id', 'box');
			newdiv1.setAttribute('class', 'box');
			
			var newdiv2 = document.createElement('div');			
			newdiv2.setAttribute('class', 'overback');
			
			if ((typeof width != "undefined")){
				newdiv1.style.width =  width + 'px';
				newdiv1.style.height =  height + 'px';
				newdiv1.style.marginLeft = (0 - width/2) + 'px';
				newdiv1.style.marginTop = (0 - height/2) + 'px';
			}
			var h = height - 50;
			
			if((typeof refresh != "undefined") && refresh == 1){
				newdiv1.innerHTML = '<img align="right" class="dialogClose" src="/s.gif" onclick="closeMe(\'overlay0\',\'true\')">';
			}
			else 
				newdiv1.innerHTML = '<img align="right" class="dialogClose" src="/s.gif" onclick="closeMe(\'overlay0\',\'false\')">';
			
			newdiv1.innerHTML += '<iframe id="if1" width="100%" height="' + h + 'px" frameborder="0" title="Content" scrolling="auto" src="' + url + '" name="if1">';		
			document.body.appendChild(newdiv);
			newdiv.appendChild(newdiv1);
			newdiv.appendChild(newdiv2);
		}
		else{
			var c = document.getElementById("overlay0");
			c.style.visibility = " visible";
		}

	}