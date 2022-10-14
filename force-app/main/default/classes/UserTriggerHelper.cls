public class UserTriggerHelper {
    public Static Void checkingManagerandTranferLead(Map<Id, User> oldMap, Map<Id, User> newMap){
        try{
            set<Id> deactivatedUsersId = new Set<Id>();
            
            for(User userRec : newMap.values()){
                if(userRec.isActive != oldMap.get(userRec.id).isActive && userRec.isActive == false ){
                    if(userRec.ManagerId == null){
                        system.debug('Error');
                        userRec.Id.addError('Please Tag Manager to TRANSFER LEADS');
                    }else{
                        system.debug('No Error');
                        deactivatedUsersId.add(userRec.ID);
                    }
                }
            }
            system.debug('deactivatedUsersId>>'+deactivatedUsersId);
            if(!deactivatedUsersId.isEmpty()){
                UpdateLeadOwner.changeLeadOwnerShip(deactivatedUsersId);
                DeleteAssignmentGroupMember.deleteAGM(deactivatedUsersId);
            }
        }catch(Exception ex){
            system.debug('Erro>>'+ex.getMessage());
            system.debug('Error@@@'+ex.getLineNumber());
        }
    }
}