/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class SecureContactAndAccountRetrievalTest {
    @future
    private static void extSystemApiPermissionSetAssignment(string userId) {
        PermissionSet ps = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = 'Supabase_Named_Credential'
        ];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = ps.Id,
            AssigneeId = userId
        );
        insert psa;
    }

    @testSetup
    static void setup() {
        List<User> testUsers = new List<User>();
        List<Contact> testContacts = new List<Contact>();
        List<Account> testAccounts = new List<Account>();

        Profile standardProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
        ];
        Profile standardTestProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Test User'
        ];

        testUsers.add(
            new User(
                Alias = 'standt',
                Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'standarduser' +
                    DateTime.now().getTime() +
                    '@testorg.com'
            )
        );

        testUsers.add(
            new User(
                Alias = 'standt',
                Email = 'standarduser2@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'standarduser2' +
                    DateTime.now().getTime() +
                    '@testorg.com'
            )
        );

        testUsers.add(
            new User(
                Alias = 'standt',
                Email = 'standarduser3@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardTestProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                UserName = 'standarduser3' +
                    DateTime.now().getTime() +
                    '@testorg.com'
            )
        );

        insert testUsers;

        testAccounts.add(
            new Account(
                Name = 'Account1',
                Verification_Status__c = 'Unverified',
                OwnerId = testUsers[0].Id
            )
        );
        testAccounts.add(
            new Account(
                Name = 'Account2',
                Verification_Status__c = 'Unverified',
                OwnerId = testUsers[1].Id
            )
        );
        testAccounts.add(
            new Account(
                Name = 'Account3',
                Verification_Status__c = 'Unverified',
                OwnerId = testUsers[1].Id
            )
        );
        testAccounts.add(
            new Account(
                Name = 'Account4',
                Verification_Status__c = 'Unverified',
                OwnerId = testUsers[2].Id
            )
        );
        insert testAccounts;

        extSystemApiPermissionSetAssignment(testUsers[1].Id);

        testContacts.add(
            new Contact(
                FirstName = 'No',
                LastName = 'Owner',
                Email = 'No.Owner@email.com',
                OwnerId = testUsers[0].Id,
                AccountId = testAccounts[0].Id
            )
        );
        testContacts.add(
            new Contact(
                FirstName = 'Bob',
                LastName = 'Rogers',
                Email = 'Bob.Rogers@email.com',
                OwnerId = testUsers[1].id,
                AccountId = testAccounts[1].Id
            )
        );
        testContacts.add(
            new Contact(
                FirstName = 'Bob',
                LastName = 'Saint',
                Email = 'Bob.Saint@email.com',
                OwnerId = testUsers[1].id,
                AccountId = testAccounts[2].Id
            )
        );
        testContacts.add(
            new Contact(
                FirstName = 'Bob',
                LastName = 'Visibilty',
                Email = 'Bob.Visibilty@email.com',
                OwnerId = testUsers[2].id,
                AccountId = testAccounts[3].Id
            )
        );

        insert testContacts;
    }

    @isTest
    static void canRetrieveContactsByEmail() {
        List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
            'Bob.Rogers@email.com'
        );
        Assert.isTrue(contacts.size() == 1, 'Contacts found');
    }

    @isTest
    static void canRetrieveContactByLastName() {
        List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
            'ain'
        );
        Assert.isTrue(contacts.size() == 1, 'Contacts found');
    }

    @isTest
    static void emptyInputContacts() {
        List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
            ''
        );
        Assert.isFalse(contacts.size() > 0, 'No contacts found');
    }

    @isTest
    static void cantRetrieveContactsWithoutOwnership() {
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];
        System.runAs(u2) {
            List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
                'no.owner'
            );
            Assert.isTrue(contacts.isEmpty(), 'no contacts found');
        }
    }

    @isTest
    static void canRetrieveContactsWithOwnership() {
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];
        System.runAs(u2) {
            List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
                'email.com'
            );
            Assert.isTrue(
                contacts.size() == 2,
                '2 contacts found with ownership'
            );
        }
    }

    // A test profile was created (cloned from standard user)
    // The Account verification_status__c field is not visible in this profile
    // This test should validate that field visibilty is accounted for when running SOQL queries on Contact Account
    @isTest
    static void getContactsAndAccountFieldVerificationStatusNotVisible() {
        User u3 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser3@testorg.com'
        ];
        System.runAs(u3) {
            List<SecureContactAndAccountRetrievalModel> secureContactAndAccount = SecureContactAndAccountRetrieval.getContactsAndAccount(
                'Bob.Visibilty@email.com'
            );

            Assert.isTrue(!secureContactAndAccount.isEmpty());
            Assert.isTrue(
                secureContactAndAccount[0]
                    .verificationStatus.contains('Permissions')
            );
        }
    }

    @isTest
    static void accountFieldVerificationStatusVisible() {
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];
        System.runAs(u2) {
            List<Contact> contacts = SecureContactAndAccountRetrieval.retrieveContactsAndAccounts(
                'email.com'
            );
            Assert.isTrue(contacts.size() == 2, 'contacts found');
            Assert.isTrue(
                contacts[0].Account.isSet('verification_status__c'),
                'verification_status__c is set/visible'
            );
        }
    }

    @isTest
    static void canRetrieveAccountAddress200() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        System.runAs(u2) {
            Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock());
            Test.startTest();
            AccountAddressModel returnObj = SecureContactAndAccountRetrieval.retrieveAccountAddress(
                acc.Id
            );
            Test.stopTest();
            Assert.areEqual(200, returnObj.statusCode, returnObj.response);
        }
    }

    @isTest
    static void canRetrieveAccountAddress401() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock(401));
        System.runAs(u2) {
            Test.startTest();
            AccountAddressModel returnObj = SecureContactAndAccountRetrieval.retrieveAccountAddress(
                acc.Id
            );
            Test.stopTest();
            Assert.areEqual(401, returnObj.statusCode, returnObj.response);
        }
    }

    @isTest
    static void canRetrieveAccountAddress404() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock(404));
        System.runAs(u2) {
            Test.startTest();
            AccountAddressModel returnObj = SecureContactAndAccountRetrieval.retrieveAccountAddress(
                acc.Id
            );
            Test.stopTest();
            Assert.areEqual(404, returnObj.statusCode, returnObj.response);
        }
    }

    @isTest
    static void canRetrieveAccountAddress500() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock(500));
        System.runAs(u2) {
            Test.startTest();
            AccountAddressModel returnObj = SecureContactAndAccountRetrieval.retrieveAccountAddress(
                acc.Id
            );
            Test.stopTest();
            Assert.areEqual(500, returnObj.statusCode, returnObj.response);
        }
    }

    @isTest
    static void cantRetrieveAccountAddressWithoutPermissions() {
        Account acc = [SELECT ID FROM ACCOUNT LIMIT 1];
        User u = [SELECT ID FROM USER WHERE Email = 'standarduser@testorg.com'];

        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock());
            Test.startTest();
            AccountAddressModel returnObj = SecureContactAndAccountRetrieval.retrieveAccountAddress(
                acc.Id
            );
            Test.stopTest();
            Assert.areEqual(500, returnObj.statusCode, returnObj.response);
        }
    }

    @isTest
    static void canGetContactsAndAccount200() {
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        System.runAs(u2) {
            Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock());
            Test.startTest();
            List<SecureContactAndAccountRetrievalModel> models = SecureContactAndAccountRetrieval.getContactsAndAccount(
                'roger'
            );
            Test.stopTest();

            for (SecureContactAndAccountRetrievalModel m : models) {
                Assert.isNotNull(m.address, 'api was successful');
                Assert.isNull(m.addressError, 'api had no errors');
            }
        }
    }

    @isTest
    static void canGetContactsAndAccount404() {
        User u2 = [
            SELECT ID
            FROM USER
            WHERE Email = 'standarduser2@testorg.com'
        ];

        System.runAs(u2) {
            Test.setMock(HttpCalloutMock.class, new AccountRetrievalMock(404));
            Test.startTest();
            List<SecureContactAndAccountRetrievalModel> models = SecureContactAndAccountRetrieval.getContactsAndAccount(
                'roger'
            );
            Test.stopTest();
            for (SecureContactAndAccountRetrievalModel m : models) {
                Assert.isNull(m.address, 'api call was successful');
                Assert.isNotNull(
                    m.addressError,
                    'but addresses were not found'
                );
            }
        }
    }
}
