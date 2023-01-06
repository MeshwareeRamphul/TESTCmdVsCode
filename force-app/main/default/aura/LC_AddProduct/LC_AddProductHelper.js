({
    
	initAll : function(component){
        var lstStep = ["step1", "step2"];
        component.set("v.isError", true);
        component.set('v.isSearching', false);
        component.set("v.isSelectAll", false);
        component.set("v.nameSearch", '');
        component.set("v.activeSectionName", "search");
        component.set("v.stepsArray", lstStep);
        component.set("v.currentSteps", lstStep[0]);
        component.set("v.lstSubProduct", new Array());
        component.set("v.lstProductSearch", new Array());
        component.set("v.lstProductTable", new Array());
        component.set("v.lstProductSelected", new Array());
        component.set("v.lstChoosenProdLine", new Array());
        component.set("v.lstChoosenSubProd", new Array());
   	},

    getRecord : function(component){
        var productLevel3 = '';
        var recordId = component.get('v.recordId');
        var action = component.get('c.getRecord');
        console.log('*****recordId ', recordId);
        action.setParams({
            "recordId" : recordId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
            	var result = response.getReturnValue();
                console.log('***** ', result);
                if(typeof result.Product_Level_3__c !== 'undefined'){
                    productLevel3 = result.Product_Level_3__c;
                }
                
                component.set("v.productLevel3", productLevel3);
            }
		}); 
        $A.enqueueAction(action);
        this.initAll(component);
    },
    
    /* Add products to a contract */
    addProducts : function(component) {
        var recordId = component.get('v.recordId');
        var lstIdProduct = component.get('v.lstProductSelected')
        var action = component.get('c.saveRecords');
        action.setParams({
            "recordId" : recordId, 
            "lstIdProduct" : lstIdProduct
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            if (state === "SUCCESS") {
                toastEvent.setParams({
                    "title": "Success!",
                    "message": 'Product item(s) created successfully',
                    "type" : "success",
                    "mode" : "dismissable"
                });

                this.initAll(component);
                component.set("v.showSpinner",false);
                component.set("v.isModalOpen", false);
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            }else{
                toastEvent.setParams({
                    "title": "Error!",
                    "message": 'Technical error when creating Product Item(s).',
                    "type" : "error",
                    "mode" : "sticky"
                });
            }
            toastEvent.fire();
		}); 
        $A.enqueueAction(action);
    },
    
    /* Get all products contains nameSearch not related to contract */
    getProducts : function(component) {
        var nameSearch = component.find("nameSearch").get("v.value");
        var action = component.get('c.getProducts');
        var recordId = component.get('v.recordId');
        var productLevel3 = component.get('v.productLevel3');
        var lstChoosenSubProd = component.get("v.lstChoosenSubProd");
        
        component.set('v.isSearching', true);
        action.setParams({
            "nameSearch" : nameSearch.toLowerCase(), 
            "recordId" : recordId,
            "productLevel3" : productLevel3,
            "lstSelectedProduct" : lstChoosenSubProd
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var lstSubProduct = new Array();
            if (state === "SUCCESS") {
            	var result = response.getReturnValue();
                if(component.find("nameSearch").get("v.value") != ''){
                    lstSubProduct = result;
                	component.set("v.isDropdown", true);
        		}else{
                    result = new Array();
                }
                           
                component.set("v.lstProductSearch", result);
                component.set("v.lstSubProduct", lstSubProduct);
            }else{
            	component.set("v.lstProduct", null);
            }
            component.set('v.isSearching', false);
		}); 
        $A.enqueueAction(action);
    },
})