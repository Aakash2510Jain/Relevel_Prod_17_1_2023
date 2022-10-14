public without sharing class LeadTriggerHandler{
    public static Boolean runOnce = false;
    public static void assignDefaultQueue(list<lead> newLeadList){
        try{
            List<Lead> existingLeadLists = new List<Lead>();
            Map<String, Lead> leadIdByLearnerUID = new Map<String, Lead>();
            Map<String, string> ownerIdByLearnerUID = new Map<String, String>();
            //List<String> leadEmail = new List<String>();
            List<String> leadPhone = new List<String>();
            Map<Id, Lead> existingLeadListWithEmailOrPhone = new Map<Id, Lead>();
            Map<String, String> leadEmailByLeadIdMap = new Map<String, String>();
            Map<String, String> leadPhoneByLeadIdMap = new Map<String, String>();
            Map<String, String> leadLearnerUIDByLeadIdMap = new Map<String, String>();

            string queueId = [SELECT Id, Type
                              FROM Group
                              WHERE Type = 'Queue' AND Name = 'Relevel Default Queue'
                              limit 1].Id;
            for (Lead ld : newLeadList){
                if (!test.isRunningTest()){
                    //if(ld.LeadSource == 'Referral' && ld.Referred_User_ID__c != null){
                    //    leadIdByLearnerUID.put(ld.Referred_User_ID__c, ld);
                    //}
                    //else{
                    ld.ownerId = queueId;
                    //}
                    //if(ld.Email != null)
                    //    leadEmail.add(ld.Email);
                    if (ld.Phone != null)
                        leadPhone.add(ld.Phone);
                }
                ld.First_Activity_Date__c = system.today();
            }
            if (leadPhone != null){
                existingLeadListWithEmailOrPhone = new Map<Id, Lead>([Select Id, Email, Phone, Learner_Uid__c
                                                                      From Lead
                                                                      Where Phone in:leadPhone]);

                if (!existingLeadListWithEmailOrPhone.isEmpty()){
                    for (Lead ld : existingLeadListWithEmailOrPhone.values()){
                        if (ld.Email != null)
                            leadEmailByLeadIdMap.put(ld.Email, Ld.Id);
                        if (ld.Phone != null)
                            leadPhoneByLeadIdMap.put(ld.phone, ld.Id);
                        if (ld.Learner_Uid__c != null)
                            leadLearnerUIDByLeadIdMap.put(ld.Learner_Uid__c, ld.Id);
                    }
                }
            }
            for (Lead leadRec : newLeadList){
                if (leadEmailByLeadIdMap.containsKey(leadRec.email) || leadPhoneByLeadIdMap.containsKey(leadRec.Phone) || leadLearnerUIDByLeadIdMap.containsKey(leadRec.Learner_Uid__c)){
                    leadRec.addError('Potential Duplicate Found');
                }
            }
            /*if(!leadIdByLearnerUID.isEmpty()){
             existingLeadLists = [Select id,Learner_UID__C,Ownerid from Lead where Learner_UID__C in : leadIdByLearnerUID.keySet()];
             if(!existingLeadLists.isEmpty()){
             for(Lead leadRec : existingLeadLists){
             ownerIdByLearnerUID.put(leadRec.Learner_Uid__c, leadRec.OwnerId);
             }
             }
             for(Lead leadRec : leadIdByLearnerUID.values()){
             leadRec.ownerId = ownerIdByLearnerUID.get(leadRec.Referred_User_ID__c);
             }
             }*/

        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void runLeadAssignment(List<Lead> leadList){
        try{
            /* if (!leadList.isEmpty() && leadList[0].Goal_Interested_In__c != null){
RoundRobinLeadAssignment.assignLeadsToBDS(leadList[0].Goal_Interested_In__c);
}*/
            if (!leadList.isEmpty() && leadList[0].Category__c != null){
                RoundRobinLeadAssignment.assignLeadsToBDS(leadList[0].Category__c);
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void assignDefaultQueueBeforeReassign(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        try{
            list<lead> reassignmentleadList = new list<lead>();
            for (Lead leadRec : newLeadMap.values()){
                if (leadRec.Goal_Interested_In__c != oldLeadMap.get(leadRec.Id).Goal_Interested_In__c){
                    reassignmentleadList.add(leadRec);
                }
            }
            if (!reassignmentleadList.isEmpty()){
                string queueId = [SELECT Id, Type
                                  FROM Group
                                  WHERE Type = 'Queue' AND Name = 'Relevel Default Queue'
                                  limit 1].Id;
                for (Lead ld : reassignmentleadList){
                    ld.ownerId = queueId;
                }
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

   public static void runLeadAssignmentOnOwnerUpdate(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        try{
            boolean rerunLeadassignment = false;
            string courseIntrested = '';
            for (Lead leadRec : newLeadMap.values()){
                if (leadRec.Category__c != oldLeadMap.get(leadRec.Id).Category__c){
                    rerunLeadassignment = true;
                    courseIntrested = leadRec.Category__c;
                    break;
                    
                }
            }
            if (rerunLeadassignment){
                RoundRobinLeadAssignment.assignLeadsToBDS(courseIntrested);
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void insertFollowUpTask(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        List<Task> taskList = new List<Task>();
        List<Lead> leadList = new List<Lead>();
        List<Task> taskListForNextFollowUp = new List<Task>();

        try{
            for (Lead lead : newLeadMap.values()){
                //System.debug(lead.Follow_Up_Date__c);
                //System.debug(oldLeadMap);
                if (lead.Follow_Up_Date__c != null && lead.Follow_Up_Date__c != oldLeadMap.get(lead.Id).Follow_Up_Date__c){
                    Task taskrec = new Task();
                    taskrec.Activity_Type__c = system.label.FollowUpTaskActivityType;
                    taskrec.status = 'Open';
                    taskrec.Subject = 'Follow-up ' + lead.Follow_Up_Date__c.format();
                    taskrec.OwnerId = lead.OwnerId;
                    taskrec.WhoId = lead.Id;
                    //taskrec.ActivityDate = lead.Follow_Up_Date__c;
                    taskrec.Follow_Up_Activity_Datetime__c = lead.Follow_Up_Date__c;
                    taskrec.Priority = 'Normal';
                    taskrec.Activity_Date_Time__c = dateTime.now();
                    taskList.add(taskrec);

                }
                if (lead.Next_Followup_Date_Time__c != null && lead.Next_Followup_Date_Time__c != oldLeadMap.get(lead.Id).Next_Followup_Date_Time__c){
                    Task taskrec = new Task();
                    //taskrec.Activity_Type__c = system.label.FollowUpTaskActivityType;
                    taskrec.status = 'Open';
                    taskrec.Subject = 'Interview Scheduled ' + lead.Next_Followup_Date_Time__c.format();
                    taskrec.OwnerId = lead.OwnerId;
                    taskrec.WhoId = lead.Id;
                    taskrec.IsReminderSet = true;
                    taskrec.ReminderDateTime = lead.Next_Followup_Date_Time__c.addhours( - 1);
                    //taskrec.ActivityDate = lead.Follow_Up_Date__c;
                    taskrec.Next_FollowUp_Activity_date_Time__c = lead.Next_Followup_Date_Time__c;
                    taskrec.Priority = 'Normal';
                    taskrec.Activity_Date_Time__c = dateTime.now();

                    taskListForNextFollowUp.add(taskrec);

                }
            }
            if (!taskList.isEmpty()){
                insert taskList;
            }
            if (!taskListForNextFollowUp.isEmpty()){
                insert taskListForNextFollowUp;
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void updateFollowUpCount(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        try{
            set<id> leadId = new Set<Id>();
            List<Task> followUpTaskList = new List<Task>();
            Map<String, integer> taskCountByLeadId = new Map<String, integer>();

            for (Lead lead : newLeadMap.values()){
                if (lead.Follow_Up_Date__c != oldLeadMap.get(lead.Id).Follow_Up_Date__c && lead.Follow_Up_Date__c != null){
                    leadId.add(lead.Id);
                    lead.Follow_Up_Counter__c += 1;
                }
                if (lead.Offer_Status__c != oldLeadMap.get(lead.Id).Offer_Status__c && lead.Offer_Status__c == 'Yes'){
                    if (!lead.Is_Interview_Conducted__c)
                        lead.Is_Interview_Conducted__c = true;
                    Date myDate = system.today().addDays(1);
                    Time myTime = Time.newInstance(10, 00, 00, 00);
                    DateTime dt = DateTime.newInstance(myDate, myTime);
                    lead.Admission_Letter_Send_Date_Time__c = dt;
                    lead.Admission_Letter_Expiry_Date__c = DateTime.now().addDays(3);
                }
                if (lead.Offer_Status__c != oldLeadMap.get(lead.Id).Offer_Status__c && lead.Offer_Status__c == 'No'){
                    if (!lead.Is_Interview_Conducted__c)
                        lead.Is_Interview_Conducted__c = true;
                    lead.Admission_Letter_Send_Date_Time__c = null;
                    lead.Admission_Letter_Expiry_Date__c = null;
                }
            }
            if (!leadId.isEmpty()){
                followUpTaskList = [SELECT WhoId, Status, Follow_Up_Activity_Datetime__c
                                    FROM Task
                                    WHERE (Status = 'Open') AND Follow_Up_Activity_Datetime__c != null AND WhoId in:leadId];
                if (!followUpTaskList.isEmpty()){
                    for (Task taskRec : followUpTaskList){
                        if (taskCountByLeadId.containsKey(taskRec.WhoId)){
                            integer noOfFollowUpTask = taskCountByLeadId.get(taskRec.WhoId) + 1;
                            taskCountByLeadId.put(taskRec.WhoId, noOfFollowUpTask);
                        } else{
                            taskCountByLeadId.put(taskRec.WhoId, 1);
                        }
                    }
                    if (!taskCountByLeadId.isEmpty()){
                        for (Id leadRecId : leadId){
                            if (taskCountByLeadId.containsKey(leadRecId)){
                                if (taskCountByLeadId.get(leadRecId) != null && taskCountByLeadId.get(leadRecId) > 0){
                                    (newLeadMap.get(leadRecId).Id).addError('Please Close Opened Followup Task, to create a new Followup');
                                }
                            }
                        }
                    }
                }
            }

        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void updateStageAsClosure(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        set<Id> leadIdsForClosedWon = new Set<Id>();
        set<Id> leadIdsForClosedLost = new Set<Id>();
        set<Id> leadIdsToShowError = new Set<Id>();
        List<Lead> leadToShowError = new List<Lead>();
        List<Task> taskListToBeCompletedManually = new List<Task>();
        List<Task> taskListToBeCompletedAutomatically = new List<Task>();
        //system.debug('Payment Activity');
        try{
            for (Lead lead : newLeadMap.values()){
                if (lead.Lead_status__c != oldLeadMap.get(lead.Id).Lead_status__c){
                    // system.debug('lead.Lead_status__c------------------>'+lead.Lead_status__c);
                    if ((lead.Lead_status__c == 'Refund' || lead.Lead_status__c == 'Junk' || lead.Lead_status__c == 'Rejected' || lead.Lead_status__c == 'Not interested' || lead.Lead_status__c == 'No access to desktop/laptop' || lead.Lead_status__c == 'Cannot understand English' || lead.Lead_status__c == 'Just Checking Details' || lead.Lead_status__c == 'Joined/Will join competitor' || lead.Lead_status__c == 'Fee is High' || lead.Lead_status__c == 'Next Batch' || lead.Lead_status__c == 'Professionally Busy' || lead.Lead_status__c == 'Personal Reason' || lead.Lead_status__c == 'Travelling Abroad / Onsite' || lead.Lead_status__c == 'Looking for another Program' || lead.Lead_status__c == 'Enrolled for another Program with us' || lead.Lead_status__c == 'Did not Enquire' || lead.Lead_status__c == 'Looking for WFH jobs' || lead.Lead_status__c == 'Do not have laptop/desktop' || lead.Lead_status__c == 'Can not understand English' || lead.Lead_status__c == 'Can not pay 1st EMI as well' || lead.Lead_status__c == 'Loan Rejected' || lead.Lead_status__c == 'Work Experience' || lead.Lead_status__c == 'Age Bar' || lead.Lead_status__c == 'Poor Communication' || lead.Lead_status__c == 'Not a Graduate' || lead.Lead_status__c == 'Score is low')){

                        leadIdsForClosedLost.add(lead.Id);
                        lead.Lead_Stage__c = 'Closed Lost';
                        lead.Closed_Lost_Date_Time__c = system.now();
                    }
                    if (lead.Lead_status__c == 'Payment Made'){
                        lead.Lead_Stage__c = 'Closed Won';
                        leadIdsForClosedWon.add(lead.Id);
                    }
                }
            }

            if (!leadIdsForClosedLost.isEmpty()){
                taskListToBeCompletedManually = [SELECT Id, Status, WhoId
                                                 FROM Task
                                                 WHERE WhoId in:leadIdsForClosedLost AND Status = 'Open'];
                if (!taskListToBeCompletedManually.isEmpty()){
                    for (Task taskRec : taskListToBeCompletedManually){
                        leadIdsToShowError.add(taskRec.WhoId);
                    }
                    if (!leadIdsToShowError.isEmpty()){
                        leadToShowError = [Select id, Name
                                           from Lead
                                           Where Id in:leadIdsToShowError];
                        if (!leadIdsToShowError.isEmpty()){
                            for (Lead leadRec : leadToShowError){
                                newLeadMap.get(leadRec.Id).addError('Please Complete All Pending Tasks');
                                //leadRec.addError('Please Complete All Pending Tasks');
                            }
                        }
                    }

                }
            }
            //system.debug('leadIdsForClosedWon::'+leadIdsForClosedWon);
            if (!leadIdsForClosedWon.isEmpty()){
                // system.debug('Task List');
                taskListToBeCompletedAutomatically = [SELECT Id, Status
                                                      FROM Task
                                                      WHERE WhoId in:leadIdsForClosedWon];
                if (!taskListToBeCompletedAutomatically.isEmpty()){
                    for (Task taskrec : taskListToBeCompletedAutomatically){
                        taskRec.Status = 'Completed';
                    }
                    update taskListToBeCompletedAutomatically;
                }
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void updateFirstResponseTime(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap){
        try{
            for (Lead lead : newLeadMap.values()){
                if (lead.First_Called_Date_Time__c != oldLeadMap.get(lead.Id).First_Called_Date_Time__c){
                    if (lead.First_Called_Date_Time__c != null)
                        lead.First_Response_Time__c = decimal.valueof((lead.First_Called_Date_Time__c.getTime() - lead.CreatedDate.getTime()) / (60000));
                    //DateTime dt = DateTime.newInstance(myDate, myTime);
                    if (lead.New_Lead_Assigned_DateTime__c != null && lead.First_Called_Date_Time__c != null)
                        lead.FRT_Based_on_Assigned_Date_Called__c = decimal.valueof((lead.First_Called_Date_Time__c.getTime() - (lead.New_Lead_Assigned_DateTime__c).getTime()) / (60000));
                }
                //
                if (lead.First_Connected_Date_Time__c != oldLeadMap.get(lead.Id).First_Connected_Date_Time__c){
                    if (lead.First_Connected_Date_Time__c != null)
                        lead.FRT_Based_on_Created_Date_Connected__c = decimal.valueof((lead.First_Connected_Date_Time__c.getTime() - lead.CreatedDate.getTime()) / (60000));
                    //FRT_Based_on_Assigned_Date_Connected__c
                    if (lead.First_Connected_Date_Time__c != null && lead.New_Lead_Assigned_DateTime__c != null)
                        lead.FRT_Based_on_Assigned_Date_Connected__c = decimal.valueof((lead.First_Connected_Date_Time__c.getTime() - (lead.New_Lead_Assigned_DateTime__c).getTime()) / (60000));
                }
                if (oldLeadMap.get(lead.Id).Re_Engagement_Activity_Time__c != lead.Re_Engagement_Activity_Time__c){
                    if (lead.Re_Engagement_Activity_Time__c != null && lead.Closed_Lost_Date_Time__c != null)
                        lead.Re_Engagement_Time__c = decimal.valueof((lead.Re_Engagement_Activity_Time__c.getTime() - lead.Closed_Lost_Date_Time__c.getTime()) / (60000));
                }
                if (lead.First_Connected_Date_Time_RM__c != oldLeadMap.get(lead.Id).First_Connected_Date_Time_RM__c){
                    if (lead.First_Connected_Date_Time_RM__c != null)
                        lead.FRT_Based_on_RM_Connected_Date_Time__c = decimal.valueof((lead.First_Connected_Date_Time_RM__c.getTime() - lead.RM_assigned_Date_Time__c.getTime()) / (60000));
                }
                if (lead.First_Called_Date_Time_RM__c != oldLeadMap.get(lead.Id).First_Called_Date_Time_RM__c){
                    if (lead.First_Called_Date_Time_RM__c != null)
                        lead.FRT_Based_on_RM_Called_Date_Time__c = decimal.valueof((lead.First_Called_Date_Time_RM__c.getTime() - lead.RM_assigned_Date_Time__c.getTime()) / (60000));
                }
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void trackOwnerChangeDetails(map<Id, Lead> newLeadMap, map<Id, Lead> oldLeadMap){
        //system.debug('newMap::'+newLeadMap);
        //system.debug('oldMap::'+oldLeadMap);
        try{
            Map<Id, Lead> leadByIdMap = new Map<ID, Lead>();
            Set<String> reciepientsId = new Set<String>();

            string queueId = [SELECT Id, Type
                              FROM Group
                              WHERE Type = 'Queue' AND Name = 'Relevel Default Queue'
                              limit 1].Id;
            for (lead ld : newLeadMap.values()){
                if (ld.ownerID != oldLeadMap.get(ld.Id).ownerId){
                    if (oldLeadMap.get(ld.Id).ownerId != queueId){

                        ld.Previous_Owner__c = oldLeadMap.get(ld.Id).ownerId;
                        ld.Transferred_By__c = UserInfo.getName();
                    }
                    ld.Owner_Change_Datetime__c = DateTime.now();
                }
                if (ld.lead_stage__c == 'Unassigned' && ld.ownerID != queueId){
                    ld.lead_stage__c = 'New';
                }
                if (ld.ownerId != oldLeadMap.get(ld.Id).ownerId){
                    reciepientsId.add(ld.ownerId);
                    leadByIdMap.put(ld.Id, ld);
                    if (oldLeadMap.get(ld.Id).ownerId == queueId){
                        ld.New_Lead_Assigned_DateTime__c = datetime.now();
                    }
                    if (oldLeadMap.get(ld.Id).ownerId != queueId && ld.OwnerId != queueId){
                        ld.Reassign_Date_Time__c = datetime.now();
                    }


                }
            }
            if (!reciepientsId.isEmpty() && !leadByIdMap.isEmpty()){
                CustomNotification.notifyUsers(reciepientsId, leadByIdMap, 'New Lead Assigned', 'New Lead Has Been Assigned to you ');
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void handleStageChange(map<Id, Lead> newLeadMap, map<Id, Lead> oldLeadMap){
        //system.debug('newMap::'+newLeadMap);
        //system.debug('oldMap::'+oldLeadMap);
        try{
            for (lead ld : newLeadMap.values()){
                if ((ld.lead_stage__c == 'New' || ld.lead_stage__c == 'Called' || ld.lead_stage__c == 'Unassigned') && oldLeadMap.get(ld.Id).lead_stage__c == 'Nurturing'){
                    ld.lead_stage__c = 'Nurturing';
                    if (ld.Nurturing_to_New_Stage__c == null)
                        ld.Nurturing_to_New_Stage__c = 0;
                    ld.Nurturing_to_New_Stage__c += 1;
                }

                // system.debug('oldLeadMap.get(ld.Id).lead_stage__c--->'+oldLeadMap.get(ld.Id).lead_stage__c);
                if (oldLeadMap.get(ld.Id).lead_stage__c == 'Closed Won'){
                    // system.debug('oldLeadMap.get(ld.Id).lead_stage__c--->'+oldLeadMap.get(ld.Id).lead_stage__c);
                    ld.lead_stage__c = 'Closed Won';
                    ld.Lead_status__c = oldLeadMap.get(ld.Id).Lead_status__c;
                }
                if (oldLeadMap.get(ld.Id).lead_stage__c == 'Closed Lost' && ld.Lead_Stage__c != 'Closed Won'){
                    ld.lead_stage__c = 'Closed Lost';
                }
            }
        } catch (exception ex){
            system.debug('Error==>' + ex.getMessage());
            system.debug('Error==>@@' + ex.getLineNumber());
        }
    }

    public static void TargetAchievementUpdationCreation(Map<Id, Lead> newMap, Map<Id, Lead> oldMap){

        integer currentMonth = system.today().month();
        List<Target_Achievement__c> TAListTobeUpdated = new List<Target_Achievement__c>();
        List<Target_Achievement__c> allTargetAchievementRecs = new List<Target_Achievement__c>();
        Map<string, Target_Achievement__c> TArecByUserId = new Map<String, Target_Achievement__c>();
        map<Id, List<Lead>> listOfLeadByUserId = new map<Id, List<Lead>>();
        Map<String, Map<String, Target_Achievement__c>> TArecByMonthByUserId = new Map<String, Map<String, Target_Achievement__c>>();

        try{
            if (!newMap.isEmpty()){
                for (lead newlead : newMap.values()){
                    if (newlead.Payment_details__c != null && newlead.Payment_details__c != oldMap.get(newlead.id).Payment_details__c && newlead.Payment_Date__c != null){
                        if (listOfLeadByUserId.containsKey(newlead.OwnerId)){
                            //system.debug('inside If');
                            List<Lead> leadList = listOfLeadByUserId.get(newlead.OwnerId);
                            leadList.add(newlead);
                            listOfLeadByUserId.put(newlead.OwnerId, leadList);
                        } else{
                            listOfLeadByUserId.put(newlead.OwnerId, new List<Lead>{ newlead });
                        }
                    }
                }
            }
            //system.debug('listOfLeadByUserId :: ' + listOfLeadByUserId);

            if (!listOfLeadByUserId.isEmpty()){
                allTargetAchievementRecs = [Select Id, Achievement_Revenue__c, User__c, Total_Orders__c
                                            From Target_Achievement__c
                                            Where User__c in:listOfLeadByUserId.keySet() And Month__c = :currentMonth];
                if (!allTargetAchievementRecs.isEmpty()){
                    for (Target_Achievement__c TARec : allTargetAchievementRecs){
                        TArecByUserId.put(TARec.User__c, TARec);
                    }
                }

                for (Id userId : listOfLeadByUserId.keySet()){
                    Target_Achievement__c targetAchivementRec = new Target_Achievement__c();
                    if (TArecByUserId.containsKey(userId)){
                        decimal amount = 0;
                        integer orders = 0;

                        for (Lead leadRec : listOfLeadByUserId.get(userId)){
                            amount += leadRec.Payment_details__c;
                            orders++;
                        }
                        targetAchivementRec.Id = TArecByUserId.get(userId).Id;
                        targetAchivementRec.Achievement_Revenue__c = TArecByUserId.get(userId).Achievement_Revenue__c + amount;
                        targetAchivementRec.Total_Orders__c = TArecByUserId.get(userId).Total_Orders__c + orders;
                    } else{
                        targetAchivementRec.User__c = userId;
                        decimal amount = 0;
                        integer orders = 0;

                        for (Lead leadRec : listOfLeadByUserId.get(userId)){
                            amount += leadRec.Payment_details__c;
                            orders++;
                        }
                        targetAchivementRec.Start_Date__c = system.today();
                        targetAchivementRec.Target_Revenue__c = 100000;
                        targetAchivementRec.Achievement_Revenue__c = amount;
                        targetAchivementRec.Total_Orders__c = orders;
                    }
                    TAListTobeUpdated.add(targetAchivementRec);
                }
                if (!TAListTobeUpdated.isEmpty()){
                    upsert TAListTobeUpdated;
                }
            }
        } catch (exception ex){
            system.debug('Error-->' + ex.getMessage());
            system.debug('Error-->' + ex.getLineNumber());
        }
    }

    public static void updateFlagForRemarketingLeadClosure(Map<Id, Lead> newMap, Map<Id, Lead> oldMap){
        try{
            List<Remarketing_Config__c> customSettingForRmTeam = Remarketing_Config__c.getall().values();
            for (Lead leadRec : newMap.values()){
                if (leadRec.Is_Remarketing_Lead__c == true){
                    if ((leadRec.Total_Calls_Made_after_RM_assigned_date__c != oldMap.get(leadRec.Id).Total_Calls_Made_after_RM_assigned_date__c && leadRec.Total_Calls_Made_after_RM_assigned_date__c > oldMap.get(leadRec.Id).Total_Calls_Made_after_RM_assigned_date__c && leadRec.Total_Calls_Made_after_RM_assigned_date__c > integer.valueOf(customSettingForRmTeam[0].Lead_Called_X_times__c)) || (leadRec.Total_Connected_calls_Made_after_RM_ass__c != oldMap.get(leadRec.Id).Total_Connected_calls_Made_after_RM_ass__c && leadRec.Total_Connected_calls_Made_after_RM_ass__c > oldMap.get(leadRec.Id).Total_Connected_calls_Made_after_RM_ass__c && leadRec.Total_Calls_Made_after_RM_assigned_date__c > integer.valueOf(customSettingForRmTeam[0].Leads_Connected_X_times__c))){
                        leadRec.Closed_By_Remarketing__c = true;
                    }
                }
            }
        } catch (exception ex){
            system.debug('Error-->' + ex.getMessage());
            system.debug('Error-->' + ex.getLineNumber());
        }
    }

    public static void beforeUpdate(Map<Id, Lead> newMap, Map<Id, Lead> oldMap){
        try{
            List<Task> taskListToInsert = new List<Task>();
            for (Lead leadRec : newMap.values()){
                if (leadRec.Application_form_completed__c != oldMap.get(leadRec.Id).Application_form_completed__c && (leadRec.Application_form_completed__c == 'Submitted')){
                    if (leadRec.Application_Form_Completed_Date_Time__c == null)
                        leadRec.Application_Form_Completed_Date_Time__c = system.now();
                }
                if (leadRec.Application_form_completed__c != oldMap.get(leadRec.Id).Application_form_completed__c && (leadRec.Application_form_completed__c == 'Interview Slot Booked')){
                    if (leadRec.Interview_Slot_Date_Time__c == null)
                        leadRec.Interview_Slot_Date_Time__c = system.now();
                }
                if (leadRec.Interview_Status_AO__c != oldMap.get(leadRec.Id).Interview_Status_AO__c && (leadRec.Interview_Status_AO__c == 'Conducted')){
                    if (leadRec.Interview_Conducted_Date_Time__c == null)
                        leadRec.Interview_Conducted_Date_Time__c = system.now();
                }
                if(leadRec.Is_Interview_Conducted__c != oldMap.get(leadRec.Id).Is_Interview_Conducted__c && leadRec.Is_Interview_Conducted__c == true){
                    Task gmeetTask = new Task();
                    gmeetTask.Subject =  'Interview Task at '+ String.valueOf(Time.newInstance(system.now().hour(), system.now().minute(), system.now().second(), 00)).remove('.000Z')+' on '+ string.valueOf(system.now().Date()).remove(' 00:00:00');
                    gmeetTask.WhoId = leadRec.Id;
                    gmeetTask.OwnerId = leadRec.OwnerId;
                    gmeetTask.Status = 'Completed';
                    gmeetTask.Priority = 'Normal';
                    gmeetTask.Activity_Date_Time__c = system.now();
                    gmeetTask.Activity_Type__c = 'Interview Scheduled';
                    taskListToInsert.add(gmeetTask);
                }
            }
            if(!taskListToInsert.isEmpty()){
                insert taskListToInsert;
            }
        } catch (exception ex){
            system.debug('Error-->' + ex.getMessage());
            system.debug('Error-->' + ex.getLineNumber());
        }
    }

}