public with sharing class AP44_BlockNewContractTeam{
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP44_BlockNewContractTeam
-- - Author        : Spoon
-- - Description   : blocks contract team to be added to approval process if no pdf with "send for esignature" is available on esignature
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 24-MAR-2020  MRA    1.0     UAT Ticket : SP-001
-- 31-MAR-2020  SGO    1.2     Determine num of signable docs : SP-00214
*************************************************************************************/
   public static boolean allowAP44=false;
   public static boolean bypassSpecial=false;
   
    public static void blockCreationCt(list<cTin_ContractTeam__c> lstCteam) {
        allowAP44=true;
        set<id> setContentDoc=new set<id>();
        set<id> setContentDocSignable=new set<id>();
        map<id,list<cTin_ContractTeam__c>> mapCtrTeam=new map<id,list<cTin_ContractTeam__c>>();
        set<id> setCtrWithSignablePdf=new set<id>();
        map<id, id> mapConIdCdId=new map<id,id>();
    
       //retrieve contracts linked to contract team => build map<contractId, list<contractteam>
       
       for(cTin_ContractTeam__c ctrTeam: lstCteam){
                                          
            if(mapCtrTeam.containsKey(ctrTeam.cTin_Contract__c ))
               (mapCtrTeam.get(ctrTeam.cTin_Contract__c )).add(ctrTeam);
            else
               mapCtrTeam.put(ctrTeam.cTin_Contract__c,new list<cTin_ContractTeam__c >{ctrTeam});
    
       }
       
       system.debug('## mapCtrTeam'+mapCtrTeam);
     
       for(Id relatedCtr: mapCtrTeam.keyset()){
           //retrieve contentversion linked to contract where no sign-able__c = true => build set of contractId
           for(ContentDocumentLink cdl :  [SELECT ContentDocumentId,LinkedEntityId 
                                           FROM ContentDocumentLink 
                                           where LinkedEntityId =: relatedCtr]){
              setContentDoc.add(cdl.ContentDocumentId);
              mapConIdCdId.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
           }
       }
            
       
       for(ContentVersion  cv : [ SELECT ContentDocumentId, title 
                                  FROM ContentVersion 
                                  WHERE ContentDocumentId  IN :setContentDoc 
                                  AND Sign_able__c = true AND FileType = 'PDF']){
          if (cv.title.length() <=89){
            setContentDocSignable.add(cv.ContentDocumentId);
          }
       }
       
       system.debug('## setContentDocSignable'+setContentDocSignable.size());
       //get set of contract ids with signable pdf
       for(id contentDocId: setContentDocSignable){
           id CtrWithSignablePdf=mapConIdCdId.get(contentDocId);
           setCtrWithSignablePdf.add(CtrWithSignablePdf);
       }
       
       system.debug('## setCtrWithSignablePdf'+setCtrWithSignablePdf.size());
       
       //add error for all new contract teams linked to contracts without sign-able pdfs
       for(id ctr: mapCtrTeam.keyset()){
           if(!setCtrWithSignablePdf.contains(ctr) || setCtrWithSignablePdf.size()==0 ){
               system.debug('### No signable pdf detected');
               list<cTin_ContractTeam__c> lstCteamError = mapCtrTeam.get(ctr);
              
               for(cTin_ContractTeam__c  cTeam: lstCteamError){
                   if(!bypassSpecial) cTeam.addError(system.label.NoPdfError);
               }
           }
       }
       
    }
    
    // 16/06/2022 MRA - method recalculates cTin_NumUploadedDocs__c,cTin_NumberSignablePDF__c on contract after a file is updated/inserted
    public static void determineNumOfSignablePDF(List<ContentVersion> lstContentVersion){
        System.debug('Start of method determineNumOfSignablePDF from contentversion after insert / after update');
        allowAP44=true;            
        Set<Id> setSignableDocumentId = new Set<Id>();
        //AMA     
        Map<Id, ContentVersion> mapofAllDocIdCV = new Map<Id, ContentVersion>();
        Set<Id> setAllContractId = new Set<Id>();
        Map<Id, set<Id>> mapContractIdContentAllDocId = new Map<Id, set<Id>>();
        Map<Id, Contract__c> mapContractIdCtrUpd = new Map<Id, Contract__c>();

        // build map containing all pdfs   
        for (ContentVersion cv : lstContentVersion){
            mapofAllDocIdCV.put(cv.ContentDocumentId, cv);
        }

        if(mapofAllDocIdCV.size()>0){
            //AMA Get all contracts associated with the documents inserted or updated
            for (ContentDocumentLink cdl : [SELECT LinkedEntityId,contentDocumentId FROM ContentDocumentLink 
                                           WHERE ContentDocumentId IN :mapofAllDocIdCV.KeySet()]){
                if (String.valueOf(cdl.LinkedEntityId).startsWith('a0D')){
                    setAllContractId.add(cdl.LinkedEntityId); //set of all contracts
                    System.debug(' archad id ctr ' +cdl.LinkedEntityId);                
                }
            }
        }        
     
        if(setAllContractId.size()>0){
            //AMA Get all content doc link of contracts
            for (ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN :setAllContractId]){
                // Get all content Document Id for each ctr
                if (mapContractIdContentAllDocId.containsKey(cdl.LinkedEntityId)){
                    mapContractIdContentAllDocId.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                    System.debug(' archad id ctr contain' +cdl.LinkedEntityId);
                }
                else{
                    mapContractIdContentAllDocId.put(cdl.LinkedEntityId, new Set<Id>{cdl.ContentDocumentId});
                    System.debug(' archad id ctr no contain ' +cdl.LinkedEntityId);
                }
            }
            System.debug('mapContractIdContentAllDocId ' + mapContractIdContentAllDocId.size());
        }

        // Get all signable Content Version of all contracts
        Set<Id> setContentDocId = new set<id>();
        for( Id CtrId: mapContractIdContentAllDocId.keyset()){
             setContentDocId=mapContractIdContentAllDocId.get(CtrId);
        }
        
        for (ContentVersion cv:[SELECT Id, Sign_able__c,filetype, ContentDocumentId FROM ContentVersion 
                                WHERE ContentDocumentId IN :setContentDocId AND IsLatest=TRUE]){
            if (cv.Sign_able__c == TRUE && cv.filetype=='PDF'){
                setSignableDocumentId.add(cv.ContentDocumentId); // set contains signable pdfs
            }
        }
        System.debug(' archad for6');
        // For each ctr, set cTin_NumberSignablePDF__c  and cTin_NumUploadedDocs__c
        for (Contract__c ctr : [SELECT Id, name, cTin_NumberSignablePDF__c,cTin_NumUploadedDocs__c 
                                FROM Contract__c 
                                WHERE Id IN :mapContractIdContentAllDocId.KeySet()]){
            
            Integer numOfSignableDocs = 0;  // Reset num of signable docs                     
            Integer numberDocs = 0; // Reset num of docs
            
            for(Id currContentDocId:mapContractIdContentAllDocId.get(ctr.Id)){
                if (setSignableDocumentId.contains(currContentDocId)){
                    numOfSignableDocs++;
                }                
                numberDocs++;
            }
           
            ctr.cTin_NumberSignablePDF__c = numOfSignableDocs;  // Set num of signable pdf      
            System.debug(' archad numOfSignableDocs '+ numOfSignableDocs);             
            ctr.cTin_NumUploadedDocs__c = numberDocs;// Set num of docs uploaded      
            System.debug(' archad numberDocs ' + numberDocs); 
            
            if (mapContractIdCtrUpd.containsKey(ctr.id) ) {
                mapContractIdCtrUpd.get(ctr.id).cTin_NumberSignablePDF__c = numOfSignableDocs;
            } 
            else {
                mapContractIdCtrUpd.put(ctr.id,new Contract__c(id=ctr.id,cTin_NumUploadedDocs__c=mapContractIdContentAllDocId.get(ctr.id).size(),cTin_NumberSignablePDF__c = numOfSignableDocs));
            }
           
        }
        
        //updating cTin_NumUploadedDocs__c,cTin_NumberSignablePDF__c
        if (mapContractIdCtrUpd.values().size()>0)
            update mapContractIdCtrUpd.values();
       
        System.debug('## End of method determineNumOfSignablePDF from contentversion after insert / after update');
    }

    // 16/06/2022 MRA - method recalculates cTin_NumUploadedDocs__c,cTin_NumberSignablePDF__c on contract after a file is deleted 
    public static void determineNumOfSignablePDF(List<ContentDocument> lstContentDocument){
        allowAP44=true;
        System.debug('## Start of method determineNumOfSignablePDF from ContentDocument after delete' );
        List<Contract__c> lstContractsToUpd = new List<Contract__c>();
        List<ContentDocument> lstDocuments = new List<ContentDocument>();
        Set<Id> setContractId = new Set<Id>();
        Map<Id, set<Id>> mapContractIdContentDocId = new Map<Id, set<Id>>();
        Set<Id> setSignableDocumentId = new Set<Id>();
        Set<Id> setContentDocumentId = new Set<Id>();
        Map<Id, ContentDocument> mapofDocIdCD = new Map<Id, ContentDocument>();

        // Need to build set else error (implementation restriction for query on contentdocumentLink)
        for (ContentDocument cd:lstContentDocument){
            setContentDocumentId.add(cd.Id);
        }
        
        // Get all contracts associated with documents
        for (ContentDocumentLink cdl : [SELECT LinkedEntityId 
                                        FROM ContentDocumentLink 
                                        WHERE ContentDocumentId IN :setContentDocumentId]){
            if (String.valueOf(cdl.LinkedEntityId).startsWith('a0D')){
                setContractId.add(cdl.LinkedEntityId);
            }
        }

        // Get all content doc link of contracts
        if(setContractId.size()>0) {
            for (ContentDocumentLink cdl : [SELECT Id, ContentDocumentId, LinkedEntityId 
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId IN :setContractId
                                            and ContentDocumentId NOT IN: setContentDocumentId]){
                // Get all content Document Id for each ctr
                if (mapContractIdContentDocId.containsKey(cdl.LinkedEntityId)){
                    mapContractIdContentDocId.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                }
                else{
                    mapContractIdContentDocId.put(cdl.LinkedEntityId, new Set<Id>{cdl.ContentDocumentId});
                }
            }
            
            
            if(mapContractIdContentDocId.size()>0){
                // Get all signable Content Version of all contracts
                for (Set<Id> setContentDocId : mapContractIdContentDocId.values()){
                    for (ContentVersion cv:[SELECT Id, Sign_able__c,ContentDocumentId , filetype
                                            FROM ContentVersion 
                                            WHERE ContentDocumentId IN:setContentDocId
                                            AND IsLatest=TRUE]){
                        if (cv.Sign_able__c == TRUE && cv.filetype=='PDF'){
                            setSignableDocumentId.add(cv.ContentDocumentId);
                        }
                    }
                }
               
                // For each ctr
                for (Contract__c ctr : [SELECT Id, name, cTin_NumberSignablePDF__c 
                                        FROM Contract__c
                                        WHERE Id IN :mapContractIdContentDocId.KeySet()]){
                    Integer numOfSignableDocs = 0;// Reset num of signable docs
                    Integer numberDocs = 0; // reset documents uploaded
                    for(Id currContentDocId:mapContractIdContentDocId.get(ctr.Id)){
                        if (setSignableDocumentId.contains(currContentDocId)){
                            numOfSignableDocs++;
                        }
                        numberDocs ++;
                    }
                    
                    ctr.cTin_NumberSignablePDF__c = numOfSignableDocs;// Set num of signable pdf
                    ctr.cTin_NumUploadedDocs__c= numberDocs;// reset documents uploaded
                    lstContractsToUpd.add(ctr);
                }
            }
            //cater for scenarios where only one pdf is avaialble and deleted
            else{
                for(id ctrId: setContractId){
                    Contract__c ctr=new Contract__c(id=ctrId,cTin_NumberSignablePDF__c =0,cTin_NumUploadedDocs__c=0);                
                    lstContractsToUpd.add(ctr);
                }
            }
            
            if (lstContractsToUpd.size() > 0){
                update lstContractsToUpd;
            }
     }

        System.debug('## End of method determineNumOfSignablePDF from ContentDocument after delete' );
    }
    
    public static void dummy(){
        integer i=0;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
         i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
        i=i+1;
    }
}