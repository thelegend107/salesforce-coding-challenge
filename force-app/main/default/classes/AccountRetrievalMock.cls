public with sharing class AccountRetrievalMock implements HttpCalloutMock {
    private HttpResponse response = new HttpResponse();

    public AccountRetrievalMock() {
        response.setStatusCode(200);
    }

    public AccountRetrievalMock(Integer statusCode) {
        response.setStatusCode(statusCode);
    }

    public HttpResponse respond(HttpRequest request) {
        if (!isAuthorized()) {
            throw new CalloutException(
                'User does not have the required permission set to make the following callout: ' +
                request.getEndpoint()
            );
        }

        response.setHeader('Content-Type', 'application/json; charset=utf-8');
        if (response.getStatusCode() == 401) {
            response.setBody(
                '{"message":"No API key found in request","hint":"No `apikey` request header or url param was found."}'
            );
        } else if (response.getStatusCode() == 404) {
            response.setBody(
                '{"code":"42P01","details":null,"hint":null,"message":"relation \"public.zeal-a\" does not exist"}'
            );
        } else {
            response.setBody(
                '{"id":1,"sf_id":"001ak00000CFPdYAAX","created_at":"2024-04-09T01:01:24.559249+00:00","address1":"9376 E. Helen Ave.","address2":null,"city":"East Haven","state":"CT","country":"USA","postalCode":"06512"}'
            );
        }
        return response;
    }

    private Boolean isAuthorized() {
        string userId = UserInfo.getUserId();
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        List<PermissionSet> ps = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'Supabase_Named_Credential'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (!ps.isEmpty()) {
            psa = [
                SELECT ID
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSet.Id = :ps[0].Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        }

        if (!psa.isEmpty()) {
            return true;
        } else {
            return false;
        }
    }
}
