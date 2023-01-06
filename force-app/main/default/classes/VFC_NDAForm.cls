public class VFC_NDAForm{

    public string email { get; set; }
    public string errorMsg{get;set;}
    
    public VFC_NDAForm(){
      email='';
      errorMsg ='';      
     
    }
    
    public pagereference acceptNda(){
   
    Pagereference pg;
      if(email!=''){
          list<Contact> lstCon=[select id from contact where email =:email limit 1];
          list<Bidder__c> lstBidder=new list<Bidder__c>();
          
          if(lstCon.size()>0){
          
              for(Bidder__c bidder: [select id,Sourcing_Event__c 
                                  from Bidder__c 
                                  where Contact_Bidder__c=:lstCon[0].id and Bidder_Status__c=:'Contacted']){
                bidder.Bidder_Status__c='NDA Signed';
                lstBidder.add(bidder);
                }
          }
          
          if(lstBidder.size()>0){
              update lstBidder;
          }
                   
          
        //   pg=new pagereference('https://axags--esourcing--c.visualforce.com/apex/VFP_ThankYou');
        pg = new PageReference('/apex/VFP_ThankYou');
      }
      else{
          errorMsg ='Please enter your email address before clicking on agree / disagree';
          pg=null;
      }
      
        return pg;
    }
     
    public Pagereference declineNDA(){
    Pagereference pg;
   
        if(email!=''){
              list<Contact> lstCon=[select id from contact where email =:email limit 1];
              list<Bidder__c> lstBidder=new list<Bidder__c>();
              
              if(lstCon.size()>0){
              
                  for(Bidder__c bidder: [select id,Sourcing_Event__c 
                                      from Bidder__c 
                                      where Contact_Bidder__c=:lstCon[0].id and Bidder_Status__c=:'Contacted']){
                    bidder.Bidder_Status__c='Declined';
                    lstBidder.add(bidder);
                    }
              }
              
              if(lstBidder.size()>0){
                  update lstBidder;
              }
              
            //   pg=new pagereference('https://axags--esourcing--c.visualforce.com/apex/VFP_ThankYouDecline');
            pg = new PageReference('/apex/VFP_ThankYouDecline');
          }
          else{
              errorMsg ='Please enter your email address before clicking on agree / disagree';
              pg=null;
          }
          return pg;
     }
 


}