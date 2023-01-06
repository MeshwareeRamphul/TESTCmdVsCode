/**
 * @description       : 
 * @author            : SCHSO
 * @group             : 
 * @last modified on  : 12-05-2021
 * @last modified by  : SCHSO
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   12-02-2021   SCHSO   Initial Version
**/
public without sharing class VFC_ValidateParticipation {
    public  String urlvalue{get; set;}

    public VFC_ValidateParticipation() {
        urlvalue = ApexPages.currentPage().getParameters().get('id');
    }
    
    //accept to participate
    public  PageReference accept(){
        PageReference pg;

        List<Bidder__c> lstBidder = new List<Bidder__c>();

        for(Bidder__c b : [SELECT Id, Bidder_Status__c, Participant_Name__c, Sourcing_Event__c, Sourcing_Event__r.Sourcing_Status__c FROM Bidder__c WHERE Id = :urlvalue LIMIT 1]){
            if(b.Sourcing_Event__r.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PREPARATION_IN_PROGRESS){
                b.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_CONFIRMED;
            }else if(b.Sourcing_Event__r.Sourcing_Status__c == AP_Constant.SOURCING_EVENT_STATUS_PUBLISHED){
                Negotiation_Round__c round = [SELECT Id, Round_Status__c FROM Negotiation_Round__c WHERE Sourcing_Event__c = :b.Sourcing_Event__c AND Round_Status__c = :AP_Constant.ROUND_STATUS_IN_PROGRESS LIMIT 1];
                if(round != null){
                    b.Negotiation_Round__c = round.Id;
                }
                b.Bidder_Status__c = AP_Constant.PARTICIPANT_STATUS_PARTICIPATIONINPROGRESS;
            }
            lstBidder.add(b);
        }

        if(lstBidder.size() > 0){
            update lstBidder;    
        }
        
        // pg=new PageReference('https://axags--esourcing--c.visualforce.com/apex/VFP_AcceptParticipation');
        pg = new PageReference('/apex/VFP_AcceptParticipation');
        return pg;
    }

    //decline the participation
    public  PageReference decline(){
        PageReference pg;

        List<Bidder__c> lstBidder = new List<Bidder__c>();

        for(Bidder__c b : [SELECT Id, Bidder_Status__c, Participant_Name__c,Contact_Bidder__r.cTin_RelatedUser__r.LanguageLocaleKey,Sourcing_Event__r.Name,TECH_ParticipantName__c,Contact_Bidder__r.cTin_RelatedUser__r.username,Contact_Bidder__c,Sourcing_Event__r.owner.name,Sourcing_Event__r.owner.email FROM Bidder__c WHERE Id = :urlvalue LIMIT 1]){
            b.Bidder_Status__c = 'Declined';
            lstBidder.add(b);
        }

        if(lstBidder.size() > 0){
            update lstBidder; 
            AP75_ManageNotificationSE_ctin.sendNotifDecline(lstBidder);     
        }

        // pg=new PageReference('https://axags--esourcing--c.visualforce.com/apex/VFP_DeclineParticipation');
        pg = new PageReference('/apex/VFP_DeclineParticipation');
        return pg;
    }


}