import ballerina/time;

// Conflict Resolution Strategy
public enum ConflictResolution {
    SOURCE_WINS,
    DESTINATION_WINS,
    MOST_RECENT
}

// Duplicate Match Strategy
public enum DuplicateMatchStrategy {
    MATCH_BY_NAME,
    MATCH_BY_EMAIL,
    MATCH_BY_EXTERNAL_ID
}

// QuickBooks Customer Webhook Event
public type QuickBooksWebhookEvent record {
    string eventNotifications;
};

public type EventNotification record {
    string realmId;
    DataChangeEvent[] dataChangeEvent;
};

public type DataChangeEvent record {
    string[] entities;
};

public type Entity record {
    string name;
    string id;
    string operation;
    string lastUpdated;
};

// QuickBooks Customer Record
public type QuickBooksCustomer record {
    string Id;
    string DisplayName;
    string? CompanyName?;
    string? GivenName?;
    string? FamilyName?;
    string? PrimaryEmailAddr?;
    PrimaryPhone? PrimaryPhone?;
    BillAddr? BillAddr?;
    string? WebAddr?;
    boolean? Active?;
    string? CustomerType?;
    time:Civil? MetaData?;
};

public type PrimaryPhone record {
    string? FreeFormNumber?;
};

public type EmailAddress record {
    string? Address?;
};

public type BillAddr record {
    string? Line1?;
    string? City?;
    string? CountrySubDivisionCode?;
    string? PostalCode?;
    string? Country?;
};

// Salesforce Account Record
public type SalesforceAccount record {
    string? Id?;
    string Name;
    string? Phone?;
    string? Website?;
    string? BillingStreet?;
    string? BillingCity?;
    string? BillingState?;
    string? BillingPostalCode?;
    string? BillingCountry?;
    string? Type?;
    string? QuickBooks_Customer_Id__c?;
    string? LastModifiedDate?;
};

// Salesforce Contact Record
public type SalesforceContact record {
    string? Id?;
    string LastName;
    string? FirstName?;
    string? Email?;
    string? Phone?;
    string? AccountId?;
};

// Sync Result
public type SyncResult record {
    boolean success;
    string? accountId?;
    string? contactId?;
    string? message?;
    string? errorDetails?;
};
