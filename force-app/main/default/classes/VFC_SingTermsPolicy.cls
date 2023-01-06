public class VFC_SingTermsPolicy {
    
    public String buttonAction {get; set;}
    public String checkbox {get; set;}
    public Boolean agree {get; set;}
    public Boolean decline {get; set;}
    public String portalURL {get; set;}
    public String accId{get; set;}
    public String conId{get; set;}
    public list<User> usrLst{get; set;}
    public list<Bidder__c> bidderlst{get; set;}
    public list<cTin_LegalAcceptanceHistory__c > LAHistoryLst{get; set;}
    //Initialize the controller
    public VFC_SingTermsPolicy() {
        agree = false;
        decline = false;
        Site site = [SELECT Id FROM Site WHERE Name = :Label.Site_SupplierPortal];
        portalURL = [SELECT SecureURL FROM SiteDetail WHERE DurableId = :site.Id].SecureURL;
        usrLst=[select contactId,contact.AccountId,firstname,lastname from user where id=:UserInfo.getUserId()];
        LAHistoryLst=new list<cTin_LegalAcceptanceHistory__c >();
        if(usrLst.size()>0){
            conId=usrLst[0].contactId;
            accId=usrLst[0].contact.AccountId;
            bidderlst=[select id, Sourcing_Event__c,Contact_Bidder__c,Participant_Name__c, 
                       Sing_Account__c,Negotiation_Round__c,
            Negotiation_Round__r.Round_Status__c,
            Sourcing_Event__r.Sourcing_Status__c from Bidder__c where 
            (Sourcing_Event__r.Sourcing_Status__c!='Cancelled'
            and Sourcing_Event__r.Sourcing_Status__c!=:'Completed')
            and (Negotiation_Round__r.Round_Status__c!=:'Completed' and 
            Negotiation_Round__r.Round_Status__c!=:'Completed')
            and (Bidder_Status__c=:'Participation in Progress'
            and Contact_Bidder__c =:conId
            and Sing_Account__c=:accId)];
            }
    }

    //Handle the action of the commandLink
    public PageReference processCommandLink(){
        String redirectTo = '';
        cTin_LegalAcceptanceHistory__c LAhistory;
        User currentUser = new User(id=UserInfo.getUserId());
        if(buttonAction == 'Next_TermCondition' && agree){
            currentUser.TermsOfService__c = true;
           /*if(bidderlst.size()>0){
                for(Bidder__c bidder : bidderlst){
                      LAhistory=new cTin_LegalAcceptanceHistory__c (
                                                                  Name=usrLst[0].firstname+ ' ' +usrLst[0].lastname +' -' + ' agreed to Terms & Conditions',
                                                                  Account__c=bidder.Sing_Account__c,
                                                                  Contact__c=bidder.Contact_Bidder__c,
                                                                  SourcingEvent__c=bidder.sourcing_Event__c,
                                                                  User__c=currentUser.id,
                                                                  AgreedTermsConditions__c=true,
                                                                  AcceptanceDeclineDate__c=system.now(),
                                                                  VendorParticipant__c=bidder.id);
                       LAHistoryLst.add(LAhistory); 
                   }
                       
            }*/
            redirectTo = portalURL + '/VFP_Sing_PrivacyPolicy';
        }else if(buttonAction == 'Next_PrivacyPolicy' && agree){
            currentUser.AgreedToPolicy__c = true;
            if(bidderlst.size()>0){
                for(Bidder__c bidder : bidderlst){
                    LAhistory=new cTin_LegalAcceptanceHistory__c (Name=usrLst[0].firstname+ ' ' +usrLst[0].lastname +' -' + ' agreed to Privacy Policy',   
                                                                  Account__c=bidder.Sing_Account__c,
                                                                  Contact__c=bidder.Contact_Bidder__c,
                                                                  SourcingEvent__c=bidder.sourcing_Event__c,
                                                                  User__c=currentUser.id,
                                                                  AgreedTermsConditions__c=true,AgreedPrivacyPolicy__c=true, AcceptanceDeclineDate__c=system.now(),VendorParticipant__c=bidder.id);
                    LAHistoryLst.add(LAhistory);  
                }            
            }
           
            redirectTo = portalURL;
        }
            /*redirectTo = portalURL + '/VFP_Sing_LegalNotice';
        }else if(buttonAction == 'Finish_LegalNotice' && agree){
            currentUser.Sing_LegalNotice__c  = true;
            redirectTo = portalURL;
        }*/

        if(redirectTo == ''){
           redirectTo = portalURL + '/VFC_SingTermsPolicyDecline';
          
            if(bidderlst.size()>0){
                for(Bidder__c bidder : bidderlst){
                    LAhistory=new cTin_LegalAcceptanceHistory__c (AcceptanceDeclineDate__c=system.now(),
                                                                  Name=usrLst[0].firstname+ ' ' +usrLst[0].lastname +' -' + ' declined to Terms and Privacy Policy',                                                                
                                                                  Account__c=bidder.Sing_Account__c,
                                                                  Contact__c=bidder.Contact_Bidder__c,SourcingEvent__c=bidder.sourcing_Event__c,User__c=currentUser.id,AgreedTermsConditions__c=false, AgreedPrivacyPolicy__c=false,VendorParticipant__c=bidder.id);
                    LAHistoryLst.add(LAhistory);  
                }            
            }
        }else{
            update currentUser; 
        }
        if (LAHistoryLst.size()>0) insert LAHistoryLst;
        
        return new PageReference(redirectTo);
    }

    //Handle the action of the commandLink
    public PageReference checkTerm(){
        if(checkbox == 'agree1'){
            if(agree){
                agree = false;
            }else{
                agree = true;
            }
        }
        return new PageReference(portalURL + '/VFP_SingTermsPolicy');
    }
}