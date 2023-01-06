public class VFC34_AmendContract {
    /*
    ----------------------------------------------------------------------
    -- - Name          : VFC34_AmendContract
    -- - Author        : Spoon Consulting 
    -- - Description   : full clone of parent contract that will be copied
                                             
    --                                       
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 14-JAN-2016  RLA    1.0      Intitial version
    -- 02-FEB-2017  MRA    1.1      Clone field 'date of risk assessment' w.r.t to new VR rule implemenented
    -- 23-OCT-2017  HVA    1.2      Reworked - All In merge contract In 
    -- 05-DEC-2019  MRA    1.3      Re-adpted class for reuse in LEX
    -- 02-JUN-2021  MRA    1.4      check confidential to team members if owner entity equals ABCL
    -- 16-JUN-2021  MRA    1.5      Do not copy tacit renewal info if one of the fields are not filled (SP-02014)
    -- 22-JUN-2021  MRA    1.6      Copy only buyer in charge (contract owner) from team member(SP-01860)
    ----------------------------------------------------------------------
    **********************************************************************
    */
    
        public Id contractId {get; set;}
        public boolean isSuccess {get; private set;}
        public Contract__c newContract {get; private set;}
        public string role_legal_rep;
        public string role_business_owner;
        public Contract__c oldContract;
        public list<cTin_LegalEntity__c> legalEntityList;
        public list<cTin_ContractTeam__c> contractTeamList;
        public list<cTin_Location__c> locationList;
    
        //LEX variables 
        public boolean isLex{get;set;}
        public string cloneErr{get;set;}
    
        //05-DEC-2019:constructor for classic
        public VFC34_AmendContract(ApexPages.StandardController stdController) {
            isLex=false;        
            cloneErr='';
            role_legal_rep = '009';
            role_business_owner = '016';
            this.isSuccess = false;
            this.contractId = stdController.getId();
            init();
        }
    
        //05-DEC-2019:constructor for LEX
        public VFC34_AmendContract(string contractId) {
            isLex=true;
            cloneErr='';
            role_legal_rep = '009';
            role_business_owner = '016';
            this.isSuccess = false;
            this.contractId = contractId;
            init();
        }
    
        public void init() {
        
            oldContract = [SELECT id, recordtypeId,
                                       cTin_TacitRenewalType__c,cTin_TacitRenewalTimeframe__c,
                                       Name,
                                       Status__c,
                                       cTin_TypeOfDocument__c,
                                       cTin_ParentContract__c,
                                       cTin_Confidential__c,
                                       cTin_ContractSegment__c,
                                       cTin_BusinessOwner__c,
                                       cTin_Owner__c, 
                                       cTin_MainAPCL0__c,
                                       cTin_MainAPCL1__c,
                                       cTin_MainAPCL2__c,
                                       cTin_MainAPCL3__c,
                                       cTin_SecondaryAPCL2__c,
                                       cTin_eSourcingReferenceId__c,
                                       cTin_LegacyId__c,
                                       LinkToDocument__c,
                                       /*cTin_ShortDescription__c,*/
                                       cTin_KeyPoints__c,
                                       cTin_OrganizationalScope__c,
                                       /*cTin_CompleteDescription__c,*/
                                       cTin_CommentsLong__c,
                                       cTin_GeographicalScope__c,
                                       StartDate__c,
                                       EndDate__c,
                                       cTin_EarlyTerminationDate__c,
                                       cTin_Unlimited__c,
                                       cTin_TacitRenewal__c,
                                       cTin_SignatureDate__c,
                                       /*cTin_Reminder__c,*/
                                       /*cTin_NoticePeriodForTermination__c,*/
                                       cTin_RetentionPeriod__c,
                                       cTin_TacitRenewalComments__c,
                                      /* Contract_Value_excl_VAT__c,*/
                                       cTin_CommittedPartExclVAT__c,
                                       cTin_OptionalPartExclVAT__c,
                                       CurrencyIsoCode,
                                       cTin_SpecificTerms__c,
                                       cTin_SpecificTermsComments__c,
                                       cTin_SpecificTermsCommentsLong__c,
                                       cTin_AXAMainLegalSignatoryEntity__c,
                                       cTin_AXASignatoryRepresentative__c,
                                       cTin_ExternalThirdPartyCheckbox__c,
                                       cTin_ExternalThirdParty__c,
                                       cTin_OtherAXASignatoryEntityPicklist__c,
                                       cTin_OtherAXASignatoryEntity__c,
                                       cTin_SupplierAccount__c,
                                       /*cTin_SupplierSignatoryRepresentative__c,*/
                                       cTin_AntiBriberyClause__c,
                                       cTin_AntiBriberyComments__c,
                                       /*cTin_CRClause__c,*/
                                       cTin_CRClauseComments__c,
                                       cTin_DataPrivacyClause__c,
                                       cTin_DataPrivacyComments__c,
                                       cTin_LiabilityClause__c,
                                       cTin_LiabilityLimits__c,
                                       cTin_OutsourcingStandards__c,
                                       cTin_OutsourcingStandardsComments__c,
                                       cTin_ProcurementInvolvementGrade__c,
                                       cTin_FairTransparentSelectionProcess__c,
                                       cTin_SupplierAcceptsUNGlobalCompact__c,
                                       cTin_SupplierSelectionComments__c,
                                       cTin_TerminationClause__c,
                                       cTin_TerminationComments__c,
                                       cTin_UNGlobalCompactcomments__c,
                                       cTin_AgreementDate__c,
                                       //cTin_AgreementDateYYYYMMDD__c,
                                       cTin_AgreementBeforeAuthority__c,
                                       cTin_AnnualReportingToTransfer__c,
                                       cTin_APC__c,
                                       /*cTin_Art102AgreementBeforeArt41__c,*/
                                       cTin_AuthorizationDocument__c,
                                       cTin_AutoRenewal__c,
                                       cTin_AXAContractTemplate__c,
                                       cTin_AXALogoNameClause__c,
                                       cTin_AXALogoNameClauseComments__c,
                                       cTin_BenefitsYear1__c,
                                       cTin_BoDApprovalDate__c,
                                       //cTin_BoDApprovalDateYYYYMMDD__c,
                                       cTin_BusinessContinuityByWhom__c,
                                       cTin_BusinessContinuityDate__c,
                                       cTin_BusinessRequester__c,
                                       cTin_CADApproval__c,
                                       cTin_CASS__c,
                                       cTin_CASSComments__c,
                                       cTin_CharacterOfSourcing__c,
                                       cTin_CharacterOfSourcingComments__c,
                                       cTin_CommittedSpentAmount__c,
                                       cTin_ContractDuration__c,
                                       cTin_ContractObject__c,
                                       cTin_ContractTotalBenefits__c,
                                       cTin_CountMandate__c,
                                       cTin_DataOwner__c,
                                       //cTin_CRDateBeforeCNSF__c,
                                       //cTin_CRDateBeforeCNSFYYYYMMDD__c,
                                       cTin_AuthorizationDate__c,
                                       //cTin_AuthorizationDateYYYYMMDD__c,
                                       cTin_ContractExecutionDate__c,
                                       //cTin_ContractExecutionDateYYYYMMDD__c,
                                       cTin_DateEndRelation__c,
                                       cTin_TerminationDate__c,
                                       //cTin_TerminationDateYYYYMMDD__c,
                                       cTin_OtherServicesDescription__c,
                                       cTin_DifferenceCommittedPart__c,
                                       cTin_DifferenceOptionalPart__c,
                                       //cTin_DirectTaxesIRCIRS__c,
                                       cTin_DocumentExecution__c,
                                       cTin_ExitPlan__c,
                                       cTin_FCAPRANotificationByWhom__c,
                                       cTin_FCAPRANotificationDate__c,
                                       cTin_FinancialCheck__c,
                                       cTin_FinancialCheckDate__c,
                                       cTin_FinancialComments__c,
                                       //cTin_FinancialConditionsComments__c,
                                       cTin_GroupOfContract__c,
                                       cTin_GroupsOfContractsForSharing__c,
                                       /*cTin_HasAXAEntityADTWithThatState__c,*/
                                       cTin_HaveAnyConcernsRaisedBeenAddressed__c,                                       
                                       cTin_IFCRelevant__c,
                                       cTin_IndefiniteTerminationDate__c,
                                       //cTin_IndefiniteTerminationDateTrue__c,
                                       cTin_IndemnityClause__c,
                                       cTin_IndemnityClauseComments__c,
                                       cTin_CriticalityRating__c,
                                       cTin_FullHealthCheckRequired__c,
                                       cTin_OperationsWithinAXAGroup__c,
                                       cTin_ResidentDomesticProviderNotSubject__c,
                                       cTin_ResidentWithholding__c,
                                       //cTin_LegalExpiryDate__c,
                                       cTin_LocalRetentionPeriod__c,
                                       cTin_Location__c,
                                       cTin_MainAPCDetailedCategory__c,
                                       cTin_MasterReference__c,
                                       cTin_MaterialityRating__c,
                                       cTin_MaterialityRatingDate__c,
                                       cTin_Mega__c,                                       
                                       cTin_NotificationtoAXAGroup__c,
                                       cTin_NumberOfContractModel__c,
                                       cTin_OtherClause__c,
                                       cTin_ParentContractReference__c,
                                       //cTin_ParentSupplierName__c,
                                       cTin_PaymentTerm__c,
                                       cTin_PaymentTermIfOther__c,
                                       cTin_PaymentTerms__c,
                                       cTin_PED__c,
                                       cTin_PEDNumber__c,
                                       cTin_PhysicalLocation__c,
                                       cTin_POBPONumber__c,
                                       cTin_ProcurementInvolvementGradeComments__c,
                                       cTin_ProcurementValueContribution__c,
                                       cTin_ProductKey__c,
                                       //cTin_ProductKeyKey__c,
                                       cTin_ProjectName__c,
                                       cTin_ReceivedVia__c,
                                       cTin_RiskAssessment__c,
                                       cTin_RiskAssessmentComments__c,
                                       cTin_SavingsType__c,
                                       cTin_SecondaryAPCDetailedCategory__c,
                                       /*cTin_ServiceProviderDesignation__c,*/
                                       cTin_SourcingDomain__c,
                                       //cTin_StampDuty__c,
                                       cTin_SubContractingSolvencyII__c,
                                       //cTin_SubProductKey__c,
                                       //cTin_SubProductKeyKey__c,
                                       cTin_AmountType__c,
                                       cTin_TypeOfDocumentIfOther__c,
                                       cTin_TypeOfDocumentL2__c,
                                       cTin_TypeOfDocumentL3__c,
                                       cTin_ServiceType__c,
                                       //cTin_ServiceTypeKey__c,
                                       cTin_VATExemption__c,
                                       cTin_VATOperation__c,
                                       cTin_SingleSourcingRisksComments__c,
                                       cTin_AreSingleSourcingRisksIdentified__c,
                                       cTin_SourcingDecision__c,
                                       cTin_OutsourcingCriticalityAssessment__c,
                                       cTin_DateofRiskAssessment__c,
                                      /* Sourcing_Request__c,
                                      cTin_VRFCriticality__c,*/cTin_VRFCriticalityComments__c,/*cTin_ReputationRisk__c,*/
                                       cTin_ReputationConcernComments__c,cTin_FinancialHealthRisk_Comments__c,cTin_FinancialHealthRiskRating__c,cTin_ComplianceRiskRating__c,cTin_ComplianceRiskComments__c,
                                       cTin_OpReRiskRatingComments__c,cTin_OperationalResilienceRiskRating__c,cTin_InfoSecRiskRating__c,cTin_InfoSecRiskRatingComments__c,cTin_DataPrivacyRisk__c   
                                FROM Contract__c
                                WHERE Id = :contractId];
    
            legalEntityList = [SELECT Id,
                                           cTin_Active__c,
                                           cTin_Contract__c,
                                           cTin_Entity__c,
                                           cTin_Mandate__c,
                                           cTin_Organization__c
                                    FROM cTin_LegalEntity__c
                                    WHERE cTin_Contract__c = :this.contractId];
            
            contractTeamList = [SELECT Id,
                                            cTin_GroupMember__c,
                                            cTin_ApprovalOrder__c,
                                            cTin_Active__c,
                                            cTin_Contract__c,
                                            cTin_ContractAccessLevel__c,
                                            cTin_Role__c,
                                            cTin_TeamMember__c
                                    FROM cTin_ContractTeam__c
                                    WHERE cTin_Contract__c = :this.contractId
                                      AND (cTin_Role__c = '000')
                                    ORDER BY cTin_ApprovalOrder__c];
    
            locationList = [SELECT Id,
                                        cTin_City__c,
                                        cTin_Contract__c,
                                        cTin_Country__c,
                                        cTin_Entity__c,
                                        cTin_Location__c,
                                        cTin_Street__c
                                FROM cTin_Location__c
                                WHERE cTin_Contract__c = :this.contractId];
        }
    
        public void InsertContractAndRelatedLists(){
    
            // preserve Id = false, deep clone = true, preserve timestamp = false
            Savepoint sp = Database.setSavepoint();
            if(oldContract != null){
                list<cTin_LegalEntity__c> newLegalEntityList = new list<cTin_LegalEntity__c>();
                list<cTin_ContractTeam__c> newContractTeamList = new list<cTin_ContractTeam__c>();
                list<cTin_Location__c> newLocationList = new list<cTin_Location__c>();
                newContract = this.oldContract.clone(false, true, false);
    
                //map of key and ContractTeam
                list<cTin_ContractTeam__c> tempContractTeamList = new list<cTin_ContractTeam__c>();
                map<String,cTin_ContractTeam__c> mapKeyContractTeam = new map<String, cTin_ContractTeam__c>();
                string key;
    
                //newContract.Name = label.cTin_AmendName + ' '+oldContract.Name;
    
                System.debug('>### newContract.Name '+newContract.Name);
                
                newContract.cTin_TypeOfDocument__c = label.cTin_AmendTypeOfDoc; 
                newContract.status__c = label.cTin_amendStatus;
                newContract.ownerId = userInfo.getUserId();
                newContract.cTin_ParentContract__c = oldContract.Id; //oldContract.ParentContract__c;    ##Should NJA: Id of old contract
                newContract.cTin_LegacyId__c = ''; 
                newContract.LinkToDocument__c= ''; 
                newContract.cTin_SignatureDate__c = NULL;
                newContract.StartDate__c = NULL;
                newContract.EndDate__c = NULL;
                newContract.cTin_EarlyTerminationDate__c = NULL;
                newContract.cTin_Unlimited__c = false;
                newContract.cTin_TacitRenewal__c = false;
                newContract.cTin_CommittedPartExclVAT__c = NULL;
                newContract.cTin_OptionalPartExclVAT__c = NULL;
                newContract.cTin_isDuplicateInProgress__c = true;
                newContract.cTin_VRFCriticality__c='';
                newContract.cTin_ReputationRisk__c='';
                newContract.cTin_Reminder__c = '';
                newContract.recordtypeId=oldContract.recordtypeId;
                
                /* MRA 14/07 - SP-01860 - do not copy legal rep and business owner*/
                //newContract.cTin_BusinessOwner__c  =null;   
                newContract.cTin_AXASignatoryRepresentative__c=null;
                //newContract.cTin_AXAMainLegalSignatoryEntity__c =null;
                //MRA: 02-jun-2021
                list<User> currUser=[select id,cTin_EntityLocalCode__c from user where id=:userInfo.getUserId()];
                if(currUser[0].cTin_EntityLocalCode__c =='ABCL') newContract.cTin_Confidential__c =true; 
                
                 //16-JUN-2021 : MRA - do not copy tacit renewal info if one of the fields are not filled (SP-02014)
                if(string.isblank(oldContract.cTin_TacitRenewalType__c) || string.isblank(oldContract.cTin_TacitRenewalTimeframe__c)){
                    newContract.cTin_TacitRenewalType__c='';
                    newContract.cTin_TacitRenewalTimeframe__c='';
                    newContract.cTin_TacitRenewal__c=false;
                }
    
    
                if(this.contractTeamList.size()>0){
                    tempContractTeamList = this.contractTeamList.deepClone();
                } 
    
                map<String,Group> existingGroupMap = new map<String,Group>();
                for(Group g :[Select Name , Type from Group]){
                    existingGroupMap.put(g.Name, g);
                }
    
                System.debug('@@@ existingGroupMap '+existingGroupMap);
    
                for(cTin_ContractTeam__c ct : tempContractTeamList){
                    System.debug('@@@ ct.cTin_GroupMember__c '+ct.cTin_GroupMember__c);
    
                    if(ct.cTin_GroupMember__c != null && ct.cTin_GroupMember__c.trim() != ''){
                        
                        if(existingGroupMap.containsKey(ct.cTin_GroupMember__c)){
                            key = ct.cTin_GroupMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                            mapKeyContractTeam.put(key,ct);
                        }
                    }
    
                    if(ct.cTin_TeamMember__c != null) {
                        key = ct.cTin_TeamMember__c+'-'+ct.cTin_Role__c+'-'+ct.cTin_ApprovalOrder__c;
                        mapKeyContractTeam.put(key,ct);
                    }
                }
    
                if(legalEntityList.size()>0){
                    newLegalEntityList = legalEntityList.deepClone();
                }
                
                if(locationList.size()>0){
                    newLocationList = locationList.deepClone();
                }
    
                try{
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
                    
                    for(cTin_LegalEntity__c le : newLegalEntityList){
                        le.cTin_Contract__c = newContract.Id;
                    }
    
                    //retrieve values AXASignatoryRepresentative user id 
                    Contract__c c1 = [SELECT cTin_AXASignatoryRepresentative__r.cTin_RelatedUser__c,
                                             cTin_BusinessOwner__c
                                        FROM Contract__c
                                        WHERE Id = :newContract.Id];
    
                    // filter business owner and legal rep from contract team member
                    for(cTin_ContractTeam__c ct : mapKeyContractTeam.values()){ 
    
                        /*if((ct.cTin_Role__c <> role_legal_rep)){
                            if((ct.cTin_Role__c <> role_business_owner)){
                                ct.cTin_Contract__c = newContract.Id;
                                newContractTeamList.add(ct);
    
                            }else{
                                
                                if((ct.cTin_Role__c == role_business_owner) && (ct.cTin_TeamMember__c <> c1.cTin_BusinessOwner__c)){
                                    ct.cTin_Contract__c = newContract.Id;
                                    newContractTeamList.add(ct);
                                }else if(ct.cTin_ApprovalOrder__c <> 'Not in Approval Process'){
                                    ct.cTin_Contract__c = newContract.Id;
                                    newContractTeamList.add(ct);
                                }
                            }
                            
                        }else{
                            if((ct.cTin_Role__c == role_legal_rep) && (ct.cTin_TeamMember__c <> c1.cTin_AXASignatoryRepresentative__r.cTin_RelatedUser__c)){
                                ct.cTin_Contract__c = newContract.Id;
                                newContractTeamList.add(ct);
                            }else if(ct.cTin_ApprovalOrder__c <> 'Not in Approval Process'){
                                ct.cTin_Contract__c = newContract.Id;
                                newContractTeamList.add(ct);        
                            }
                        }*/
                         if(ct.cTin_Role__c=='000' && ct.cTin_TeamMember__c !=userinfo.getUserId()){
                             ct.cTin_Active__c=false;                     
                             ct.cTin_Contract__c = newContract.Id;
                             newContractTeamList.add(ct);  
                         } 
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
    
                    newContract.cTin_isDuplicateInProgress__c = false;
                    this.isSuccess = true;
                    update newContract;
                }
                catch(Exception e){
                    system.debug('Kerensen e.getMessage() : ' + e.getMessage());
    
                    if(!isLex)
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Duplication Error: ' + e)); 
                    else
                        cloneErr=e.getMessage();
    
                    Database.rollback(sp);
                }
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