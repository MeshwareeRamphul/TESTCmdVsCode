/**
 * <b>Abstract class VFCXX_SObjectClone </b>: an abstract controllor to be used for
 * overriding clone button.
 */
public with sharing abstract class VFCXX_SObjectClone {
    //Attributs of the class VFCXX_SObjectClone
    /**
     * <b>mysObject </b>: the SObject contain inside the standard controller
     */
	protected final sObject mysObject;

    /**
     * <b>myClonedSObject </b>: the cloned SObject 
     */
    protected sObject myClonedSObject;

    // Constructors for the abstract class VFCXX_SObjectClone
    /**
     * <b>Constructor for the abstract class VFCXX_SObjectClone</b>
     * Constructor with one argument
     * @param stdController (ApexPages.StandardController) : sent by the corresponding 
     * visualforce page
     */
    public VFCXX_SObjectClone(ApexPages.StandardController stdController) {       
        //if (!Test.isRunningTest()) { 
        //    // Retrieve all contracts fields (full object to clone it)
        //    SObjectType vContractType = Schema.getGlobalDescribe().get('Opportunity');
        //    Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();
        //    List<String> vFieldsToRetrieve = new List<String>(vFields);
        //    stdController.addFields(vFieldsToRetrieve);
        //}
        //this.mysObject = (sObject)stdController.getRecord();
    }



    //Methodes for the abstract class VFCXX_SObjectClone
    /**
     * <b>Methode canBeCloned </b>: determine if the sObject can be cloned or not
     * @return Boolean : always true
     */
    public virtual Boolean canBeCloned(){
        //System.debug call for debug log purpose
        System.debug(LoggingLevel.INFO, '## VFCXX_SObjectClone.canBeCloned.start() ');

        //Return the value "True"
        return true;
    }

    /**
     * <b>Methode getCantBeClonedErrorMessage </b>: return the error message 
     * @return String : the corresponding error message
     */
    public virtual String getCantBeClonedErrorMessage(){
        return 'You cannot cloned the SObject with the following Id : ' + this.mysObject.Id;
    }

    /**
     * <b>Methode initializeClonedObject </b>: intialise the cloned object. You must override this fonction if necessary
     */
    public virtual void initializeClonedObject(){
        
    }    


    /**
     * <B>Methode cloneAction </b>: clone the SObject en return a page reference in edit mode
     * to this SObject
     * @return PageReference 
     */
    public virtual PageReference cloneAction(){
        if(this.canBeCloned()){
            this.myClonedSObject = this.mysObject.clone(false, true, false, false);
            this.initializeClonedObject();

            try {
                insert this.myClonedSObject;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical error occured : ' + e.getMessage()));
                return null;
            }

            // Redirect to the new cloned record
            return new PageReference('/' + this.myClonedSObject.Id);
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, this.getCantBeClonedErrorMessage()));
        }
        return null;
    }

    
}