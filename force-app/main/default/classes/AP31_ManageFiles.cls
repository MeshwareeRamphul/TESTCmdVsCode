public without sharing class  AP31_ManageFiles {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP31_ManageFiles
-- - Author        : Spoon Consulting 
-- - Description   : 
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 08-AUG-2019  USA    1.0     Initial version
-- 09-JAN-2020  SGO    1.1     cTin - Insert / Delete Content distribution when content document link is inserted / deleted
-- 20-APR-2020  MRA    1.2     cTin- updated class to populate final doc url only when "Send for signature" is checked (SP-00186)
--------------------------------------------------------------------------------------*/
    //Added boolean hasRunAP31 to prevent trigger from executing more than once
    public static boolean hasRunAP31=false;
    public static void generatePublicURL(List<ContentDocumentLink> lstcdl){
      //  hasRunAP31=true;
        System.debug('@@ AP31_ManageFiles.generatePublicURL starts ');
        map<Id,Id> mapDocEntity = new map<Id,Id>();
        List<contentVersion> lstCV = new list<contentVersion>();
        List<contentDistribution> lstContentDistribution = new List<contentDistribution>();
        map<Id,Contract__c> mapCtrToUpdateDoc = new map<Id,Contract__c>();
        set<Id> setCVpdf = new Set<Id>(); //opco
        set<Id> setCtrIds = new Set<Id>();
        set<Id> setESignIds = new Set<Id>();
        set<Id> setCtrLEXIds = new Set<Id>(); //opco
        set<id> setcTinCtrLEX=new set<id>();//ctin
        set<Id> setCVcTinpdf = new Set<Id>(); //ctin
        set<Id> setESignLEXIds = new Set<Id>(); //ctin
        set<id> signedCV=new set<id>();
        set<id> setCd=new set<id>();
        
        try{

            for (ContentDocumentLink cdl :lstcdl){
                if (String.valueOf(cdl.LinkedEntityId).startsWith('a0D')){      //Contract
                    mapDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                    setCtrIds.add(cdl.LinkedEntityId);
                }
                // SGO - 09/01/2020 - cTin
                if (String.valueOf(cdl.LinkedEntityId).startsWith('a0S')){       //eSignature
                    mapDocEntity.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                    setESignIds.add(cdl.LinkedEntityId);
                }
            }

            // Contract 
            for (Contract__c ctr :[SELECT Id, RecordTypeId, RecordType.Developername,LinkToDocument__c
                                FROM contract__c
                                WHERE Id IN :setCtrIds]){
                if (ctr.RecordType.DeveloperName.contains('OpCo360') ){
                    setCtrLEXIds.add(ctr.Id);
                }
                if(ctr.RecordType.DeveloperName.contains('cTin')){
                     setcTinCtrLEX.add(ctr.Id);
                }
                
            }
            // eSignature 
            for (eSignature__c eSign :[SELECT Id, RecordTypeId, RecordType.Developername,contract__r.LinkToDocument__c
                                FROM eSignature__c
                                WHERE Id IN :setESignIds]){
                if (eSign.RecordType.DeveloperName.contains('cTin')){
                    setESignLEXIds.add(eSign.Id);
                }
            }
            
            // System.debug('##AP31signed## mapDocEntity'+ mapDocEntity);
            if (mapDocEntity.size() > 0){
                for (contentVersion cv : [SELECT Id, contentDocumentId, contentDocument.title, contentDocument.fileType,sign_able__c
                FROM contentVersion
                WHERE contentDocumentId in :mapDocEntity.keySet()]){
                    
                    // For Contract & eSignature
                    if (setCtrLEXIds.contains(mapDocEntity.get(cv.contentDocumentId)) || setcTinCtrLEX.contains(mapDocEntity.get(cv.contentDocumentId)) || setESignLEXIds.contains(mapDocEntity.get(cv.contentDocumentId))) {
                       
                        ContentDistribution cd = new ContentDistribution();
                        cd.Name = cv.contentDocument.title;
                        cd.ContentVersionId = cv.Id;
                        cd.PreferencesAllowViewInBrowser = true;
                        cd.PreferencesLinkLatestVersion = true;
                        cd.PreferencesNotifyOnVisit = false;
                        cd.PreferencesPasswordRequired = false;
                        cd.PreferencesAllowOriginalDownload = true;
                        cd.RelatedRecordId = mapDocEntity.get(cv.contentDocumentId);
                        if(!setCd.contains(cv.contentDocumentId))
                        	lstContentDistribution.add(cd);

                        if (cv.contentDocument.fileType == 'PDF' && setCtrLEXIds.contains(mapDocEntity.get(cv.contentDocumentId))) {
                             if(!setCd.contains(cv.contentDocumentId)) setCVpdf.add(cv.Id);
                        }
                        
                        if (cv.contentDocument.fileType == 'PDF' && cv.sign_able__c==true &&  
                        (setcTinCtrLEX.contains(mapDocEntity.get(cv.contentDocumentId)) || setESignLEXIds.contains(mapDocEntity.get(cv.contentDocumentId)) )) {
                             if(!setCd.contains(cv.contentDocumentId)) setCVcTinpdf.add(cv.Id);
                        }
                        
                        /*if(cv.contentDocument.fileType == 'PDF' && 
                        cv.contentDocument.Title.substring(cv.contentDocument.Title.length()-7,cv.contentDocument.Title.length()).equalsignorecase('_signed') 
                        &&
                        (setcTinCtrLEX.contains(mapDocEntity.get(cv.contentDocumentId)) || setESignLEXIds.contains(mapDocEntity.get(cv.contentDocumentId)) )){
                        system.debug('## detected a signed pdf for ctin');
                        signedCV.add(cv.Id);
                        }*/
                        setCd.add(cv.contentDocumentId);
                        
                    }
                }
            }
        
             System.debug('##AP31signed## setcd'+ setcd.size());
           
             if(lstContentDistribution.size()>0)
                    insert lstContentDistribution;
                
            
            

            for (ContentDistribution cd :[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId,contentDocumentId
                                        FROM ContentDistribution
                                        WHERE id=:lstContentDistribution]){
                if((cd.DistributionPublicUrl !=null) && (cd.RelatedRecordId !=null) && /*(setCVpdf.contains(cd.ContentVersionId)) && */ (String.valueOf(cd.RelatedRecordId).startsWith('a0D'))){
                    
                    if((setCVpdf.contains(cd.ContentVersionId))){
                        // 06-08-2021   ARA     SP-01729 set LinkToDocument__c
                        Contract__c ctr = new Contract__c(Id = cd.RelatedRecordId/*, FinalDocumentURL__c = cd.DistributionPublicUrl*/,LinkToDocument__c=System.Label.Contract_LinkToDocument+cd.contentDocumentId+'/view', PDFStatus_lgt__c = 'Updated');
                        if (!mapCtrToUpdateDoc.containsKey(cd.RelatedRecordId)){
                            mapCtrToUpdateDoc.put(cd.RelatedRecordId, ctr);
                        }
                    }
                    
                    if((setCVcTinpdf.contains(cd.ContentVersionId))){
                        Contract__c ctr = new Contract__c(Id = cd.RelatedRecordId, FinalDocumentURL__c = cd.DistributionPublicUrl,LinkToDocument__c=System.Label.Contract_LinkToDocument+cd.contentDocumentId+'/view');
                        if (!mapCtrToUpdateDoc.containsKey(cd.RelatedRecordId)){
                            mapCtrToUpdateDoc.put(cd.RelatedRecordId, ctr);
                        }
                    }
                    
                   /* //mra : 22-JUl-2020
                    if((signedCV.contains(cd.ContentVersionId))){
                        Contract__c ctr = new Contract__c(Id = cd.RelatedRecordId, FinalDocumentURL__c = cd.DistributionPublicUrl);
                        if (!mapCtrToUpdateDoc.containsKey(cd.RelatedRecordId)){
                            mapCtrToUpdateDoc.put(cd.RelatedRecordId, ctr);
                        }
                    }*/
                    
                }
            }
            
            // System.debug('##AP31signed## mapCtrToUpdateDoc'+ mapCtrToUpdateDoc);
            if (mapCtrToUpdateDoc.size()>0){
                update mapCtrToUpdateDoc.values();
            }

        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        System.debug('@@ AP31_ManageFiles.generatePublicURL ends ');
    }

    public static void deleteContentDistribution(List<ContentDocumentLink> lstcdl){
        System.debug('@@ AP31_ManageFiles.deleteContentDistribution starts ');
        map<Id,Id> mapDocEntity = new map<Id,Id>();
        map<Id,Id> mapEntityDoc = new map<Id,Id>();
        List<contentVersion> lstCV = new list<contentVersion>();
        List<contentDistribution> lstContentDistribution = new List<contentDistribution>();
        map<Id,Contract__c> mapCtrToUpdateDoc = new map<Id,Contract__c>();
        set<Id> setCVpdf = new Set<Id>();
        set<Id> setCtrIds = new Set<Id>();
        set<Id> setESignIds = new Set<Id>();
        set<Id> setCtrLEXIds = new Set<Id>();
        set<Id> setESignLEXIds = new Set<Id>();
        set<Id> setDocIds = new set<Id>();
        set<Id> setDocId = new set<Id>();
        
       // map<string, string> mapDocUrlCon=new map<string, string>();
        //set<string> conWithDocUrlSet=new set<string>();
        //list<Contract__c> lstCtr=new list<Contract__c>();

        try{
    
            for (ContentDocumentLink cdl :lstcdl){
                // System.debug('@@@ cdl.LinkedEntityId ' + cdl.LinkedEntityId);

                if (String.valueOf(cdl.LinkedEntityId).startsWith('a0D')){      //Contract
                    mapEntityDoc.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                    setCtrIds.add(cdl.LinkedEntityId);
                    setDocIds.add(cdl.ContentDocumentId);
                    
                }
                if (String.valueOf(cdl.LinkedEntityId).startsWith('a0S')){       //eSignature
                    mapEntityDoc.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                    setESignIds.add(cdl.LinkedEntityId);
                    setDocIds.add(cdl.ContentDocumentId);
                }
            }
            // System.debug('@@@ setCtrIds ' + setCtrIds);
            // System.debug('@@@ setESignIds ' + setESignIds);
            // System.debug('@@@ mapEntityDoc ' + mapEntityDoc);
            
            // Contract 
            for (Contract__c ctr :[SELECT Id, RecordTypeId, RecordType.Developername,FinalDocumentURL__c 
                                FROM contract__c
                                WHERE Id IN :setCtrIds]){
                if (ctr.RecordType.DeveloperName.contains('cTin')){
                    system.debug('##ctr.FinalDocumentURL__c'+ctr.FinalDocumentURL__c);
                   // mapDocUrlCon.put(ctr.FinalDocumentURL__c , ctr.Id);
                    setCtrLEXIds.add(ctr.Id);
                }
            }
            // eSignature 
            for (eSignature__c eSign :[SELECT Id, RecordTypeId, RecordType.Developername
                                FROM eSignature__c
                                WHERE Id IN :setESignIds]){
                if (eSign.RecordType.DeveloperName.contains('cTin')){
                    setESignLEXIds.add(eSign.Id);
                }
            }
            
            if (mapEntityDoc.size() > 0){
                // For Contract
                if (setCtrLEXIds.size() > 0){
                    for (ContentDistribution doc : [select Id, contentDocumentId, RelatedRecordId,DistributionPublicUrl from ContentDistribution Where RelatedRecordId in :setCtrLEXIds AND contentDocumentId in :setDocIds]){
                        setDocId.add(doc.Id);
                        //system.debug('##doc.DistributionPublicUrl '+doc.DistributionPublicUrl );
                       //if(mapDocUrlCon.containsKey(doc.DistributionPublicUrl )){
                     //       conWithDocUrlSet.add(mapDocUrlCon.get(doc.DistributionPublicUrl));
                    //   } 
                      // lstContentDistribution.add(doc);
                    }
           }
           
           // For eSignature
            if (setESignLEXIds.size() > 0){
                    for (ContentDistribution doc : [select Id, contentDocumentId, RelatedRecordId,DistributionPublicUrl from ContentDistribution Where RelatedRecordId in :setESignLEXIds AND contentDocumentId in :setDocIds]){
                       setDocId.add(doc.Id);
                     //  if(mapDocUrlCon.containsKey(doc.DistributionPublicUrl )){
                      //      conWithDocUrlSet.add(mapDocUrlCon.get(doc.DistributionPublicUrl));
                      // } 
                      // lstContentDistribution.add(doc);
                    }
                }
                // System.debug('@@@ setDocId'+ setDocId);     // docs to be deleted

                if (setDocId.size() > 0){
                    lstContentDistribution = [select Id, Name, RelatedRecordId, ContentDocumentId From ContentDistribution Where Id in :setDocId];
                }
            }
        
            // System.debug('@@@ lstContentDistribution '+ lstContentDistribution);
           if (lstContentDistribution.size() > 0){
                delete lstContentDistribution;
            }
            
            //system.debug('## conWithDocUrlSet'+ conWithDocUrlSet);
            
            //if(conWithDocUrlSet.size()>0){
            //    for( Id conId: conWithDocUrlSet){
              //      contract__c ctr=new contract__c(Id=conId,FinalDocumentURL__c='');   
              //      lstCtr.add(ctr);        
              //  }
          //  }
            
           // if(lstCtr.size()>0)
             //   update lstCtr;
            
            // for (ContentDistribution cd :[SELECT id,DistributionPublicUrl,RelatedRecordId,ContentVersionId
            //                             FROM ContentDistribution
            //                             WHERE id=:lstContentDistribution]){
            //     System.debug('@@ delete cd ' + cd);

            //     if((cd.DistributionPublicUrl !=null) && (cd.RelatedRecordId !=null) && (String.valueOf(cd.RelatedRecordId).startsWith('a0D'))){
            //         Contract__c ctr = new Contract__c(Id = cd.RelatedRecordId, FinalDocumentURL__c = '', PDFStatus_lgt__c = '');
            //         if (!mapCtrToUpdateDoc.containsKey(cd.RelatedRecordId)){
            //             mapCtrToUpdateDoc.put(cd.RelatedRecordId, ctr);
            //         }
            //     }
            // }
            
            // System.debug('@@@ mapCtrToUpdateDoc'+ mapCtrToUpdateDoc);
            // if (mapCtrToUpdateDoc.size()>0){
            //     update mapCtrToUpdateDoc.values();
            // }

        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        System.debug('@@ AP31_ManageFiles.deleteContentDistribution ends ');
    }
}