/**
 * <b>Class VFC21_OpportunityClone </b>: controller for the opportunity clone action
 * @version 1.0
 * @author Eric Wartelle; updates : Urvashi Sadasing
 */
public with sharing class VFC21_OpportunityClone extends VFCXX_SObjectClone {
	//Attributs 
	/**
	 * <b>standardController </b>: the controller send by the visual force page
	 */
	public ApexPages.StandardController standardController {get; set;}

	//Constructors
	/**
	 * <b>Constructors of the VFC21_OpportunityClone</b>
	 * Constructors with one argument
	 * @param standardController (ApexPages.StandardController)
	 */
	public VFC21_OpportunityClone(ApexPages.StandardController standardController) {
		super(standardController);
		if (!Test.isRunningTest()) { 
            // Retrieve all contracts fields (full object to clone it)
            SObjectType vContractType = Schema.getGlobalDescribe().get('Opportunity');
            Set<String> vFields = vContractType.getDescribe().fields.getMap().keySet();
            List<String> vFieldsToRetrieve = new List<String>(vFields);
            standardController.addFields(vFieldsToRetrieve);
        }
        this.mysObject = (sObject)standardController.getRecord();
	}

	//Methods
	/**
	 * <b>Methods initializeClonedObject</b>: see the abstract class for more informations. 
	 */
	public override void initializeClonedObject(){

		map<String, RecordType> mapOppRecTypes = new map<String, RecordType>();

		for (RecordType recType : [SELECT id, DeveloperName
								     FROM RecordType
								    WHERE SobjectType = 'Opportunity']){
			mapOppRecTypes.put(recType.Id, recType);
			mapOppRecTypes.put(recType.DeveloperName, recType);
		}

		map<String,String> mapOppMapping = new map<String,String>();
		mapOppMapping.put('All_In_Stage_Closed', 'All_In_Opty'); //Full Opportunity Contract Process - Read-Only => Full Opportunity Contract Process
		mapOppMapping.put('All_In_Oppty_Only_Read_Only', 'All_In_Light'); //Opportunity Only Process - Read-Only => Opportunity Only Process

		map<String,String> mapServicesEntityMapping = new map<String,String>();
		mapServicesEntityMapping.put('AXA GS France', 'AXA Services France');
		mapServicesEntityMapping.put('AXA GS Asia', 'AXA Services Asia');
		mapServicesEntityMapping.put('AXA GS UK', 'AXA Services UK');
		mapServicesEntityMapping.put('AXA GS Spain', 'AXA Services Spain');
		mapServicesEntityMapping.put('AXA GS Portugal', 'AXA Services Portugal');
		mapServicesEntityMapping.put('AXA GS Switzerland', 'AXA Services Switzerland');
		mapServicesEntityMapping.put('AXA GS Germany', 'AXA Services Germany');

		//2018/07/31 : USA : comment to remove hardcoding of ID
		//if(this.mySObject.get('RecordTypeId') == '01224000000FKReAAO'){  
		//	this.myClonedSObject.put('RecordTypeId','01224000000QmkgAAC');
		//}
		//else if(this.mySObject.get('RecordTypeId') == '01224000000FKRdAAO'){ 
		//	this.myClonedSObject.put('RecordTypeId','01224000000FKRcAAO'); 	
		//}
		String strRecTypeId = String.valueOf(this.mySObject.get('RecordTypeId'));
		if(mapOppRecTypes.containsKey(strRecTypeId)){
			if (mapOppMapping.containsKey(mapOppRecTypes.get(strRecTypeId).DeveloperName) && (mapOppRecTypes.containsKey(mapOppMapping.get(mapOppRecTypes.get(strRecTypeId).DeveloperName)))){
				this.myClonedSObject.put('RecordTypeId',mapOppRecTypes.get(mapOppMapping.get(mapOppRecTypes.get(strRecTypeId).DeveloperName)).Id);
			}
		}

		this.myClonedSObject.put('stageName', AP_Constant.STAGE_LEADS_GATHERING);
		this.myClonedSObject.put('Name', 'NEW_OPPORTUNITY');
		this.myClonedSObject.put('TECH_HaveContract__c', false);
		this.myClonedSObject.put('TECH_Assignment_done__c', false);
		this.myClonedSObject.put('TECH_ContractStatus__c', '');
		this.myClonedSObject.put('Probability', 10.0);

		String strServicesEntity = String.valueOf(this.mySObject.get('AXA_GO_Entity__c'));
		if(mapServicesEntityMapping.containsKey(strServicesEntity)){
			this.myClonedSObject.put('AXA_GO_Entity__c', mapServicesEntityMapping.get(strServicesEntity));
		}
	}
}