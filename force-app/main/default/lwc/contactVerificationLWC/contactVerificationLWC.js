import { LightningElement, track, wire } from "lwc";
import displayAddress from "./displayAddress";
import getContactsAndAccount from "@salesforce/apex/SecureContactAndAccountRetrieval.getContactsAndAccount";

export default class ContactVerificationLWC extends LightningElement {
    columns = [
        { label: "FName", fieldName: "firstname" },
        { label: "LName", fieldName: "lastname" },
        { label: "Email Address", fieldName: "email", type: "email" },
        { label: "Address", fieldName: "address" },
        { label: "Verification Status", fieldName: "verificationStatus" }
    ];

    searchKeyword = "";
    @track loading = false;
    @track searchInput = "";
    @track contactsAndAccounts = [];
    @track error;
    @wire(getContactsAndAccount, { searchKeyword: "$searchInput" })
    wiredContactsAndAccounts({ data, error }) {
        console.log(data)
        if (data) {
            let cleanData = [];

            data.forEach((c) => {
                let accountAddress = "";
                if (c.address) {
                    // external system returns an array by default (supabase thing...)
                    // even though its always going to be one account
                    if (JSON.parse(c.address) && JSON.parse(c.address).length > 0)
                        accountAddress = displayAddress(JSON.parse(c.address)[0]);
                } else accountAddress = c.addressError;

                cleanData.push({
                    firstname: c.firstname,
                    lastname: c.lastname,
                    email: c.email,
                    address: accountAddress,
                    verificationStatus: c.verificationStatus
                });
            });

            if (cleanData.length > 0) this.contactsAndAccounts = cleanData;
            else this.contactsAndAccounts = [];

            this.error = undefined;
        } else {
            this.contactsAndAccounts = undefined;
            this.error = error;
        }

        this.loading = false;
    }

    handleSearchKeywordChange(e) {
        this.searchKeyword = e.target.value;
    }

    handleSearchClick() {
        if (
            this.searchInput.toLocaleLowerCase() !==
            this.searchKeyword.toLocaleLowerCase()
        ) {
            this.loading = true;
            this.searchInput = this.searchKeyword;
        }
    }
}