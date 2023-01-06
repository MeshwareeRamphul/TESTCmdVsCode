public with sharing class VFC31_DynamicApproversDisplay {
/* 
--------------------------------------------------------------------------------------
-- - Name          : VFC31_DynamicApproversDisplay
-- - Author        : Nurit Chen
-- - Description   : This is a controller for inline vf page "DynamicApproversDisplay" 
                     to present all approvals related list of specific contract form record
--
-- Maintenance History: 
--
-- Date         Name  Version  Remarks 
-- -----------  ----  -------  -------------------------------------------------------
-- 10/7/14      NCH    1.0     Initial version
-- 23-OCT-2017  HVA    1.1     Reworked - All In merge contract In
*************************************************************************************/

    public cTin_ContractForm__c ContractForm {get; private set;}
    public Map<Integer, String> viewAllApproversMap {get; private set;}
    public boolean isMobile {get; private set;}
    public Map<String,String> map_LabelsOfRoles {get; private set;}
    public Map<String, String> map_statusColor {get; private set;}

    public VFC31_DynamicApproversDisplay(ApexPages.StandardController stdController) {

        this.map_statusColor = new map<String, String>{'Approved'=>'color:green', 'Waiting'=>'color:orange', 'Rejected'=>'color:red'};

        String userAgent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
        this.isMobile = isMobile(userAgent);
        List<Integer> finalApprovalsNumbersList = new List<Integer>();
        this.viewAllApproversMap = new Map<Integer, String>();

        // getting the custom labels in sandbox (for each new role add here the mapping for translations)
        this.map_LabelsOfRoles = new Map<String,String>{'000'=> Label.cTin_Approval_Role_00,
                                                        '001'=> Label.cTin_Approval_Role_001,
                                                        '002'=> Label.cTin_Approval_Role_002,
                                                        '003'=> Label.cTin_Approval_Role_003,
                                                        '004'=> Label.cTin_Approval_Role_004,
                                                        '005'=> Label.cTin_Approval_Role_005,
                                                        '006'=> Label.cTin_Approval_Role_006,
                                                        '007'=> Label.cTin_Approval_Role_007,
                                                        '008'=> Label.cTin_Approval_Role_008,
                                                        '009'=> Label.cTin_Approval_Role_009,
                                                        '010'=> Label.cTin_Approval_Role_010,
                                                        '011'=> Label.cTin_Approval_Role_011,
                                                        '012'=> Label.cTin_Approval_Role_012,
                                                        '013'=> Label.cTin_Approval_Role_013,
                                                        '014'=> Label.cTin_Approval_Role_014,
                                                        '015'=> Label.cTin_Approval_Role_015, 
                                                        '016'=> Label.cTin_Approval_Role_016,
                                                        '017'=> Label.cTin_Approval_Role_017,
                                                        '018'=>Label.cTin_Approval_Role_018,
                                                        '019'=>'Vendor Manager',
                                                        '020'=>'Health-check Owner',
                                                        '025'=>'Risk Expert',
                                                        '026'=>'Compliance',
                                                        '027'=>'Sustainability Expert',
                                                        '028'=>'Procurement / Category Manager',
                                                        '029'=>'Cesame Owner',
                                                        '030'=>'TAX',
                                                        '031'=>system.label.cTin_Approval_Role_031
                                                        /*,
                                                        'Risk'=>'Risk',
                                                        'Compliance'=>'Compliance',
                                                        'Corporate Social Responsibility'=>'Corporate Social Responsibility'*/};

        // create a set of all users Ids
        Set<Id> userIdSet = new Set<Id>();
        Id contractFormId = ApexPages.currentPage().getParameters().get('id');

        // getting the data from the record currently viewed
        this.ContractForm =  [SELECT Id,
                                     Name,
                                     cTin_ApproverName1__c,
                                     cTin_ApproverName2__c,
                                     cTin_ApproverName3__c,
                                     cTin_ApproverName4__c,
                                     cTin_ApproverName5__c,
                                     cTin_ApproverName6__c,
                                     cTin_ApproverName7__c,
                                     cTin_ApproverName8__c,
                                     cTin_ApproverName9__c,
                                     cTin_ApproverName10__c,
                                     cTin_ApproverRole1__c,
                                     cTin_ApproverRole2__c,
                                     cTin_ApproverRole3__c,
                                     cTin_ApproverRole4__c,
                                     cTin_ApproverRole5__c,
                                     cTin_ApproverRole6__c,
                                     cTin_ApproverRole7__c,
                                     cTin_ApproverRole8__c,
                                     cTin_ApproverRole9__c,
                                     cTin_ApproverRole10__c,
                                     cTin_ApprovalStatus1__c,
                                     cTin_ApprovalStatus2__c,
                                     cTin_ApprovalStatus3__c,
                                     cTin_ApprovalStatus4__c,
                                     cTin_ApprovalStatus5__c,
                                     cTin_ApprovalStatus6__c,
                                     cTin_ApprovalStatus7__c,
                                     cTin_ApprovalStatus8__c,
                                     cTin_ApprovalStatus9__c,
                                     cTin_ApprovalStatus10__c,
                                     cTin_OverallStatus1__c ,
                                     cTin_OverallStatus2__c,
                                     cTin_OverallStatus3__c,
                                     cTin_OverallStatus4__c,
                                     cTin_OverallStatus5__c,
                                     cTin_OverallStatus6__c,
                                     cTin_OverallStatus7__c,
                                     cTin_OverallStatus8__c,
                                     cTin_OverallStatus9__c,
                                     cTin_OverallStatus10__c
                               FROM cTin_ContractForm__c
                              WHERE Id = :contractFormId]; 

        // System.debug('kerensen this.ContractForm: ' + this.ContractForm);
        
        // iterating over the ApproverName 1-10 fields and adding only the user Ids that are in the database
        for(integer i = 1; i < 11; ++i) {
            if (ContractForm.get('cTin_ApproverName' + i + '__c') != null &&  String.valueOf(ContractForm.get('cTin_ApproverName' + i + '__c')).trim() != ''){
                    
                userIdSet.add(Id.valueOf(String.valueOf(ContractForm.get('cTin_ApproverName' + i + '__c'))));
                finalApprovalsNumbersList.add(i);
            }
        }

        // selecting the first name and last name of the users and mapping it to the ids currently in the record
        Map<Id, User> approverIdUserMap = new Map<Id, User>([Select Id, Name, FirstName, LastName From User Where Id in: userIdSet]);

        Integer index = 1;
        for (integer i = 0; i < finalApprovalsNumbersList.size(); i++){
                
            String approvalRecName = ((approverIdUserMap.get(Id.valueOf(String.valueOf(ContractForm.get('cTin_ApproverName' + finalApprovalsNumbersList[i] + '__c')))).Name + ' '));    
            this.viewAllApproversMap.put(i+1, approvalRecName);
                
        }

    }

    public boolean isMobile(String userAgentString) {
        
        //Using RegEx, figure out if the user is on a mobile device based on the user-agent string
        if (userAgentString == null)  return false;
        Pattern p = Pattern.compile('Mobile|iP(hone|od|ad)|Android|BlackBerry|IEMobile|Kindle|NetFront|Silk-Accelerated|(hpw|web)OS|Fennec|Minimo|Opera M(obi|ini)|Blazer|Dolfin|Dolphin|Skyfire|Zune');
        Matcher pm = p.matcher( userAgentString );

        return pm.find();

    }
}