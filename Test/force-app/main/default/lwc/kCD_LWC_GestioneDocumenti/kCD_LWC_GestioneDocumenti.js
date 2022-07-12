import { api, LightningElement, track, wire } from 'lwc';
import getDocumentsByDate from '@salesforce/apex/TelepassProxyController.getDocumentsByDate';
import insertDocument from '@salesforce/apex/TelepassProxyController.insertDocument';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import dismissionDocument from '@salesforce/apex/TelepassProxyController.dismissionDocument';

export default class Test_Telepass extends LightningElement {

    @track dateToSearch = null;
    @track documentsRepo = { documents: [] };
    @track showPDF = false;
    @track blobURL;
    @track insertResult = {};
    @track agreementId;
    @api recordId;


    uploadFile(event) {
        var fileReader = new FileReader();
        var base64;
        var nameFile = (event.target.value).split('\\').reverse()[0];
        fileReader.onload = (function (fileLoadedEvent) {
            base64 = (fileLoadedEvent.target.result).replace('data:application/pdf;base64,', '');
            //console.log(base64);
            insertDocument({ agreementId: this.agreementId, document: base64, description: nameFile, userId: Id }).then(result => {
                console.log('result: ' + result), this.insertResult = result, this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Documento ' + nameFile + ' inserito',
                        variant: 'success'
                    })
                ), (() => {
                    let date;
                    date = this.dateToSearch;
                    this.dateToSearch = date;
                }).bind(this)();
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Errore creazione documento',
                        variant: 'error'
                    })
                )
            });
        }).bind(this);
        fileReader.readAsDataURL(event.target.files[0]);
    }

    closeModalPDF(event) {

        this.showPDF = false;
    }

    changeDate(event) {
        this.dateToSearch = event.target.value;
    }

    openDocument(event) {
        let base64 = event.target.value;
        let sliceSize = 512;
        base64 = base64.replace(/^[^,]+,/, '');
        base64 = base64.replace(/\s/g, '');
        let byteCharacters = window.atob(base64);
        let byteArrays = [];
        for (let offset = 0; offset < byteCharacters.length; offset = offset + sliceSize) {
            let slice = byteCharacters.slice(offset, offset + sliceSize);
            let byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
                byteNumbers[i] = slice.charCodeAt(i);
            }
            let byteArray = new Uint8Array(byteNumbers);

            byteArrays.push(byteArray);
        }

        let blobText = new Blob(byteArrays, { type: 'application/pdf' });
        this.blobURL = URL.createObjectURL(blobText);
        //console.log(' this.blobURL:' + this.blobURL);
        //console.log(this.agreementId);

        if (this.showPDF === false)
            this.showPDF = true;
    }


    @wire(getDocumentsByDate, { agreementId: '$agreementId', dataFiltro: '$dateToSearch' })
    documentsList({ error, data }) {
        if (error != null) {
            console.log('error getdocumentbydate: ' + error);
        } else {
            this.documentsRepo = data;
            console.log('data =' + data);
        }
    };

    @wire(getRecord, { recordId: '$recordId', fields: 'Convenzioni_TKCC02__c.Name' })
    wiredRecord({ error, data }) {
        if (error != null) {
            console.log('error: ' + error);
        } else if (data) {
            this.agreementId = data.fields.Name.value;
        }
    }

    dismissDocument(event) {
        console.log('insertion date:' + event.target.value);
        dismissionDocument({ agreementId: 100, insertionDate: event.target.value, userId: Id }).then(result => {
            console.log('result: ' + result);
            if (result.length > 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Errore cancellazione',
                        variant: 'error'
                    })
                );
                (() => {
                    let date;
                    date = this.dateToSearch;
                    this.dateToSearch = date;
                }).bind(this)();
                console.log('data da cercare: ' + this.dateToSearch);
            }

        }).catch(error => {this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Cancellazione effettuata con successo',
                variant: 'success'
            })
        )});
    }
}