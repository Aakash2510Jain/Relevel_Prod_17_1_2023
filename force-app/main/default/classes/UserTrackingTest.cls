@isTest
public class UserTrackingTest {

    @isTest
    public static void users()
    {
        test.startTest();
        Assignment_Group__c grouping= new Assignment_Group__c();
        grouping.Name='Test';
        insert grouping;
        
        Assignment_Group_Member__c member=new Assignment_Group_Member__c();
        member.Group_Member__c='0055j000002pmqhAAA';
        member.Assignment_Group__c=grouping.Id;
        member.Assignment_Id__c=12;
        insert member;
            
        User_Tracking__c users=new User_Tracking__c();
        users.Checkin_Detatime__c=Date.today();
        users.Checkout_Datetime__c=Date.today();
        users.Member__c='0055j000002pmqhAAA';
        insert users;
        
        UserTracking.OnpageLoad('0055j000002pmqhAAA');
        UserTracking.OnpageLoad('0055g000002pmqhAAA');
        //UserTracking.UserCheckin('0055g000002pmqhAAA');
        new UserTracking();        
        UserTracking.UserCheckin('0055j000002pmqhAAA');
        UserTracking.UserCheckout('0055j000002pmqhAAA');
        UserTracking.UserCheckout('0055g000002pmqhAAA');
        UserTracking.UserCheckout(null);
        test.stopTest();
    }
}