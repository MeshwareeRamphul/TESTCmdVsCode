public without sharing class AP22_CSVParser {
/*  
----------------------------------------------------------------------
-- - Name          : AP22_CSVParser 
-- - Author        : Spoon Consulting
-- - Description   : class to generate a CSV from list of Data. 
                     This class is used in batch to format the error in a csv
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  ---------------------------------------
-- 17-MAY-2017  MRA    1.0      Intitial version
----------------------------------------------------------------------

*/  
    Public list <String> header;
    public list<String> line;
    public string body;
    public boolean hasHeader;

    public AP22_CSVParser(){
        header = new list <String>();       
        line = new list<String>();
        body = '';
        hasHeader = false;
    }
    public void writeHeader(list<String> h){       
        if(h.size()>0){
            for(integer i=0;i<h.size();i++){
                header.add(h[i]);
                body += formatData(h[i])+ ',';  
            }
            body = body.removeEnd(',');
            body += '\r\n';
            hasHeader = true;
        }
        else{
            body='';
            hasHeader=false;
        }
    }
    public String formatData(string s){
        if(s!=null) { 
            s = s.replaceAll('"','');          
        }
        else{
            s='';
        }
         return '"' + s + '"';
    }
    public void addToLine(String s){
        line.add(formatData(s));
        body += formatData(s) + ',';    
    }
    public void createLine(){
        body = body.removeEnd(',');
        body += '\r\n';
    }
    public blob getBlobBody(){
        return blob.valueOf(body);
    }
}