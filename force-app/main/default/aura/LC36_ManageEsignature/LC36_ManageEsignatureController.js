({
    submitEsign : function(component, event, helper){
        component.set('v.showSpinner',true);
        var action = component.get("c.submitEsignature");
        action.setParams({
            esignId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log("result :", result);
               
                //check if error
                if(result.error){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error"
                    });
                    toastEvent.fire(); 
                   // component.set("v.showSpinner", false);
                    $A.get("e.force:closeQuickAction").fire();                          
                }
                else{
                    //component.set("v.showSpinner", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success", 
                        "message": result.success,
                        "type" : "success"
                    });
                    toastEvent.fire();
                    //$A.get('e.force:refreshView').fire();
                    //redirect to cloned contract
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": result.contractId,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'We encountered an unexpected error: Cannot submit eSignature',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }  
            component.set('v.showSpinner',false);
        });
        $A.enqueueAction(action);
    },

    getSignatoryLst: function(component, event, helper) {
       // component.set('v.disabled',false);
        component.set('v.toEditRow','');
        component.set('v.showLookup',false);
        //component.set('v.SearchAccountId','');
        //component.set('v.toEditSupplierRow','');
        component.set('v.TypeAXA',false);
        
        
        var action = component.get('c.buildSignatorylst'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "esignId" : component.get('v.recordId') 
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                var res=a.getReturnValue();
                console.log('disablebtn',res.disablebtn)
            	component.set('v.disabled',res.disablebtn);
                component.set('v.eSignatoryList', res.lst);   
                component.set('v.disableSign',res.disableSignbtn);
                
            }
        });
        $A.enqueueAction(action);
        
        var cId = component.get('v.value');
        if (cId) {
            helper.searchById(component);
        }

        helper.getCode(component, event);
    },
    
    //phone mandatory if code changes to SMS
    changeCode: function(component, event, helper) {
        
        console.log('detected change in code');
        var lst = [];
        
        console.log(component.get("v.eSignatoryList"));
        
        for(var i=0;i<component.get('v.eSignatoryList').length;i++){
            console.log('mobile : ' [i] + component.get('v.eSignatoryList')[i].MobileTxt__c);
            
            if(component.get('v.eSignatoryList')[i].Code__c =='sms'){
                lst[i]=component.get('v.eSignatoryList')[i].MobileTxt__c;
                component.set("v.codesms",true);
            }
               
            else {
                component.set("v.codesms",lst);
            }
                
          
       }
       console.log('lst from changecode', lst);
        
       console.log('codesms is true or false : '+ component.get("v.codesms"));  
    },
    
    changeRole: function(component, event, helper) {
    },

    editEsign: function(component, event, helper) {
        component.set('v.showEditPanel', true);
             
    },
	
    //implements logic for cancel button
    hideEditPanel: function(component, event, helper) {
        component.set('v.showEditPanel', false);
        
         //calling apex to determine if selection is valid
        var action = component.get("c.cancelChanges");
        action.setParams({eSignatureId: component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
				component.set('v.eSignatoryList', result);
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'We encountered an unexpected error',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }   
        });
        $A.enqueueAction(action);       
    },
	
     //implements logic for cancel button
    saveSignatories: function(component, event, helper) {
        component.set('v.showEditPanel', false);
		component.set('v.showSpinner',true);
        //calling apex to determine if selection is valid
        var action = component.get("c.saveChanges");
        action.setParams({
            eSignatureId: component.get("v.recordId"),
            lstEsignatories:component.get('v.eSignatoryList')
        });

        action.setCallback(this, function(response) {
            var result = response.getReturnValue();
            var state = response.getState();
            console.log("state :", state);
            console.log("result :", result);
            if (state === "SUCCESS") {
                if(result.error != null && result.error != ''){
                    console.log("result1 :", result.success);
                    component.set("v.showEditPanel", true);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error",
                        "mode" : "sticky"
                    });
                    toastEvent.fire();
                }else if(result.success == ''){
                    component.set('v.showEditPanel', false);
                }else if(result.success != ''){
                    console.log("result2 :", result);
                    //component.set('v.eSignatoryList', result.success);
                    component.set('v.showEditPanel', false);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success", 
                        "message" : result.success,
                        "type" : "success"
                    });
                    toastEvent.fire();
                    //redirect to esignature
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get("v.recordId"),
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
            } 
            else { 
                console.log("result3 :", result.success);
                component.set('v.showEditPanel', true);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": result.error,
                    "type" : "error"
                });
                toastEvent.fire();
            }
            component.set('v.showSpinner',false);
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action); 
     
    },
	
    AddNewSignatory: function(component, event, helper){
        helper.getDefaultValues(component, event);
        var role = event.currentTarget.dataset.value;
        var lstEsignatory = component.get("v.eSignatoryList");
        var newObj = new Object();
           
        newObj.Order__c = (role == "Validator" ? 1 : lstEsignatory.length+1);
        newObj.cTin_Role__c = (role == "AXA" ? 'AXA Representative' : (role == "Supplier" ? 'Supplier Representative' : 'Validator'));
        newObj.EsignatoryType__c = (role == "AXA" ? 'AXA' : 'Customer');
        newObj.Code__c = 'email';
        newObj.TECH_defaultSignatory__c = false;
        newObj.Name = null;
        newObj.EntityName__c = '';

        if(role == "Validator"){
            for(var i= lstEsignatory.length-1; i>=0; i--){
                lstEsignatory[i].Order__c = lstEsignatory[i].Order__c + 1;
                lstEsignatory[i+1] = lstEsignatory[i];
            }
            lstEsignatory[0] = newObj;
        }else{
            lstEsignatory.push(newObj);
        }

        component.set("v.eSignatoryList",lstEsignatory);
        component.set('v.currentRow',lstEsignatory.length);
    },

    removeEsignatory: function(component, event, helper){
        var lstEsignatory = component.get("v.eSignatoryList");
        var nbrEsignatory = lstEsignatory.length;
        var index = event.currentTarget.id;
        for(var i= parseInt(index)+1; i<nbrEsignatory; i++){
            lstEsignatory[i].Order__c = lstEsignatory[i].Order__c - 1;
        }
        if(lstEsignatory != null){
            lstEsignatory.splice(index,1);
        }
        component.set("v.eSignatoryList", lstEsignatory);
    },
    
    /*removeRow : function(component, event, helper){
       console.log('deleting row');
       //console.log(' lst length ', component.get('v.eSignatoryList').length);
       var currIndex = event.target.getAttribute("id");
       //console.log(' currIndex ',currIndex);

      for(var i=0;i<component.get('v.eSignatoryList').length;i++){
          // console.log('i',i +'' +component.get('v.eSignatoryList')[i].Id);
           
           if(i==currIndex){
             // newList = component.get('v.eSignatoryList')[i];
             component.set('v.toDelRow', component.get('v.eSignatoryList')[i].Id);
             component.set('v.toDelOrder', component.get('v.eSignatoryList')[i].Order__c);
             //component.set( 'v.eSignatoryList',
             component.get('v.eSignatoryList').splice( component.get('v.eSignatoryList').indexOf(component.get('v.eSignatoryList')[i].Id), 1 );
             //);
             //component.set('v.toDelRow', component.get('v.eSignatoryList')[i].Id);
             //component.get('v.eSignatoryList').splice( component.get('v.eSignatoryList').indexOf(component.get('v.eSignatoryList')[i].Id), 1 );
           }
          
       }      
      // console.log(' newList ',component.get('v.eSignatoryList'));
        
       //$A.get('e.force:refreshView').fire();
       //
      //console.log('v.toDelRow', component.get('v.toDelRow'));
      
       console.log('deleting row 2');
        
       var action = component.get('c.deleteSignatory'); 
        // method name i.e. getEntity should be same as defined in apex class
        // params name i.e. entityType should be same as defined in getEntity method
        action.setParams({
            "signatoryId" : component.get('v.toDelRow'),
            "esignId" : component.get('v.recordId') ,
            "ordertbd" : component.get('v.toDelOrder')
        });
        action.setCallback(this, function(a){
            var state = a.getState(); // get the response state
            if(state == 'SUCCESS') {
                component.set('v.eSignatoryList', a.getReturnValue());
                console.log('component.getlist', component.get('v.eSignatoryList'));
            }
            else{
                   console.log('Error deleting row');
            }
        });
        $A.enqueueAction(action);
        
		
    }, */
    
    editRow : function(component, event, helper){
       console.log('component.getlist', component.get('v.eSignatoryList'));
       console.log(' lst length ', component.get('v.eSignatoryList').length);
       var currIndex = event.target.getAttribute("id");
       console.log(' currIndex ',currIndex);
       component.set('v.toEditRow',currIndex);
    },
    
    assignURL : function(component, event, helper) {
        var esignId = component.get("v.recordId");
		var action = component.get("c.assignSignatoryURL");
        action.setParams({
            eSignatureId: esignId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(">>> result :", result);
               
                //check if error
                if(result.error){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": result.error,
                        "type" : "error"
                    });
                    toastEvent.fire(); 
                    $A.get("e.force:closeQuickAction").fire();                          
                }
                else{
                    var signURL = result.success;
                    console.log(">>> signURL :", signURL);
                    var urlsaleforce = window.location.hostname;
                    var url = '/apex/VFP22_AxaExecSign?signUrl='+signURL+'&eSignatureId='+esignId;
                    //var url = '/apex/VFP22_AxaExecSign?signUrl=https://sign.test.universign.eu/sig/?id=eaf03786-1e59-4e36-8a83-ec04c4214a96' +'&eSignatureId='+'a0S1w000001WliVEAS';
                    console.log(">>> url :", url);
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": url
                    });
                    console.log(">>> urlEvent :", urlEvent);
                    urlEvent.fire();
                    $A.get("e.force:closeQuickAction").fire();  
                    
                }
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'An unexpected error occurred. Please contact your admin.',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }         
        });
        $A.enqueueAction(action);
    },
  /*  
    editAccountLookup: function(component, event, helper) {
        component.set('v.sObjName','Account');
        var currId = event.target.getAttribute("id");
        console.log('editAccountLookup currId',currId ); //Supplier RepresentativeAcc3
       
        var currindex=currId[currId.length -1];
        console.log('editAccountLookup currindex',currindex ); // 3
        
        component.set('v.toEditSupplierRow',currId); 
        component.set('v.SearchAccountId',component.get('v.eSignatoryList')[currindex].EntityName__c);
    },*/
	
    editContactLookup : function(component, event, helper) {
        component.set('v.sObjName','Contact');
        var currId = event.target.getAttribute("id");
        var currindex=currId[currId.length -1];
        console.log('triggered on ', currId);
       // console.log('component.getlist', component.get('v.eSignatoryList')[currindex].Name);
        component.set('v.toEditRow',currId); 
        //component.set('v.toEditRow',currIndex);
        console.log('row number being edited' , component.get('v.toEditRow'));
        component.set('v.showLookup',true);  
        
        //set TypeAXA => true if axa : used in search query to fetch AXA contacts
        if((component.get('v.eSignatoryList')[currindex].cTin_Role__c)== 'AXA Representative' )
        	component.set('v.TypeAXA', true);
        else
        	component.set('v.TypeAXA', false);
        
        //set SearchAccountId -> used in search query to fetch contacts related to the account
        component.set('v.SearchAccountId',component.get('v.eSignatoryList')[currindex].EntityName__c);
    },
    
    handleLookupComponentEvent : function(component, event, helper) {
      
        console.log('#### starting handleLookupComponentEvent');
        
        console.log('#### IN handleLookupComponentEvent Id : ', component.get("v.value"));
        console.log('#### IN handleLookupComponentEvent text : ', component.get("v.searchTerm"));
        var currId=component.get('v.toEditRow');
        var currindex=currId[currId.length -1];
        /* //get current index being modified
        if(component.get('v.sObjName')=='Account'){
           currId=component.get('v.toEditSupplierRow'); 
        }
        else{
           currId=component.get('v.toEditRow');
        }
        
        
       	console.log( ' current Id name ', component.get('v.eSignatoryList')[currindex].Id);         
       
       ***/
        
      
        
        /****/
		console.log('#### ending handleLookupComponentEvent');
        var esignId = component.get("v.recordId");
        
        //calling apex to determine if selection is valid
        var action = component.get("c.refreshSignatoryLst");
        action.setParams({
            eSignatureId: esignId,
            contactType :component.get('v.TypeAXA'),
            esignatoryId: component.get('v.eSignatoryList')[currindex].Id,
            recordId:component.get("v.value"),
            recordName:component.get("v.searchTerm"),
            objectType:component.get('v.sObjName'),
            code:component.get('v.eSignatoryList')[currindex].Code__c,
            mobilephone: component.get('v.eSignatoryList')[currindex].MobileTxt__c,
            esignOrder: component.get('v.eSignatoryList')[currindex].Order__c
          
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
             console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('result save signatory',result);
                component.set('v.eSignatoryList', result);
                //console.log('result.errWrongContact', result.errWrongContact);
               // $A.get("e.force:refreshView").fire();
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'An unexpected error from refreshsignatories',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }         
        });
        $A.enqueueAction(action);
        component.set('v.showLookup',false);
        component.set('v.toEditRow','');
       // component.set('v.toEditSupplierRow',''); 
    },
    
     handleClick: function (component, event, helper) {
        var currId = event.target.getAttribute("id");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": currId
        });
        navEvt.fire();
    },
    
    /*increaseOrder: function (component, event, helper) {
        var currId ='';
        currId=event.target.getAttribute("id");
        if(currId!='' && currId.includes('a0Q')){
        //console.log('id increase order',currId);
		var currindex=currId[currId.length -1];
        
        var action = component.get("c.changeOrder");
        action.setParams({
            eSignatureId: component.get('v.recordId'),
            esignatoryId: component.get('v.eSignatoryList')[currindex].Id, 
            sortType: 'up',
            currentOrder:component.get('v.eSignatoryList')[currindex].Order__c - 1,
            currEsign:component.get('v.eSignatoryList')[currindex]
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
             console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();  
                component.set('v.eSignatoryList', result); 
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'An unexpected error',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }         
        });
        $A.enqueueAction(action);
        }
        else{
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams({
               "title": "Error",
               "message": 'Please specify a signatory before changing order',
               "type" : "error"
           });
           toastEvent.fire();
           $A.get("e.force:closeQuickAction").fire();
        }
    },
    
    decreaseOrder: function (component, event, helper) {
        var currId = '';
        currId=event.target.getAttribute("id");
        if(currId!='' && currId.includes('a0Q')){
        //console.log('id decrease order',currId);
        var currindex=currId[currId.length -1];
        
        var action = component.get("c.changeOrder");
        action.setParams({
            eSignatureId: component.get('v.recordId'),
            esignatoryId: component.get('v.eSignatoryList')[currindex].Id, 
            sortType: 'down',
            currentOrder:component.get('v.eSignatoryList')[currindex].Order__c + 1,
            currEsign:component.get('v.eSignatoryList')[currindex]
     
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
             console.log("state :", state);
            if (state === "SUCCESS") {
                var result = response.getReturnValue();  
                component.set('v.eSignatoryList', result); 
            } 
            else {       
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": 'An unexpected error',
                    "type" : "error"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }         
        });
        $A.enqueueAction(action);
   	  }
      else{
           var toastEvent = $A.get("e.force:showToast");
           toastEvent.setParams({
               "title": "Error",
               "message": 'Please specify a signatory before changing order',
               "type" : "error"
           });
           toastEvent.fire();
           $A.get("e.force:closeQuickAction").fire();
        }
    },*/
    
    increaseOrder: function (component, event, helper) {
        var lstEsignatory = component.get("v.eSignatoryList");
        var currIndex = parseInt(event.target.getAttribute("name"));
        console.log('index ', currIndex);
        var prevIndex = parseInt(currIndex) - 1;
        var currItem = lstEsignatory[currIndex];
        var currOrder = currItem.Order__c;

        currItem.Order__c = currOrder - 1;
        lstEsignatory[prevIndex].Order__c = currOrder;
        lstEsignatory[currIndex] = lstEsignatory[prevIndex];
        lstEsignatory[prevIndex] = currItem;
        component.set("v.eSignatoryList", lstEsignatory);
    },
    
    decreaseOrder: function (component, event, helper) {
        var lstEsignatory = component.get("v.eSignatoryList");
        var currIndex = parseInt(event.target.getAttribute("name"));
        var nextIndex = parseInt(currIndex) + 1;
        var currItem = lstEsignatory[currIndex];
        var currOrder = currItem.Order__c;

        currItem.Order__c = currOrder + 1;
        lstEsignatory[nextIndex].Order__c = currOrder;
        lstEsignatory[currIndex] = lstEsignatory[nextIndex];
        lstEsignatory[nextIndex] = currItem;
        component.set("v.eSignatoryList", lstEsignatory);
    },
    
	
    /**lookup handlers **/
    handleIdInput: function(component) {
     console.log('one');
        var cId = component.get('v.value');
        var cName = component.get('v.searchTerm');
      
        if (cId && !cName) {
            helper.searchById(component);
        }        
    },

    handleSearchChange : function(component, event, helper) {
		var lstEsignatory = component.get("v.eSignatoryList");
        var index = (event.getSource().get("v.class")).replace('slds-input','');
        var searchTerm = event.getSource().get("v.value");

        component.set('v.searchIndex',parseInt(index)+1);
        component.set('v.searchTerm',searchTerm);
        console.log('searchTerm', component.get('v.searchTerm'));
        console.log('searchIndex', component.get('v.searchIndex'));
        component.set('v.eSignatoryType', lstEsignatory[parseInt(index)].cTin_Role__c);
        
        if (component.get('v.searchTerm') && component.get('v.searchTerm').length>1){
            helper.searchByName(component);
        }else{
            component.set('v.hasResults',false);
        }
    },
    
   handleResultSelect: function(component,event,helper) {
		var lstEsignatory = component.get("v.eSignatoryList");
        console.log('lstEsignatory ', lstEsignatory.length);
        var lstContact = component.get('v.searchResults');
        var index = event.target.getAttribute("name");
        var lookupId = event.target.getAttribute("data-id");
        var contact = lstContact.filter(e=>e.Id === lookupId)[0];
        var object = new Object();

        console.log('Contact', JSON.stringify(contact));
        object.Code__c = 'email';
        object.Name = contact.Name;
        object.MobileTxt__c = contact.MobilePhone;
        object.EmailTxt__c = contact.Email;
        object.TECH_defaultSignatory__c = false;
        object.Tech_OriginalSignatory__c = false;
        object.Contact__c = contact.Id;
        object.Contact__r = contact;
        object.EntityName__c = contact.Account.Id;
        object.EntityName__r = contact.Account;
        object.cTin_Role__c = lstEsignatory[index].cTin_Role__c;
        object.Order__c = lstEsignatory[index].Order__c;


        console.log('object.EntityName__r ', JSON.stringify(object.EntityName__r));
        lstEsignatory[index] = object; 
        component.set("v.eSignatoryList", lstEsignatory);
        component.set('v.hasResults',false);           
    }
    

})