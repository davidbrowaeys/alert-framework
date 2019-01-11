({
	doInit : function(component, event, helper) {
        helper.getAlertRecords(component,event,'all');
        //execute getAlertRecords() again after 'x' sec each
        if (component.get("v.pollingRecordUpdate")){
            var frequency = component.get("v.pollingFrequency");
            if (!frequency || frequency < 500) frequency = 500;
            window.setInterval(
                $A.getCallback(function() { 
                    helper.getAlertRecords(component,event,'list');
                }), frequency
            );
        }
	},
	getAlertRecords : function(component, event, displayType){                       
		var action = component.get("c.getAlerts");
        action.setParams({
            category: component.get("v.category"),
			recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();           
            if (state === "SUCCESS") {               
                const results = response.getReturnValue();
                var alerts = [];
                var popups = [];
                if (results && results[0]){
                    for (var i in results){
                        if (results[i].Display_Type__c.indexOf('Popup') >= 0 && (displayType === 'all' || displayType === 'popup')){
                            popups.push(results[i]);
                        }
                        if ( (!results[i].Display_Type__c || results[i].Display_Type__c.indexOf('List') >= 0) && (displayType === 'all' || displayType === 'list')){
                            alerts.push(results[i]);
                        }
                    }
                }
                component.set("v.alerts",alerts);
                component.set("v.popups",popups);
                if (popups && popups.length > 0){
                    console.log('open popup');
                    component.set("v.isOpen",true);
                }
            }
            component.set("v.loaded",true);
        });
        
        $A.enqueueAction(action); 
	}
})