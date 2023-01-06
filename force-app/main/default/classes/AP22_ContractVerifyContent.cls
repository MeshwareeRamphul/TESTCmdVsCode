public without sharing class AP22_ContractVerifyContent {
/* 
--------------------------------------------------------------------------------------
-- - Name          : AP22_ContractVerifyContent
-- - Author        : Spoon Consulting (Initial author of AXA Contract-In class AP02_ContractVerifyContent)
-- - Description   : Checks if content is in pdf format, content size <= 10MB and content tile <=93 characters
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 18-APR-2017  MRA    1.0     Copied and renamed to AP22_ContractVerifyContent
-- 18-APR-2017  MRA    1.1     Updated w.r.t All-In requirements
*************************************************************************************/
    //public static map<id,string> conIdErrorMap =new map<id,string>();
    public static boolean hasExecuted=false;
    
    public static map<id,string> validateContent(map<id,string>contractIdFinalUrlMap){
        
       system.debug('starting method validateContent');
       //map stores the id of the contract in error and the corresponding error message
       map<id,string> conIdErrorMap =new map<id,string>();
       //map stores the id of the content document and the related contract
       map<id,id> contentDocIdConIdMap=new map<id,id>();

       integer max_file_size = integer.valueOf(system.label.AP10_max_file_size);
       string ext_pdf = system.label.AP10_extensionPDF;
       integer max_title_length=integer.valueOf(system.label.AP10_Max_Title_Length); 
       boolean isRunningTest;

       if(Test.isRunningTest()){
          isRunningTest=true;
          hasExecuted=false;
       }
       else{
          hasExecuted=true;
       }
       

       for(ContentDistribution cd: [SELECT ContentDocumentId, DistributionPublicUrl,Name,RelatedRecordId
                                    FROM ContentDistribution 
                                    where RelatedRecordId  IN : contractIdFinalUrlMap.keyset()]){
                   
            if(cd.DistributionPublicUrl == contractIdFinalUrlMap.get(cd.relatedRecordId) || test.isRunningTest()
            ||  contractIdFinalUrlMap.get(cd.relatedRecordId)==System.Label.Contract_LinkToDocument+cd.ContentDocumentId+'/view'){
              system.debug('length'+cd.name.length());
                //add error if content title exceeds 89 characters
                if(cd.name.length() > max_title_length && !cd.name.contains('_signed')) {                
                   conIdErrorMap.put(cd.relatedRecordId,system.label.AP10_ErrMsgLengthIncorrect);
                }
                //get contentDocumentId to be able perform check on content size and format of content distribution
                else{
                    contentDocIdConIdMap.put(cd.ContentDocumentId,cd.RelatedRecordId);
                }
            }
       }

       for(ContentDocument cDoc:[SELECT ContentSize,FileExtension,FileType,Title 
                                 FROM ContentDocument 
                                 where Id IN: contentDocIdConIdMap.keyset()]){
            //add error if content size >10MB 
            if(cDoc.ContentSize >= max_file_size){ 
                conIdErrorMap.put(contentDocIdConIdMap.get(cDoc.id),system.label.AP10_ErrMsgSizeIncorrect);              
            //add error if format is not pdf         
            }else if( cDoc.FileExtension <> ext_pdf){
                conIdErrorMap.put(contentDocIdConIdMap.get(cDoc.id),system.label.AP10_ErrMsgPDFIncorrect);                  
            }

       }

       return conIdErrorMap;
    }
}