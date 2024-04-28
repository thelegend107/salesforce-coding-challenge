public with sharing class SecureContactAndAccountRetrieval {
    public static List<Contact> retrieveContactsAndAccounts(
        String searchKeyword
    ) {
        if (String.isBlank(searchKeyword) || String.isEmpty(searchKeyword)) {
            return new List<Contact>();
        }

        searchKeyword = '%' + searchKeyword + '%';

        SObjectAccessDecision secureContacts = Security.stripInaccessible(
            AccessType.READABLE,
            [
                SELECT
                    Id,
                    FirstName,
                    LastName,
                    Email,
                    Account.Id,
                    Account.Name,
                    Account.Verification_Status__c
                FROM Contact
                WHERE LastName LIKE :searchKeyword OR Email LIKE :searchKeyword
            ]
        );

        return secureContacts.getRecords();
    }

    public static AccountAddressModel retrieveAccountAddress(string accountId) {
        Http http = new http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(
            'callout:supabase_zeal_ext_system?sf_id=eq.' + accountId
        );
        request.setHeader('Content-Type', 'application/json');

        AccountAddressModel accountAddress = new AccountAddressModel();

        try {
            HttpResponse response = Http.send(request);
            accountAddress.statusCode = response.getStatusCode();
            accountAddress.response = response.getBody();
            return accountAddress;
        } catch (Exception ex) {
            accountAddress.statusCode = 500;
            accountAddress.response = ex.getMessage();
            return accountAddress;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SecureContactAndAccountRetrievalModel> getContactsAndAccount(
        string searchKeyword
    ) {
        List<SecureContactAndAccountRetrievalModel> models = new List<SecureContactAndAccountRetrievalModel>();

        List<Contact> contacts = retrieveContactsAndAccounts(searchKeyword);
        string securityMsg = 'Permissions Required to access field';

        for (Contact c : contacts) {
            SecureContactAndAccountRetrievalModel model = new SecureContactAndAccountRetrievalModel();
            model.firstname = c.isSet('FirstName') ? c.FirstName : securityMsg;
            model.lastname = c.isSet('LastName') ? c.LastName : securityMsg;
            model.email = c.isSet('Email') ? c.Email : securityMsg;
            model.verificationStatus = c.Account.isSet('Verification_Status__c')
                ? c.Account.Verification_Status__c
                : securityMsg;

            if (c.Account.Id != null) {
                AccountAddressModel accountAddress = retrieveAccountAddress(
                    c.AccountId
                );

                if (accountAddress.statusCode == 200) {
                    model.address = accountAddress.response;
                } else {
                    model.addressError =
                        accountAddress.statusCode +
                        ': ' +
                        accountAddress.response;
                }
            }

            models.add(model);
        }

        return models;
    }
}
