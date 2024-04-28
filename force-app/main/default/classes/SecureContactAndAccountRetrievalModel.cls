public with sharing class SecureContactAndAccountRetrievalModel {
    @AuraEnabled
    public String firstname { get; set; }
    @AuraEnabled
    public String lastname { get; set; }
    @AuraEnabled
    public String email { get; set; }
    @AuraEnabled
    public String address { get; set; }
    @AuraEnabled
    public String addressError { get; set; }
    @AuraEnabled
    public String verificationStatus { get; set; }
}
