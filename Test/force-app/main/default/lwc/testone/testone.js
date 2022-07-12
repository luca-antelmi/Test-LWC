import { api, LightningElement, track, wire } from 'lwc';
import getDocumentsByDate from '@salesforce/apex/TelepassProxyController.getDocumentsByDate';

export default class Test_Telepass extends LightningElement {

    @track dateToSearch = null;
    @track documentsRepo = { documents: [] };
    @track showPDF = false;
    @track blobURL;
    @api myRecordId;


    closeModalPDF(event){

        this.showPDF = false;
    }



    get acceptedFormats() {
        return ['.pdf'];
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert("Numero di file caricati : " + uploadedFiles.length);
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
        console.log(' this.blobURL:'+  this.blobURL);

        if (this.showPDF === false)
            this.showPDF = true;
        else
            this.showPDF = false;
    }


    @wire(getDocumentsByDate, { agreementId: 1, dataFiltro: '$dateToSearch' })
    documentsList({ error, data }) {
        if (error != null) {
            console.log(error);
        } else {
            this.documentsRepo = data;
            console.log(data);
        }
    };






}