import { LightningElement } from 'lwc';

export default class ScheduleComparisonWithRecordPicker extends LightningElement {
    recordId;
    get recordNotChosen(){return !this.recordId;}

    handleChange(event) {
        console.log('event.detail: ' + event.detail);
        this.recordId = event.detail.recordId;
    }
}