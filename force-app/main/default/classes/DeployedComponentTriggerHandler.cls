/*************************************************************************************
Class Name - DeployedComponentTriggerHandler
Version - 1.0
Created Date - 24 AUG 2015
Function - Class to Manage Case Changes

Modification Log :
-----------------------------------------------------------------------------
* Developer     Date        Description
* ----------    ----------  -----------------------
* Cecile L      24/08/2015  Original Version
* Urvashi S     09/01/2020  Deployed Version
*************************************************************************************/
public class DeployedComponentTriggerHandler {

    private boolean bIsExecuting = false;
    private integer iBatchSize = 0;
    public static boolean bFirstRun = true;
    public static Integer runNumber = 0;    
        
    public DeployedComponentTriggerHandler(boolean isExecuting, integer size){
        bIsExecuting = isExecuting;
        iBatchSize = size;
    }    
    
    public void OnBeforeInsert(DeployedComponent__c[] newDeployedComponents){
    }
    
    public void OnAfterInsert(DeployedComponent__c[] newDeployedComponents){
        List<DeployedComponent__c> l_DeployedComponentsToInsert = new List<DeployedComponent__c>();
        
        for(DeployedComponent__c depComp : newDeployedComponents){
            System.debug('## Here ');
            if(depComp.ComponentType__c == 'CustomField' && depComp.IsNewField__c){
                DeployedComponent__c newDepTranslate = depComp.clone(false, true);
                newDepTranslate.ComponentType__c = 'Translation';
                newDepTranslate.NeedManualDeploiement__c = TRUE;
                l_DeployedComponentsToInsert.add(newDepTranslate);
                
                DeployedComponent__c newDepSecurity = depComp.clone(false, true);
                newDepSecurity.ComponentType__c = 'Field Level Security';
                newDepSecurity.NeedManualDeploiement__c = TRUE;
                newDepSecurity.ExecuteManualTask__c = 'After Deployment (Critical)';
                l_DeployedComponentsToInsert.add(newDepSecurity);
            }
        }
        
        try{
            if(l_DeployedComponentsToInsert.size() > 0)
                insert l_DeployedComponentsToInsert;
        } catch(Exception ex){
            system.debug('###### Exception '+ex.getStackTraceString());
        }
    }
    
   
}