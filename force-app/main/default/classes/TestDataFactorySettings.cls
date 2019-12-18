/**
* @author David Browaeys
* @description Serves as test data factory for test classes
* @group SF Offers
**/
@isTest
public class TestDataFactorySettings {

    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }
    //Account
    public class AccountDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> { 
                Account.Name => 'Test Account'
            };
    	}
    }
    //Contact
    public class ContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Contact.FirstName => 'First',
                Contact.LastName => 'Last'
            };
        }
    }
    //Opportunity
    public class OpportunityDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                Opportunity.StageName => 'Identification',
                Opportunity.CloseDate => System.today()
            };
        }
    }
    //OpportunityLineItem
    public class OpportunityLineItemDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults(){
            return new Map<Schema.SObjectField, Object>{
               OpportunityLineItem.quantity => 1,
               OpportunityLineItem.UnitPrice => 1000    
        	};
    	}
    }
   //Product2
    public class Product2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Product2.Name => 'Bachelor of Accounting',
				Product2.Family => 'Course',
				Product2.ProductCode => '123',
				Product2.IsActive => true   
           };
        }
    }
    //Pricebook2
    public class Pricebook2Defaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				Pricebook2.Name => 'International',
                Pricebook2.IsActive => true
           };
        }
    }
    //PricebookEntry
    public class PricebookEntryDefaults implements FieldDefaults{
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
				PricebookEntry.unitprice => 25000,
                PricebookEntry.IsActive => true    
           };
        }
    }
 	//User
    public class UserDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                User.Username=>'test@mydomain.test',
                User.Email=>'test@mydomain.com.au',
                User.LastName=>'test',
                User.Alias=>'tst',
                User.TimeZoneSidKey=>'Australia/Sydney',
                User.LocaleSidKey=>'en_AU',
                User.EmailEncodingKey=>'ISO-8859-1',
                User.LanguageLocaleKey=>'en_US'
            };
        }
    }
    // When we create a list of SObjects, we need to(do we need this?)
    public static Map<String, String> nameFieldMap = new Map<String, String> {
        'Contact' => 'LastName',
        'Case' => 'Subject'
    };
}