({
    handleBlur : function(component, event, helper) {
		component.set("v.isDropdown", false);
    },
    
    handleFocus : function(component, event, helper) {
        helper.getProducts(component);
        if(component.get("v.lstSubProduct").length == 0){
            component.set("v.isDropdown", false);
        }else{
            component.set("v.isDropdown", true);
        }
        event.stopPropagation();
    },
    
    openModal : function(component, event, helper) {
        component.set("v.isModalOpen", true);
        helper.getRecord(component);
    },
    
    closeModal : function(component, event, helper) {
        helper.initAll(component);
		component.set("v.showSpinner",false);
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
    
    /* Previous step */
    goToBack : function(component, event, helper) {
        var accordion = component.find("accordion").get("v.value");
        var currentStage = component.get("v.currentSteps");
        var stepsArray = component.get("v.stepsArray");
        
        if(currentStage != stepsArray[0]) {
            var currIndex = stepsArray.indexOf(currentStage);
            currentStage = stepsArray[currIndex-1];
            component.set("v.currentSteps", currentStage);
            if(currentStage == 'step2') {
                component.set("v.activeSectionName", "products");
            } else {
                component.set("v.activeSectionName", "search");
            }
            component.set("v.isError", false);
        }
    },
    
    /* Next step */
    goToNext : function(component, event, helper) {
        var isError = true;
        var currentStage = component.get("v.currentSteps");
        var stepsArray = component.get("v.stepsArray");
        var lstProductTable = component.get("v.lstProductTable");
        
        if(currentStage != stepsArray[stepsArray.length - 1]){
            var currIndex = stepsArray.indexOf(currentStage);
            currentStage = stepsArray[currIndex+1];
            component.set("v.currentSteps", currentStage);
            if(currentStage == 'step2') {
                component.set("v.activeSectionName", "products");
                lstProductTable.forEach(product =>{
                    if(product.isChecked){
                        isError = false;
                    }
                });
                component.set("v.isError", isError);
            }else{
                component.set("v.activeSectionName", "summary");
                component.set("v.isError", false);
            }
        }
    },
    
    searchProducts: function (component, event, helper) {
        helper.getProducts(component);
    },

	/* Remove product from table */    
    removeProduct : function(component, event, helper) {
        var isError = true;
        var idEvent = event.currentTarget.id;
        var lstProductTable = component.get("v.lstProductTable");
        var currentStage = component.get("v.currentSteps");
        var stepsArray = component.get("v.stepsArray");
        var lstProductSearch = component.get("v.lstProductSearch");
        
        if(currentStage == stepsArray[1] || currentStage == stepsArray[2]) {
            component.set("v.currentSteps", stepsArray[0])
        }
        
        if(idEvent.startsWith('closeProductLine-')){
            /* for Product Line */
            /*var productLine = idEvent.replace('closeProductLine-', '');
        	var lstChoosenProdLine = component.get("v.lstChoosenProdLine");
        	var lstProductSearch = component.get("v.lstProductSearch");
            if(lstChoosenProdLine != null){
        		component.set("v.lstChoosenProdLine", lstChoosenProdLine.filter(e => e !== productLine));
            }
            if(lstProductSearch != null){
        		component.set("v.lstProductSearch", lstProductSearch.filter(e => e.Domain_Name__c !== productLine));
            }
            if(lstProductTable != null){
                lstProductTable = lstProductTable.filter(e => e.Domain_Name__c !== productLine);
            }*/
		}else{
            /* for Product */
            var idProduct = idEvent.replace('closeProduct-', '');
        	var lstChoosenSubProd = component.get("v.lstChoosenSubProd");
            if(lstChoosenSubProd != null){
        		component.set("v.lstChoosenSubProd", lstChoosenSubProd.filter(e => e.Id !== idProduct));
            }
            if(lstProductSearch != null){
        		component.set("v.lstProductSearch", lstProductSearch.filter(e => e.Id !== idProduct));
            }
            if(lstProductTable != null){
                lstProductTable = lstProductTable.filter(e => e.Id !== idProduct);
            }
 		}
        
        if(lstProductTable != null && lstProductTable.length > 0){
            isError = false;
        }
        component.set("v.isError", isError);
        component.set("v.lstProductTable", lstProductTable);
	},
    
    /* Add product(s) into table */
    addToTable : function(component, event, helper) {
        var idEvent = event.currentTarget.id;
        var lstProductSearch = component.get("v.lstProductSearch");
        var lstProductTable = component.get("v.lstProductTable");
        var lstChoosenProdLine = component.get("v.lstChoosenProdLine");
        var lstChoosenSubProd = component.get("v.lstChoosenSubProd");
        var lstSubProduct = component.get("v.lstSubProduct");
        var currentStage = component.get("v.currentSteps");
        var stepsArray = component.get("v.stepsArray");
        
        if(currentStage == stepsArray[1] || currentStage == stepsArray[2]) {
            component.set("v.currentSteps", stepsArray[0])
        }
        
        if(idEvent.startsWith('productLine-')){
            /* for Product Line */
            /*var productLine = idEvent.replace('productLine-', '');
            var lstProduct = lstProductSearch.filter(e => e.Domain_Name__c === productLine);
            if(lstProduct != null){
                if (lstChoosenProdLine.find(e => e === productLine) == null) {
                    lstChoosenProdLine.push(productLine);
                }
                lstProduct.forEach(product =>{
                    if (lstProductTable.find(e => e.Id === product.Id) == null) {
                    	product.isChecked = false;
                        lstProductTable.push(product);
                    }
                });
    		}*/
		}else{
            /* for Product */
            var idProduct = idEvent.replace('product-', '');
            var product = lstProductSearch.find(e => e.Id === idProduct);
            if(product != null){
                // Product default selected
                if (lstProductTable.find(e => e.Id === product.Id) == null) {
                    product.isChecked = true;
                    lstProductTable.push(product);
                    lstChoosenSubProd.push(product);
                }else{
                    lstProductTable.find(e => e.Id === product.Id).isChecked = true;
                }

                component.set("v.lstSubProduct", lstSubProduct.filter(e => e.Id !== idProduct));
 			}
        }
        component.set("v.isSelectAll", false);
        component.set("v.isError", false);
        component.set("v.lstProductTable", lstProductTable);
        component.set("v.lstChoosenSubProd", lstChoosenSubProd);
        component.set("v.lstChoosenProdLine", lstChoosenProdLine);
    },
    
    /* Select or Deselect Product */
    checkboxSelect : function(component, event, helper) {
        var checkbox = event.getSource();
        var isChecked = checkbox.get("v.value");
        var idProduct = checkbox.get('v.labelClass');
        var isError = true;
        var lstProductTable = component.get("v.lstProductTable");
        lstProductTable.find(e => e.Id === idProduct).isChecked = isChecked;
        if(!isChecked){
            lstProductTable.forEach(product =>{
                if(product.isChecked){
					isError = false;
                }
            });
        }else{
			isError = false;
        }
        component.set("v.isError", isError);
        component.set("v.lstProductTable", lstProductTable);
	},
    
    /* Select all */
    selectAll : function(component, event, helper) {
        var isSelectAll = component.get("v.isSelectAll");
        var lstProductTable = component.get("v.lstProductTable");
        if(lstProductTable != null){
            lstProductTable.forEach(product =>{product.isChecked = isSelectAll});
        }else{
            component.set("v.isSelectAll", false);
        }
        component.set("v.isError", !isSelectAll);
        component.set("v.lstProductTable", lstProductTable);
	},
    
	/* Save selected products */
 	onSave : function(component, event, helper) {
        var lstProductTable = component.get("v.lstProductTable");
        var ltsIdProduct = new Array();
        //var isError = false;
        var productLevel3 = '';
        
		component.set("v.showSpinner",true);
        // 08-09-2022   ARA SP-03707 : Update Product selection module to allow multiple products from diff. Lvl3
        if(lstProductTable != null){
        	var lstProductSelected = lstProductTable.filter(e => e.isChecked === true);
            if(lstProductSelected != null){
                lstProductSelected.forEach(product =>{
                    /*// Allow only products with the same Product level 3
                    if(productLevel3 == ''){
                        productLevel3 = product.Product_Level_3__c;
                    }else if(productLevel3 != product.Product_Level_3__c){
                        isError = true;
                    }*/
                    ltsIdProduct.push(product.Id);
                });
                
                //if(!isError){
                    component.set("v.lstProductSelected", ltsIdProduct);
                    helper.addProducts(component);
                /*}else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": 'You cannot add products that have a different Product Level 3',
                        "type" : "error",
                        "mode" : "sticky"
                    });
                    toastEvent.fire();
                    component.set("v.showSpinner",false);
                }*/
        	}
       	}
	},

    goToProductCatalog : function(component, event, helper) {
        var action = component.get('c.getProductCatalog');
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
            	var result = response.getReturnValue();
                if(typeof result !== 'undefined'){
                    /*var workspaceAPI = component.find("workspace");

                    workspaceAPI.isConsoleNavigation().then(function(response) {
                        if(response){
                            workspaceAPI.getFocusedTabInfo().then(function(response) {
                                var focusedTabId = response.tabId;
                                workspaceAPI.openSubtab({
                                    parentTabId: focusedTabId,                
                                    recordId : result,
                                    focus: true
                                });          
                            })
                            .catch(function(error) {
                                console.log(error);
                            });
                        }else{
                            window.open('/' + result);
                        }
                    })
                    .catch(function(error) {
                        console.log(error);
                    });  */
                    window.open('/' + result);
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": 'No report available for Live Product',
                        "type" : "error",
                        "mode" : "sticky"
                    });
                    toastEvent.fire();
                }
            }else{
                console.log('*****state ',state);
            }
		}); 
        $A.enqueueAction(action);
	},
})