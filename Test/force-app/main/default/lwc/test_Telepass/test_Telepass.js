import { api, LightningElement, track, wire } from 'lwc';
import getDocumentsByDate from '@salesforce/apex/TelepassProxyController.getDocumentsByDate';
import insertDocument from '@salesforce/apex/TelepassProxyController.insertDocument';
import Id from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

export default class Test_Telepass extends LightningElement {

    @track dateToSearch = null;
    @track documentsRepo = { documents: [] };
    @track showPDF = false;
    @track blobURL;
    @track insertResult = {};
    @track agreementId;
    @api recordId;

    uploadFile(event) {
        let name = (event.target.value).split('\\').reverse()[0];
        console.log(name);
        var fileReader = new FileReader();
        var base64;
        fileReader.onload = (function (fileLoadedEvent) {
            base64 = (fileLoadedEvent.target.result).replace('data:application/pdf;base64,', '');
            //console.log(base64);
            insertDocument({ document: base64, description: 'descrizione', userId: Id }).then(result => {
                console.log(result), this.insertResult = result, this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Documento inserito',
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

        if (this.showPDF === false)
            this.showPDF = true;
        else
            this.showPDF = false;
    }

    closeModal() {
        this.showPDF = false;
    }


    @wire(getDocumentsByDate, { agreementId: 1, dataFiltro: '$dateToSearch' })
    documentsList({ error, data }) {
        if (error != null) {
            console.log(error);
        } else {
            this.documentsRepo = data;
            //console.log('dati:' + data);
        }
    };

    @wire(getRecord, { recordId: '$recordId', fields: 'Contact.Id' })
    wiredRecord({ error, data }) {
        if (error != null) {
            console.log(error);
        } else if (data) {
            this.agreementId = data.fields.Id.value;
        }
    }
}
