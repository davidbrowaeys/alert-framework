import { LightningElement,api } from 'lwc';

export default class AlertListItem extends LightningElement {
    @api alert;
    
    get containerSize(){
        //style="{! 'width:' + v.actioncontainersize}"
    }
    get iconClass(){
        return this.alert.Type__c+' alertIcon';
    }
}