public without sharing class VFC35_TransactContract {
/*
// VFC_TransactContract
----------------------------------------------------------------------
-- - Name          : VFC_TransactContract
-- - Author        : Spoon Consulting 
-- - Description   : full clone of parent contract that will be copied
                                         
--                                       
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 18-JAN-2016  RLA    1.0      Intitial version
-- 02-FEB-2017  MRA    1.1      Clone field 'date of risk assessment' w.r.t to new VR rule implemenented
-- 04-DEC-2019  MRA    1.2      Re-adpted class for reuse in LEX
-- 02-JUN-2021  MRA    1.4      check confidential to team members if owner entity equals ABCL
-- 16-JUN-2021  MRA    1.5      Do not copy tacit renewal info if one of the fields are not filled (SP-02014)
-- 22-JUN-2021  MRA    1.6      Copy only buyer in charge (contract owner) from team member(SP-01860)
-- 26-APR-2022  MRA    1.7      SP-03727 - ctin Release 3 (new rules for transact)
-- 02-JUN-2022  MRA    1.8      SP-03960 - clone legal information from Master Agreement
----------------------------------------------------------------------
**********************************************************************
*/

    public Id contractId {get; set;}
    public boolean isSuccess {get; private set;}
    public Contract__c newContract {get; private set;}
    public string role_legal_rep;
    public string role_business_owner;

    public Contract__c oldContract;
    public list<cTin_LegalEntity__c> legalEntityList = new list<cTin_LegalEntity__c>();
    public list<cTin_ContractTeam__c> contractTeamList = new list<cTin_ContractTeam__c>();
    public list<cTin_Location__c> locationList = new list<cTin_Location__c>();
    public list<User> userlist = new list<User>();
    public list<cTin_Entity__c> Entitylist = new list<cTin_Entity__c>();
    public list<Legal_Information__c> lstoldLegal = new list<Legal_Information__c>();

    //LEX variables 
    public boolean isLex{get;set;}
    public string cloneErr{get;set;}

    //04-DEC-2019:constructor for classic
    public VFC35_TransactContract(ApexPages.StandardController stdController) {
        cloneErr='';
        isLex=false;
        role_legal_rep = '009';
        role_business_owner = '016';
        this.isSuccess = false;
        this.contractId = stdController.getId();
        init();
    }

    //04-DEC-2019:constructor for LEX
    public VFC35_TransactContract(string contractId) {
        cloneErr='';
        isLex=true;
        role_legal_rep = '009';
        role_business_owner = '016';
        this.isSuccess = false;
        this.contractId = contractId;
        init();
    }
        
    //public VFC35_TransactContract(ApexPages.StandardController stdController) {
        //role_legal_rep = '009';
        //role_business_owner = '016';
        //this.isSuccess = false;
        //this.contractId = stdController.getId();
    public void init(){

       
        oldContract = [SELECT id , recordtypeId,Name , Status__c , cTin_TypeOfDocument__c , cTin_ParentContract__c , cTin_Confidential__c , cTin_ContractSegment__c ,
                                    cTin_BusinessOwner__c  , cTin_MainAPCL0__c , cTin_MainAPCL1__c , cTin_MainAPCL2__c , cTin_MainAPCL3__c , cTin_SecondaryAPCL2__c ,
                                     cTin_eSourcingReferenceId__c , cTin_LegacyId__c , LinkToDocument__c, cTin_ShortDescription__c , cTin_KeyPoints__c , 
                                     cTin_OrganizationalScope__c , /*cTin_CompleteDescription__c ,*/ cTin_GeographicalScope__c , StartDate__c , 
                                     EndDate__c , cTin_EarlyTerminationDate__c , cTin_Unlimited__c , cTin_TacitRenewal__c , cTin_SignatureDate__c , /*cTin_Reminder__c , */
                                     cTin_NoticePeriodForTermination__c , cTin_RetentionPeriod__c , cTin_TacitRenewalComments__c , cTin_TotalSpendExcVAT__c , 
                                     cTin_CommittedPartExclVAT__c , cTin_OptionalPartExclVAT__c , CurrencyIsoCode , cTin_SpecificTerms__c , cTin_SpecificTermsComments__c , 
                                     cTin_SpecificTermsCommentsLong__c , cTin_AXAMainLegalSignatoryEntity__c , cTin_AXASignatoryRepresentative__c , 
                                     cTin_ExternalThirdPartyCheckbox__c , cTin_ExternalThirdParty__c , cTin_OtherAXASignatoryEntityPicklist__c , 
                                     cTin_OtherAXASignatoryEntity__c , cTin_SupplierAccount__c , /*cTin_SupplierSignatoryRepresentative__c ,*/ cTin_AntiBriberyClause__c , 
                                     cTin_AntiBriberyComments__c , /*cTin_CRClause__c ,*/ cTin_CRClauseComments__c , cTin_DataPrivacyClause__c , cTin_DataPrivacyComments__c , 
                                     cTin_LiabilityClause__c , cTin_LiabilityLimits__c , cTin_OutsourcingStandards__c , cTin_OutsourcingStandardsComments__c , 
                                     cTin_ProcurementInvolvementGrade__c , cTin_FairTransparentSelectionProcess__c , 
                                     cTin_SupplierAcceptsUNGlobalCompact__c , cTin_SupplierSelectionComments__c , cTin_TerminationClause__c , cTin_TerminationComments__c , 
                                     cTin_UNGlobalCompactcomments__c ,
                                     cTin_AgreementDate__c  ,cTin_AgreementBeforeAuthority__c  ,
                                     cTin_AnnualReportingToTransfer__c ,cTin_APC__c ,/*cTin_Art102AgreementBeforeArt41__c ,*/cTin_AuthorizationDocument__c ,cTin_AutoRenewal__c ,
                                     cTin_AXAContractTemplate__c ,cTin_AXALogoNameClause__c ,cTin_AXALogoNameClauseComments__c ,cTin_BenefitsYear1__c ,cTin_BoDApprovalDate__c ,
                                     cTin_BusinessContinuityByWhom__c ,cTin_BusinessContinuityDate__c ,cTin_BusinessRequester__c ,
                                     cTin_CADApproval__c ,cTin_CASS__c ,cTin_CASSComments__c ,cTin_CharacterOfSourcing__c ,cTin_CharacterOfSourcingComments__c ,
                                     cTin_CommittedSpentAmount__c ,cTin_ContractDuration__c ,cTin_ContractObject__c ,cTin_ContractTotalBenefits__c ,cTin_CountMandate__c ,
                                     cTin_DataOwner__c ,cTin_AuthorizationDate__c ,
                                     cTin_ContractExecutionDate__c  ,cTin_DateEndRelation__c ,cTin_TerminationDate__c ,
                                     cTin_OtherServicesDescription__c ,cTin_DifferenceCommittedPart__c ,cTin_DifferenceOptionalPart__c ,
                                     cTin_DocumentExecution__c ,cTin_ExitPlan__c ,cTin_FCAPRANotificationByWhom__c ,cTin_FCAPRANotificationDate__c ,
                                     cTin_FinancialCheck__c ,cTin_FinancialCheckDate__c ,cTin_FinancialComments__c ,cTin_GroupOfContract__c ,
                                     cTin_GroupsOfContractsForSharing__c /*,cTin_HasAXAEntityADTWithThatState__c*/ ,cTin_HaveAnyConcernsRaisedBeenAddressed__c ,
                                      cTin_IFCRelevant__c ,cTin_IndefiniteTerminationDate__c ,
                                     cTin_IndemnityClause__c ,cTin_IndemnityClauseComments__c ,cTin_CriticalityRating__c ,cTin_FullHealthCheckRequired__c ,
                                     cTin_OperationsWithinAXAGroup__c ,cTin_ResidentDomesticProviderNotSubject__c ,cTin_ResidentWithholding__c ,/*cTin_LegalExpiryDate__c ,*/
                                     cTin_LocalRetentionPeriod__c ,cTin_Location__c ,cTin_MainAPCDetailedCategory__c ,cTin_MasterReference__c ,cTin_MaterialityRating__c ,
                                     cTin_MaterialityRatingDate__c ,cTin_Mega__c ,cTin_NotificationtoAXAGroup__c ,cTin_NumberOfContractModel__c ,
                                     cTin_OtherClause__c,cTin_PaymentTerm__c ,cTin_PaymentTermIfOther__c ,
                                     cTin_PaymentTerms__c ,cTin_PED__c ,cTin_PEDNumber__c ,cTin_POBPONumber__c ,
                                     cTin_ProcurementInvolvementGradeComments__c ,cTin_ProcurementValueContribution__c ,cTin_ProductKey__c ,cTin_ProjectName__c 
                                     ,cTin_ReceivedVia__c ,cTin_RiskAssessment__c ,cTin_RiskAssessmentComments__c ,cTin_SavingsType__c ,cTin_SecondaryAPCDetailedCategory__c ,
                                     /*cTin_ServiceProviderDesignation__c ,*/cTin_SourcingDomain__c ,cTin_SubContractingSolvencyII__c ,
                                     cTin_AmountType__c ,cTin_TypeOfDocumentIfOther__c ,cTin_TypeOfDocumentL2__c ,cTin_TypeOfDocumentL3__c ,cTin_ServiceType__c ,
                                     cTin_VATExemption__c ,cTin_VATOperation__c , cTin_SingleSourcingRisksComments__c,
                                     cTin_AreSingleSourcingRisksIdentified__c , cTin_SourcingDecision__c,cTin_DateofRiskAssessment__c, cTin_TacitRenewalType__c,cTin_TacitRenewalTimeframe__c, 
                                    /* cTin_VRFCriticality__c,*/cTin_VRFCriticalityComments__c,/*cTin_ReputationRisk__c,Sourcing_Request__c,*/
                                     cTin_ReputationConcernComments__c,cTin_FinancialHealthRisk_Comments__c,cTin_FinancialHealthRiskRating__c,cTin_ComplianceRiskRating__c,cTin_ComplianceRiskComments__c,
                                     cTin_OpReRiskRatingComments__c,cTin_OperationalResilienceRiskRating__c,cTin_InfoSecRiskRating__c,cTin_InfoSecRiskRatingComments__c,cTin_DataPrivacyRisk__c,cTin_OutsourcingCriticalityAssessment__c                                  
                                     ,Sourcing_Request__c  FROM Contract__c
                                     WHERE Id = :contractId];
        userlist = [SELECT Id,cTin_Entity__c,Country 
                         FROM User
                         WHERE id = :userInfo.getUserId() 
                         LIMIT 1 ];
        if(userlist.size() > 0){
            Entitylist = [SELECT Id,cTin_Country__c
                         FROM cTin_Entity__c
                         WHERE cTin_Organization__c = :userlist[0].cTin_Entity__c 
                         LIMIT 1 ];
        }  
        
        System.debug('$$$$userlist:'+userlist);

        legalEntityList = [SELECT Id, cTin_Active__c, cTin_Contract__c, cTin_Entity__c, cTin_Mandate__c, cTin_Organization__c FROM cTin_LegalEntity__c WHERE cTin_Contract__c = :this.contractId];
        
        contractTeamList = [SELECT Id, cTin_GroupMember__c, cTin_ApprovalOrder__c, cTin_Active__c, cTin_Contract__c, cTin_ContractAccessLevel__c, cTin_Role__c, cTin_TeamMember__c 
                                FROM cTin_ContractTeam__c 
                                WHERE cTin_Contract__c = :this.contractId AND (cTin_Role__c = '000' OR cTin_TeamMember__c =:userinfo.getUserId()) Order By cTin_ApprovalOrder__c] ;
        locationList = [SELECT Id, cTin_City__c, cTin_Contract__c, cTin_Country__c, cTin_Entity__c, cTin_Location__c, cTin_Street__c FROM cTin_Location__c WHERE cTin_Contract__c = :this.contractId];
        system.debug('kerensen VF_CloneContract this.locationList.size(): ' + this.locationList.size());
        
        if(oldContract.cTin_TypeOfDocument__c=='Master Agreement'){
                //clone legal informations
                String fieldsNames = '';
                for (Schema.SObjectField sObjectField : Schema.getGlobalDescribe().get('Legal_Information__c').getDescribe().fields.getMap().values()) {
                     fieldsNames += sObjectField.getDescribe().getName() + ',';
                }
                /*lstoldLegal=Database.query(
                      'SELECT ' + fieldsNames + ' FROM Legal_Information__c Where Contract__c= ' + oldContract.Id
                );*/
                //list<Legal_Information__c>newLegalList=new list<Legal_Information__c>();
                //list<Legal_Information__c>newLegalInfoList=new list<Legal_Information__c>();
                
                // Legal_Information__c>newLegalList = this.lstoldLegal.deepClone();
                //to comment after Go live R7
                //fieldsNames=fieldsNames.removeEnd(',');
                //fieldsNames=fieldsNames.remove('OwnerId,IsDeleted,Name,CurrencyIsoCode,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,SystemModstamp,LastActivityDate,LastViewedDate,LastReferencedDate,');
                //string querystr='SELECT ' + fieldsNames + ' FROM Legal_Information__c Where Contract__c= ' +'\'' + oldContract.id + '\'';  
                //system.debug('##querystr'+querystr);
                //lstoldLegal=Database.query(querystr);
                //system.debug('##lstoldLegal'+lstoldLegal);
                
                //if(lstoldLegal.size()>0)
                  //  newLegalList=this.lstoldLegal.deepclone();
                
                /* system.debug('##newLegalList'+newLegalList);
                if(newLegalList.size()>0){
                    for(Legal_Information__c newLInfo: newLegalList){
                        Legal_Information__c l;
                        l=newLInfo;
                        newLInfo.contract__c=newContract.Id;
                        newLegalInfoList.add(newLInfo);
                        
                    }
                    insert newLegalInfoList;
                }*/
                
            
            }
    }

    public void InsertContractAndRelatedLists(){
        cloneErr='';
        // preserve Id = false, deep clone = true, preserve timestamp = false
        Savepoint sp = Database.setSavepoint();
        if(oldContract != null){
            list<cTin_LegalEntity__c> newLegalEntityList = new list<cTin_LegalEntity__c>();
            list<cTin_ContractTeam__c> newContractTeamList = new list<cTin_ContractTeam__c>();
            list<cTin_Location__c> newLocationList = new list<cTin_Location__c>();
            list<Legal_Information__c >newLegalInfoList =new list<Legal_Information__c>();
            newContract = this.oldContract.clone(false, true, false);
            //newContract.CountApprovalMember__c = 0;

            //map of key and ContractTeam
            list<cTin_ContractTeam__c> tempContractTeamList = new list<cTin_ContractTeam__c>();
            map<String,cTin_ContractTeam__c> mapKeyContractTeam = new map<String, cTin_ContractTeam__c>();
            string key;

            system.debug('kerensen VF_CloneContract newContract.CountApprovalMember__c: ' + newContract.cTin_CountApprovalMember__c);
             //26/04/2022 - cpm changesnewContract.Name = label.cTin_tranName + ' '+oldContract.Name;
            newContract.cTin_TypeOfDocument__c = label.cTin_tranTypeOfDoc;
            newContract.status__c = label.cTin_amendStatus;
            newContract.ownerId = userInfo.getUserId();
            newContract.cTin_ParentContract__c = oldContract.Id; //NJA: oldContract.ParentContract__c;
            //26/04/2022 - cpm changes newContract.cTin_BusinessOwner__c = NULL;
            newContract.cTin_LegacyId__c = ''; 
            newContract.LinkToDocument__c= ''; 
            newContract.cTin_SignatureDate__c = NULL;
            newContract.StartDate__c = NULL;
            newContract.EndDate__c = NULL;
            newContract.cTin_EarlyTerminationDate__c = NULL;
            newContract.cTin_Unlimited__c = false;
            newContract.cTin_TacitRenewal__c = false;
            //26/04/2022if(userlist.size()>0) newContract.cTin_OrganizationalScope__c = userlist[0].cTin_Entity__c;
            //26/04/2022if(Entitylist.size()>0) newContract.cTin_GeographicalScope__c = Entitylist[0].cTin_Country__c;
           //cpm changes newContract.cTin_Reminder__c = label.cTin_tranReminder;
           newContract.cTin_Reminder__c = '';
            newContract.cTin_NoticePeriodForTermination__c = NULL;
            newContract.cTin_RetentionPeriod__c = label.cTin_tranRetentionPeriod;
            newContract.cTin_TacitRenewalComments__c = '';
            newContract.cTin_CommittedPartExclVAT__c = 0;
            newContract.cTin_OptionalPartExclVAT__c = 0;
            //26/04/2022 MRA cpm changes newContract.cTin_AXAMainLegalSignatoryEntity__c = NULL;          
            newContract.cTin_OtherAXASignatoryEntity__c = '';
            newContract.cTin_OtherAXASignatoryEntityPicklist__c = 'No';
            newContract.cTin_isDuplicateInProgress__c = True;
            newContract.cTin_AXASignatoryRepresentative__c = NULL;
            newContract.cTin_VRFCriticality__c='';
            newContract.cTin_ReputationRisk__c='';
            newContract.recordtypeId=oldContract.recordtypeId;
            // to uncomment after go live R7 
            newContract.Sourcing_Request__c = null;
            //MRA: 02-jun-2021
            list<User> currUser=[select id,cTin_EntityLocalCode__c from user where id=:userInfo.getUserId()];
            if(currUser[0].cTin_EntityLocalCode__c =='ABCL') newContract.cTin_Confidential__c =true; 
            
            //16-JUN-2021 : MRA - do not copy tacit renewal info if one of the fields are not filled (SP-02014)
            if(string.isblank(oldContract.cTin_TacitRenewalType__c) || string.isblank(oldContract.cTin_TacitRenewalTimeframe__c)){
                newContract.cTin_TacitRenewalType__c='';
                newContract.cTin_TacitRenewalTimeframe__c='';
                newContract.cTin_TacitRenewal__c=false;
            }
            
            if(contractTeamList.size()>0){
                tempContractTeamList = this.contractTeamList.deepClone();
            } 

            map<String,Group> existingGroupMap = new map<String,Group>();
            for(Group g :[Select Name , Type from Group]){
                existingGroupMap.put(g.Name, g);
            }
            
         

            for(cTin_ContractTeam__c ct : tempContractTeamList){


                system.debug('## ct.GroupMember__c: '+ct.cTin_GroupMember__c);
                if(ct.cTin_GroupMember__c != null && ct.cTin_GroupMember__c.trim() != ''){
                    if(existingGroupMap.containsKey(ct.cTin_GroupMember__c)){
                        key = ct.cTin_GroupMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                        system.debug('## key: '+key);
                        mapKeyContractTeam.put(key,ct);
                    }
                }

                system.debug('## ct.TeamMember__c '+ct.cTin_TeamMember__c);
                if(ct.cTin_TeamMember__c != null) {
                    key = ct.cTin_TeamMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                    system.debug('## key: '+key);
                    mapKeyContractTeam.put(key,ct);
                }
            }
            
            system.debug('## mapKeyContractTeam '+mapKeyContractTeam);
            
            // to comment after go live R7
            if(lstoldLegal.size()>0){
                newLegalInfoList = this.lstoldLegal.deepClone();
            }
            
            if(legalEntityList.size()>0){
                newLegalEntityList = this.legalEntityList.deepClone();
            }
            
            if(locationList.size()>0){
                newLocationList = this.locationList.deepClone();
            }

            try{
                //AMA
                if(newContract != null){
                    insert newContract;
                } 
                   
                      
                /*07/09/2022- mra : commented as per request / no longer valid
                if( (oldContract.cTin_TypeOfDocument__c=='Transaction Agreement' || oldContract.cTin_TypeOfDocument__c=='Standalone Contract' 
                    || oldContract.cTin_TypeOfDocument__c=='Amendment' || oldContract.cTin_TypeOfDocument__c=='Master Agreement')){
                    //insert newContract;
                    Sourcing_Request__c srcRqt = new Sourcing_Request__c(
                        Parent_Sourcing_request__c = oldContract.Sourcing_Request__c,
                        Status__c = 'Not Started',
                        Demand_type__c = 'Amendment to master agreement/standalone contract',
                        APC_L0__c = oldContract.cTin_MainAPCL0__c,
                        APC_L1__c = oldContract.cTin_MainAPCL1__c,
                        APC_L2__c = oldContract.cTin_MainAPCL2__c,
                        APC_L3__c = oldContract.cTin_MainAPCL3__c
                    );
                    insert srcRqt;
                    system.debug(' srcRqtid'+srcRqt);
                    
                    newContract.Sourcing_Request__c = srcRqt.id;
                    
                }*/
                //
                for(cTin_LegalEntity__c le : newLegalEntityList){
                    le.cTin_Contract__c = newContract.Id;

                }

                //retrieve values AXASignatoryRepresentative user id 
                Contract__c c1 = [Select cTin_AXASignatoryRepresentative__r.cTin_RelatedUser__c, cTin_BusinessOwner__c from Contract__c where Id = :newContract.Id];

                // filter business owner and legal rep from contract team member
                for(cTin_ContractTeam__c ct : mapKeyContractTeam.values()){ //
                    /*system.debug('## ct.TeamMember__c: '+ct.cTin_TeamMember__c);
                    system.debug('## c1.BusinessOwner__c: '+c1.cTin_BusinessOwner__c);
                    system.debug('## c1.AXASignatoryRepresentative__c: '+c1.cTin_AXASignatoryRepresentative__r.cTin_RelatedUser__c);
                    system.debug('## ct.ApprovalOrder__c: '+ct.cTin_ApprovalOrder__c);
                    system.debug('## ct.Role__c: '+ct.cTin_Role__c);

                    if((ct.cTin_Role__c <> role_legal_rep)){
                        if((ct.cTin_Role__c <> role_business_owner)){
                            System.debug('@@@ 1');
                            ct.cTin_Contract__c = newContract.Id;
                            newContractTeamList.add(ct);

                        }else{
                            
                            if((ct.cTin_Role__c == role_business_owner) && (ct.cTin_TeamMember__c <> c1.cTin_BusinessOwner__c)){
                            System.debug('@@@ 2');

                                ct.cTin_Contract__c = newContract.Id;
                                newContractTeamList.add(ct);
                            }else if(ct.cTin_ApprovalOrder__c <> 'Not in Approval Process'){
                            System.debug('@@@ 3');
                                ct.cTin_Contract__c = newContract.Id;
                                newContractTeamList.add(ct);
                            }
                        }
                        
                    }else{
                        if((ct.cTin_Role__c == role_legal_rep) && (ct.cTin_TeamMember__c <> c1.cTin_AXASignatoryRepresentative__r.cTin_RelatedUser__c)){
                            System.debug('@@@ 4');
                            ct.cTin_Contract__c = newContract.Id;
                            newContractTeamList.add(ct);
                        }else if(ct.cTin_ApprovalOrder__c <> 'Not in Approval Process'){
                            System.debug('@@@ 5');
                            ct.cTin_Contract__c = newContract.Id;
                            newContractTeamList.add(ct);        
                        }
                    }*/
                    if(ct.cTin_Role__c=='000' && ct.cTin_TeamMember__c !=userinfo.getUserId()){
                        ct.cTin_Active__c=false;                   
                        ct.cTin_Contract__c = newContract.Id;
                        newContractTeamList.add(ct);  
                   }
                   else{
                        ct.cTin_Active__c=false;                   
                        ct.cTin_Contract__c = newContract.Id;
                        newContractTeamList.add(ct);
                   }
                }       
                
                system.debug('## newContractTeamList: '+newContractTeamList);
                
                
                for(Legal_Information__c leInfo : newLegalInfoList){
                    leInfo.Contract__c = newContract.Id;
                    leInfo.OwnerId=userInfo.getUserId();
                }
                
                for(cTin_Location__c loc : newLocationList){
                    loc.cTin_Contract__c = newContract.Id;
                }
                if(newLegalEntityList != null && newLegalEntityList.size()>0){
                    insert newLegalEntityList;
                }
                if(newContractTeamList != null && newContractTeamList.size()>0){
                    insert newContractTeamList;
                }
                if(newLocationList!= null && newLocationList.size()>0){
                    insert newLocationList;
                }
                if(newLegalInfoList!= null && newLegalInfoList.size()>0){
                    insert newLegalInfoList;
                }

                newContract.cTin_isDuplicateInProgress__c = false;
                this.isSuccess = true;
                update newContract;
            }
            catch(Exception e){
                system.debug('Kerensen e.getMessage() : ' + e.getMessage());

                if(!isLex){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Duplication Error: ' + e)); 
                }
                else{
                    cloneErr=e.getmessage();
                }
                Database.rollback(sp);
            }
            system.debug('kerensen newContract.status__c: ' + newContract.status__c);
        }      
    }

    //04-DEC-2019 MRA: method for LEX (returns error if any)
    public string cloneStatus(){  
        return cloneErr;
    }
    
    //04-DEC-2019 MRA: method for LEX (returns id of new contract)
    public string newContractId(){
        return newContract.id;
    }

}