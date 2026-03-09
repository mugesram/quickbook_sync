// Map QuickBooks Customer to Salesforce Account
public function mapQuickBooksCustomerToSalesforceAccount(QuickBooksCustomer qbCustomer) returns SalesforceAccount {
    
    // Build billing address
    string? billingStreet = ();
    string? billingCity = ();
    string? billingState = ();
    string? billingPostalCode = ();
    string? billingCountry = ();
    
    BillAddr? billAddr = qbCustomer?.BillAddr;
    if billAddr is BillAddr {
        billingStreet = billAddr?.Line1;
        billingCity = billAddr?.City;
        billingState = billAddr?.CountrySubDivisionCode;
        billingPostalCode = billAddr?.PostalCode;
        billingCountry = billAddr?.Country;
    }
    
    // Extract phone
    string? phone = ();
    PrimaryPhone? primaryPhone = qbCustomer?.PrimaryPhone;
    if primaryPhone is PrimaryPhone {
        phone = primaryPhone?.FreeFormNumber;
    }
    
    // Map to Salesforce Account
    SalesforceAccount sfAccount = {
        Name: qbCustomer.DisplayName,
        Phone: phone,
        Website: qbCustomer?.WebAddr,
        BillingStreet: billingStreet,
        BillingCity: billingCity,
        BillingState: billingState,
        BillingPostalCode: billingPostalCode,
        BillingCountry: billingCountry,
        Type: qbCustomer?.CustomerType,
        QuickBooks_Customer_Id__c: qbCustomer.Id
    };
    
    return sfAccount;
}

// Map QuickBooks Customer to Salesforce Contact
public function mapQuickBooksCustomerToSalesforceContact(QuickBooksCustomer qbCustomer, string accountId) returns SalesforceContact? {
    
    string? givenName = qbCustomer?.GivenName;
    string? familyName = qbCustomer?.FamilyName;
    string? email = qbCustomer?.PrimaryEmailAddr;
    
    // Only create contact if we have at least a last name
    if familyName is () {
        return ();
    }
    
    // Extract phone
    string? phone = ();
    PrimaryPhone? primaryPhone = qbCustomer?.PrimaryPhone;
    if primaryPhone is PrimaryPhone {
        phone = primaryPhone?.FreeFormNumber;
    }
    
    SalesforceContact sfContact = {
        FirstName: givenName,
        LastName: familyName,
        Email: email,
        Phone: phone,
        AccountId: accountId
    };
    
    return sfContact;
}
