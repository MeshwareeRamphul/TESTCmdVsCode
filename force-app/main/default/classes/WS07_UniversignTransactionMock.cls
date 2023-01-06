@isTest
global class WS07_UniversignTransactionMock implements HttpCalloutMock {

	global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        System.debug('******** respond '+req.getEndpoint());
        if(req.getEndpoint() == System.Label.Universign_EndPoint_Transaction+'/full'){
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"object":"transaction","id":"tx_aveG7QvK72qo","folder_id":"fol_DJEwkmwZDBK3","created_at":"2022-11-15T14:21:48Z","started_at":"2022-11-15T14:21:48Z","expires_at":"2022-11-29T14:21:48Z","name":"NEWCONTRACT","folder_name":"uat_transaction","stalled":false,"language":"en","creator":{"workspace_name":"AXA Procurement recette","api_key_name":"UniversignDevKey"},"state":"started","participants":[{"email":"test1@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test3@email.com","name_constraint":"Jim Brown","fullname_prerequisite":"Jim Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"},{"email":"test2@email.com","name_constraint":"Jane Brown","fullname_prerequisite":"Jane Brown","min_signature_level":"level1","schedule":[],"ongoing_conversation":false,"has_unread_message":false,"state":"open"}],"watchers":[],"sealers":[],"documents":[{"id":"doc_Bwnl","name":"NEWCONTRACT_20221115_12-07_SOW.pdf","updatable":true,"deletable":false,"fields":[{"id":"fld_6Ane","name":"field0","position":{"page":1,"x":100,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false},{"id":"fld_Q46","name":"field1","position":{"page":1,"x":390,"y":55,"width":200,"height":50},"type":"signature","built_in":false,"consents":[],"updatable":true,"deletable":false}]}],"instructions":{"signatures":[{"signer":"test2@email.com","field":"fld_6Ane"},{"signer":"test3@email.com","field":"fld_Q46"}],"reviews":[{"reviewer":"test1@email.com","recipient":"test2@email.com"}],"captures":[],"sequencing":[{"before":"test2@email.com","after":"test3@email.com"}],"editions":[]},"actions":[{"id":"act_K6MBX92qzlew1","actor":"test1@email.com","state":"open","url":"https://apps.universign.com/npds/act_K6MBX92qzlew1","tasks":[{"type":"review","state":"todo","recipient":"test2@email.com","document":"doc_Bwnl"}],"stalled":false},{"id":"act_6JwBA1r9wBXn4","actor":"test2@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_6JwBA1r9wBXn4","tasks":[{"type":"signature","state":"todo","field":"fld_6Ane"}],"stalled":false},{"id":"act_JzZJe5X3dBOPW","actor":"test3@email.com","state":"waiting","url":"https://apps.universign.com/npds/act_JzZJe5X3dBOPW","tasks":[{"type":"signature","state":"todo","field":"fld_Q46"}],"stalled":false}],"metadata":{},"progress_value":0,"ongoing_conversation":false,"has_unread_message":false,"origin":"API","carbon_copies":[],"uploads":[],"private":false}');
            response.setStatus('OK');
            response.setStatusCode(200);
        }else if(req.getEndpoint() == System.Label.Universign_EndPoint_Files){
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"object" : "file-id", "id" : "file_MZPQJaaQ5kJwQUD15WkerJ8bA2"}');
            response.setStatus('OK');
            response.setStatusCode(200);
        }else if(req.getMethod() == 'GET' && req.getEndpoint().contains('dist/version/download')){
            response.setHeader('Content-Type', 'application/pdf;charset=UTF-8');
            response.setBody('test');
            response.setBodyAsBlob(Blob.toPDF('test'));
            response.setStatus('OK');
            response.setStatusCode(200);
        }
        return response;
    }
}