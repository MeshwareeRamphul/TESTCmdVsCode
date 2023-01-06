({
     getCode: function(component, event) {
        var action = component.get("c.getCodes");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var codeMap = [];
                for(var key in result){
                    codeMap.push({value: key, label: result[key]});
                }
                console.log(JSON.stringify(codeMap));
                component.set("v.codeMap", codeMap);
            }
        });
        $A.enqueueAction(action);
    },
    
    getDefaultValues:function(component,event){
        console.log("from helper",component.get('v.eSignatoryList').length);
        for(var i=0;i<component.get('v.eSignatoryList').length;i++){
        
            if(component.get('v.eSignatoryList')[i].TECH_defaultSignatory__c==true && 
               component.get('v.eSignatoryList')[i].cTin_Role__c=='AXA Representative' &&
               component.get('v.eSignatoryList')[i].Name!=''
              ){
               component.set('v.DefaultAXAEntityName',component.get('v.eSignatoryList')[i].EntityName__r.Name);
        	   component.set('v.DefaultAXAEntityId',component.get('v.eSignatoryList')[i].EntityName__c);
            }
            if(component.get('v.eSignatoryList')[i].TECH_defaultSignatory__c==true && 
               component.get('v.eSignatoryList')[i].cTin_Role__c=='Supplier Representative' &&
               component.get('v.eSignatoryList')[i].Name!=''){
               component.set('v.DefaultSupplierEntityName',component.get('v.eSignatoryList')[i].EntityName__r.Name);
        	   component.set('v.DefaultSupplierEntityId',component.get('v.eSignatoryList')[i].EntityName__c);
            }
        }
        
     
        console.log("component.get('v.DefaultSupplierEntityName')",component.get('v.DefaultSupplierEntityName'));
        console.log("component.get('v.DefaultSupplierEntityId')",component.get('v.DefaultSupplierEntityId'));
    },
    
    /** lookup helper **/
    

    searchByName: function(cmp) {
        // clear search result info
        cmp.set('v.searchResults',[]);
        cmp.set('v.hasResults',false);
        
        // get search params
        var objName = cmp.get('v.sObjName');
        var searchTerm = cmp.get('v.searchTerm');
        
        var lstEsignatory = cmp.get('v.eSignatoryList');
        var ids='';
        for (var i= 0 ; i < lstEsignatory.length ; i++){
            if(typeof lstEsignatory[i].Contact__c !== 'undefined') ids += (ids == '' ? lstEsignatory[i].Contact__c : ','+lstEsignatory[i].Contact__c);
        }

        // controller action
        var action = cmp.get("c.getSObjectList");
        action.setParams({
            sObjectType: objName,
            searchTerm: searchTerm,
            contactType : cmp.get('v.eSignatoryType'),
            esignatoriesId : ids
        });
        action.setCallback(this, function(response) {
            cmp.set('v.hasResults',true);
            cmp.set('v.searchResults',response.getReturnValue());  
        });
        
        $A.enqueueAction(action);
    },
    searchById: function(cmp) {
            cmp.set('v.hasResults',false);
            
        var objName = cmp.get('v.sObjName');    
            var searchId = cmp.get('v.value');    
    
            // controller action
        var action = cmp.get("c.getSObject");
            action.setParams({
                sObjectType: objName,
                searchId: searchId
            });
            
            action.setCallback(this, function(response){          
                var state = response.getState();
    
            // if we have a result, set the component attribute values           
            if (state === "SUCCESS" && response.getReturnValue() 
                && response.getReturnValue()[0].id!=='error') {
                var sObj = response.getReturnValue()[0];
                cmp.set('v.searchTerm',sObj.name);             
            }
            });
            
            $A.enqueueAction(action);
    },    
    setResultsInfo: function(cmp,event) {
        //SMO: commenting reference to getElements(), because critical security update Locker service does not allow this
        // var el = event.getSource().getElements()[0];

         var target;
         if (event.getSource) {
           // handling a framework component event
            target = event.getSource(); // this is a Component object
         } 
         else {
           // handling a native browser event
           target = event.target.id; // this is a DOM element
         }
        //console.log('target = ' + target);

        var elementId = '#'+target;

        // clear results 
        cmp.set('v.hasResults',false);
        // add parameters to name and id fields
        // cmp.set('v.searchTerm',el.text);    
        // cmp.set('v.value',el.title);     

        //SMO: using jquery to get select lookup id and value
        var lookupId = $(elementId).attr('rel');
        var lookupTextValue = $(elementId).text();

        console.log('itemSelected id= ' , lookupId);
        console.log('itemSelected val= ' , lookupTextValue);

        cmp.set('v.searchTerm',lookupTextValue);    
        cmp.set('v.value',lookupId); 

        // Get the component event by using the
        // name value from aura:registerEvent
        var cmpEvent = cmp.getEvent("cmpEvent");
        cmpEvent.setParams({
            "lookupId" :  lookupId});
        cmpEvent.fire();          
    }

})