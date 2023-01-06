public class AP47_UpdateFinalDocUrl{
    /* 
    --------------------------------------------------------------------------------------
    -- - Name          : AP47_UpdateFinalDocUrl
    -- - Author        : Spoon

    --
    -- Maintenance History: 
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  -------------------------------------------------------
    -- 21-APR-2020  MRA    1.0     BAU Bundle 3.2 Ticket : SP-00186
    -- 23-APR-2021  ARA    1.1     BAU Release cTin 3: SP-00556 (populate LinkToDocument__c)
    -- 10-AUG-2021  ARA    1.2     SP-01729 (populate LinkToDocument__c for opco)
    *************************************************************************************/
    public static boolean allowAP47=false;
    //method is triggered on delete of content document link => clears final doc url or updates with most recent sign-able PDF 
    public static void UpdateFinaldocUrlToBlank(set<id> ContentDocIdSet){
        allowAP47=true;
        system.debug('## starting method UpdateFinaldocUrlToBlank');
        list<ContentVersion> lstcv = new list<ContentVersion>();
        map<string,string>mapUrlCtr=new map<string,string>();
        Map<Id,contract__c> mapCtr;
        list<contract__c> lstcon=new list<contract__c>();
        
        //query content version linked to the content document link which is deleted 
        for(ContentVersion cv:[ SELECT Id, Sign_able__c,ContentDocumentId , filetype
                                FROM ContentVersion 
                                WHERE ContentDocumentId IN: ContentDocIdSet]){
                lstcv.add(cv);                                        
        }

        //query content distribution linked to the content document link which is deleted 
        for (ContentDistribution cd :[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId
                                        FROM ContentDistribution
                                        WHERE ContentVersionId IN: lstcv]){
            if(string.valueOf(cd.RelatedRecordId).startsWith('a0D'))                        
                mapUrlCtr.put(cd.DistributionPublicUrl,cd.RelatedRecordId); 
        }   
        
        mapCtr = new Map<Id,contract__c>([SELECT Id, TECH_IsContractIn__c FROM Contract__c WHERE Id IN :mapUrlCtr.values()]);
        //check if a content document link exists on the contract where sign-able is checked => if yes update final url with its public url else set final url to blank
        for(id ctrId :mapUrlCtr.values()){
            Contract__c ctr;
            list<ContentDistribution> cdlst;
            
            if(mapCtr.get(ctrId).TECH_IsContractIn__c){
                cdlst = [SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId,ContentVersion.Sign_able__c 
                        FROM ContentDistribution
                        WHERE RelatedRecordId =:ctrId AND ContentVersion.Sign_able__c = true AND ContentVersionId NOT IN: lstcv
                        ORDER BY LastmodifiedDate DESC LIMIT 1];
            }else {
                cdlst = [SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId,ContentVersion.Sign_able__c 
                        FROM ContentDistribution
                        WHERE RelatedRecordId =:ctrId AND ContentVersionId NOT IN: lstcv
                        ORDER BY LastmodifiedDate DESC LIMIT 1];
            }

            if(cdlst.size()>0){
                ctr = new Contract__c(id = ctrId, LinkToDocument__c = System.Label.Contract_LinkToDocument+ cdlst[0].contentDocumentId +'/view');  
            }else{
                ctr = new Contract__c(id = ctrId, LinkToDocument__c = '');
            }
            
            lstcon.add(ctr);                                       
        }

        if(lstcon.size()>0){
            try{update lstcon;} catch(Exception e){}
        } 
            
        system.debug('## Ending method UpdateFinaldocUrlToBlank');                          
    }

    //method is triggered on update of content version when document link when sign-able is checked /unchecked  => clears final doc url or updates with most recent sign-able PDF  
    public static void UpdateFinaldocUrl(List<ContentVersion> lstContentVersion){
        system.debug('## starting UpdateFinaldocUrl ');
        allowAP47=true;
        list<contract__c> lstcon=new list<contract__c>();
        map<string,string> mapUrlCtrBlank=new map<string,string>();
        map<string,string> mapUrlCtr=new map<string,string>();
        set<id>cdIdSignableSet=new set<id>();
        set<id>cdIdNotSignableSet=new set<id>();
        set<id> relatedContractSet=new set<id>();
        
        //query content document Id linked to the updated content conversion 
        for(Contentversion cv: [select id,contentDocumentId,Sign_able__c from ContentVersion where id IN: lstContentVersion]){
            if(cv.Sign_able__c)
                cdIdSignableSet.add(cv.contentDocumentId);
            else
                cdIdNotSignableSet.add(cv.contentDocumentId);
        }
        
        //query content distriution linked to content document link
        for (ContentDistribution cd :[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId
                                        FROM ContentDistribution
                                        WHERE contentDocumentId IN: cdIdSignableSet
                                        OR contentDocumentId IN: cdIdNotSignableSet
                                        OR ContentVersionId IN: lstContentVersion ]){
            if(string.valueOf(cd.RelatedRecordId).startsWith('a0D'))    {
                if(cdIdSignableSet.contains(cd.contentDocumentId)){
                    //mapUrlCtr.put(cd.RelatedRecordId,cd.DistributionPublicUrl); //map containing sign-able pdf per contract
                    mapUrlCtr.put(cd.RelatedRecordId,cd.contentDocumentId); //map containing sign-able pdf per contract
                }
                if(cdIdNotSignableSet.contains(cd.contentDocumentId)){
                    //mapUrlCtrBlank.put(cd.RelatedRecordId,cd.DistributionPublicUrl); //map containing non sign-able pdf per contract
                    mapUrlCtrBlank.put(cd.RelatedRecordId,cd.contentDocumentId); //map containing non sign-able pdf per contract
                }   
                relatedContractSet.add(cd.RelatedRecordId);          
            }                                    
        }  

        //update final doc url with most recent sign-able pdf 
        for(Id ctrId: mapUrlCtr.keyset()){
            //Contract__c ctr=new Contract__c(id=ctrId,FinalDocumentURL__c=mapUrlCtr.get(ctrId));  
            Contract__c ctr=new Contract__c(id=ctrId,LinkToDocument__c=System.Label.Contract_LinkToDocument+mapUrlCtr.get(ctrId)+'/view');  
            lstcon.add(ctr);      
        } 
        
        if(mapUrlCtrBlank.size()>0){           
            for(id ctrId :mapUrlCtrBlank.keyset()){
                    Contract__c ctr;
                    list<ContentDistribution> cdlst=[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId,ContentVersion.Sign_able__c 
                                                    FROM ContentDistribution
                                                    WHERE RelatedRecordId =:ctrId 
                                                    and  ContentVersion.Sign_able__c=:true 
                                                    order by LastmodifiedDate Desc limit 1];                             
                if(cdlst.size()>0){
                    //ctr=new Contract__c(id=ctrId ,FinalDocumentURL__c=cdlst[0].DistributionPublicUrl);
                    ctr=new Contract__c(id=ctrId /*,FinalDocumentURL__c=cdlst[0].DistributionPublicUrl*/,
                                        LinkToDocument__c=System.Label.Contract_LinkToDocument+cdlst[0].contentDocumentId+'/view');
                    
                }else{
                    //ctr=new Contract__c(id=ctrId ,FinalDocumentURL__c=''); 
                    ctr=new Contract__c(id=ctrId ,/*FinalDocumentURL__c='',*/LinkToDocument__c='');  
                }
                lstcon.add(ctr);      
            }                  
        }                                

        if(lstcon.size()>0)
        update lstcon; 
        
    }

    //method is triggered on update of content version when document link when sign-able is checked /unchecked  => clears final doc url or updates with most recent sign-able PDF  
    /* public static void UpdateLinkToDocument(List<ContentVersion> lstContentVersion){
        system.debug('## starting UpdateFinaldocUrl ');
        allowAP47=true;
        list<contract__c> lstcon=new list<contract__c>();
        set<Id>setContractId=new set<Id>();
        map<Id, List<Contentversion>> mapSignable=new map<Id, List<Contentversion>>();        
        map<Id, Id>mapCVId=new map<Id, Id>();
        
        for (ContentDistribution cd :[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId
                                    FROM ContentDistribution
                                    WHERE ContentVersionId IN: lstContentVersion ]){
            if(string.valueOf(cd.RelatedRecordId).startsWith('a0D')) {
                setContractId.add(cd.RelatedRecordId);
            }
        }

        if(setContractId.size()>0){
            system.debug('*****setContractId.size() '+setContractId.size());
            List<ContentDistribution> lstCD = [ SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId
                                                FROM ContentDistribution
                                                WHERE RelatedRecordId IN: setContractId ORDER BY createdDate DESC];
            system.debug('*****lstCD '+lstCD.size());
            for (ContentDistribution cd : lstCD){
                mapCVId.put(cd.ContentVersionId, cd.RelatedRecordId);
            }

            List<Contentversion> lstCV = [select id,contentDocumentId,Sign_able__c from ContentVersion where id IN: mapCVId.keySet() order by createdDate desc];
            for(Contentversion cv: lstCV){
                if(cv.Sign_able__c)
                    if(mapSignable.containsKey(mapCVId.get(cv.Id))){
                        List<Contentversion> ltsContentVersion = mapSignable.get(mapCVId.get(cv.Id));
                        ltsContentVersion.add(cv);
                        mapSignable.put(mapCVId.get(cv.Id), ltsContentVersion);
                    }else{
                        List<Contentversion> ltsContentVersion = new List<Contentversion>();
                        ltsContentVersion.add(cv);
                        mapSignable.put(mapCVId.get(cv.Id), ltsContentVersion);
                    }
            }

            for(Id ctrId : setContractId){
                if(mapSignable.containsKey(ctrId)){
                    system.debug('*****ctrId '+ctrId);
                    Boolean isLastCreated = false;
                    for(ContentDistribution  cd : lstCD){
                        for(ContentVersion cv : mapSignable.get(ctrId)){
                            if(cd.ContentVersionId == cv.Id){
                                lstcon.add(new Contract__c(id=ctrId ,LinkToDocument__c=System.Label.Contract_LinkToDocument+ cd.contentDocumentId +'/view'));
                                isLastCreated = true;
                                break;
                            }
                        }
                        if(isLastCreated) break;
                    }
                }else{
                    lstcon.add(new Contract__c(id=ctrId ,LinkToDocument__c=''));  
                }
            }
            update lstcon;
        }
    }*/

    public static void UpdateLinkToDocument(Set<Id> setCtrId){
        system.debug('## starting UpdateLinkToDocument ');
        allowAP47=true;
        Map<Id,contract__c> mapCon=new Map<Id,contract__c>();
        string signed = '%_signed%';
        Map<Id,ContentDistribution> mapCD=new Map<Id,ContentDistribution>();
        
        map<id,id> maprecIdCd=new map<id,id>();
        map<id,id> cdWithSignable=new map<id,id>();
        for(ContentDocumentLink  cdl: [select linkedEntityId, contentdocumentId from ContentDocumentLink where  linkedEntityId in:setCtrId]){
                maprecIdCd.put(cdl.contentdocumentId,cdl.linkedEntityId);
        }
        
        for (id cd: maprecIdCd.keyset()){
            for(contentversion cv: [ SELECT id,contentdocumentId FROM ContentVersion 
                                    WHERE  (sign_able__c=:true or ContentVersion.title LIKE :signed) and ContentDocumentId = :cd  and IsLatest=true]){
                                    cdWithSignable.put(cd,cv.id);
            }
            /*for(contentversion cv: [select id,contentdocumentId from contentversion
                where contentdocumentId =:cd
            (sign_able__c=:true or ContentVersion.title LIKE :signed) and islatest=:true 
                ]){
                cdWithSignable.put(cd,cv.id);
            } */            
        }
        
        
        for(id cd:maprecIdCd.keyset()){
            Contract__c ctr;   
            if(cdWithSignable.containsKey(cd)){
                ctr=new Contract__c(Id = maprecIdCd.get(cd), 
                                    /*Tech_RecoverLinkToDocument__c   = true,*/ 
                                    /* FinalDocumentURL__c             = mapCD.get(ctrId).DistributionPublicUrl,*/
                                    LinkToDocument__c               = System.Label.Contract_LinkToDocument + cd + '/view');
            }
            else{
                ctr=new Contract__c(Id = maprecIdCd.get(cd), 
                                    /*Tech_RecoverLinkToDocument__c   = true,*/ 
                                    /* FinalDocumentURL__c             = mapCD.get(ctrId).DistributionPublicUrl,*/
                                    LinkToDocument__c               = '');
            }
            mapCon.put(ctr.id, ctr);    
        }
        
        if(mapCon.values().size()>0)
            update mapCon.values();
    }

    public static void UpdateLinkToDocumentOpCo(Set<Id> setCtrId){
        system.debug('## starting UpdateLinkToDocument ');
        allowAP47=true;
        Map<Id,contract__c> mapCon=new Map<Id,contract__c>();
        string signed = '%_signed%';
        Map<Id,ContentDistribution> mapCD=new Map<Id,ContentDistribution>();
        
        map<id,id> maprecIdCd=new map<id,id>();
        map<id,id> cdWithSignable=new map<id,id>();
        for(ContentDocumentLink  cdl: [select linkedEntityId, contentdocumentId from ContentDocumentLink where  linkedEntityId in:setCtrId]){
                maprecIdCd.put(cdl.contentdocumentId,cdl.linkedEntityId);
        }
        
        for (id cd: maprecIdCd.keyset()){
            for(contentversion cv: [ SELECT id,contentdocumentId FROM ContentVersion 
                                    WHERE  /*ContentVersion.title LIKE :signed AND */ContentDocumentId = :cd  AND IsLatest=true]){
                cdWithSignable.put(cd,cv.id);
            }  
        }
        
        
        for(id cd:maprecIdCd.keyset()){
            Contract__c ctr;   
            if(cdWithSignable.containsKey(cd)){
                ctr=new Contract__c(Id = maprecIdCd.get(cd), 
                                    /*Tech_RecoverLinkToDocument__c   = true,*/ 
                                    /* FinalDocumentURL__c             = mapCD.get(ctrId).DistributionPublicUrl,*/
                                    LinkToDocument__c               = System.Label.Contract_LinkToDocument + cd + '/view');
            }
            else{
                ctr=new Contract__c(Id = maprecIdCd.get(cd), 
                                    /*Tech_RecoverLinkToDocument__c   = true,*/ 
                                    /* FinalDocumentURL__c             = mapCD.get(ctrId).DistributionPublicUrl,*/
                                    LinkToDocument__c               = '');
            }
            mapCon.put(ctr.id, ctr);    
        }
        
        if(mapCon.values().size()>0)
            update mapCon.values();
    }
}