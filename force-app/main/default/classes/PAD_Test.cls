@isTest
public class PAD_Test{
    /*
    // PAD_Test
    ----------------------------------------------------------------------
    -- - Name          : PAD_Test
    -- - Author        : Spoon
    -- - Description   : Test class for coverage PAD
    --
    -- Maintenance History:
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  ---------------------------------------
    -- 11-JAN-2018  SBH    1.0      Intitial version 
    ----------------------------------------------------------------------
    **********************************************************************
    */

    static String ApToBypass;
    static String ApToBypassOnce;
    static String currencyIsoCode;
    static Decimal amount;
    static double amountDouble;
    static set<String> SetNotToExecute;
    static {
        ApToBypass = 'AP25';
        ApToBypassOnce = 'AP04';

        currencyIsoCode = 'GBP';
        amount = 400.2;
        amountDouble = 400.2;

        SetNotToExecute = new Set<String>();
        SetNotToExecute.add('AP01');
    }

    @isTest
    static void testBypass(){
        PAD.canTrigger(ApToBypass);
    }

    @isTest
    static void testBypassOnce(){
        Pad.canTrigger(ApToBypassOnce);
    }

    //@isTest
    //static void testConvertToCorporateCurrency(){
    //  Map<String, Decimal> currencyRateMap = new Map<String, Decimal>();
        

    //  Pad.currencyRate = currencyRateMap;

    //  Pad.convertToCorporateCurrency(currencyIsoCode, amountDouble);
    //}

    @isTest
    static void testPAD_log(){
        Pad.Pad_log pl = new Pad.Pad_log('msg', 'reason');
        Pad.Pad_log p2 = new Pad.Pad_log('msg', 'reason' ,'css');
        //p1.timer = 'timer';
        //p1.reason = 'reason';
        //p1.message = 'message';
        //p1.rowCSS =  'rowcss';

        //p1.PAD_log('message' , 'reason');
        //p1.PAD_log('msg', 'reason', 'css');

    }

    @isTest
    static void testStartTimer(){
        PAD.StartTimer();
    }

    @isTest
    static void testLimits(){
        Pad.limits();
    }

    //@isTest
    //static void testGetPAD_logs(){
    //  PAD.getPAD_logs();
    //}

    //@isTest 
    //static void testPAD_Main_TestMethod(){
    //  PAD.PAD_Main_TestMethod();
    //}

    @isTest 
    static void doNotExecuteAfterMe(){
        PAD.doNotExecuteAfterMe(SetNotToExecute);
    }
}