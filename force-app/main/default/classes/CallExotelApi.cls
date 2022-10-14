global class CallExotelApi implements Schedulable
{
    global void execute(SchedulableContext ctx)
    {
        DateTime systemNow = System.now();
        DateTime thirtyFiveMins = System.now().addMinutes(35);
        
        String query = 'SELECT id,Name,Phone,Email,SID__c,Interview_Date_Time_AC__c,IVR_Called__c,OwnerId FROM Lead WHERE Interview_Date_Time_AC__c >: systemNow AND Interview_Date_Time_AC__c <: thirtyFiveMins AND IVR_Called__c = false AND Phone != null limit 40000';
        List<Lead> LeadList =  Database.query(query);
        
        if(!LeadList.isEmpty()){
            System.enqueueJob(new AsyncHelperForIVR(LeadList,0,1));
        }
    }
}