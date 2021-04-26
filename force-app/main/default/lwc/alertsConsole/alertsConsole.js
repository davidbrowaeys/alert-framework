import { api, LightningElement,wire } from 'lwc';
import getAlerts from '@salesforce/apex/AlertConsoleController.getAlerts';
import { getRecord } from 'lightning/uiRecordApi';

export default class AlertsConsole extends LightningElement {
    @api recordId
    @api objectApiName
    @api popupBanner = 'error';
    @api displayType = 'all';

    alerts;
    popups;
    error;
    showModal = false;
    loading = true;

    @wire(getRecord, {recordId:'$recordId', layoutTypes: 'Full', modes: 'View' })
    wiredGetRecord({data,error}) {
        if (data){
            this.record = data;
        }else if(error){
            this.error = error;
        }
    }

    set record(data){
        this.refreshAlerts();
    }

    async refreshAlerts() {
        try {
            console.log('Call imperative apex');
            this.loading = true;
            const result = await getAlerts({ category: this.objectApiName, recordId: this.recordId });
            this.alerts = [];
            this.popups = [];
            result.forEach(element => {
                if (element.Display_Type__c.indexOf('Popup') >= 0 && (this.displayType === 'all' || this.displayType === 'popup')) {
                    this.popups.push(element);
                }
                if ((!element.Display_Type__c || element.Display_Type__c.indexOf('List') >= 0) && (this.displayType === 'all' || this.displayType === 'list')) {
                    this.alerts.push(element);
                }
            });
            // this.buildChart(component, alerts); //????
            if (this.popups && this.popups.length > 0) {
                this.showModal = true;
            }
        } catch (error) {
            this.error = error;
        }
        this.loading = false;
    }
    get hasAlerts(){
        return this.alerts && this.alerts.length > 0;
    }
    closeModal() {
        this.showModal = false;
    }
    get popupBannerClass() {
        return `slds-modal__header slds-theme_alert-texture slds-theme_${this.popupBanner}`;
    }
}