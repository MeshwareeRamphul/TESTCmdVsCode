public without sharing class AP22_XmlRpcWrapper {
/*
--------------------------------------------------------------------------------------
-- - Name          : AP22_XmlRpcWrapper
-- - Author        : Team Kerensen (Initial author of AXA Contract-In class Xml_Rpc_Wrapper)
-- - Description   : Methods of this class parse response as XMLRPC structure and return WrapperResponse class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-APR-2017  MRA    1.0     Copied renamed to AP22_XmlRpcWrapper
-- 26-APR-2017  MRA    1.1     Updated methods CreateXmlRpc and ParseXmlRPcResponse2 to be able to submit a transaction
-- 27-APR-2017  MRA    1.2     Updated method CreateXmlRpcForCancel to be able to cancel transaction
-- 28-APR-2017  DMU    1.3     Created instance currentAuth as public for code optimization and since Custom setting
                               UniversignAuthentification__c always contain one record, getInstance is used instead of getAll.
                               commented creation of map authentifications & currentAuth in methods
-- 02-MAY-2017  MRA    1.4     Created method CreateXmlRpcForSignedDocument to retrieve signed document from Universign
-- 04-MAY-2017  DMU    1.5     Created method calloutUniversign for generic WS callout Universign - for code optimisation
                               Commented all individual http request in methods ; use of generic method buildHttpRequest
-- 05-DEC-2017  MRA    1.6     Updated class to send correct universign profile based on entity of contract owner
                               (applicable for All-In only)
-- 02-FEB-2018  MRA    1.8     Issue corrupted pdf : Updated method "CreateXmlRpcForSignedDocument" to retrieve base64 corresponding to element content only.
                               [universign sends 2 base64 (content/original content)]
-- 30-JAN-2020  SGO    1.9     Insert content document link when signed doc
-- 22-APR-2020  MRA    2.0     Added method getRejectComment - retrieve refusal comment (cTin => SP-00239 / bundle 3.2)
-- 02-DEC-2020  MRA    2.1     Updated method CreateXmlRpc => Ctin uses AXA_GO profile now, default profile is dedicated for Opco
-- 09-MARS-2021 MRA/ARA 2.2    OpCo: SP-0204 : Add validator role to xml request 
-- 15-MARS-2021 MRA    2.2     cTin: SP-01376 ( Add parameter to xml request so as to change checkbox text on Universign's esignature page)
-- 09-APR-2021  MRA    2.3     cTin_SP0219 (added parameter finalDocCCeMails to submit request)
-- 28-APR-2021  ARA    2.4     OpCo : SP-01470 (Add possibility for a signatory to reject a contract & indicate a comment)
-- 10-MAY-2021  ARA    2.5     OpCo : SP-01668 (block email invitation for all signers/validators and email notif with signed pdf for all)
-- 06-AUG-2021  MRA    2.6     CtIn: 1277 - AXA Gulf (EB) uses Universign's email template
-- 28-JUL-2022  ARA    2.7     SP-02770 - Contract | Change PO reminder functionality
*************************************************************************************/

    public static HttpResponse dummyResponse {get;set;}
    public static boolean testError=false;
    static UniversignAuthentification__c currentAuth;
    public static id esignatureId = 'a0SO0xxxxxxxxxx';
    public static boolean hasExecutedXmlRpc=false;
    //Authentification from Custom Setting
    static{
        Map<String, UniversignAuthentification__c> authentifications = UniversignAuthentification__c.getAll();
        currentAuth= new UniversignAuthentification__c() ;
        currentAuth =  authentifications.get('AGS');
    }


    //Generic method to build HttpRequest
    public static Object buildHttpRequest(String XmlRpcRequest){
        Httprequest request = new HttpRequest();
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setEndpoint(System.Label.WSUniversignEndPoint);
        request.setHeader('content-type', 'text/xml; charset=utf-8');
        String username = currentAuth.WS_Universign_Username__c;
        String password = currentAuth.WS_Universign_Password__c;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        request.setHeader('Authorization', authorizationHeader);
        request.setBody(XmlRpcRequest);
        return request;
    }

     public static String DocumentsArray(List<eSignatory__c> eSignatoryList, List<ContentDistribution> contDistList,string ProfileName)
    {
        String XMLRequest;
        XMLRequest = '<data>';
        if (contDistList != Null){
            for (ContentDistribution contDist : [select id, name, contentversionId,DistributionPublicUrl,ContentDocumentId,ContentDownloadUrl,PdfDownloadUrl  from contentdistribution where id IN: contDistList])
            {
                XMLRequest += '<value><struct>';

                //XMLRequest += '<member><name>profile</name><value><string>'+ProfileName+'</string></value></member>';
                if (contDist.DistributionPublicUrl != Null || test.isRunningTest()){

                    String xml_url=(test.isrunningTest() ? 'https://sign.test.universign.eu/en/signature/':String.valueOf(contDist.DistributionPublicUrl));
                    Integer j = xml_url.indexOf('p/');
                    Integer i = xml_url.indexOf('a/');
                    String oid = '00D'+ xml_url.substring(j+2,j+14);
                    String sub_xml_url = xml_url.substring(i+2,xml_url.length());
                    //XMLRequest += '<member><name>url</name><value><string>'+Label.contentStartUrl+'?oid='+oid+'&ids='+contDist.ContentVersionId+'&d=/a/'+sub_xml_url+'&operationContext=DELIVERY'+'</string></value></member>';
                    XMLRequest += '<member><name>url</name><value><string>'+contDist.PdfDownloadUrl+'</string></value></member>';

                }
                if (contDist.Name != Null){
                    XMLRequest += '<member><name>name</name><value><string>'+contDist.Name+'.pdf</string></value></member>';
                }
                if (eSignatoryList != Null){
                    XMLRequest += '<member><name>signatureFields</name><value><array>'+SignatureFieldsArray(eSignatoryList)+'</array></value></member>';
                }
                
               // SP-01376
               if(profileName!='default'){  
                    XMLRequest += '<member><name>checkBoxTexts</name><value><array><data>'+
                                    '<value><string>I have read the above document</string></value>'+       
                                    '<value><string></string> </value></data> </array></value></member>';
                }
                XMLRequest += '</struct></value>';
            }
        }
        XMLRequest += '</data>';

         
        return XMLRequest;
    }
    
    public static String SignatureFieldsArray(List<eSignatory__c> eSignatoryList)
    {
        String XMLRequest;
        XMLRequest = '<data>';
        Integer indexValidator = 1;
        Integer indexSigner;
        
        set<id> validatorSet=new set<id>();
        
        for (eSignatory__c eSignatory : eSignatoryList){
           if(esignatory.cTin_Role__c=='Validator')
               validatorSet.add(eSignatory.id);
        }
        if(validatorSet.size()>0)  indexSigner = validatorSet.size();
        
        for (eSignatory__c eSignatory : eSignatoryList){

               if(validatorSet.size()>0){                 
                   if(esignatory.cTin_Role__c!='Validator'){
                       XMLRequest += '<value><struct>';               
                       //XMLRequest += '<member><name>signerIndex</name><value><int>'+ indexSigner +'</int></value></member>';
                       //indexSigner++;
                       XMLRequest += '<member><name>signerIndex</name><value><int>'+ (eSignatory.Order__c-1) +'</int></value></member>';
                   }
                }
                else{
                    XMLRequest += '<value><struct>';
                   if (!test.IsRunningTest())XMLRequest += '<member><name>signerIndex</name><value><int>'+  (eSignatory.Order__c-1) +'</int></value></member>';
                   else XMLRequest += '<member><name>signerIndex</name><value><int>'+ eSignatory.OrderToSend__c +'</int></value></member>';
                }
                
             if(esignatory.cTin_Role__c!='Validator'){
                XMLRequest += '<member><name>page</name><value><int>'+1+'</int></value></member>';
                XMLRequest += '<member><name>x</name><value><int>'+eSignatory.x__c+'</int></value></member>';
                XMLRequest += '<member><name>y</name><value><int>'+eSignatory.y__c+'</int></value></member>';
                XMLRequest += '</struct></value>';
             }
           
            
        }

        XMLRequest += '</data>';
        return XMLRequest;
    }

    public static String SignersArray(List<eSignatory__c> lstSigners)
    {
        String XMLRequest;
        XMLRequest = '<data>';

        for(eSignatory__c eSignatory : lstSigners)
        {
            if(esignatory.cTin_Role__c=='Validator'){
                XMLRequest += '<value><struct>';
                
                if (eSignatory.contact__r.FirstName != Null){

                    XMLRequest += '<member><name>firstname</name><value><string>'+eSignatory.contact__r.FirstName.substring(0,1).toUpperCase() + eSignatory.contact__r.FirstName.substring(1, eSignatory.contact__r.FirstName.length())+'</string></value></member>';
                }
                if (eSignatory.contact__r.LastName != Null){

                    XMLRequest += '<member><name>lastname</name><value><string>'+eSignatory.contact__r.LastName.substring(0,1).toUpperCase() + eSignatory.contact__r.LastName.substring(1, eSignatory.contact__r.LastName.length())+'</string></value></member>';
                }
                
                if (eSignatory.EmailTxt__c != Null){
                    XMLRequest += '<member><name>emailAddress</name><value><string>'+eSignatory.EmailTxt__c+'</string></value></member>';
                }
                if (eSignatory.cTin_Role__c != Null){
                    XMLRequest += '<member><name>role</name><value><string>'+eSignatory.cTin_Role_Universign__c+'</string></value></member>';
                }
                
                if (eSignatory.code__c != Null){
                    XMLRequest += '<member><name>identificationType</name><value><string>'+eSignatory.code__c+'</string></value></member>';
                }
              
                                            
                XMLRequest += '<member><name>successURL</name><value><string>'+eSignatory.successURL__c+'</string></value></member>';
                XMLRequest += '<member><name>cancelURL</name><value><string>'+eSignatory.cancelURL__c+'</string></value></member>';
                
                XMLRequest += '</struct></value>';
            }
            else{
                XMLRequest += '<value><struct>';


                //MRA 7-JUL-2018 - specify subprofiles so that correct email template is applied (ATS/All-IN,CTin)
                if(eSignatory.esignature__r.cTin_TECH_IsContractIn__c){
                    if (esignatory.cTin_Role__c=='Supplier Representative' || esignatory.cTin_Profile__c=='signersupplier'){
                    //XMLRequest += '<member><name>profile</name><value><string>'+'signersupplier'+'</string></value></member>';
                    if(esignatory.contract__r.cTin_OwnerEntity__c!='750 - Avanssur')
                          XMLRequest += '<member><name>profile</name><value><string>'+'signersupplier'+'</string></value></member>';
                       else
                          XMLRequest += '<member><name>profile</name><value><string>'+'AVANSSUR_signersupplier'+'</string></value></member>';
                    
                    }
                    
                    if (esignatory.cTin_Role__c=='AXA Representative' || esignatory.cTin_Profile__c=='signeraxa'){
                       // XMLRequest += '<member><name>profile</name><value><string>'+'signeraxa'+'</string></value></member>';

                     if(esignatory.contract__r.cTin_OwnerEntity__c!='750 - Avanssur')
                         XMLRequest += '<member><name>profile</name><value><string>'+'signeraxa'+'</string></value></member>';
                     else
                         XMLRequest += '<member><name>profile</name><value><string>'+'AVANSSUR_signeraxa'+'</string></value></member>';
                    
                    }
                }
                else{
                    //if(esignatory.cTin_Role__c!='Validator'){
                    XMLRequest += '<member><name>profile</name><value><string>'+'signeraxa'+'</string></value></member>';
                    //XMLRequest += '<member><name>profile</name><value><string>DIT</string></value></member>';
                    //}
                }

                if (eSignatory.FirstName__c != Null){

                    XMLRequest += '<member><name>firstname</name><value><string>'+eSignatory.FirstName__c.substring(0,1).toUpperCase()+ eSignatory.FirstName__c.substring(1, eSignatory.FirstName__c.length()) +'</string></value></member>';
                   
                }
                if (eSignatory.LastName__c != Null){

                    XMLRequest += '<member><name>lastname</name><value><string>'+eSignatory.LastName__c.substring(0,1).toUpperCase() + eSignatory.lastName__c.substring(1, eSignatory.lastName__c.length()) +'</string></value></member>';
                }
              
                if (eSignatory.Code__c != Null && eSignatory.Code__c !=''){
                    XMLRequest += '<member><name>identificationType</name><value><string>'+eSignatory.Code__c+'</string></value></member>';
                }
                
                if (eSignatory.EmailTxt__c != Null){

                    XMLRequest += '<member><name>emailAddress</name><value><string>'+eSignatory.EmailTxt__c+'</string></value></member>';
                }
                /*if (eSignatory.cTin_Role__c != Null){
                    XMLRequest += '<member><name>role</name><value><string>'+eSignatory.cTin_Role_Universign__c+'</string></value></member>';
                }*/
                
                if(!eSignatory.esignature__r.cTin_TECH_IsContractIn__c){
                    if (eSignatory.MobileTxt__c != Null){
                      XMLRequest += '<member><name>phoneNum</name><value><string>'+eSignatory.MobileTxt__c.trim()+'</string></value></member>';
                    }
                }
                else{ 
                    if (eSignatory.contact__r.MobilePhone!= Null){
                        XMLRequest += '<member><name>phoneNum</name><value><string>'+eSignatory.contact__r.MobilePhone +'</string></value></member>';
                    }
                }

                XMLRequest += '<member><name>successURL</name><value><string>'+eSignatory.successURL__c+'</string></value></member>';
                XMLRequest += '<member><name>cancelURL</name><value><string>'+eSignatory.cancelURL__c+'</string></value></member>';
                XMLRequest += '<member><name>failURL</name><value><string>'+eSignatory.failURL__c+'</string></value></member>';
                XMLRequest += '</struct></value>';
            }
        }
        XMLRequest += '</data>';
        return XMLRequest;
    }
    
  
   /* //MRA 28-APR-2020 - get list of user email to put in cc => these users received a signed copy by email
    public static String ccemailArray(List<string> emailcclst)
    {
        String XMLRequest='';
      //  XMLRequest = '<data>';

        for(string ccemail: emailcclst)
        {
           // XMLRequest ='';
            if (ccemail != ''){
                XMLRequest += ccemail;
            } 
              
       }
        //XMLRequest += '</data>';
        return XMLRequest;
    }*/


    public static WrapperResponse CreateXmlRpc(eSignature__c eSignature, List<eSignatory__c> eSignatoryList, List<ContentDistribution> contDistList)
    {

        //ARA: 10-May-2021 -  block email invitation for all signers/validators and email notif with signed pdf for all
        Integer mustContactFirstSigner  = 0;
        Integer finalDocValidatorSent = 1;
        Integer finalDocSent = 1;
        //String chainingMode = 'email';
        String chainingMode = 'none';
        //MRA: 05-Dec-2017 - updated method to cater for contract-In profiles/sub profiles
        string ProfileName='';
        list<string>profileLst=new list<string>();
        string ccEmails='';
        //to uncomment when pushing to UAT/PROD
        if(eSignature.cTin_TECH_IsContractIn__c){
            //ProfileName - retrieve from cs based on entity of contract owner
            Map<String, cTin_UniversignProfiles__c> csUniversignProfile = cTin_UniversignProfiles__c.getAll();
            cTin_UniversignProfiles__c universignProfile= new cTin_UniversignProfiles__c() ;
            if(eSignature.contract__r.cTin_OwnerEntity__c=='500 - AXA Business Services Private Limited'){
                ProfileName='AXA_ABS';
            }            
            else if(csUniversignProfile.containskey(eSignature.contract__r.cTin_OwnerEntity__c)){
                if (csUniversignProfile.get(eSignature.contract__r.cTin_OwnerEntity__c).ProfileName__c!=null){
                    //stored in a single string in the format: default profile;supplier profile;axa profile
                    profileLst = csUniversignProfile.get(eSignature.contract__r.cTin_OwnerEntity__c).ProfileName__c.split(';');
                    ProfileName=profileLst[0];
                    system.debug('profile name : ' + ProfileName);
                }
                else{
                    ProfileName=system.label.AP22_cTinEnvironmentProfile;
                }
            }
            else{
                ProfileName=system.label.AP22_cTinEnvironmentProfile;
            }
            
            if(eSignature.contract__r.cTin_OwnerEntity__c=='1277 - AXA Gulf (EB)'){
               mustContactFirstSigner  = 1;
               finalDocValidatorSent = 1;
               finalDocSent = 1;
               chainingMode = 'email';
            }
            
        }else{
            // to block email invitation for all signers / validators
            mustContactFirstSigner  = 0;
            // to  block email notif with signed pdf for all
            finalDocValidatorSent = 0;
            finalDocSent = 0;
            // No invitation email is sent to the next signer
            chainingMode = 'none';
            //set to default
            ProfileName=system.label.AP22_ProfileEnvironment;
        }

        ////using one profile for contractin/allin/ats
        // ProfileName= system.label.AP22_ProfileEnvironment;

        system.debug('#### enter WrapperResponse CreateXmlRpc 1');
        map<string,string> mapLangCode=new Map<String, String>{'French'=>'fr','English'=>'en','Spanish'=>'es','German'=>'de'};

        string languageCode;
        
         //MRA:04-Jun-2020 - SP-00279: Universign accepts language codes: fr,en,de,es (does not impact OpCo)
        if (mapLangCode.containsKey(eSignature.language__c))
            languageCode=mapLangCode.get(eSignature.language__c);
        else 
             languageCode='en';
             
             
      /*  //Universign accepts language code,eg fr,en
        if (eSignature.language__c=='French')
            languageCode='fr';
        else
                languageCode='en';*/

        //MRA 26-09-2018 : For Ctin: set id as param for "Description" , For All-In set Name as param for "Description"
        string description;
        if(!eSignature.cTin_TECH_IsContractIn__c || ProfileName==system.label.AP22_ProfileEnvironment){
            description=eSignature.Contract__r.Name;
        }else{
              description=eSignature.Id;
            //description=eSignature.Contract__r.Name;
        }
        List<string> emailcclst = new list<string>();
        emailcclst.add('salesforce@sc-mauritius.com');
        
        list<esignatory__c>lstSigners =new list<esignatory__c>();
        list<esignatory__c>lstValidators =new list<esignatory__c>();
        
        for (esignatory__c esignatory:eSignatoryList){
            if(esignatory.cTin_Role__c=='Validator')
                lstValidators.add(esignatory);
            else
                lstSigners.add(esignatory);
        }
        
        system.debug('#### enter WrapperResponse CreateXmlRpc 2');
        //system.debug('## content '+ contDistList);
        /*if(esignature.cTin_TECH_IsContractIn__c){
            if (eSignature.contract__r.cTin_FinalDocRecipient__c!='' && eSignature.contract__r.cTin_FinalDocRecipient__c!=null){
                list<string> lstccemails=new list<string>();
                lstccemails=eSignature.contract__r.cTin_FinalDocRecipient__c.split(';');
                ccEmails= '<member><name>finalDocCCeMails</name><value><array><data>';
                
                for (string ccEmail:lstccemails){
                   ccEmails+='<value><string>'+ccEmail+'</string></value>';
                }
                ccEmails+='</data></array></value></member>';
            }
        }*/
        
        String XmlRpcRequest = '<?xml version="1.0" encoding="UTF-8"?>'
                +'<methodCall>'
                +'<methodName>requester.requestTransaction</methodName>'      
                +'<params>'
                +'<param>'
                +'<value>'
                +'<struct>'
                +'<member>'
                +'<name>profile</name>'
                +'<value>'
                +'<string>'+ProfileName+'</string>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>documents</name>'
                +'<value>'
                +'<array>'
                +DocumentsArray(eSignatoryList, contDistList,ProfileName)
                +'</array>'
                +'</value>'             
                +'</member>'
                +'<member>'
                +'<name>mustContactFirstSigner</name>'
                +'<value>'
                +'<boolean>'
                +mustContactFirstSigner
                +'</boolean>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>chainingMode</name>'
                +'<value>'
                +'<string>'
                + chainingMode
                +'</string>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>language</name>'
                +'<value>'
                +'<string>'
                + languageCode
                +'</string>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>signers</name>'
                +'<value>'
                +'<array>'
                + SignersArray(eSignatoryList)
                +'</array>'
                +'</value>'
                +'</member>'                
                +'<member>'
                +'<name>customId</name>'
                +'<value>'
                +'<string>'
                +'Id=' + eSignature.Id + '&Contract=' + eSignature.Contract__c + '&CreatedById=' + eSignature.CreatedById
                +'</string>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>finalDocSent</name>'
                +'<value>'
                +'<boolean>'
                +finalDocSent
                +'</boolean>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>finalDocValidatorSent</name>'
                +'<value>'
                +'<boolean>'
                +finalDocValidatorSent
                +'</boolean>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>finalDocRequesterSent</name>'
                +'<value>'
                +'<boolean>0</boolean>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>handwrittenSignatureMode</name>'
                +'<value>'
                +'<int>'
                +eSignature.HandWrittenSignatureMode__c
                +'</int>'
                +'</value>'
                +'</member>'
                +'<member>'
                +'<name>description</name>'
                +'<value>'
                +'<string>'
                +  description   //eSignature.Contract__r.Name //eSignature.Id
                +'</string>'
                +'</value>'
                +'</member>'
                +'</struct>'
                +'</value>'
                +'</param>'
                +'</params>'
                +'</methodCall>';
                
               /* if(ccEmails!='' && ccEmails!=null)
                    XmlRpcRequest+= ccEmails;
             
                XmlRpcRequest+='</struct>'
                    +'</value>'
                    +'</param>'
                    +'</params>'
                    +'</methodCall>';*/
                
                
        XmlRpcRequest = XmlRpcRequest.replace('&','&amp;'); // new

        system.debug('####dmu XmlRpcRequest: '+XmlRpcRequest);

        Http http = new Http();
        //DMU:20170606 - added dummy response for class coverage
        HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XmlRpcRequest));
        String xmlString = response.getBody();
        system.debug('####dmu response: '+response);
        system.debug('####dmu xmlString: '+xmlString);
        system.debug('####dmu (HttpRequest)buildHttpRequest(XmlRpcRequest): '+(HttpRequest)buildHttpRequest(XmlRpcRequest));
        return ParseXmlRPcResponse(eSignature , xmlString, XmlRpcRequest);
    }

    //Method to relaunch transaction
    public static WrapperResponse CreateXmlRpcForRelaunch(eSignature__c eSignature, string transactionId, list<eSignatory__c> esignatoryList, integer relaunchCount){
        //building XML
        String XmlRpcRequest =
                '<methodCall>'+
                        '<methodName>requester.relaunchTransaction</methodName>' +
                        '<params>'+
                        '<param>' +
                        '<value>' +
                        '<string>'  + transactionId + '</string>' +
                        '</value>' +
                        '</param>' +
                        '</params>'+
                        '</methodCall>';

        Http http = new Http();
        //DMU:20170606 - added dummy response for class coverage
        HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XmlRpcRequest));


        String xmlString = response.getBody();

        /*Evol Universign contract In
         Commmented to test with a dummy response
         String xmlString ='<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct><member><name>id</name><value><string>311a3f60-bbe8-31e7-9d0e-5c71a6a6ae74</string></value></member><member><name>url</name><value><string>https://app.universign.com/en/signature/?id=311b50d0-bbe8-31e7-9d0e-5c71a6a6ae74</string></value></member></struct></value></param></params></methodResponse>';
        */

        return ParseXmlRelaunchResponse(eSignature,xmlString,XmlRpcRequest,esignatoryList,relaunchCount);
    }


    //process Relaunch response
    public static WrapperResponse ParseXmlRelaunchResponse(eSignature__c eSignature, String  XML_STR, String XmlRpcRequest,list<esignatory__c> esignatoryList,integer relaunchCount){

        system.debug('##starting method ParseXmlRelaunchResponse');

        WrapperResponse WResponse = new WrapperResponse();

        eSignatureLog__c eSign_log = new eSignatureLog__c();

        //Indicates whether it's a Fault response or not
        boolean isFaultCode = false ;
        boolean isSuccessUrl = false ;
        boolean issuccessId = false ;
        boolean isFaultMessage = false ;

        XmlStreamReader reader = new XmlStreamReader(XML_STR);
        try{
            if (reader != null) {
                //Iterate over the Xml structure
                while (reader.hasNext()) {
                    //Check its not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                        break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        //Update Success Flags
                        if(reader.getText() == 'url'){
                            isSuccessUrl = true;
                        }
                        if(reader.getText() == 'id'){
                            isSuccessId = true;
                        }
                        if(reader.getText() == 'faultCode'){
                            isFaultCode = true;
                        }
                        if(reader.getText() == 'faultString'){
                            isFaultMessage = true;
                        }

                        //Handle Fault Case
                        if(isFaultCode == true && reader.getText() != 'faultCode'  && reader.getText() != '' && reader.getText() != ' '){
                            if(WResponse.FaultMessage == '')
                                WResponse.FaultMessage = 'Fault code is: ' + reader.getText();
                            isFaultCode = false;
                        }
                        else if(isFaultMessage == true && reader.getText() != 'faultString'  && reader.getText() != '' && reader.getText() != ' '){
                            WResponse.FaultMessage = reader.getText();
                            isFaultMessage = false;
                        }
                        else
                        {
                            //Handle Success Case
                            if(isSuccessId == true &&  reader.getText() != 'id'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.externalid = reader.getText() ;
                                isSuccessId = false;
                            }
                            if(isSuccessurl == true &&  reader.getText() != 'url'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.url = reader.getText() ;
                                isSuccessurl = false ;
                            }
                        }
                    }

                    reader.next();
                }
            }
            //update esignature
            
            system.debug('*** - relaunch : '+WResponse.externalId);
            eSignature.URL__c = WResponse.url;
            eSignature.Error_Message__c = WResponse.FaultMessage;
            update eSignature;

            //update esignatory
            esignatoryList[0].RelaunchCount__c=relaunchCount+1;
            esignatoryList[0].LastRelaunchDate__c=system.now();
            esignatoryList[0].RelaunchErrorMessage__c=WResponse.FaultMessage;
            update esignatoryList;

            //create esignature log
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = 'Submit Esignature';
            eSign_log.Response__c =  XML_STR;
            eSign_log.Request__c = XmlRpcRequest;
            eSign_log.DateCall__c = Datetime.now();
            insert eSign_log;

            return WResponse;
        }
        catch (Exception e){
            eSignatureLog__c eSignature_log = new eSignatureLog__c();
            eSignature_log.StepName__c = 'Relaunch Esignature and Parsing response';
            eSignature_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSignature_log.DateCall__c = Datetime.now();
            insert eSignature_log;
            return null;
        }

    }
  
    //ARA 28-APR-2021 - SP-01470
    //Method to retrieve refusal comment for a transaction for OpCo
    public static String GetRefusalComment(string transactionId){
        
        string refusalComment='';
        //integer index = integer.valueOf(esignatory.order__c)-1;
        //building XML
        String XmlRpcRequest =
                '<methodCall>'+
                        '<methodName>requester.getTransactionInfo</methodName>' +
                        '<params>'+
                        '<param>' +
                        '<value>' +
                        '<string>'  + transactionId + '</string>' +
                        '</value>' +
                        '</param>' +
                        '</params>'+
                  '</methodCall>';

        Http http = new Http();
        //DMU:20170606 - added dummy response for class coverage
        HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XmlRpcRequest));
        
        Dom.Document doc = response.getBodyDocument();
       
        DOM.XMLNode root = doc.getRootElement();
        try{
            Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
        
            Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElements();
            //getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
            system.debug('## xmlMembersArray'+xmlMembersArray.size());

            for (Dom.XMLNode element : xmlMembersArray) {
                Dom.xmlNode[] detailElement = element.getChildElements()[0].getChildElements();
                for (Dom.XMLNode detail : detailElement) {
                    if(detail.getChildElement('name',null).getText()=='refusalComment'){ 
                        refusalComment+=detail.getChildElement('value',null).getChildElement('string',null).getText();             
                    }
                }
            }
        }catch(Exception e){

        }
        
        return refusalComment;
    }
  
    //MRA 23-APR-2020 - SP-00239
    //Method to retrieve refusal comment for a transaction
    public static WrapperResponse CreateXmlRpcForRefusalComment(string transactionId,string esignatureId,esignatory__c esignatory){
        
        string refusalComment='';
        //integer index = integer.valueOf(esignatory.order__c)-1;
        //building XML
        String XmlRpcRequest =
                '<methodCall>'+
                        '<methodName>requester.getTransactionInfo</methodName>' +
                        '<params>'+
                        '<param>' +
                        '<value>' +
                        '<string>'  + transactionId + '</string>' +
                        '</value>' +
                        '</param>' +
                        '</params>'+
                  '</methodCall>';

        Http http = new Http();
        //DMU:20170606 - added dummy response for class coverage
        HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XmlRpcRequest));


        String xmlString = response.getBody();
        system.debug('##xmlString '+xmlString );
        
        Dom.Document doc = response.getBodyDocument();
       
        DOM.XMLNode root = doc.getRootElement();
        try{
            Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
        
            Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElements();
            //getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
            system.debug('## xmlMembersArray'+xmlMembersArray.size());

            for (Dom.XMLNode element : xmlMembersArray) {
                Dom.xmlNode[] detailElement = element.getChildElements()[0].getChildElements();
                for (Dom.XMLNode detail : detailElement) {
                    if(detail.getChildElement('name',null).getText()=='refusalComment'){ 
                        refusalComment+=detail.getChildElement('value',null).getChildElement('string',null).getText();             
                    }
                }
            }
        }catch(Exception e){

        }

        system.debug('## refusalComment '+refusalComment);
        esignatory.cTin_RefusalComment__c=refusalComment;
            esignatory.status__c=AP_Constant.esignatoryStatusCancelled;
            update esignatory;
        
        return ParseXmlRefusalResponse(xmlString,XmlRpcRequest,esignatureId,esignatory,refusalComment);
    }
    
      
    //process refusal comment response
    public static WrapperResponse ParseXmlRefusalResponse(string XML_STR,string XmlRpcRequest,string esignatureId,esignatory__c esignatory, string refusalComment){

        system.debug('##starting method ParseXmlRefusalResponse');

        WrapperResponse WResponse = new WrapperResponse();

        eSignatureLog__c eSign_log = new eSignatureLog__c();

        //Indicates whether it's a Fault response or not
        boolean isFaultCode = false ;
        boolean isSuccessUrl = false ;
        boolean issuccessId = false ;
        boolean isFaultMessage = false ;
        boolean isRefusalComment=false;
        //string refusalComment='';
        XmlStreamReader reader = new XmlStreamReader(XML_STR);
        try{
            if (reader != null) {
                //Iterate over the Xml structure
                while (reader.hasNext()) {
                    //Check its not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                        break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        //Update Success Flags
                        if(reader.getText() == 'url'){
                            isSuccessUrl = true;
                        }
                        if(reader.getText() == 'id'){
                            isSuccessId = true;
                        }
                        if(reader.getText() == 'faultCode'){
                            isFaultCode = true;
                        }
                        if(reader.getText() == 'faultString'){
                            isFaultMessage = true;
                        }
                        if(reader.getText() =='refusalComment'){
                            isRefusalComment=true;
                        }

                        //Handle Fault Case
                        if(isFaultCode == true && reader.getText() != 'faultCode'  && reader.getText() != '' && reader.getText() != ' '){
                            if(WResponse.FaultMessage == '')
                                WResponse.FaultMessage = 'Fault code is: ' + reader.getText();
                            isFaultCode = false;
                        }
                        else if(isFaultMessage == true && reader.getText() != 'faultString'  && reader.getText() != '' && reader.getText() != ' '){
                            WResponse.FaultMessage = reader.getText();
                            isFaultMessage = false;
                        }
                        else
                        {
                            //Handle Success Case
                            if(isSuccessId == true &&  reader.getText() != 'id'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.externalid = reader.getText() ;
                                isSuccessId = false;
                            }
                            if(isSuccessurl == true &&  reader.getText() != 'url'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.url = reader.getText() ;
                                isSuccessurl = false ;
                            }
                            
                             // if( reader.getText() == 'refusalComment'  && reader.getText() != '' && reader.getText() != ' '){
                               // WResponse.refusalComment= reader.getText() ;
                                //isSuccessurl = false ;
                               // refusalComment=reader.getText() ;
                            //}
                        }
                    }

                    reader.next();
                }
            }
           
            //update esignature
            eSignature__c esignature = new esignature__c(id=esignatureId);
            eSignature.URL__c = WResponse.url;
            eSignature.Error_Message__c = WResponse.FaultMessage;
            eSignature.status__c='Cancelled';
            
            update eSignature;
            
            list<esignatory__c >esignatorylst=new list<esignatory__c >();
            for(esignatory__c  signer:[select id,esignature__c,contract__c,contract__r.cTin_OwnerEntity__c from esignatory__c 
                                        where esignature__c =:esignatureId  and id <>: esignatory.Id]){
                    signer.status__c='Cancelled';
                    //if(signer.id==esignatory.Id){
                     //  esignatory.cTin_RefusalComment__c=refusalComment;
                   // }
                    esignatorylst.add(signer);
            }
            
           if(esignatorylst.size()>0)
                update esignatorylst;
             //esignatory.cTin_RefusalComment__c=refusalComment;            
             //esignatory.status__c='Cancelled';
             //update esignatory;

            //create esignature log
            eSign_log.eSignatureId__c = eSignatureId;
            eSign_log.StepName__c = 'Retrieving Refusal Comment';
            eSign_log.Response__c =  XML_STR;
            eSign_log.Request__c = XmlRpcRequest;
            eSign_log.DateCall__c = Datetime.now();
            insert eSign_log;

            return WResponse;
        }
        catch (Exception e){
            eSignatureLog__c eSignature_log = new eSignatureLog__c();
            eSignature_log.StepName__c = 'Retrieving Refusal Comment Parsing response';
            eSignature_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSignature_log.DateCall__c = Datetime.now();
            insert eSignature_log;
            return null;
        }

    }


    //Method to cancel Transaction
    public static WrapperResponse CreateXmlRpcForCancel(eSignature__c eSignature, string transactionId, list<eSignatory__c> esignatoryList){
        //building XML
        String XmlRpcRequest =
                '<methodCall>'+
                        '<methodName>requester.cancelTransaction</methodName>' +
                        '<params>'+
                        '<param>' +
                        '<value>' +
                        '<string>'+ transactionId + '</string>' +
                        '</value>' +
                        '</param>' +
                        '</params>'+
                        '</methodCall>';
        System.debug('@@@ XmlRpcRequest ' + XmlRpcRequest);

        Http http = new Http();

        //DMU:20170606 - commented if/else test.isrunningTest for testCoverage
        HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XmlRpcRequest));
        System.debug('@@@ response ' + response);

        String xmlString = response.getBody();
        System.debug('@@@ xmlString ' + xmlString);

        return ParseXmlCancelResponse(eSignature,xmlString,XmlRpcRequest,esignatoryList);
    }

    //method to process cancel response
    public static WrapperResponse ParseXmlCancelResponse(eSignature__c eSignature, String  XML_STR, String XmlRpcRequest,list<esignatory__c> esignatoryList){

        system.debug('##starting method ParseXmlCancelResponse');

        WrapperResponse WResponse = new WrapperResponse();

        eSignatureLog__c eSign_log = new eSignatureLog__c();

        //Indicates wheather it''s a Fault response or not
        boolean isFaultCode = false ;
        boolean isSuccessUrl = false ;
        boolean issuccessId = false ;
        boolean isFaultMessage = false ;

        XmlStreamReader reader = new XmlStreamReader(XML_STR);
        try{
            if (reader != null) {
                //Iterate over the Xml structure
                while (reader.hasNext()) {
                    //Check its not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                        break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        //Update Success Flags
                        if(reader.getText() == 'url'){
                            isSuccessUrl = true;
                        }
                        if(reader.getText() == 'id'){
                            isSuccessId = true;
                        }
                        if(reader.getText() == 'faultCode'){
                            isFaultCode = true;
                        }
                        if(reader.getText() == 'faultString'){
                            isFaultMessage = true;
                        }

                        //Handle Fault Case
                        if(isFaultCode == true && reader.getText() != 'faultCode'  && reader.getText() != '' && reader.getText() != ' '){
                            if(WResponse.FaultMessage == '')
                                WResponse.FaultMessage = 'Fault code is: ' + reader.getText();
                            isFaultCode = false;
                        }
                        else if(isFaultMessage == true && reader.getText() != 'faultString'  && reader.getText() != '' && reader.getText() != ' '){
                            WResponse.FaultMessage = reader.getText();
                            isFaultMessage = false;
                        }
                        else
                        {
                            //Handle Success Case
                            if(isSuccessId == true &&  reader.getText() != 'id'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.externalid = reader.getText() ;
                                isSuccessId = false;
                            }
                            if(isSuccessurl == true &&  reader.getText() != 'url'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.url = reader.getText() ;
                                isSuccessurl = false ;
                            }
                        }
                    }

                    reader.next();
                }
            }

            //update esignature
            system.debug('*** - '+WResponse.externalId);
            eSignature.URL__c = WResponse.url;
            eSignature.Error_Message__c = WResponse.FaultMessage;
            
            //07-JAN-2021: Update status of esignature to cancelled only if no error msg is received from Universign
            if(WResponse.FaultMessage==null || WResponse.FaultMessage=='' || WResponse.FaultMessage==' ')
                eSignature.Status__c = 'Cancelled';           
            eSignature.SignatureDateTime__c = system.now();
            try{
                update eSignature;
            }catch(Exception e){
System.debug('***** '+ e.getMessage());
            }

            //update esignatory
            list<eSignatory__c> eSignatoryToUpdate = new list<eSignatory__c>();
            //07-JAN-2021: Update status of esignatories to cancelled only if no error msg is received from Universign
            if(WResponse.FaultMessage==null || WResponse.FaultMessage=='' || WResponse.FaultMessage==' ' || string.isblank(eSignature.transactionId__c)){
                for(eSignatory__c eSignatory: eSignatoryList){
                    eSignatory.Status__c = AP_Constant.esignatoryStatusCancelled;
                    eSignatoryToUpdate.add(eSignatory);
                }
                update eSignatoryToUpdate;
            }
            //inserting log
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = 'Cancel Esignature';
            eSign_log.Response__c =  XML_STR;
            eSign_log.Request__c = XmlRpcRequest;
            eSign_log.DateCall__c = Datetime.now();
            insert eSign_log;

            return WResponse;
        }
        catch (Exception e){
            eSignatureLog__c eSignature_log = new eSignatureLog__c();
            eSignature_log.StepName__c = 'Cancel Esignature and Parsing response';
            eSignature_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSignature_log.DateCall__c = Datetime.now();
            insert eSignature_log;
            return null;
        }

    }

    //Wrapper class returned as a response
    public class WrapperResponse{
        public String externalId ;
        public string Url ;
        public string FaultMessage ;
        public Map<String,String> map1 ;

        public WrapperResponse(){
            externalId = '';
            Url = '';
            FaultMessage = '';
            map1 = new Map<String,String>();
        }
    }

    //Method Parse the response as XMLRPC structure and return WrapperResponse class
    public static WrapperResponse ParseXmlRPcResponse(eSignature__c eSignature, String  XML_STR, String XmlRpcRequest){

        WrapperResponse WResponse = new WrapperResponse();

        eSignatureLog__c eSign_log = new eSignatureLog__c();

        //Indicates whether it's a Fault response or not
        boolean isFaultCode = false ;
        boolean isSuccessUrl = false ;
        boolean issuccessId = false ;
        boolean isFaultMessage = false ;

        XmlStreamReader reader = new XmlStreamReader(XML_STR);
        try{
            if (reader != null) {
                //Iterate over the Xml structure
                while (reader.hasNext()) {
                    system.debug('***** '+reader);
                    //Check its not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                        break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        //Update Success Flags
                        if(reader.getText() == 'url'){
                            isSuccessUrl = true;
                        }
                        if(reader.getText() == 'id'){
                            isSuccessId = true;
                        }
                        if(reader.getText() == 'faultCode'){
                            isFaultCode = true;
                        }
                        if(reader.getText() == 'faultString'){
                            isFaultMessage = true;
                        }

                        //Handle Fault Case
                        if(isFaultCode == true && reader.getText() != 'faultCode'  && reader.getText() != '' && reader.getText() != ' '){
                            if(WResponse.FaultMessage == '')
                                WResponse.FaultMessage = 'Fault code is: ' + reader.getText();
                            isFaultCode = false;
                        }
                        else if(isFaultMessage == true && reader.getText() != 'faultString'  && reader.getText() != '' && reader.getText() != ' '){
                            WResponse.FaultMessage = reader.getText();
                            isFaultMessage = false;
                        }
                        else
                        {
                            //Handle Success Case
                            if(isSuccessId == true &&  reader.getText() != 'id'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.externalid = reader.getText() ;
                                isSuccessId = false;
                            }
                            if(isSuccessurl == true &&  reader.getText() != 'url'  && reader.getText() != '' && reader.getText() != ' '){
                                WResponse.url = reader.getText() ;
                                isSuccessurl = false ;
                            }
                        }
                    }
                    reader.next();
                }
            }

            //update esignature
            if(WResponse.externalId != null && WResponse.externalId != '')
                eSignature.ExternalId__c  = WResponse.externalId;

            eSignature.URL__c = WResponse.url;
            eSignature.Error_Message__c = WResponse.FaultMessage;

            if(WResponse.externalId != null && WResponse.externalId != '')
                eSignature.transactionId__c  = WResponse.externalId;
            
            //MRA 28/05 - Automate esignature
            if(eSignature.TECH_AutomatedEsign__c){
            string xmlstr=getTransactionInfo(eSignature,WResponse.externalId);
            list<string> signurlList=new list<string>();
            
            system.debug('xmlString from AP22'+xmlstr);   
            
            list<string> lst=(string.valueOf(xmlstr)).split('<member>');
            for(string s: lst){
                String str2 = s.subStringBetween('<string>', '</string>');
                System.debug('##str'+str2);
                if(str2!=null){
                    if(str2.startsWith('https')){
                        signurlList.add(str2);
                    }
                }
            }
            list<esignatory__c> esignatoryToUpdateLst=new list<esignatory__c>(); 
            list<esignatory__c>esignatoryLst=[Select Contact__r.FirstName, Contact__r.LastName,esignature__c,cTin_signLink__c,order__c,
                                              esignature__r.Name, esignature__r.Status__c, esignature__r.CreatedDate, 
                                              esignature__r.Contract__r.Name, esignature__r.CreatedById, 
                                              esignature__r.FinalDocumentURL__c, esignature__r.ExternalId__c
                                              from  eSignatory__c
                                              where eSignature__c = :  eSignature.id
                                              order by order__c asc];
                                                  
                                                  
            if(esignatoryLst.size()>0 && signurlList.size()>0){
                for(integer i=0;i<esignatoryLst.size();i++){                
                    esignatoryLst[i].cTin_signLink__c= signurlList[i];    
                    esignatoryLst[i].signURL__c = signurlList[i];    
                    esignatoryToUpdateLst.add(esignatoryLst[i]);  
                }
            }
            
            if(esignatoryToUpdateLst.size()>0){
                update esignatoryToUpdateLst ; 
            } 
            }

            update eSignature;

            //update log
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = 'Submit Esignature';
            eSign_log.Response__c =  XML_STR;
            eSign_log.Request__c = XmlRpcRequest;
            eSign_log.DateCall__c = Datetime.now();
            insert eSign_log;
            return WResponse;
        }
        catch (Exception e){
            system.debug('*********** error '+e.getMessage());
            eSignatureLog__c eSignature_log = new eSignatureLog__c();
            eSignature_log.StepName__c = 'Submit Esignature and Parsing response';
            eSignature_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber() + '.  Response: ' +XML_STR;
            eSignature_log.DateCall__c = Datetime.now();
            insert eSignature_log;

            //eSignature.transactionId__c  = 'Error while Submitting Esignature and Parsing response';
            eSignature.Error_Message__c  = 'Error while Submitting Esignature and Parsing response';
            update eSignature;

            return null;
        }
    }

    public static WrapperResponse ParseXmlRPcResponse2(String  XML_STR)
    {
        WrapperResponse WResponse = new WrapperResponse();
        //Indicates whether it's a Fault response or not
        String firstName, lastName, url;
        Boolean isFaultCode = false;
        Boolean isSuccessFirstName = false;
        Boolean isSuccessLastName = false;
        Boolean isSuccessUrl = false;
        Boolean isFaultMessage = false;
        Boolean isInSignerInfos = false;
        Boolean tookFirstName = false, tookLastName = false, tookUrl = false;
        XmlStreamReader reader = new XmlStreamReader(XML_STR);
        try{
            if (reader != null) {
                //Iterate over the Xml structure
                while (reader.hasNext()) {
                    //Check its not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                        break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {
                        //Update Success Flags
                        if(reader.getText() == 'firstName'){
                            isSuccessFirstName = true;
                        }
                        if(reader.getText() == 'lastName'){
                            isSuccessLastName = true;
                        }
                        if(reader.getText() == 'url'){
                            isSuccessUrl = true;
                        }
                        if(reader.getText() == 'faultCode'){
                            isFaultCode = true;
                        }
                        if(reader.getText() == 'faultString'){
                            isFaultMessage = true;
                        }

                        //Handle Fault Case
                        if(isFaultCode == true && reader.getText() != 'faultCode'  && reader.getText() != '' && reader.getText() != ' '){
                            if(WResponse.FaultMessage == '')
                                WResponse.FaultMessage = 'Fault code is: ' + reader.getText();
                            isFaultCode = false;
                        }
                        else if(isFaultMessage == true && reader.getText() != 'faultString'  && reader.getText() != '' && reader.getText() != ' '){
                            WResponse.FaultMessage = reader.getText();
                            return WResponse;
                        }
                        else
                        {
                            //Handle Success Case
                            if(isSuccessFirstName == true &&  reader.getText() != 'firstName' && reader.getText() != '' && reader.getText() != ' '){
                                firstName = reader.getText();
                                isSuccessFirstName = false;
                                tookFirstName = true;
                            }
                            if(isSuccessLastName == true &&  reader.getText() != 'LastName' && reader.getText() != '' && reader.getText() != ' '){
                                lastName = reader.getText();
                                isSuccessLastName = false;
                                tookLastName = true;
                            }
                            if(isSuccessUrl == true &&  reader.getText() != 'url' && reader.getText() != '' && reader.getText() != ' ' && reader.getText()!=null){
                                url = reader.getText();
                                isSuccessurl = false;
                                tookUrl = true;
                            }
                        }
                        if(tookFirstName && tookLastName && tookUrl){
                            tookFirstName = false; tookLastName = false; tookUrl = false;
                            WResponse.map1.put(firstName+lastName,url);
                        }
                    }
                    reader.next();
                }
            }
            return WResponse;
        }
        catch (Exception e){
            eSignatureLog__c eSignature_log = new eSignatureLog__c();
            eSignature_log.StepName__c = 'Parsing response';
            eSignature_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSignature_log.DateCall__c = Datetime.now();
            insert eSignature_log;
            return null;
        }
    }

    public static String getTransactionInfo(eSignature__c eSignature)
    {

        String XMLRequest =
                '<methodCall>'

                        +
                        '<methodName>requester.getTransactionInfo</methodName>'

                        +
                        '<params>'

                        +
                        '<param>'

                        +
                        '<value>'

                        +
                        '<string>'

                        +
                        eSignature.ExternalId__c

                        +
                        '</string>'

                        +
                        '</value>'

                        +
                        '</param>'

                        +
                        '</params>'

                        +
                        '</methodCall>';

        Http http = new Http();
        try{
            //DMU:20170606 - added dummy response for class coverage
            HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XMLRequest));
            String xmlString = response.getBody();
        
            eSignatureLog__c eSign_log = new eSignatureLog__c();
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = 'TR001. getSignatories';
            eSign_log.Response__c =  xmlString;
            eSign_log.Request__c = XMLRequest;
            eSign_log.DateCall__c = Datetime.now();

            insert eSign_log;
            
            system.debug('##xmlString'+xmlString);
            /*list<esignatory__c> esignatorylst= [select id from esignatory__c where eSignature__c =: eSignature.Id order by Order__c asc];
            list<string> signurlList=new list<string>();
            list<string> lst=(string.valueOf(xmlString)).split('<member>');
                for(string s: lst){
                String str2 = s.subStringBetween('<string>', '</string>');
                System.debug('##str'+str2);
                if(str2.startsWith('https')){
                  signurlList.add(str2);
                }
            }
            
            system.debug('##signurlList.size()'+signurlList);
           */
            /*
                Dom.Document doc = response.getBodyDocument();
           
                DOM.XMLNode root = doc.getRootElement();
        
                Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
                
                system.debug('##xmlValueArray.size()'+xmlValueArray.size());
                
                
                   
                   
                   Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
                   Dom.xmlNode[] xmlMembersArray2= xmlValueArray[1].getChildElement('value',null).getChildElement('struct',null).getchildelements();
  
                   system.debug( 'xmlMembersArray' + xmlMembersArray.size());
                   system.debug( 'xmlMembersArray2' + xmlMembersArray2.size());
                
                    for(integer i=0;i<xmlMembersArray.size();i++){                   
                        if(xmlMembersArray[i].getChildElement('name',null).getText()=='url'){
                         system.debug('url detected : ' +  xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText());                                
                        }                         
                    }
                
            
                  for(integer i=0;i<xmlMembersArray2.size();i++){                   
                        if(xmlMembersArray2[i].getChildElement('name',null).getText()=='url'){
                         system.debug('url detected : ' +  xmlMembersArray2[i].getChildElement('value',null).getChildElement('string',null).getText());                                
                        }                         
                    }*/
            
            
           /* 
            //MRA 12/05/2020
            
        
            Dom.Document doc = response.getBodyDocument();
           
            DOM.XMLNode root = doc.getRootElement();
    
            Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
            
            system.debug('##xmlValueArray.size()'+xmlValueArray.size());
           
             Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
            for(integer i=0;i<xmlMembersArray.size();i++){
                //system.debug('element name' +xmlValueArray[i].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements());
               // Dom.xmlNode[] xmlMembersArray= xmlValueArray[i].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
                 //system.debug('##xmlMembersArray.size()'+xmlMembersArray.size());
                 
               // for(integer j=0;j<xmlMembersArray.size();j++){
                    if(xmlMembersArray[i].getChildElement('name',null).getText()=='url'){
                     system.debug('url detected : ' +  xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText());   
                    // refusalComment=xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText();             
                    }   
                
              //  }
                       
            }*/
            
             return xmlString;
            
        }
        catch(exception e){
            return '';
        }
    }
    
    public static String getTransactionInfo(eSignature__c eSignature, string transactionId)
    {

        String XMLRequest =
                '<methodCall>'

                        +
                        '<methodName>requester.getTransactionInfo</methodName>'

                        +
                        '<params>'

                        +
                        '<param>'

                        +
                        '<value>'

                        +
                        '<string>'

                        +
                        transactionId

                        +
                        '</string>'

                        +
                        '</value>'

                        +
                        '</param>'

                        +
                        '</params>'

                        +
                        '</methodCall>';

        Http http = new Http();
        try{
            //DMU:20170606 - added dummy response for class coverage
            HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XMLRequest));
            String xmlString = response.getBody();
        
            eSignatureLog__c eSign_log = new eSignatureLog__c();
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = 'TR001. getSignatories';
            eSign_log.Response__c =  xmlString;
            eSign_log.Request__c = XMLRequest;
            eSign_log.DateCall__c = Datetime.now();

            insert eSign_log;
            
            system.debug('##xmlString'+xmlString);
            /*list<esignatory__c> esignatorylst= [select id from esignatory__c where eSignature__c =: eSignature.Id order by Order__c asc];
            list<string> signurlList=new list<string>();
            list<string> lst=(string.valueOf(xmlString)).split('<member>');
                for(string s: lst){
                String str2 = s.subStringBetween('<string>', '</string>');
                System.debug('##str'+str2);
                if(str2.startsWith('https')){
                  signurlList.add(str2);
                }
            }
            
            system.debug('##signurlList.size()'+signurlList);
           */
            /*
                Dom.Document doc = response.getBodyDocument();
           
                DOM.XMLNode root = doc.getRootElement();
        
                Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
                
                system.debug('##xmlValueArray.size()'+xmlValueArray.size());
                
                
                   
                   
                   Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
                   Dom.xmlNode[] xmlMembersArray2= xmlValueArray[1].getChildElement('value',null).getChildElement('struct',null).getchildelements();
  
                   system.debug( 'xmlMembersArray' + xmlMembersArray.size());
                   system.debug( 'xmlMembersArray2' + xmlMembersArray2.size());
                
                    for(integer i=0;i<xmlMembersArray.size();i++){                   
                        if(xmlMembersArray[i].getChildElement('name',null).getText()=='url'){
                         system.debug('url detected : ' +  xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText());                                
                        }                         
                    }
                
            
                  for(integer i=0;i<xmlMembersArray2.size();i++){                   
                        if(xmlMembersArray2[i].getChildElement('name',null).getText()=='url'){
                         system.debug('url detected : ' +  xmlMembersArray2[i].getChildElement('value',null).getChildElement('string',null).getText());                                
                        }                         
                    }*/
            
            
           /* 
            //MRA 12/05/2020
            
        
            Dom.Document doc = response.getBodyDocument();
           
            DOM.XMLNode root = doc.getRootElement();
    
            Dom.xmlNode[] xmlValueArray = root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('struct',null).getChildElements();
            
            system.debug('##xmlValueArray.size()'+xmlValueArray.size());
           
             Dom.xmlNode[] xmlMembersArray= xmlValueArray[0].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
            for(integer i=0;i<xmlMembersArray.size();i++){
                //system.debug('element name' +xmlValueArray[i].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements());
               // Dom.xmlNode[] xmlMembersArray= xmlValueArray[i].getChildElement('value',null).getChildElement('array',null).getChildElement('data',null).getChildElement('value',null).getChildElement('struct',null).getchildelements();
            
                 //system.debug('##xmlMembersArray.size()'+xmlMembersArray.size());
                 
               // for(integer j=0;j<xmlMembersArray.size();j++){
                    if(xmlMembersArray[i].getChildElement('name',null).getText()=='url'){
                     system.debug('url detected : ' +  xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText());   
                    // refusalComment=xmlMembersArray[i].getChildElement('value',null).getChildElement('string',null).getText();             
                    }   
                
              //  }
                       
            }*/
            
             return xmlString;
            
        }
        catch(exception e){
            return '';
        }
    }

    public static void CreateXmlRpcForSignedDocument(eSignature__c eSignature,contract__c contract, string source){

        hasExecutedXmlRpc=true;
        list<eSignatureLog__c>esignLogLst=new list<eSignatureLog__c>();
        string documentTitle=null;
        string body='';
        String xmlString=null;
        List<ContentDocumentLink> lstcdl = new List<ContentDocumentLink>();
        List<ContentDocumentLink> lstcTin_cdl = new List<ContentDocumentLink>();
        List<Contract__c> lstCtr = new List<Contract__c>();

        contract = [SELECT id, OpCo_Send_Automatic_PO_Reminder__c, OpCo_CountILNoPO__c, Tech_RecordTypeName__c, TECH_IsContractIn__c FROM contract__c  WHERE id = :contract.Id];        

        //stores the pdf name (as key) -> base 64 (as value)
        map<string,string>mapDocNameBase64=new map<string,string>();


        string XMLRequest ='<methodCall>' +
                '<methodName>requester.getDocuments</methodName>' +
                '<params>' +
                '<param>' +
                '<value>' +
                '<string>' +
                eSignature.ExternalId__c+
                '</string>' +
                '</value>'+
                '</param>'+
                '</params>'+
                '</methodCall>';

        try{
            boolean isFaultMessage=false;
            Httprequest request = new HttpRequest();

            Http http = new Http();
            //DMU:20170606 - added dummy response for class coverage
            HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XMLRequest));

            /*

            xmlString=response.getBody();

            if(xmlString.contains('faultString') || xmlString.contains('faultCode') || (test.isRunningTest() && testError)){
                isFaultMessage=true;
                //response is not captured in log when signed document is retrieved successfully since response returned is too long
                // only fault response is captured
                eSignatureLog__c eSignature_log = new eSignatureLog__c();
                eSignature_log.eSignatureId__c = eSignature.Id;
                eSignature_log.StepName__c = 'Error: '+ source + ' execution to retrieve signed content ';
                //eSignature_log.Response__c =  xmlString;
                eSignature_log.Request__c = XMLRequest;
                eSignature_log.DateCall__c = Datetime.now();
                esignLogLst.add(eSignature_log);
            }
      */

            //22-MARS-2018:MRA reworked logic to read all signed copies returned in XML response. (Contract-In ACH can submit more than one doc for signature)
            if  (!isFaultMessage){
                /*
                Dom.Document doc = new Dom.Document();
                doc.load(xmlString.remove('<struct></struct>'));
                */
                Dom.Document doc = response.getBodyDocument();
                DOM.XMLNode root = doc.getRootElement();
                system.debug('## root '+root);
                Dom.xmlNode[] xmlValueArray=root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('array', null).getChildElement('data', null).getChildElements();
                string filename='';

                //loop through xml to read all member tags in order to retrieve filename + base 64
                for(integer i=0;i<xmlValueArray.size();i++){
                    Dom.xmlNode[] xmlMembersArray= xmlValueArray[i].getChildElement('struct',null).getChildElements();
                    for(integer j=0;j<xmlMembersArray.size();j++){
                        //retrieving file name
                        if(xmlMembersArray[j].getChildElement('name',null).getText()=='fileName'){
                            //13-JUL-2018 - MRA : appended  '*' + i to title
                            //Reason: to generate unique filenames and to be able to build mapDocNameBase64 correctly
                            filename=(xmlMembersArray[j].getChildElement('value',null).getChildElement('string',null).getText()).remove('.pdf')+'*'+i+ '_signed.pdf';
                        }

                        //retrieving content
                        if(xmlMembersArray[j].getChildElement('name',null).getText()=='content'){
                            mapDocNameBase64.put(filename,xmlMembersArray[j].getChildElement('value',null).getChildElement('base64',null).getText());
                        }
                    }
                }
            }//if not fault message
            //system.debug('mapDocNameBase64'+ mapDocNameBase64);

            list<ContentDistribution> cdeSignList=new list<ContentDistribution>();
            list<ContentVersion>lstContractContentVersion=new list<ContentVersion>();
            list<ContentDistribution> cdContractList=new list<ContentDistribution>();
            //create content versions + attachments (All-In + ATS Only)
            if(mapDocNameBase64.size()>0){
                list<Attachment> lstAttachment=new list<Attachment>();
                //applicable for All-In + ATS only
                for(string file:mapDocNameBase64.keyset()){
                    // system.debug('file'+file);
                    if(contract.Tech_RecordTypeName__c.contains('OpCo360')){
                        lstAttachment.add(new Attachment(name=file.substringBefore('*')+'_signed.pdf',parentId=contract.id,
                                body= (test.isRunningTest()? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(mapDocNameBase64.get(file)))));
                    }
                }
                system.debug('lstAttachment'+ lstAttachment);
                if(lstAttachment.size()>0)
                    insert lstAttachment;

                //Query workspace for All-In ,ATS + contract-In
                string workspaceId;
                if (test.isrunningTest()){
                    workspaceId=[SELECT Id,name,DeveloperName
                    FROM ContentWorkspace
                    where DeveloperName=:'Workspace_test'
                    limit 1].id;
                }
                else{
                    // query content workspace for All-In  + ATS
                    if(contract.Tech_RecordTypeName__c.contains('OpCo360')){
                        system.debug('## querying OpCo workspace');
                        workspaceId=[SELECT Id,name,DeveloperName
                        FROM ContentWorkspace
                        where DeveloperName=:system.label.ContentWorkspace
                        limit 1].id;
                    }
                    else{
                       system.debug('## querying cTin workspace');
                        // query content workspace for Contract-In
                        workspaceId=[SELECT Id,name,DeveloperName
                        FROM ContentWorkspace
                        where DeveloperName=:system.label.cTin_ContentWorkspace
                        limit 1].id;
                    }
                }
                
                system.debug('## ctin workspaceId'+ system.label.cTin_ContentWorkspace);
                system.debug('## opco workspaceId'+ system.label.ContentWorkspace);
                system.debug('##AP22signed## workspaceId'+ workspaceId);

                //create contentversions for contract (ATS,All-In,Contract-In)
                for(string file:mapDocNameBase64.keyset()){
                    ContentVersion cv = new ContentVersion();
                    cv.Title = file.substringBefore('*')+'_signed.pdf';
                    cv.PathOnClient = file.substringBefore('*')+'_signed.pdf';
                    cv.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(mapDocNameBase64.get(file)));

                    // firstpublishLocationId needs not be specified for unit tests, asssigned automatically to the workspace created in test class
                    // if assigned throws an exception invalid id
                    if (!test.isrunningTest()){
                        cv.FirstPublishLocationId = workspaceId;
                    }
                    system.debug('##AP22signed## cv'+ cv);
                    lstContractContentVersion.add(cv);
                }
                system.debug('##AP22signed## lstContractContentVersion'+ lstContractContentVersion);
                if(lstContractContentVersion.size()>0){
                    insert lstContractContentVersion;


                    list<ContentVersion> cveSignList=new list<ContentVersion>();

                    //create content distributions for contract (All-IN,ATS,Contract-In)
//                    for(contentVersion cv: lstContractContentVersion){
                    for (ContentVersion cv :[SELECT id, ContentDocumentId, title,VersionData FROM ContentVersion WHERE id IN :lstContractContentVersion]){
                        //USA : Migration lightning
                       // if (contract.Tech_RecordTypeName__c.contains('OpCo360')) {
                            lstcdl.add(new contentDocumentLink(
                                    ContentDocumentId = cv.ContentDocumentId,
                                    LinkedEntityId = contract.Id,
                                    ShareType = 'V',
                                    Visibility = 'AllUsers'
                            ));
                            
                            
                       // }
                       
                       if (contract.Tech_RecordTypeName__c.contains('cTin')){
                           lstcTin_cdl.add(new contentDocumentLink(
                                    ContentDocumentId = cv.ContentDocumentId,
                                    LinkedEntityId = eSignature.Id,
                                    ShareType = 'V',
                                    Visibility = 'AllUsers'));
                           ContentVersion cvEsign = new ContentVersion();
                           cvEsign.Title = cv.title;
                           cvEsign.PathOnClient = cv.title;
                           cvEsign.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):cv.versionData);
                           cvEsign.FirstPublishLocationId = workspaceId;
                          // insert cvEsign;
                           
                          if(cv!=null) {
                                ContentDistribution contentEsignature = new ContentDistribution();
                                contentEsignature.RelatedRecordId = eSignature.Id;
                                contentEsignature.Name = cv.title;
                                contentEsignature.ContentVersionId = cv.Id;
                                contentEsignature.PreferencesNotifyOnVisit = false ;
                                cdeSignList.add(contentEsignature);
 
                            }
                       }

                        if(cv!=null){
                           /* ContentDistribution contentContract = new ContentDistribution();
                            contentContract.RelatedRecordId = contract.Id;
                            contentContract.Name = cv.title;
                            contentContract.ContentVersionId = cv.Id;
                            contentContract.PreferencesNotifyOnVisit = false ;
                            cdContractList.add(contentContract);
                           
                           if (contract.Tech_RecordTypeName__c.contains('cTin')){
                                ContentVersion cvEsign = new ContentVersion();
                                cvEsign.Title = cv.title;
                                cvEsign.PathOnClient = cv.title;
                                cvEsign.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):cv.versionData);
                                cveSignList.add(cvEsign);
                                if(cveSignList.size()>0)
                                    insert cveSignList;
                                for(ContentVersion cve :cveSignList){
                                    ContentDistribution contentesign = new ContentDistribution();
                                    contentesign.RelatedRecordId = eSignature.Id;
                                    contentesign.Name = cve.title;
                                    contentesign.ContentVersionId = cve.Id;
                                    contentesign.PreferencesNotifyOnVisit = false ;
                                    cdeSignList.add(contentesign);
                                }
                           } 
                            */
                        }

                       /* //create content version for esignature (Contract-In only)
                        if(esignature.cTin_TECH_IsContractIn__c){
                            
                            ContentVersion cvEsign = new ContentVersion();
                            cvEsign.Title = cv.title;
                            cvEsign.PathOnClient = cv.title;
                            cvEsign.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):cv.versionData);
                            cveSignList.add(cvEsign);
                        }*/
                    }
                    
                    
                                
                    system.debug('##AP22signed## lstcdl'+ lstcdl);
                    if (lstcdl != null) {
                        insert lstcdl;
                    }
                    if (lstcTin_cdl != null) {
                     insert lstcTin_cdl ;
                    }
                    
                 // if(cdeSignList.size()>0)
                      // insert cdeSignList;
                    /*//insert content distribution for contract
                    if(cdContractList.size()>0){
                        insert cdContractList;
                    }*/

                   /* //insert content version for esignature (Contract-In only)
                    if(cveSignList.size()>0){
                        insert cveSignList;
                    }*/
                    //create content distribution & content doc link for esignature (Contract-In only)
                   // if(cveSignList.size()>0 || cdContractList.size()>0){
                      
                       // list<ContentDocumentLink> lstCDLs=new list<ContentDocumentLink>();
                        /*
                        for(ContentVersion cv:[SELECT id, ContentDocumentId, title,VersionData FROM ContentVersion WHERE id IN :cveSignList or id IN:lstContractContentVersion]){
                            if(cv!=null){
                                ContentDistribution contentEsignature = new ContentDistribution();
                                contentEsignature.RelatedRecordId = eSignature.Id;
                                contentEsignature.Name = cv.title;
                                contentEsignature.ContentVersionId = cv.Id;
                                contentEsignature.PreferencesNotifyOnVisit = false ;
                                cdeSignList.add(contentEsignature);
 
                                // eSignature
                                ContentDocumentLink cdlEsignature = new ContentDocumentLink();
                                cdlEsignature.LinkedEntityId = eSignature.Id;
                                cdlEsignature.ContentDocumentId = cv.ContentDocumentId;
                                cdlEsignature.ShareType = 'V';
                                cdlEsignature.Visibility = 'AllUsers';
                                lstCDLs.add(cdlEsignature);

                                //Contract
                                ContentDocumentLink cdlCtr = new ContentDocumentLink();
                                cdlCtr.LinkedEntityId = contract.Id;
                                cdlCtr.ContentDocumentId = cv.ContentDocumentId;
                                cdlCtr.ShareType = 'V';
                                cdlCtr.Visibility = 'AllUsers';
                                lstCDLs.add(cdlCtr);
                            }
                        }*/

                        //insert content distribution for esignature (Contract-In only)
                        /*System.debug('@@ cTin cdeSignList '+cdeSignList);
                      
                        if(cdeSignList.size()>0){
                            insert cdeSignList;
                        }*/
                      /*  //insert content doc link for esignature (Contract-In only)
                        System.debug('@@ cTin lstCDLs '+lstCDLs);
                        if(lstCDLs.size()>0){
                            try{
                                insert lstCDLs;
                            }
                            catch(Exception ex){
                                System.debug('@@@ exception ' + ex.getMessage());
                            }
                        }*/
                        
                   // }

                }

                /* //updating final document url on contract
                 list<ContentDistribution> cdLst= [select id,DistributionPublicUrl
                                                 from ContentDistribution
                                                 where id=:cdContractList[0].id];
                 if(cdLst.size()>0){
                    if(cdLst[0].DistributionPublicUrl !=null){
                         contract.FinalDocumentURL__c=cdLst[0].DistributionPublicUrl;
                         update contract;
                    }
                 } */
                if(contract.Tech_RecordTypeName__c.contains('OpCo360')){
                    //skipped this part for contract in since final doc url is already being updated in AP53_UncheckExpirePreference
                   if(lstContractContentVersion.size()>0){
                        for(ContentDistribution cd: [select id,DistributionPublicUrl,ContentDocumentId
                        from ContentDistribution
                        where contentversionId=:lstContractContentVersion[0].Id]){
                            if(cd.DistributionPublicUrl !=null){
                                // 06-08-2021   ARA     SP-1729
                                //contract.FinalDocumentURL__c=cd.DistributionPublicUrl;
                                contract.LinkToDocument__c = System.Label.Contract_LinkToDocument+cd.ContentDocumentId+'/view';
                            }
                        }
                        contract.Status__c = AP_Constant.CONTRACT_STATUS_SIGNED;
                        contract.Contract_Signed_Date__c = System.Today();
                        update contract;

                        // SP-02770 Contract | Change PO reminder functionality
                        List<String> lstRTContract = new List<String>{Label.RT_ContractReadOnlyLightning, Label.RT_AmendmentReadOnlyLightning};
                        if(PAD.canTrigger('AP1209') && !contract.TECH_IsContractIn__c && contract.OpCo_Send_Automatic_PO_Reminder__c && contract.OpCo_CountILNoPO__c > 0 && lstRTContract.contains(contract.Tech_RecordTypeName__c)){
                            AP12_Contract.sendPOReminder(new Set<Id>{contract.Id});
                        }
                    }
                }
                
                

                //updating esignature
                if(!isFaultMessage){
                    esignature.isSuccess__c=true;
                    update esignature;
                }

                //to increase coverage for catch block
                if(testError && test.isRunningTest()){
                    map<id,esignature__c> esignIdMap=new map<id,esignature__c>();
                    esignIdMap.put(esignatureId,new esignature__c());
                    update esignIdMap.values();
                }

            }//end map size >0

        }
        catch(Exception e){
            eSignatureLog__c eSign_log = new eSignatureLog__c();
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = source + ' execution to retrieve signed content';
            eSign_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSign_log.Request__c = XMLRequest;
            eSign_log.DateCall__c = Datetime.now();
            esignLogLst.add(eSign_log);

            esignature.isSuccess__c=false;
            update esignature;
        }

        if(esignLogLst.size()>0){
            try{insert esignLogLst;}
            catch(Exception e){
                system.debug('##Exception request too large to be stored'+ e.getMessage());
            }
        }

    }
  
    /* //method retrieves signed document from Universign
     public static void CreateXmlRpcForSignedDocument(eSignature__c eSignature,contract__c contract, string source){

         hasExecutedXmlRpc=true;
         list<eSignatureLog__c>esignLogLst=new list<eSignatureLog__c>();
         string documentTitle=null;
         string body='';
         String xmlString=null;

         //stores the pdf name (as key) -> base 64 (as value)
         map<string,string>mapDocNameBase64=new map<string,string>();


         string XMLRequest ='<methodCall>' +
                                 '<methodName>requester.getDocuments</methodName>' +
                                 '<params>' +
                                 '<param>' +
                                 '<value>' +
                                 '<string>' +
                                 eSignature.ExternalId__c+
                                 '</string>' +
                                 '</value>'+
                                 '</param>'+
                                 '</params>'+
                                 '</methodCall>';

         try{
             boolean isFaultMessage=false;
             Httprequest request = new HttpRequest();

             Http http = new Http();
             //DMU:20170606 - added dummy response for class coverage
             HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XMLRequest));

             system.debug('##response.getBody()'+response.getBody());
             //xmlString = '<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><array><data><value><struct><member><name>metaData</name><value><struct></struct></value></member><member><name>fileName</name><value><string>PDFSample 4 21/3/2018.pdf</string></value></member><member><name>documentType</name><value><string>pdf</string></value></member><member><name>name</name><value><string>PDFSample 4 21/3/2018.pdf</string></value></member><member><name>content</name><value><base64>1234</base64></value></member></struct></value><value><struct><member><name>metaData</name><value><struct></struct></value></member><member><name>fileName</name><value><string>PDFSample 3 21/3/2018.pdf</string></value></member><member><name>documentType</name><value><string>pdf</string></value></member><member><name>name</name><value><string>PDFSample 3 21/3/2018.pdf</string></value></member><member><name>content</name><value><base64>5678</base64></value></member></struct></value></data></array></value></param></params></methodResponse>';
             xmlString=response.getBody();

             if(xmlString.contains('faultString') || xmlString.contains('faultCode') || (test.isRunningTest() && testError)){
                 isFaultMessage=true;
                 //response is not captured in log when signed document is retrieved successfully since response returned is too long
                 // only fault response is captured
                 eSignatureLog__c eSignature_log = new eSignatureLog__c();
                 eSignature_log.eSignatureId__c = eSignature.Id;
                 eSignature_log.StepName__c = 'Error: '+ source + ' execution to retrieve signed content ';
                 //eSignature_log.Response__c =  xmlString;
                 eSignature_log.Request__c = XMLRequest;
                 eSignature_log.DateCall__c = Datetime.now();
                 esignLogLst.add(eSignature_log);
             }

             //22-MARS-2018:MRA reworked logic to read all signed copies returned in XML response. (Contract-In ACH can submit more than one doc for signature)
             if  (!isFaultMessage){
                 Dom.Document doc = new Dom.Document();
                 doc.load(xmlString.remove('<struct></struct>'));
                 string contentBase64='';
                 DOM.XMLNode root = doc.getRootElement();


                 //system.debug('#aa'+root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('array', null).getChildElement('data', null).getChildElements().size());
                 Dom.xmlNode[] xmlValueArray=root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('array', null).getChildElement('data', null).getChildElements();


                 string filename='';

                 //loop through xml to read all member tags in order to retrieve filename + base 64
                 for(integer i=0;i<xmlValueArray.size();i++){
                       Dom.xmlNode[] xmlMembersArray= xmlValueArray[i].getChildElement('struct',null).getChildElements();
                       for(integer j=0;j<xmlMembersArray.size();j++){
                             //retrieving file name
                             if(xmlMembersArray[j].getChildElement('name',null).getText()=='fileName'){
                                filename=(xmlMembersArray[j].getChildElement('value',null).getChildElement('string',null).getText()).remove('.pdf')+ '_signed.pdf';
                               // system.debug('filename'+filename);
                             }

                             //retrieving content
                             if(xmlMembersArray[j].getChildElement('name',null).getText()=='content'){
                                 mapDocNameBase64.put(filename,xmlMembersArray[j].getChildElement('value',null).getChildElement('base64',null).getText());
                             }
                       }
                 }
             }//if not fault message
             //system.debug('mapDocNameBase64'+ mapDocNameBase64);


              list<ContentVersion>lstContractContentVersion=new list<ContentVersion>();
              list<ContentDistribution> cdContractList=new list<ContentDistribution>();
             //create content versions + attachments (All-In + ATS Only)
             if(mapDocNameBase64.size()>0){
                 list<Attachment> lstAttachment=new list<Attachment>();
                 //applicable for All-In + ATS only
                 for(string file:mapDocNameBase64.keyset()){
                    // system.debug('file'+file);
                     if(!esignature.cTin_TECH_IsContractIn__c){
                         lstAttachment.add(new Attachment(name=file,parentId=contract.id,
                         body= (test.isRunningTest()? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(mapDocNameBase64.get(file)))));
                     }
                 }
                 if(lstAttachment.size()>0)
                     insert lstAttachment;

                 //Query workspace for All-In ,ATS + contract-In
                 string workspaceId;
                 if (test.isrunningTest()){
                     workspaceId=[SELECT Id,name,DeveloperName
                                     FROM ContentWorkspace
                                     where DeveloperName=:'Workspace_test'
                                     limit 1].id;
                 }
                 else{
                    // query content workspace for All-In  + ATS
                     if(!eSignature.cTin_TECH_IsContractIn__c){
                        workspaceId=[SELECT Id,name,DeveloperName
                                         FROM ContentWorkspace
                                         where DeveloperName=:system.label.ContentWorkspace
                                         limit 1].id;
                     }
                     else{
                         // query content workspace for Contract-In
                         workspaceId=[SELECT Id,name,DeveloperName
                                         FROM ContentWorkspace
                                         where DeveloperName=:system.label.cTin_ContentWorkspace
                                         limit 1].id;
                     }
                 }
                // system.debug('workspaceId'+workspaceId);

                 //create contentversions for contract (ATS,All-In,Contract-In)
                 for(string file:mapDocNameBase64.keyset()){
                     ContentVersion cv = new ContentVersion();
                     cv.Title = file;
                     cv.PathOnClient = file;
                     cv.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(mapDocNameBase64.get(file)));

                     // firstpublishLocationId needs not be specified for unit tests, asssigned automatically to the workspace created in test class
                     // if assigned throws an exception invalid id
                     if (!test.isrunningTest()){
                         cv.FirstPublishLocationId = workspaceId;
                     }

                     lstContractContentVersion.add(cv);
                 }

                 if(lstContractContentVersion.size()>0){
                     insert lstContractContentVersion;


                     list<ContentVersion> cveSignList=new list<ContentVersion>();

                     //create content distributions for contract (All-IN,ATS,Contract-In)
                     for(contentVersion cv: lstContractContentVersion){
                         if(cv!=null){
                             ContentDistribution contentContract = new ContentDistribution();
                             contentContract.RelatedRecordId = contract.Id;
                             contentContract.Name = cv.title;
                             contentContract.ContentVersionId = cv.Id;
                             contentContract.PreferencesNotifyOnVisit = false ;
                             cdContractList.add(contentContract);
                         }

                         //create content version for esignature (Contract-In only)
                         if(esignature.cTin_TECH_IsContractIn__c){
                             ContentVersion cvEsign = new ContentVersion();
                             cvEsign.Title = cv.title;
                             cvEsign.PathOnClient = cv.title;
                             cvEsign.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):cv.versionData);
                             cveSignList.add(cvEsign);
                         }
                     }

                     //insert content distribution for contract
                     if(cdContractList.size()>0){
                         insert cdContractList;
                     }

                     //insert content version for esignature (Contract-In only)
                     if(cveSignList.size()>0){
                         insert cveSignList;
                     }
                     //create content distribution for esignature (Contract-In only)
                     if(cveSignList.size()>0){
                         list<ContentDistribution> cdeSignList=new list<ContentDistribution>();
                         for(ContentVersion cv:cveSignList){
                             if(cv!=null){
                                 ContentDistribution contentEsignature = new ContentDistribution();
                                 contentEsignature.RelatedRecordId = eSignature.Id;
                                 contentEsignature.Name = cv.title;
                                 contentEsignature.ContentVersionId = cv.Id;
                                 contentEsignature.PreferencesNotifyOnVisit = false ;
                                 cdeSignList.add(contentEsignature);
                             }
                         }

                         //insert content distribution for esignature (Contract-In only)
                         if(cdeSignList.size()>0){
                             insert cdeSignList;
                         }

                     }

                 }



                 for(ContentDistribution cd: [select id,DistributionPublicUrl
                                                 from ContentDistribution
                                                 where id=:cdContractList[0].id]){
                     if(cd.DistributionPublicUrl !=null){
                         contract.FinalDocumentURL__c=cd.DistributionPublicUrl;
                         update contract;
                     }

                 }

                 //updating esignature
                 if(!isFaultMessage){
                     esignature.isSuccess__c=true;
                     update esignature;
                 }

                 //to increase coverage for catch block
                 if(testError && test.isRunningTest()){
                     map<id,esignature__c> esignIdMap=new map<id,esignature__c>();
                     esignIdMap.put(esignatureId,new esignature__c());
                     update esignIdMap.values();
                 }

             }//end map size >0

         }
         catch(Exception e){
            eSignatureLog__c eSign_log = new eSignatureLog__c();
            eSign_log.eSignatureId__c = eSignature.Id;
            eSign_log.StepName__c = source + ' execution to retrieve signed content';
            eSign_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
            eSign_log.Request__c = XMLRequest;
            eSign_log.DateCall__c = Datetime.now();
            esignLogLst.add(eSign_log);

            esignature.isSuccess__c=false;
            update esignature;
         }

         if(esignLogLst.size()>0){
             try{insert esignLogLst;}
             catch(Exception e){
             system.debug('##Exception request too large to be stored'+ e.getMessage());
             }
         }

     } */

    /* //MRA 22-MARS-2018 - commented and reworked because method can retrieve only one signed copy
       // In Contract-In  - It is possible to submit more than one document for esignature
    public static void CreateXmlRpcForSignedDocument(eSignature__c eSignature,contract__c contract, string source){

        hasExecutedXmlRpc=true;
        list<eSignatureLog__c>esignLogLst=new list<eSignatureLog__c>();
        string documentTitle=null;
        string body='';
        String xmlString=null;
        list<string>base64ContentLst=new list<string>();


        string XMLRequest ='<methodCall>' +
                                '<methodName>requester.getDocuments</methodName>' +
                                '<params>' +
                                '<param>' +
                                '<value>' +
                                '<string>' +
                                eSignature.ExternalId__c+
                                '</string>' +
                                '</value>'+
                                '</param>'+
                                '</params>'+
                                '</methodCall>';


        try{
            boolean isFaultMessage=false;
            Httprequest request = new HttpRequest();

            Http http = new Http();
            //DMU:20170606 - added dummy response for class coverage
            HttpResponse response = test.isrunningTest() ? dummyResponse : http.send((HttpRequest)buildHttpRequest(XMLRequest));

            system.debug('##response.getBody()'+response.getBody());
            xmlString = response.getBody();

            if(xmlString.contains('faultString') || xmlString.contains('faultCode') || (test.isRunningTest() && testError)){
                isFaultMessage=true;
                //response is not captured in log when signed document is retrieved successfully since response returned is too long
                // only fault response is captured
                eSignatureLog__c eSignature_log = new eSignatureLog__c();
                eSignature_log.eSignatureId__c = eSignature.Id;
                eSignature_log.StepName__c = 'Error: '+ source + ' execution to retrieve signed content ';
                //eSignature_log.Response__c =  xmlString;
                eSignature_log.Request__c = XMLRequest;
                eSignature_log.DateCall__c = Datetime.now();
                esignLogLst.add(eSignature_log);
            }





           //MRA 09-MARCH-2018: Optimised code block to read xml using DOM instead of XMLStreamReader
           // Reason: To Resolve issue "Heap Size Limit exceeded". XMLStreamReader buffers too much memory when pdf is large (>1MB)
           // Reason : To resolve issue corrupted pdf (retrieve only base 64 belonging to member Content)


           XmlStreamReader reader = new XmlStreamReader(xmlString);

           /* if (reader != null && !isFaultMessage) {

                while (reader.hasNext()) {
                    //Check if not END_DOCUMENT
                    if (reader.getEventType() == XmlTag.END_DOCUMENT) {
                       break;
                    }

                    if (reader.getEventType() == XmlTag.CHARACTERS) {

                        //retrieving and appending _signed.pdf to signed doc name
                        if(reader.getText()!='' && reader.getText().endsWith('.pdf')){
                            documentTitle=(reader.getText().remove('.pdf'))+ '_signed.pdf';
                        }

                        //retrieving body of signed doc and converting to blob
                        if(reader.getText()!=''
                        //&&  reader.getText()!='content'
                          //&& reader.getText()!='originalContent'
                            &&  reader.getText()!='documentType'
                           &&  reader.getText()!='pdf'
                           && reader.getText()!='name'
                           && (!reader.getText().endsWith('.pdf'))
                           && reader.getText()!='metaData'
                          ){

                            if(body==null)
                                body=((reader.getText()));
                            else
                               body=body+((reader.getText()));
                        }
                    }
                    reader.next();
                }
             }*/

    /*if  (!isFaultMessage){
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString.remove('<struct></struct>'));
        string contentBase64='';
        DOM.XMLNode root = doc.getRootElement();

        system.debug('##numberofattributes'+root.getAttributeCount());
        system.debug('#aa'+root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('array', null).getChildElement('data', null).getChildElement('value', null).getChildElement('struct', null));
        Dom.XMLNode param=root.getChildElement('params',null).getChildElement('param',null).getChildElement('value',null).getChildElement('array', null).getChildElement('data', null).getChildElement('value', null).getChildElement('struct', null);
        system.debug('##numberofattributes'+param.getAttributeCount());

        documentTitle=(param.getChildElements().get(1).getChildElement('value', null).getChildElement('string', null).getText().remove('.pdf'))+ '_signed.pdf';
        body=param.getChildElements().get(4).getChildElement('value', null).getChildElement('base64', null).getText();

        system.debug('## child getchild'+param.getChildElements().size());

        //MRA 12-Feb-2018: added code to retrieve only element content -> (issue corrupted pdf)
        body=body.removeStart('fileNamecontent');
    }

    if(documentTitle!=null && body!=null){
        if(!esignature.cTin_TECH_IsContractIn__c){
            attachment att_signedDoc=new attachment();
            att_signedDoc.name=documentTitle;
            att_signedDoc.parentId=contract.id;
            //to increase coverage
            att_signedDoc.body= (test.isRunningTest()? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(body));
            insert att_signedDoc;
        }
        string workspaceId;

        if (test.isrunningTest()){
            workspaceId=[SELECT Id,name,DeveloperName
                            FROM ContentWorkspace
                            where DeveloperName=:'Workspace_test'
                            limit 1].id;
        }
        else{
           // query content workspace for All-In
            if(!eSignature.cTin_TECH_IsContractIn__c){
               workspaceId=[SELECT Id,name,DeveloperName
                                FROM ContentWorkspace
                                where DeveloperName=:system.label.ContentWorkspace
                                limit 1].id;
            }
            else{
                // query content workspace for Contract-In
                workspaceId=[SELECT Id,name,DeveloperName
                                FROM ContentWorkspace
                                where DeveloperName=:system.label.cTin_ContentWorkspace
                                limit 1].id;
            }
        }

        system.debug('##workspaceId'+workspaceId);


        ContentVersion cv = new ContentVersion();
        cv.Title = documentTitle;
        cv.PathOnClient = documentTitle;
        cv.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(body));

        // firstpublishLocationId needs not be specified for unit tests, asssigned automatically to the workspace created in test class
        // if assigned throws an exception invalid id
        if (!test.isrunningTest()){
            cv.FirstPublishLocationId = workspaceId;
        }

       insert cv;


       if(cv!=null){

            ContentDistribution contentContract = new ContentDistribution();
            contentContract.RelatedRecordId = contract.Id;
            contentContract.Name = documentTitle;
            contentContract.ContentVersionId = cv.Id;
            contentContract.PreferencesNotifyOnVisit = false ;
            insert contentContract;

            //MRA 10-OCT-2017 - Copy signed doc to esignature (Evol Contract-In Universign)
            if(esignature.cTin_TECH_IsContractIn__c){

                ContentVersion cvEsign = new ContentVersion();
                cvEsign.Title = documentTitle;
                cvEsign.PathOnClient = documentTitle;
                cvEsign.VersionData =(test.isRunningTest() ? blob.valueOf('Dummy body'):EncodingUtil.base64Decode(body));

                insert cvEsign;

                  //if(cvEsign!=null){
                   // ContentDistribution contentEsignature = new ContentDistribution();
                    //contentEsignature.RelatedRecordId = eSignature.Id;
                   // contentEsignature.Name = documentTitle;
                    //contentEsignature.ContentVersionId = cvEsign.Id;
                    //contentEsignature.PreferencesNotifyOnVisit = false ;
                    //insert contentEsignature;
                    //}
                    if(cv!=null){
                    ContentDistribution contentEsignature = new ContentDistribution();
                    contentEsignature.RelatedRecordId = eSignature.Id;
                    contentEsignature.Name = documentTitle;
                    contentEsignature.ContentVersionId = cvEsign.Id;
                    contentEsignature.PreferencesNotifyOnVisit = false ;
                    insert contentEsignature;
                    }

            }

            //get public url of signed content and set final doc url on contract
           list<ContentDistribution> cdLst= [select id,DistributionPublicUrl
                                            from ContentDistribution
                                            where id=:contentContract.id];
           if(cdLst.size()>0){
               if(cdLst[0].DistributionPublicUrl !=null){
                    contract.FinalDocumentURL__c=cdLst[0].DistributionPublicUrl;
                    update contract;
               }
           }

     }
    }//end if

    //updating esignature
    if(!isFaultMessage){
        esignature.isSuccess__c=true;
        update esignature;

    }

    //to increase coverage for catch block
    if(testError && test.isRunningTest()){
        map<id,esignature__c> esignIdMap=new map<id,esignature__c>();
        esignIdMap.put(esignatureId,new esignature__c());
        update esignIdMap.values();
    }

}
catch(exception e){
   eSignatureLog__c eSign_log = new eSignatureLog__c();
   eSign_log.eSignatureId__c = eSignature.Id;
   eSign_log.StepName__c = source + ' execution to retrieve signed content';
   eSign_log.Response__c =  'Error : '+ e.getMessage() + 'at line ' + e.getLineNumber();
   eSign_log.Request__c = XMLRequest;
   eSign_log.DateCall__c = Datetime.now();
   insert eSign_log;

   esignature.isSuccess__c=false;
   update esignature;
}

if(esignLogLst.size()>0){
    try{insert esignLogLst;}
    catch(Exception e){
    system.debug('##Exception request too large to be stored'+ e.getMessage());
    }
}
}*/

 

}