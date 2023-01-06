({
	doInit: function(component, event, helper) {
        helper.getDoc(component, event, helper);
    },
    cancel: function(component, event, helper) {
    	component.set("v.ShowModule", false);
    },
    ShowModuleBox: function(component, event, helper) {
    	component.set("v.ShowModule", true);
    },
    UploadFinished : function(component, event, helper) {  
    	var uploadedFiles = event.getParam("files");  
	    var documentId = uploadedFiles[0].documentId;  
	    var fileName = uploadedFiles[0].name;  
	    helper.UpdateDocument(component,event,documentId);  
	    var toastEvent = $A.get("e.force:showToast");  
     	toastEvent.setParams({  
       		"title": "Success!",  
       		"message": "File "+fileName+" Uploaded successfully."  
     	});  
    	toastEvent.fire();
    },
    //Open File onclick event  
    OpenFile :function(component,event,helper){  
    	var rec_id = event.currentTarget.id;  
    	$A.get('e.lightning:openFiles').fire({ //Lightning Openfiles event  
    	recordIds: [rec_id] //file id
     });  
   },
})