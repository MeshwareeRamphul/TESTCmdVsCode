public class LC54_RecalculateShare {
    /*----------------------------------------------------------------------
    -- - Name          : LC54_RecalculateShare
    -- - Author        : Spoon
    -- - Description   : controller for component LC_Sing_RecalculateShare
    --
    -- - History:

    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 02-MAR-2022  ARA    1.0      Initial Version (SP-03490)
    -------------------------------------------------------------------------*/

    @AuraEnabled
    public static map<string,object> recalculateSharing(id eventId){
        Map<String, Object> result = new Map<String, Object>();
        try{
            AP05_Sing_mangageEventTeam.recalculateSharing(eventId);
            result.put('success', 'Sharing recalculated on this event');
        }catch(Exception e){result.put('error', e.getMessage());}
        return result;
    } 
}