public class VFP_ImportClausesInformation {
    public Id recordId {get;set;}
	public string callfunc{get;set;}

	public VFP_ImportClausesInformation(ApexPages.StandardController controller){
        this.recordId = controller.getId();
    }

    public void importClauses(){
        List<Contract__c> lstCtr = [SELECT Id,cTin_ParentContract__c FROM Contract__c WHERE Id = :this.recordId];
        if(lstCtr.size()>0){
            Contract__c ctr =  lstCtr[0];
            if(ctr.cTin_ParentContract__c != null){
                List<Legal_Information__c> lstParentLegalInfo= [SELECT Anti_Bribery__c,Anti_Fraud_and_Record_of_Personal_Trans__c,Assignment_Clause__c,Audit_of_the_Customer__c,AXA_Company_definition__c,
                Background_Check__c,Based_on_Axa_template_YES_NO__c,/*Clause_Information_Status__c,*/clause_sustainability__c,Comments_on_documents__c,
                Compliance_critical_Outsourcing__c,Compliance_Status__c,Compliance_with_Corporate_Responsibility__c,Confidentiality__c,Conflict_of_Interest__c,
                Contract__c,contractual_requirements__c,Critical_outsourcing__c,CurrencyIsoCode,Data_Privacy_Audit_Provisions__c,Data_Privacy_International_Data_Transfe__c,
                Data_Privacy_Laws_Regulations__c,Data_Privacy_Liability__c,Data_Privacy_Mutual_Assistance__c,Data_Privacy_Personal_Data_Breaches__c,
                Data_Privacy_Qualification_of_the_Parti__c,Data_Privacy_Security_Measures__c,Data_Privacy_Status__c,Data_Privacy_sub_processors__c,Divestiture__c,
                Ethics_and_Compliance_Program__c,Exit_Clause__c,Governing_Law__c,High_risk_summary__c,Imported__c,Info_Sec__c,InfoSec_Status__c,Intellectual_Property__c,
                Invoicing_schedule_and_processes__c,Legal_Status__c,Low_no_risk_summary__c,Medium_risk_summary__c,Name,Operational_resilience__c,Operational_Resilience_Status__c,
                Price_Evolution__c,Rate_Card__c,Return_Deletion__c,Reversibility__c,Sanctions__c,Score_Anti_Bribery__c,Score_Anti_Fraud_RPT__c,Score_Assignment__c,Score_Audit__c,
                Score_Background_Check__c,Score_Compliance_critical_Outsourci__c,Score_Compliance_with_Corporate_Respon__c,Score_Confidentiality__c,Score_Conflict_of_Interest__c,
                Score_Corp_Responsibility__c,Score_Data_Privacy_International_Data__c,Score_Data_Privacy_Laws_Regulation__c,Score_Data_Privacy_Liability__c,
                Score_Data_Privacy_Mutual_Assistance__c,Score_Data_Privacy_Personal_Data_Brea__c,Score_Data_Privacy_Processing_only_on__c,Score_Data_Privacy_Security_Measures__c,
                Score_Data_Privacy_sub_processors__c,Score_Divestiture__c,Score_Ethics_and_Compliance_Program__c,Score_Exit_Clause__c,Score_Governing_Law__c,Score_Info_Sec__c,
                Score_Intellectual_Property__c,Score_Invoicing_schedule_and_processes__c,Score_Liability__c,Score_Operational_Resilience__c,Score_Price_Evolution__c,
                Score_Qualification_of_the_Parties__c,Score_Rate_Card__c,Score_Return_Deletion__c,Score_Reversibility__c,Score_Sanctions__c,Score_sla_penalty__c,Score_Sub_contracting__c,
                Score_Sub_licensing__c,Score_Sustainability__c,Score_Termination__c,Score_Whistleblowing__c,Security_Risk_Assessment_VISCA_Level__c,SLA_Penalty__c,
                Standard_clause_Anti_Bribery__c,Standard_clause_Anti_Fraud_RPT__c,Standard_clause_Assignment__c,Standard_clause_Audit__c,Standard_clause_Background_Check__c,
                Standard_clause_Confidentiality__c,Standard_clause_Conflict_of_Interest__c,Standard_clause_Corp_Responsibility__c,Standard_clause_Data_Privacy_Liability__c,
                Standard_clause_Data_Privacy_Mutual_As__c,Standard_clause_Divestiture__c,Standard_clause_DP_Laws_Regulations__c,Standard_clause_DP_Security_Measures__c,
                Standard_clause_Ethics_and_Compliance__c,Standard_clause_Info_Sec__c,Standard_clause_Intellectual_Property__c,Standard_clause_Intern_Data_Transfer__c,
                Standard_clause_Liability__c,Standard_clause_Operational_Resilience__c,Standard_clause_Personal_Data_Breaches__c,Standard_clause_Return_Deletion__c,
                Standard_clause_Reversibility__c,Standard_clause_Sanctions__c,Standard_clause_SLA_Penalty__c,Standard_clause_Sub_contracting__c,Standard_clause_Sub_licensing__c,
                Standard_clause_Sub_Processors__c,Standard_clause_Termination__c,Standard_clause_Whistleblowing__c,Status_compliance__c,Status_data_privacy__c,Status_infosec__c,
                Status_legal__c,Status_opresilience__c,Sub_contracting__c,Sub_licensing__c,Sustainability__c,Termination__c,Whistleblowing__c,Liability__c 
                FROM Legal_Information__c 
                WHERE Contract__c = :ctr.cTin_ParentContract__c];
                if(lstParentLegalInfo.size()>0){
                    List<Legal_Information__c> lstlegalInfo = new List<Legal_Information__c>();
                    for(Legal_Information__c legalInfo : lstParentLegalInfo){
                        Legal_Information__c li = legalInfo.clone(false, true, false, false); //Deep clone
                        li.Contract__c = ctr.Id;
                        li.Imported__c = true;
                        lstlegalInfo.add(li);
                    }
                    
                    List<Legal_Information__c> lstlegalInfoImported= [SELECT Id FROM Legal_Information__c WHERE Contract__c = :ctr.Id AND Imported__c = true];
                    if(lstlegalInfoImported.size()>0){
                        delete lstlegalInfoImported;
                    }
                    try{
                        insert lstlegalInfo;
                        showToast(Label.Success_LegalClausesImported,'Success');
                    }catch(Exception e){showToast(e.getMessage(),'Error');}
                }
                else{
                    showToast(Label.Error_NoLegalClauseAvailable,'Error');
                }
            }else{
                showToast(Label.Error_NoParentContract,'Error');
            }
        }else{
            showToast(Label.Error_ErrorDuringProcess,'Error');
        }
    }

    public void showToast(String message, String type){
        this.callfunc = '<script> showToast("'+message+'","'+type+'"); </script>';
    }
}