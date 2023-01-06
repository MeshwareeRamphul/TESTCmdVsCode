public class VFC_CmpApprovalURL{
      public String recID {get; set;}
      public String urlStr{
         get{
           return cTin_createApprovalURL.generateApprovalURL(recID);
         }
      }
}