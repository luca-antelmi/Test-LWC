/**
 * Created by remos on 27/09/21.
 */
/**
 * Created by remos on 21/09/21.
 */
public with sharing class TelepassProxyController{
	private static final String OPERATION_CODE = '0';
	private static final String OPERATION_SUBCODE = '0';
	private static final String CONTENT_TYPE = 'Content-Type';
	private static final String CONTENT_TYPE_VALUE = 'application/json';
	private static final String AUTHORIZATION = 'Authorization';
	private static final String AUTHORIZATION_PREFIX = 'Bearer ';
	public virtual class DocumentRepoResponse{
		@AuraEnabled
		public Integer agreementId{ get; set; }

		@AuraEnabled
		public Datetime insertionDate{ get; set; }

		@AuraEnabled
		public List<SingleDocumentRepo> documents{ get; set; }

		@AuraEnabled
		public List<ErrorRepoResponse> errors{ get; set; }

		public DocumentRepoResponse(){
			this.documents = new List<SingleDocumentRepo>();
			this.errors = new List<ErrorRepoResponse>();
		}

		public DocumentRepoResponse(Integer agreementId, DateTime insertionDate){
			this.agreementId = agreementId;
			this.insertionDate = insertionDate;
			this.documents = new List<SingleDocumentRepo>();
			this.errors = new List<ErrorRepoResponse>();
		}
	}

	public virtual class SingleDocumentRepo{
		@AuraEnabled
		public Integer agreementId{ get; set; }

		@AuraEnabled
		public Datetime insertionDate{ get; set; }

		@AuraEnabled
		public String document{ get; set; }

		@AuraEnabled
		public String description{ get; set; }

		@AuraEnabled
		public String userId{ get; set; }

		public SingleDocumentRepo(Integer agreementId, DateTime insertionDate, String document, String description, String userId){
			this.agreementId = agreementId;
			this.insertionDate = insertionDate;
			this.document = document;
			this.description = description;
			this.userId = userId;
		}
	}

	public virtual class InsertDocumentResponse{
		@AuraEnabled
		public Integer agreementId{ get; set; }

		@AuraEnabled
		public Datetime insertionDate{ get; set; }

		@AuraEnabled
		public List<ErrorRepoResponse> errors{ get; set; }

		public InsertDocumentResponse(){
		}

		public InsertDocumentResponse(Integer agreementId, DateTime insertionDate){
			this.agreementId = agreementId;
			this.insertionDate = insertionDate;
			this.errors = new List<ErrorRepoResponse>();
		}
	}

	public virtual class WrapperErrorRepoResponse{
		@AuraEnabled
		public List<ErrorRepoResponse> errors{ get; set; }

		public WrapperErrorRepoResponse(List<ErrorRepoResponse> errors){
			if (errors == null)
				this.errors = new List<ErrorRepoResponse>();
			this.errors = errors;
		}
	}

	public virtual class ErrorRepoResponse{
		@AuraEnabled
		public String code{ get; set; }

		@AuraEnabled
		public String message{ get; set; }

		@AuraEnabled
		public String field{ get; set; }

		public ErrorRepoResponse(String code, String message, String field){
			this.code = code;
			this.message = message;
			this.field = field;
		}
	}

	public virtual class InvalidPayloadException extends Exception{
	}

	public virtual class KcdErrorsResponseException extends Exception{
	}

	/**
	 * Ritorna al frontend un elenco di documenti filtrati per data e convenzione
	 * Delelga al metodo kcdCalloutRetrieveDocumentsAction l'esecuzione della chiamata REST API GET
	 * @param agreementId
	 * @param dataFiltro
	 *
	 * @return DocumentRepoResponse
	 */
	@AuraEnabled(cacheable = true)
	public static DocumentRepoResponse getDocumentsByDate(Integer agreementId, Date dataFiltro){
		if (dataFiltro == null)
			dataFiltro = Date.today();
		DocumentRepoResponse drr = kcdCalloutRetrieveDocumentsAction(agreementId, (DateTime) dataFiltro);
		return drr;
	}

	/**
	 * Ritorna al frontend il feedback relativo al caricamento di un nuovo documento nel repository.
	 * Delega il metodo kcdCalloutInsertDocumentAction per l'esecuzione della relativa REST POST.
	 *
	 * @param agreementId
	 * @param document
	 * @param description
	 * @param userId
	 *
	 * @return InsertDocumentResponse
	 */
	@AuraEnabled(cacheable = true)
	public static InsertDocumentResponse insertDocument(Integer agreementId, String document, String description, String userId){
		Map<String, String> requestPayload = new Map<String, String>();
		requestPayload.put('document', document);
		requestPayload.put('description', description);
		requestPayload.put('userId', userId);
		InsertDocumentResponse response = kcdCalloutInsertDocumentAction(agreementId, requestPayload);
		return response;
	}

	/**
	 * Intercetta la richiesta del frontend per la rimozione di un documento dal repository
	 * Delega il metodo kcdCalloutDismissionDocumentAction per l'esecuzione della azione di PUT
	 *
	 * @param agreementId
	 * @param userId
	 *
	 * @return List<ErrorRepoResponse>
	 */
	@AuraEnabled(cacheable = true)
	public static List<ErrorRepoResponse> dismissionDocument(Integer agreementId, DateTime insertionDate, String userId){
		Map<String, String> requestPayload = new Map<String, String>();
		String dateTimeString = String.valueOfGmt(insertionDate);
		requestPayload.put('userId', userId);
		requestPayload.put('insertionDate', dateTimeString.replace(' ', 'T'));
		return kcdCalloutDismissionDocumentAction(agreementId, requestPayload);
	}

	/**
	 * Chiama l'API REST:
	 * POST  - Inserimento Documento Contrattuale(MERCHANTOP-637)
	 *
	 * @param agreementId
	 * @param requestPayload
	 *
	 * @return InsertDocumentResponse
	 */
	private static InsertDocumentResponse kcdCalloutInsertDocumentAction(Integer agreementId, Map<String, String> requestPayload){
		InsertDocumentResponse result = new InsertDocumentResponse();
		Map<String, Object> responseMap = new Map<String, Object>();
		String endpoint = '/api-merchants/v1/agreements/' + agreementId + '/documents';
		String method = 'POST';
		String requestPayloadJson;
		try{
			requestPayloadJson = JSON.serialize(requestPayload);
			Http http = new Http();
			HttpRequest req = new HttpRequest();
			//String accessToken = JwtKCD.requestAccessToken();
			/* mocked call (start)*/
			JwtKCD auth = new JwtKCD();
			String accessToken = auth.requestAccessToken();
			/* mocked call (end)*/
			req.setMethod(method);
			req.setEndpoint(endpoint);
			req.setHeader(CONTENT_TYPE, CONTENT_TYPE_VALUE);
			req.setHeader(AUTHORIZATION, AUTHORIZATION_PREFIX + accessToken);
			if (requestPayloadJson == null || requestPayloadJson == '')
				throw new InvalidPayloadException('request payload non valido');
			req.setBody(requestPayloadJson);
			/* real Call & Response */
			//HttpResponse response = http.send(request);

			/* !!Mocked call & Response!! (start) */
			HttpResponse response = new HttpResponse();
			String dateTimeString = String.valueOfGmt(DateTime.now());
			system.debug('dateTimeString = ' + dateTimeString);
			Map<String, Object> serializedElements = new Map<String, Object>();
			serializedElements.put('agreementId', agreementId);
			serializedElements.put('insertionDate', dateTimeString.replace(' ', 'T'));
			response.setBody(System.JSON.serialize(serializedElements));
			system.debug('responseBody = ' + response.getBody());
			response.setStatusCode(200);
			/* !!Mocked call & Response!! (end) */

			if (response.getStatusCode() == 200){
				result = (InsertDocumentResponse)System.JSON.deserialize(response.getBody(), InsertDocumentResponse.class);
				if (result.errors != null && !result.errors.isEmpty())
					throw new KcdErrorsResponseException('errori kcd response');
			} else{
				// FIXME-RM popolare l'oggetto errors qui
				throw new KcdErrorsResponseException('errori kcd response: ' + response.getStatusCode());
			}
			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//     requestPayloadJson, response.getStatus(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);

		} catch (Exception e){

			responseMap.put('esito = ', 901);
			responseMap.put('errorMsg = ', e.getMessage());

			// FIXME-RM bisogna scrivere sul file di log, ma come valorizziamo questi parametri?
			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//        requestPayloadJson, e.getMessage(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);
		}

		return result;
	}

	/**
	 * Chiama l'API REST:
	 * PUT - Dismissione Documento Contrattuale(MERCHANTOP-639)
	 *
	 * @param agreementId
	 * @param requestPayload
	 *
	 * @return List<ErrorRepoResponse>
	 */
	private static List<ErrorRepoResponse> kcdCalloutDismissionDocumentAction(Integer agreementId, Map<String, String> requestPayload){
		HttpResponse response;
		List<ErrorRepoResponse> result = new List<ErrorRepoResponse>();
		Map<String, Object> responseMap = new Map<String, Object>();
		String endpoint = '/api-merchants/v1/agreements/' + agreementId + '/documents/lock';
		String method = 'PUT';
		String requestPayloadJson;
		try{
			requestPayloadJson = JSON.serialize(requestPayload);
			Http http = new Http();
			HttpRequest req = new HttpRequest();

			//String accessToken = JwtKCD.requestAccessToken();
			/* mocked call (start)*/
			JwtKCD auth = new JwtKCD();
			String accessToken = auth.requestAccessToken();
			/* mocked call (end)*/

			req.setMethod(method);
			req.setEndpoint(endpoint);
			req.setHeader(CONTENT_TYPE, CONTENT_TYPE_VALUE);
			req.setHeader(AUTHORIZATION, AUTHORIZATION_PREFIX + accessToken);
			if (requestPayloadJson == null || requestPayloadJson == '')
				throw new InvalidPayloadException('request payload non valido');
			req.setBody(requestPayloadJson);
			/* real Call & Response */
			//HttpResponse response = http.send(request);

			/* !!Mocked call & Response!! (start) */
			response = new HttpResponse();
			List<ErrorRepoResponse> errorsList = new List<ErrorRepoResponse>();
			if (agreementId == 100){
				errorsList.add(new ErrorRepoResponse('E100', 'descrizione Errore', 'field in errore'));
			}
			Map<String, Object> serializedElements = new Map<String, Object>();
			serializedElements.put('errors', errorsList);
			response.setBody(System.JSON.serialize(serializedElements));
			system.debug('responseBody = ' + response.getBody());
			response.setStatusCode(200);
			/* !!Mocked call & Response!! (end) */

			if (response.getStatusCode() == 200){
				WrapperErrorRepoResponse mapResult = (WrapperErrorRepoResponse)system.JSON.deserialize(response.getBody(), WrapperErrorRepoResponse.class);
				system.debug('mapResult = ' + mapResult.errors);
				if (mapResult != null && !mapResult.errors.isEmpty()){
					throw new KcdErrorsResponseException('errori kcd response');
				}
			} else{
				throw new KcdErrorsResponseException('errori kcd response: ' + response.getStatusCode());
			}
			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//requestPayloadJson, response.getStatus(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);

		} catch (Exception e){

			responseMap.put('esito = ', 901);
			responseMap.put('errorMsg = ', e.getMessage());
			result.add(new ErrorRepoResponse('' + response.getStatusCode(), e.getMessage(), ''));

			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//        requestPayloadJson, e.getMessage(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);
		}
		return result;
	}

	/**
	 * Chiama l'API REST:
	 * GET  - Recupero Documento Contrattuale(MERCHANTOP-640)
	 *
	 * @param agreementId
	 * @param requestPayload
	 *
	 * @return DocumentRepoResponse
	 */
	private static DocumentRepoResponse kcdCalloutRetrieveDocumentsAction(Integer agreementId, DateTime dataFiltro){
		HttpResponse response;
		Map<String, Object> responseMap = new Map<String, Object>();
		DocumentRepoResponse result = new DocumentRepoResponse();
		String insertionDate = String.valueOf(dataFiltro).replace(' ', 'T');
		String endpoint = '/api-merchants/v1/agreements/' + agreementId + '/documents?insertionDate=' + insertionDate;
		system.debug('endpoint = ' + endpoint);
		String method = 'GET';
		String requestPayloadJson;
		try{
			Http http = new Http();
			HttpRequest req = new HttpRequest();
			//String accessToken = JwtKCD.requestAccessToken();
			/* mocked call (start)*/
			JwtKCD auth = new JwtKCD();
			String accessToken = auth.requestAccessToken();
			/* mocked call (end)*/
			req.setMethod(method);
			req.setEndpoint(endpoint);
			req.setHeader(CONTENT_TYPE, CONTENT_TYPE_VALUE);
			req.setHeader(AUTHORIZATION, AUTHORIZATION_PREFIX + accessToken);
			/* real Call & Response */
			//HttpResponse response = http.send(request);

			/* !!Mocked call & Response!! (start) */
			response = new HttpResponse();
			DocumentRepoResponse docResponse = new DocumentRepoResponse(agreementId, dataFiltro);
			docResponse.documents.add(new SingleDocumentRepo(agreementId, dataFiltro, doc1, 'desc 1', '1'));
			docResponse.documents.add(new SingleDocumentRepo(agreementId, dataFiltro, doc2, 'desc 2', '1'));
            if (dataFiltro.date()<Date.today())
				docResponse.documents.add(new SingleDocumentRepo(agreementId, dataFiltro, doc3, 'desc 3', '1'));
			response.setBody(System.JSON.serialize(docResponse));
			system.debug('responseBody = ' + response.getBody());
			response.setStatusCode(200);
			/* !!Mocked call & Response!! (end) */

			if (response.getStatusCode() == 200){
				DocumentRepoResponse mapResult = (DocumentRepoResponse)system.JSON.deserialize(response.getBody(), DocumentRepoResponse.class);
				system.debug('mapResult.documents.size() = ' + mapResult.documents.size());
				if (mapResult != null && !mapResult.errors.isEmpty()){
					throw new KcdErrorsResponseException('errori kcd response');
				}
				result = mapResult;
			} else{
				throw new KcdErrorsResponseException('errori kcd response: ' + response.getStatusCode());
			}
			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//      requestPayloadJson, response.getStatus(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);

		} catch (Exception e){

			responseMap.put('esito = ', 901);
			responseMap.put('errorMsg = ', e.getMessage());
			result.errors.add(new ErrorRepoResponse('' + response.getStatusCode(), e.getMessage(), ''));

			//WriteLogCallout.createLog('ERROR', '', 'KCD_RestOutbound', OPERATION_CODE , OPERATION_SUBCODE,
			//        requestPayloadJson, e.getMessage(), 'KCD', OPERATION_CODE, OPERATION_SUBCODE, endpoint, method);
		}
		return result;
	}

	public class JwtKCD{
		public String requestAccessToken(){
			return 'token JWT';
		}
	}

	public static final String doc1 = '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Q29udGVudHMgMiAwIFI+PgplbmRvYmoKCjQgMCBvYmoKPDwvVHlwZS9QYWdlcwovUmVzb3VyY2VzIDExIDAgUgovTWVkaWFCb3hbIDAgMCA1OTUgODQxIF0KL0tpZHNbIDEgMCBSIF0KL0NvdW50IDE+PgplbmRvYmoKCjEyIDAgb2JqCjw8L1R5cGUvQ2F0YWxvZy9QYWdlcyA0IDAgUgovT3BlbkFjdGlvblsxIDAgUiAvWFlaIG51bGwgbnVsbCAwXQovTGFuZyhlbi1VUykKPj4KZW5kb2JqCgoxMyAwIG9iago8PC9DcmVhdG9yPEZFRkYwMDU3MDA3MjAwNjkwMDc0MDA2NTAwNzI+Ci9Qcm9kdWNlcjxGRUZGMDA0QzAwNjkwMDYyMDA3MjAwNjUwMDRGMDA2NjAwNjYwMDY5MDA2MzAwNjUwMDIwMDAzNzAwMkUwMDMxPgovQ3JlYXRpb25EYXRlKEQ6MjAyMTA5MjExMTU1MDArMDInMDAnKT4+CmVuZG9iagoKeHJlZgowIDE0CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwNzk1NiAwMDAwMCBuIAowMDAwMDAwMDE5IDAwMDAwIG4gCjAwMDAwMDAyNDUgMDAwMDAgbiAKMDAwMDAwODEyNSAwMDAwMCBuIAowMDAwMDAwMjY1IDAwMDAwIG4gCjAwMDAwMDcwMzQgMDAwMDAgbiAKMDAwMDAwNzA1NSAwMDAwMCBuIAowMDAwMDA3MjU3IDAwMDAwIG4gCjAwMDAwMDc2MzIgMDAwMDAgbiAKMDAwMDAwNzg2OSAwMDAwMCBuIAowMDAwMDA3OTAxIDAwMDAwIG4gCjAwMDAwMDgyMjQgMDAwMDAgbiAKMDAwMDAwODMyMSAwMDAwMCBuIAp0cmFpbGVyCjw8L1NpemUgMTQvUm9vdCAxMiAwIFIKL0luZm8gMTMgMCBSCi9JRCBbIDxENkUyMDA0QTQzODRFNzNCOUI3MjRFMzg5NEQ3M0M2NT4KPEQ2RTIwMDRBNDM4NEU3M0I5QjcyNEUzODk0RDczQzY1PiBdCi9Eb2NDaGVja3N1bSAvN0Y4Q0NBNjk4RTkzNDA4QUFEMDdFNzYwMTU2MDhFRjUKPj4Kc3RhcnR4cmVmCjg0OTYKJSVFT0YK';
	public static final String doc2 = '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MS44ODk3NjM3Nzk1MjhdL0dyb3VwPDwvUy9UcmFuc3BhcmVuY3kvQ1MvRGV2aWNlUkdCL0kgdHJ1ZT4+L0NvbnRlbnRzIDIgMCBSPj4KZW5kb2JqCgo0IDAgb2JqCjw8L1R5cGUvUGFnZXMKL1Jlc291cmNlcyAxMSAwIFIKL01lZGlhQm94WyAwIDAgNTk1IDg0MSBdCi9LaWRzWyAxIDAgUiBdCi9Db3VudCAxPj4KZW5kb2JqCgoxMiAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgNCAwIFIKL09wZW5BY3Rpb25bMSAwIFIgL1hZWiBudWxsIG51bGwgMF0KL0xhbmcoZW4tVVMpCj4+CmVuZG9iagoKMTMgMCBvYmoKPDwvQ3JlYXRvcjxGRUZGMDA1NzAwNzIwMDY5MDA3NDAwNjUwMDcyPgovUHJvZHVjZXI8RkVGRjAwNEMwMDY5MDA2MjAwNzIwMDY1MDA0RjAwNjYwMDY2MDA2OTAwNjMwMDY1MDAyMDAwMzcwMDJFMDAzMT4KL0NyZWF0aW9uRGF0ZShEOjIwMjEwOTIxMTE1NTExKzAyJzAwJyk+PgplbmRvYmoKCnhyZWYKMCAxNAowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDgwMTcgMDAwMDAgbiAKMDAwMDAwMDAxOSAwMDAwMCBuIAowMDAwMDAwMjQ1IDAwMDAwIG4gCjAwMDAwMDgxODYgMDAwMDAgbiAKMDAwMDAwMDI2NSAwMDAwMCBuIAowMDAwMDA3MDk1IDAwMDAwIG4gCjAwMDAwMDcxMTYgMDAwMDAgbiAKMDAwMDAwNzMxOCAwMDAwMCBuIAowMDAwMDA3NjkzIDAwMDAwIG4gCjAwMDAwMDc5MzAgMDAwMDAgbiAKMDAwMDAwNzk2MiAwMDAwMCBuIAowMDAwMDA4Mjg1IDAwMDAwIG4gCjAwMDAwMDgzODIgMDAwMDAgbiAKdHJhaWxlcgo8PC9TaXplIDE0L1Jvb3QgMTIgMCBSCi9JbmZvIDEzIDAgUgovSUQgWyA8RjQ4RURCOEZCMEU1Q0UzNzQzOTU4MUM4MzZBNEJCRkI+CjxGNDhFREI4RkIwRTVDRTM3NDM5NTgxQzgzNkE0QkJGQj4gXQovRG9jQ2hlY2tzdW0gL0NDMUQ0MzIwQUZEODNDQjI4MTE0MEYyMUE4REY1RjZCCj4+CnN0YXJ0eHJlZgo4NTU3CiUlRU9GCg==';
	public static final String doc3 = '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b3VyY2VzIDExIDAgUi9NZWRpYUJveFswIDAgNTk1LjMwMzkzNzAwNzg3NCA4NDEuODg5NzYzNzc5NTI4XS9Hcm91cDw8L1MvVHJhbnNwYXJlbmN5L0NTL0RldmljZVJHQi9JIHRydWU+Pi9Db250ZW50cyAyIDAgUj4+CmVuZG9iagoKNCAwIG9iago8PC9UeXBlL1BhZ2VzCi9SZXNvdXJjZXMgMTEgMCBSCi9NZWRpYUJveFsgMCAwIDU5NSA4NDEgXQovS2lkc1sgMSAwIFIgXQovQ291bnQgMT4+CmVuZG9iagoKMTIgMCBvYmoKPDwvVHlwZS9DYXRhbG9nL1BhZ2VzIDQgMCBSCi9PcGVuQWN0aW9uWzEgMCBSIC9YWVogbnVsbCBudWxsIDBdCi9MYW5nKGVuLVVTKQo+PgplbmRvYmoKCjEzIDAgb2JqCjw8L0NyZWF0b3I8RkVGRjAwNTcwMDcyMDA2OTAwNzQwMDY1MDA3Mj4KL1Byb2R1Y2VyPEZFRkYwMDRDMDA2OTAwNjIwMDcyMDA2NTAwNEYwMDY2MDA2NjAwNjkwMDYzMDA2NTAwMjAwMDM3MDAyRTAwMzE+Ci9DcmVhdGlvbkRhdGUoRDoyMDIxMDkyMTExNTUyNSswMicwMCcpPj4KZW5kb2JqCgp4cmVmCjAgMTQKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDA4MDYzIDAwMDAwIG4gCjAwMDAwMDAwMTkgMDAwMDAgbiAKMDAwMDAwMDI0NSAwMDAwMCBuIAowMDAwMDA4MjMyIDAwMDAwIG4gCjAwMDAwMDAyNjUgMDAwMDAgbiAKMDAwMDAwNzE0MSAwMDAwMCBuIAowMDAwMDA3MTYyIDAwMDAwIG4gCjAwMDAwMDczNjQgMDAwMDAgbiAKMDAwMDAwNzczOSAwMDAwMCBuIAowMDAwMDA3OTc2IDAwMDAwIG4gCjAwMDAwMDgwMDggMDAwMDAgbiAKMDAwMDAwODMzMSAwMDAwMCBuIAowMDAwMDA4NDI4IDAwMDAwIG4gCnRyYWlsZXIKPDwvU2l6ZSAxNC9Sb290IDEyIDAgUgovSW5mbyAxMyAwIFIKL0lEIFsgPDNGNjU1QjNDNjAwMTM5RTFEQTA1OTRERTU5MDhBMzQ1Pgo8M0Y2NTVCM0M2MDAxMzlFMURBMDU5NERFNTkwOEEzNDU+IF0KL0RvY0NoZWNrc3VtIC9BRTNBNUJDNkY1NDcyQkNBMTg3RDMxRTdENTg5MDJCQwo+PgpzdGFydHhyZWYKODYwMwolJUVPRgo=';
}