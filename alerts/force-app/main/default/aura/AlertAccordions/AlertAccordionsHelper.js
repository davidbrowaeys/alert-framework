({
	handleClose : function(component, event) {
		var action = component.get("c.hideUserAlert"); //call controller for creating an alert user option
    	var alertId = event.getSource().get("v.value");	//get id from button value
        action.setParams({
			alertId: alertId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();           
            if (state === "SUCCESS") {        
                var tmp = [];		//remove selected alert from list
                var alerts = component.get("v.alerts");
                for(var i in alerts){
                    if (alerts[i].Id != alertId){
                        tmp.push(alerts[i]);
                    }
                }
                component.set("v.alerts",tmp);
            }
        });
        
        $A.enqueueAction(action); 
	},
    handleAlertAction : function (component, event){
        var alertId = event.getSource().get("v.value");	//get id from button value
		var alerts = component.get("v.alerts"); 
		for (var i in alerts){
			if (alerts[i].Id === alertId){
				var alert = alerts[i];
				switch (alert.Action_Type__c){
                    case "Link": { 
						var urlEvent = $A.get("e.force:navigateToURL");
						urlEvent.setParams({
							"url": alert.Action_Link__c
						});
						urlEvent.fire();
						break;
                    }case "Component":{
                        component.set("v.componentName",alert.Action_Component_Name__c);
                        component.set("v.componentParams",JSON.parse(alert.Action_Component_Params__c));
                        component.set("v.isOpen",true);
                        break;
                    }
				}
			}
		}
    }
})