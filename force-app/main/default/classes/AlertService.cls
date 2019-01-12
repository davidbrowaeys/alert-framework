/**
* @author davidbrowaeys[js]
* @date 01/11/2018
* @group Alert
* @description Service class to handle alert
*/
public class AlertService {
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method return a list of alert by category
    * @param category alert category
    * @return list of alerts that meet the criteria
    */
    private static List<String> fields = new List<String>();
    private  static List<String> regexFields = new List<String>();
    
    public static Alert__c[] getAlertsByCategory(String category){
        return [SELECT id, Subject__c, Description__c, Type__c, Type_Icon__c, Parent_ID__c, Filter_Logic__c, 
                Display_Type__c, Action_Type__c, Action_Link__c, Action_Component_Name__c, Action_Component_Params__c, Action_Label__c,
                Custom_Filter_Expression__c FROM Alert__c 
                WHERE Is_Active__c = TRUE
                AND Parent_ID__c = null AND Category__c=: category
                AND (User__c =: Userinfo.getUserId() OR User__c = null)
                AND Id NOT IN (SELECT Alert__c FROM Alert_User_Option__c WHERE User__c =: Userinfo.getUserId())
                ORDER BY Sort_Order__c ASC NULLS LAST];
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method return a list of alert base on a specified category and record id
    * @param category alert category
    * @param parentId id of the object record
    * @return list of alerts that meet the criteria
    */
    public static Alert__c[] getAlertsByObject(String category, String parentId){
        return [SELECT  id, Subject__c, Description__c, Type__c, Type_Icon__c, Parent_ID__c, Filter_Logic__c, Display_Type__c, Action_Type__c, Action_Link__c, Action_Component_Name__c, Action_Component_Params__c, Action_Label__c,
                        Custom_Filter_Expression__c, (SELECT Id, Field_Name__c, Operator__c, Value__c, Aggregate_Expression__c, Criteria_Number__c FROM Alert_Criteria__r
                                                     ORDER BY Criteria_Number__c ASC)
                FROM Alert__c 
                WHERE Is_Active__c = TRUE 
                AND Category__c =: category
                AND (Parent_ID__c =: parentId OR Parent_ID__c = null)
                AND (User__c =: Userinfo.getUserId() OR User__c = null)
                AND Id NOT IN (SELECT Alert__c FROM Alert_User_Option__c WHERE User__c =: Userinfo.getUserId())
                ORDER BY Sort_Order__c ASC NULLS LAST];
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method retrieve specific alert
    * @param alertId id of an alert
    * @return an alert instance
    */
    public static Alert__c getAlertById(String alertId){
        return [SELECT id, Subject__c, Description__c, Type__c, Type_Icon__c, Parent_ID__c, User__c 
                    FROM Alert__c
                    WHERE id =: alertId];
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method retrieve list of alert either by category and/or for a specific record. If recordId is not specified, it will only search by category
    * @param category alert category
    * @param parentId id of the object record
    * @return list of alerts that meet the criteria
    */
    public static Alert__c[] getRecordAlerts(String category, String recordId){
        BooleanEvaluate boolEval =null;
        if (String.isBlank(recordId)){  //no record id specified
            return getAlertsByCategory(category);
        }
        Alert__c[] rules = getAlertsByObject(category, recordId);   //get alert for specified record
        String queryfields = parseFieldsToString(rules); //parse field reference in alert crtieria into string
        SObject record;
        if (String.isNotBlank(queryfields) == true){    // retrieve record based on the fields reference in the alert criteria
            String soql = String.format('SELECT {0} FROM {1} WHERE Id = :recordId',new List<String>{queryfields, category});
            record = Database.query(soql);
        } 
        Map<ID,Object> aggregateResults = parseAggregateFunctionToSql(rules, recordId); //perform sql for aggregate function on child record
        List<Alert__c> alerts = new List<Alert__c>();
        for (Alert__c r : rules){
            if (r.Filter_Logic__c == null){ //is there any filter logic ?
                alerts.add(r);                  
                continue;
            }
             //filter logic works along with alert criteria, all alert are considered are consider as true by default        
            List<String> fieldsInError = new List<String>();
            Map<Integer, Boolean> criteriaResultsMap = new Map<Integer, Boolean>();
            for (Alert_Criteria__c c : r.Alert_Criteria__r){
                if(processRuleCriteria(c,record,aggregateResults) == true){
                    fieldsInError.add(c.Field_Name__c);
                }
                if(r.Filter_Logic__c == 'Custom'){//custom filter
                	criteriaResultsMap.put(Integer.valueOf(c.Criteria_Number__c), processRuleCriteria(c,record,aggregateResults));
                }
            }
            if (    (r.Filter_Logic__c == 'All' && fieldsInError.size() == r.Alert_Criteria__r.size() ) ||
                    (r.Filter_Logic__c == 'Any' && fieldsInError.size() >= 1 )||
                    (r.Filter_Logic__c == 'Custom' && criteriaResultsMap.size() >= 1 )){
                
                for (String f : regexFields){
                    Object value = getFieldValue(record, f.split('\\.'), 0);
                    if (r.Description__c != null) r.Description__c = r.Description__c.replaceAll('\\{\\{'+f+'\\}\\}', String.valueOf(value));
                    if (r.Action_Type__c == 'Link' &&  r.Action_Link__c != null) r.Action_Link__c = r.Action_Link__c.replaceAll('\\{\\{'+f+'\\}\\}', String.valueOf(value));
                    if (r.Action_Type__c == 'Component' && r.Action_Component_Params__c != null) r.Action_Component_Params__c = r.Action_Component_Params__c.replaceAll('\\{\\{'+f+'\\}\\}', String.valueOf(value));
                }
                
                if (r.Description__c != null && r.Description__c.contains('{{missingfields}}') == true && fieldsInError.isEmpty() == false){
                    String labels = findLabelsToDisplay(record,fieldsInError);
                    r.Description__c = r.Description__c.replaceAll('\\{\\{missingfields\\}\\}',labels);
                }
                if (r.Filter_Logic__c == 'Custom'){
                    //start of evaluate expression
		            boolEval = new BooleanEvaluate(r.Custom_Filter_Expression__c, criteriaResultsMap.values());
                    boolEval.evaluate();
                    //end of evaluate expression
            	}
                
                if((boolEval!= null && r.Filter_Logic__c == 'Custom' && boolEval.finalResult) ||
                   (r.Filter_Logic__c == 'Any' || r.Filter_Logic__c == 'All')){    
                	alerts.add(r); //crtieria are validated, we can add the alerts 
                }
            }
        }
        return alerts;
    }
    public static String findLabelsToDisplay(SObject record, List<String> regexFields){
        String labels = '';
        for (String f : regexFields){
            if(f != 'RecordType.Name')  //exclude record type name on the missing fields
            	labels += getFieldLabel(record, f.split('\\.'),0) + ', '; //updated 3/12/2018 DYU - Replace hyphen with comma
        }
        return labels.removeEnd(', ');
    }
    public static String getFieldLabel(SObject record, String[] fieldNames, Integer index){
        if (index == fieldNames.size() - 1){
            Schema.DescribeSObjectResult objectDescribe = record.getSObjectType().getDescribe();
            return objectDescribe.fields.getMap().get(fieldNames[index]).getDescribe().getLabel();
        }
        return getFieldLabel(record.getSObject(fieldNames[index]),fieldNames, index + 1);
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method go to all the alert crtieria and concert all fields referenced into a single string
    * @param rules list of alerts
    * @return single string containing all fields comma separated. 
    */
    public static String parseFieldsToString(List<Alert__c> rules){
        for (Alert__c r : rules){
            for (Alert_Criteria__c c : r.Alert_Criteria__r){
                if (fields.contains(c.Field_Name__c) == false && c.Field_Name__c.toLowerCase() != 'aggregate') 
                    fields.add(c.Field_Name__c);
            }
            if (r.Description__c != null) findFieldsInString(r.Description__c);
            //action 
            if (r.Action_Type__c == 'Link' && r.Action_Link__c != null) findFieldsInString(r.Action_Link__c);
            if (r.Action_Type__c == 'Component' && r.Action_Component_Params__c != null) findFieldsInString(r.Action_Component_Params__c);
        }
        return String.join(fields,',');
    }
    public static void findFieldsInString(String s){
        Pattern ptrn = Pattern.compile(Constants.MERGEFIELDREGEX); 
        Matcher matcher = ptrn.matcher(s);
        while (matcher.find()) { 
            String f = matcher.group().replaceAll('[\\{,\\}]','');
            if (fields.contains(f) == false && f != 'missingfields'){
                fields.add(f);
                regexFields.add(f);
            }
        }
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method parse all alert criteria that are set as aggregate function. Aggregate function are defined on the Alert_Crtieria__c.Aggregate_Expression__c. 
    *   Syntax: Aggregate|ChildObject|AggregateField|ParentField|Condition::AlertCriteriaValue
    *   Example: SUM|Drawdown__c|Amount__c|Opportunity__c|Amount__c > 10000
    * @param rules list of alerts
    * @param record id of the sobject record
    * @return map of calculated aggregate result by alert criteria id
    */
    public static Map<ID,Object> parseAggregateFunctionToSql(List<Alert__c> rules, String recordId){
        //interprete all the alert crtieria for aggregate function and transform them into soql query
        Map<ID,String> aggregateAlerts = new Map<ID,String>();
        for (Alert__c r : rules){
            try{
                for (Alert_Criteria__c c : r.Alert_Criteria__r){
                    if (c.Field_Name__c.toLowerCase() == 'aggregate'){ 
                        String[] attributes = c.Aggregate_Expression__c.split('\\|');//aggregate function separator
                        if (attributes.size() == 4 ) attributes.add('');    //4th attributes means there is no where condition
                        else attributes[4] = 'AND '+attributes[4];
                        //Quoting the merge field makes it literal text. In order to get the merge field to work, you have to quote the quotes
                        String query = String.format('SELECT {0}({2})result FROM {1} WHERE {3} = \'\'{5}\'\' {4} GROUP BY {3}',
                                                   new String[]{
                                                       attributes[0],   //AGR function
                                                       attributes[1],   //Child object
                                                       attributes[2],   //Aggregate field
                                                       attributes[3],   //ParentField
                                                       attributes[4],   //Condition
                                                       recordId
                                                   });
                        aggregateAlerts.put(c.Id,query);
                        break;      //make sure we have only one SOQL per alert
                    }
                }   
            }catch(Exception e){
                System.debug('Error for parsing aggregate function. Alert will be ignored!');
            }
        }
        //perform SOQL for all aggregate functions(alert crtieria). 
        //This soql into for loop is control on the front end by limiting the number of aggregate function per alerts.  
        Map<ID,Object> aggregateResults = new Map<ID,Object>();
        for (String key : aggregateAlerts.keySet()){
            if (Limits.getQueries() < (Limits.getLimitQueries() - 10)){ //this will allow 90 aggregate function per object type
                List<SObject> result = Database.query(aggregateAlerts.get(key));
                if (result != null && result.isEmpty() == false)
                    aggregateResults.put(key, result[0].get('result'));
                else{
                    aggregateResults.put(key, 0);
                }
            }
        }
        return aggregateResults;
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Evaluate all alert criteria for a specified record
    * @param crteria alert criteria to evaluate
    * @param record instance of an sobject
    * @param aggregateResults map of aggregation
    * @return true if crtieria was evaluate successfully otherwise false
    */
    public static Boolean processRuleCriteria(Alert_Criteria__c criteria, SObject record, Map<ID,Object> aggregateResults){
        Object leftValue;
        String rightValue;
        if (criteria.Field_Name__c.toLowerCase() == 'aggregate'){
            if (aggregateResults.get(criteria.Id) != null){ 
                leftValue = aggregateResults.get(criteria.Id);
                rightValue = criteria.Value__c;
            }else{
                return false;
            }
        }else{
            leftValue = getFieldValue(record, criteria.Field_Name__c.split('\\.'), 0);  //this is to cover cross object Opportunity.Account.Customer_Number__c
            rightValue = criteria.Value__c;
        }
        switch on criteria.Operator__c {
            when 'equals' {
                return isequals(leftValue,rightValue);
            }when 'not equals' {
                return isnotequals(leftValue,rightValue);
            }when 'contains' {
                return leftValue != null && ((String)leftValue).contains(rightValue);
            }when 'greater' {
                return isgreaterthan(leftValue,rightValue);
            }when 'greater or equals' {
                return isgreaterorequalsthan(leftValue,rightValue);
            }when 'less' {
                return issmallerthan(leftValue,rightValue);
            }when 'less or equals' {
                return issmallerorequalsthan(leftValue,rightValue);
            }when else {
                return false;
            }
        }
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Recursive method that retrieve object value of a specified field name, this handle cross object such as Opportunity.Account.Custom_Number__c
    * @param record instance of an sobject
    * @param fieldNames apiname of fields starting from direct parent(Opportunity) to field name(Customer_Number__c)
    * @param index current index of the field name list
    * @return untyped value of a field 
    */
    public static Object getFieldValue(SObject record, String[] fieldNames, Integer index){
        if (index == fieldNames.size() - 1){
            return record.get(fieldNames[index]);
        }
        return getFieldValue(record.getSObject(fieldNames[index]),fieldNames, index + 1);
    }
    public static Boolean isnotequals(Object o, String p){
        if(o instanceof Date)               return (Date) o != (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o != (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o != (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o != (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o != (p != null ? Double.valueOf(p) : null);
        return (String) o != p;
    }
    public static Boolean isequals(Object o, String p){
        system.debug('***instance '+o+'-'+p);
        if(o instanceof Date)               return (Date) o == (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o == (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o == (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o == (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o == (p != null ? Double.valueOf(p) : null);
        return (String) o == p;
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Compare if an entity is smaller than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is smaller than right entity 
    */
    public static Boolean issmallerthan(Object o, String p){
        if(o instanceof Date)               return (Date) o < (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o < (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o < (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o < (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o < (p != null ? Double.valueOf(p) : null);
        return false;
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Compare if an entity is smaller than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is smaller or equals than right entity 
    */
    public static Boolean issmallerorequalsthan(Object o, String p){
        if(o instanceof Date)               return (Date) o <= (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o <= (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o <= (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o <= (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o <= (p != null ? Double.valueOf(p) : null);
        return false;
    }/**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Compare if an entity is greater or equals than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is greater or equals than right entity 
    */
    public static Boolean isgreaterorequalsthan(Object o, String p){
        if(o instanceof Date)               return (Date) o >= (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o >= (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o >= (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o >= (p != null ? Double.valueOf(p) : null);
        if(o instanceof Double)             return (Double) o >= (p != null ? Double.valueOf(p) : null);
        return false;
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description Compare if an entity is greater than another entity
    * @param o left entity to compare
    * @param p right entity to compare
    * @return true is left entity is greater than right entity 
    */
    public static Boolean isgreaterthan(Object o, String p){
        if(o instanceof Date)               return (Date) o > (p != null ? parseDate(p) : null);
        if(o instanceof Datetime)           return (Datetime) o > (p != null ? parseDatetime(p) : null);
        if(o instanceof Integer)            return (Integer) o > (p != null ? Integer.valueOf(p) : null);
        if(o instanceof Decimal)            return (Double) o > Double.valueOf(p);
        if(o instanceof Double)             return (Double) o > Double.valueOf(p);
        return false;
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method parse a date string formula into a date based on well defined syntax. 
    * @usage 
    * Date mydate1 = parseDate('TODAY|Y+2');
    * Date mydate2 = parseDate('TODAY|M-2');
    * Date mydate3 = parseDate('THIS_WEEK|D-2');
    * Date mydate4 = parseDate('THIS_MONTH|M+2');
    * @param s string date
    * @return converted date
    */
    public static Date parseDate(String s){
        Date targetDate;
        switch on s.substring(0,s.indexOf('|') >= 0 ? s.indexOf('|') : s.length()){
            when 'TODAY' {
                targetDate = Date.today();
            } when 'THIS_MONTH' {
                targetDate = Date.today().toStartOfMonth();
            } when 'THIS_WEEK'{
                targetDate = Date.today().toStartOfWeek();
            } when else{
                System.debug('No date format');
            }
        }
        if (targetDate != null && s.indexOf('|') >= 0){
            String offset = s.substring(s.indexOf('|') + 1);
            switch on offset.substring(0,1) {
                when 'd' {
                    offset = offset.removeStart('d'); 
                    targetDate = targetDate.addDays(Integer.valueOf(offset));
                } when 'm' {
                    offset = offset.removeStart('m'); 
                    targetDate = targetDate.addMonths(Integer.valueOf(offset));
                } when 'y' {
                    offset = offset.removeStart('y'); 
                    targetDate = targetDate.addDays(Integer.valueOf(offset));
                } when else {
                    throw new SystemException('Unsupported Date Format');
                }
            } 
        }
        return targetDate != null ? targetDate : Date.valueOf(s);
    }
    /**
    * @author davidbrowaeys[js]
    * @date 01/11/2018
    * @description This method parse a datetime string formula into a datetime based on well defined syntax. 
    * @usage 
    * Datetime mydate1 = parseDatetime('NOW|hh+2');
    * Datetime mydate2 = parseDatetime('NOW|mm-30');
    * @param s string datetime
    * @return converted datetime
    */
    public static Datetime parseDatetime(String s){
        Datetime targetDate;
        switch on s.substring(0,s.indexOf('|') >= 0 ? s.indexOf('|') : s.length()){
            when 'NOW' {
                targetDate = Datetime.now();
            } when else{
                System.debug('No datetime format');
            }
        }
        if (targetDate != null && s.indexOf('|') >= 0){
            String offset = s.substring(s.indexOf('|') + 1);
            switch on offset.substring(0,1) {
                when 'd' {
                    offset = offset.removeStart('d'); 
                    targetDate = targetDate.addDays(Integer.valueOf(offset));
                } when 'm' {
                    offset = offset.removeStart('m'); 
                    targetDate = targetDate.addMonths(Integer.valueOf(offset));
                } when 'y' {
                    offset = offset.removeStart('y'); 
                    targetDate = targetDate.addDays(Integer.valueOf(offset));
                } when 'H' {
                    offset = offset.removeStart('H'); 
                    targetDate = targetDate.addHours(Integer.valueOf(offset));
                } when 'M' {
                    offset = offset.removeStart('M'); 
                    targetDate = targetDate.addMinutes(Integer.valueOf(offset));
                } when else {
                    System.debug('Unsupported Datetime Format');
                }
            } 
        }
        return targetDate != null ? targetDate : Datetime.valueOf(s);
    }
}