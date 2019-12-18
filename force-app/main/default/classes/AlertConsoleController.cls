/**
* @author davidbrowaeys[js]
* @date 01/11/2018
* @group Alert
* @description Controller for Alert Console Lightning Component. 
*/
public class AlertConsoleController {
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method return a list of alert base on a specified category and record id
    * @param category alert category
    * @param parentId id of the object record
    * @return list of alerts that meet the criteria
    */
    @AuraEnabled
    public static Alert__c[] getAlerts(String category, String recordId){
        return AlertService.getRecordAlerts(category, recordId);
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method hide or delete an alert for the current user
    * @param alertId id of the alert to hide or delete
    */
    @AuraEnabled
    public static void hideUserAlert(String alertId){
        Alert__c alert = AlertService.getAlertById(alertId);
        if (alert.User__c == Userinfo.getUserId()){//the alert belong to the current user
            delete alert;
        }else if (alert.User__c == null){//the alert belong to business support
            insert new Alert_User_Option__c (Alert__c = alert.Id, User__c = Userinfo.getUserId());
        }else { //current user is not authorised to delete alerts. System admin or Business support should be able to delete alert from Alert tab
            throw new IllegalArgumentException('You are not authorize to perform this action.');
        }   
    }
}