import { LightningElement } from 'lwc';

export default class HelloWorld extends LightningElement {
    greeting = 'Pippo';

    changeHandler(event){
        this.greeting = event.target.value;
    }
}