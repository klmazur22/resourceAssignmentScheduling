import { LightningElement } from 'lwc';

export default class ScheduleComparisonWithRecordPicker extends LightningElement {
    recordId;
    get recordNotChosen(){return !this.recordId;}

    handleChange(event) {
        this.recordId = event.detail.recordId;
    }
}