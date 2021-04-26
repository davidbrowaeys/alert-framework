/**
* @author David Browaeys
* @date 01/11/2018
* @group Alert
* @description A test class created to validate the AlertService class. 
*/
@isTest
private class AlertService_Test {
    
    @testSetup static void setup(){
        Account a = (Account)TestDataFactory.createSObject(new Account(),true);

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity(AccountId = a.Id));
        insert opp;
    }
    @isTest static void test_basic_alerts() {
        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Home';
        insert alert;

        Test.startTest();
        Alert__c[] throwAlerts = AlertService.getRecordAlerts('Home',null);
        System.assert(throwAlerts.isEmpty() == false);
        Test.stopTest();
    }
    @isTest static void test_alert_linked_to_record() {
        Account a = [SELECT Id FROM Account LIMIT 1];

        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Account';
        alert.Parent_ID__c = a.Id;
        alert.User__c = UserInfo.getUserId();
        insert alert;

        Test.startTest();
        Alert__c[] throwAlerts = AlertService.getRecordAlerts('Account',a.Id);
        System.assert(throwAlerts.isEmpty() == false);
        Test.stopTest();
    }
    @isTest static void test_alert_filter_all(){
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        
        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Opportunity';
        alert.Filter_Logic__c = 'All';
        alert.Action_Type__c = 'Link';
        alert.Action_Link__c = '/lightning/o/Task/new';
        alert.Description__c = 'Hello world /lightning/r/Account/{{AccountId}}/edit     {{missingfields}}';
        insert alert;

        Alert_Criteria__c[] criteria = new Alert_Criteria__c[]{
            new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Account.Customer_Number__c', Operator__c = 'equals'),
            new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Need__c', Operator__c = 'not equals', Value__c = 'Blabla')
        };
        insert criteria;

        Test.startTest();
        Alert__c[] throwAlerts = AlertService.getRecordAlerts('Opportunity',o.Id);
        System.assert(throwAlerts.isEmpty() == false);
        Test.stopTest();
    }
    
    @isTest static void test_alert_filter_any(){
        Account a = [SELECT Id FROM Account LIMIT 1];
        
        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Account';
        alert.Filter_Logic__c = 'All';
        insert alert;

        Alert_Criteria__c[] criteria = new Alert_Criteria__c[]{
            new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'AGGREGATE', Operator__c = 'equals', Value__c='1',Aggregate_Expression__c='COUNT|Opportunity|Id|AccountId|Need__c != null')
        };
        insert criteria;

        Test.startTest();
        Alert__c[] throwAlerts = AlertService.getRecordAlerts('Account',a.Id);
        System.assert(throwAlerts.isEmpty() == false);
        Test.stopTest();
    }
    
     @isTest static void test_alert_filter_custom(){
        Account a = [SELECT Id, AccountNumber, Type FROM Account LIMIT 1];
        a.AccountNumber = '123';
        a.Type = '123';
        update a;
         
        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Account';
        alert.Filter_Logic__c = 'Custom';
        alert.Custom_Filter_Expression__c = '1 OR 2';
        insert alert;

        Alert_Criteria__c[] criteria = new Alert_Criteria__c[]{
            new Alert_Criteria__c(Criteria_Number__c = 1, Alert__c = alert.Id, Field_Name__c = 'AccountNumber', Operator__c = 'equals'),
        	new Alert_Criteria__c(Criteria_Number__c = 2, Alert__c = alert.Id, Field_Name__c = 'Type', Operator__c = 'equals')
        };
        insert criteria;

        Test.startTest();
        Alert__c[] throwAlerts = AlertService.getRecordAlerts('Account',a.Id);
        System.assert(throwAlerts.isEmpty() == false);
        Test.stopTest();
    }
    
    @isTest static void test_getAlertById(){
        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Account';
        alert.Filter_Logic__c = 'All';
        insert alert;
        
        Test.startTest();
        Alert__C foundAlert = AlertService.getAlertById(alert.Id);
        System.assert(foundAlert != null);
        Test.stopTest();
    }

    @isTest static void test_alert_evaluate_criteria(){

        Opportunity opp = (Opportunity)TestDataFactory.createSObject(new Opportunity());

        Alert__c alert = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert.Category__c = 'Account';
        alert.Filter_Logic__c = 'All';
        insert alert;

        Alert_Criteria__c criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Amount', Operator__c = 'less or equals', Value__c='0');
        insert criteria;
        //compare currency/double
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Amount', Operator__c = 'less', Value__c='0');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Amount', Operator__c = 'greater', Value__c='0');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Amount', Operator__c = 'greater or equals', Value__c='0');
        AlertService.processRuleCriteria(criteria,opp,null);
        //compare date
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'equals', Value__c='TODAY|d+1');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'not equals', Value__c='TODAY|y-3');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'less', Value__c='THIS_WEEK|m+2');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'less', Value__c='THIS_WEEK|m+2');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'less or equals', Value__c='TODAY');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'less', Value__c='THIS_WEEK|m+2');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'greater', Value__c='TODAY|d-2');
        AlertService.processRuleCriteria(criteria,opp,null);
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'CloseDate', Operator__c = 'greater or equals', Value__c='THIS_MONTH|y+1');
        AlertService.processRuleCriteria(criteria,opp,null);
        //string - contains
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Need__c', Operator__c = 'contains', Value__c='test');
        AlertService.processRuleCriteria(criteria,opp,null);
        //other operator
        criteria = new Alert_Criteria__c(Alert__c = alert.Id, Field_Name__c = 'Need__c', Operator__c = 'helloworld', Value__c='test');
        AlertService.processRuleCriteria(criteria,opp,null);
    }
    @isTest static void test_alert_criteria_operator_type(){    
        Double d = 2;
        Integer i = 2;
        Decimal dm = 2; 
        Date today = Date.today();
        Datetime now = Datetime.now();

        System.assertEquals(AlertService.issmallerthan(d, '2'),false);
        System.assertEquals(AlertService.issmallerthan(i, '2'),false);
        System.assertEquals(AlertService.issmallerthan(d, '2'),false);
        System.assertEquals(AlertService.issmallerthan(today, 'TODAY'),false);
        System.assertEquals(AlertService.issmallerthan(now, 'NOW|H-66'),false);

        System.assertEquals(AlertService.issmallerorequalsthan(d, '2'),true);
        System.assertEquals(AlertService.issmallerorequalsthan(i, '2'),true);
        System.assertEquals(AlertService.issmallerorequalsthan(d, '2'),true);
        System.assertEquals(AlertService.issmallerorequalsthan(today, 'TODAY'),true);
        System.assertEquals(AlertService.issmallerorequalsthan(now, 'NOW|M+2'),true);

        AlertService.isgreaterorequalsthan(d, '2');
        AlertService.isgreaterorequalsthan(i, '2');
        AlertService.isgreaterorequalsthan(d, '2');
        AlertService.isgreaterorequalsthan(today, 'TODAY');
        AlertService.isgreaterorequalsthan(now, 'NOW|d+3');

        AlertService.isgreaterthan(d, '2');
        AlertService.isgreaterthan(i, '2');
        AlertService.isgreaterthan(d, '2');
        AlertService.isgreaterthan(today, 'TODAY');
        AlertService.isgreaterthan(now, 'NOW|H-2');
    }
    @isTest static void test_alertconsole_controller(){ 
        Account a = [SELECT Id FROM Account LIMIT 1];
        
        Alert__c alert1 = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert1.Category__c = 'Account';
        insert alert1;
        
        Alert__c alert2 = (Alert__c)TestDataFactory.createSObject(new Alert__c());
        alert2.Category__c = 'Account';
        alert2.User__c = Userinfo.getUserId();
        insert alert2;
        
        System.assert(AlertConsoleController.getAlerts('Account', a.Id).isEmpty() == false);
        AlertConsoleController.hideUserAlert(alert1.Id);
        AlertConsoleController.hideUserAlert(alert2.Id);
        System.assert(AlertConsoleController.getAlerts('Account', a.Id).isEmpty() == true);
    }
}