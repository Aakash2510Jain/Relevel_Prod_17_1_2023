public class UpdateLeadOwner {
    @future(callout=true)
    public static void changeLeadOwnerShip(Set<Id> deactivatedUsersId){
        try{
            List<user> usersList = new List<User>();
            List<Lead> leadsToBeReassignment = new List<Lead>();
            List<Lead> leadsToBeUpdated = new List<Lead>();
            Map<string, String> managerIdByUserId = new Map<String, String>();
            
            if(!deactivatedUsersId.isEmpty()){
                usersList  = [SELECT Id,ManagerId FROM User where id in : deactivatedUsersId AND ManagerId != null];
                if(!usersList.isEmpty()){
                    for(User userRecDeactivated : usersList){
                        managerIdByUserId.put(userRecDeactivated.Id, userRecDeactivated.ManagerId);
                    }
                }
                system.debug('deactivatedUsersId>>'+deactivatedUsersId);
                leadsToBeReassignment = [Select Id,OwnerId From Lead Where OwnerId in : deactivatedUsersId];
                system.debug('leadsToBeReassignment>>'+leadsToBeReassignment);
                if(!leadsToBeReassignment.isEmpty()){
                    for(Lead leadRec : leadsToBeReassignment){
                        Lead leadRecToBeUpdated = new Lead();
                        leadRecToBeUpdated.Id = leadRec.Id;
                        if(managerIdByUserId.get(leadRec.OwnerId) != null)
                            leadRecToBeUpdated.OwnerId = managerIdByUserId.get(leadRec.OwnerId);
                        leadsToBeUpdated.add(leadRecToBeUpdated);
                    }
                    if(!leadsToBeUpdated.isEmpty()){
                        update leadsToBeUpdated;
                    }
                } 
            }
        }
        catch(Exception ex){
            system.debug('Erro>>'+ex.getMessage());
            system.debug('Error@@@'+ex.getLineNumber());
        }
    }
}