/**
 * Created by remos on 27/09/21.
 */

@IsTest
private class TelepassProxyControllerTest {


    @IsTest
    static void uploadDocument_test() {
        TelepassProxyController.InsertDocumentResponse response = TelepassProxyController.insertDocument(100,
                TelepassProxyController.doc1,
                'doc 1',
                '1');
        system.debug('agreementId = ' + response.agreementId);
        system.debug('insertionDate = ' + response.insertionDate);
        system.assertEquals(100, response.agreementId);
    }


    @IsTest
    static void DismissDocumentWithErrorResponse_test() {
        List<TelepassProxyController.ErrorRepoResponse> response = TelepassProxyController.dismissionDocument(100, DateTime.now(), '1');

        if (response != null && !response.isEmpty()) {
            for (TelepassProxyController.ErrorRepoResponse error : response) {
                system.debug('code = ' + error.code);
                system.debug('message = ' + error.message);
            }
        }
        system.assertEquals(true, !response.isEmpty());
        system.assertEquals('200', response.get(0).code);
    }

    @IsTest
    static void DismissDocumentWithoutErrorResponse_test() {
        List<TelepassProxyController.ErrorRepoResponse> response = TelepassProxyController.dismissionDocument(200, DateTime.now(), '1');

        if (response != null && !response.isEmpty()) {
            for (TelepassProxyController.ErrorRepoResponse error : response) {
                system.debug('code = ' + error.code);
                system.debug('message = ' + error.message);
            }
        }
        system.assertEquals(true, response.isEmpty());
    }


    @IsTest
    static void Get2Documents_test() {
        TelepassProxyController.DocumentRepoResponse response = TelepassProxyController.getDocumentsByDate(100, Date.today());

        if (response.errors != null && !response.errors.isEmpty()) {
            for (TelepassProxyController.ErrorRepoResponse error : response.errors) {
                system.debug('code = ' + error.code);
                system.debug('message = ' + error.message);
            }
        }
        system.assertEquals(true, !response.documents.isEmpty());
        system.assertEquals(2, response.documents.size());
    }

    @IsTest
    static void Get3Documents_test() {
        TelepassProxyController.DocumentRepoResponse response = TelepassProxyController.getDocumentsByDate(100, Date.today()-1);

        if (response.errors != null && !response.errors.isEmpty()) {
            for (TelepassProxyController.ErrorRepoResponse error : response.errors) {
                system.debug('code = ' + error.code);
                system.debug('message = ' + error.message);
            }
        }
        system.assertEquals(true, !response.documents.isEmpty());
        system.assertEquals(3, response.documents.size());
    }
}