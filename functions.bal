import ballerinax/salesforce;
import ballerina/log;
import ballerina/time;

// Check if customer should be synced based on filters
public function shouldSyncCustomer(QuickBooksCustomer qbCustomer) returns boolean {
    
    // Filter by active status if configured
    if filterActiveOnly {
        boolean? active = qbCustomer?.Active;
        if active is boolean && !active {
            return false;
        }
    }
    
    return true;
}

// Find existing Salesforce Account by duplicate detection strategy
public function findExistingAccount(QuickBooksCustomer qbCustomer) returns string?|error {
    
    string soqlQuery = "";
    
    if duplicateMatchStrategy == MATCH_BY_EXTERNAL_ID {
        // Match by QuickBooks Customer ID (External ID)
        soqlQuery = string `SELECT Id FROM Account WHERE QuickBooks_Customer_Id__c = '${qbCustomer.Id}' LIMIT 1`;
    } else if duplicateMatchStrategy == MATCH_BY_EMAIL {
        // Match by email
        string? email = qbCustomer?.PrimaryEmailAddr;
        if email is () {
            return ();
        }
        soqlQuery = string `SELECT Id FROM Account WHERE PersonEmail = '${email}' LIMIT 1`;
    } else if duplicateMatchStrategy == MATCH_BY_NAME {
        // Match by name
        string name = qbCustomer.DisplayName;
        soqlQuery = string `SELECT Id FROM Account WHERE Name = '${name}' LIMIT 1`;
    }
    
    stream<record {}, error?> resultStream = check salesforceClient->query(soqlQuery);
    
    record {|record {} value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|record {} value;|} {
        record {} accountRecord = result.value;
        string? accountId = <string?>accountRecord["Id"];
        return accountId;
    }
    
    return ();
}

// Resolve conflict based on strategy
public function shouldUpdateAccount(SalesforceAccount existingAccount, QuickBooksCustomer qbCustomer) returns boolean|error {
    
    if conflictResolution == SOURCE_WINS {
        return true;
    } else if conflictResolution == DESTINATION_WINS {
        return false;
    } else if conflictResolution == MOST_RECENT {
        // Compare last modified dates
        string? sfLastModified = existingAccount?.LastModifiedDate;
        time:Civil? qbMetadata = qbCustomer?.MetaData;
        
        if sfLastModified is () || qbMetadata is () {
            return true;
        }
        
        // Parse Salesforce date and compare
        time:Utc sfTime = check time:utcFromString(sfLastModified);
        time:Utc qbTime = check time:utcFromCivil(qbMetadata);
        
        return time:utcDiffSeconds(qbTime, sfTime) > 0.0d;
    }
    
    return true;
}

// Sync QuickBooks Customer to Salesforce
public function syncCustomerToSalesforce(QuickBooksCustomer qbCustomer) returns SyncResult {
    
    // Check if customer should be synced
    if !shouldSyncCustomer(qbCustomer) {
        return {
            success: false,
            message: "Customer filtered out based on sync criteria"
        };
    }
    
    // Map QuickBooks customer to Salesforce account
    SalesforceAccount sfAccount = mapQuickBooksCustomerToSalesforceAccount(qbCustomer);
    
    // Check for existing account
    string?|error existingAccountId = findExistingAccount(qbCustomer);
    
    if existingAccountId is error {
        log:printError("Error finding existing account", existingAccountId);
        return {
            success: false,
            message: "Error finding existing account",
            errorDetails: existingAccountId.message()
        };
    }
    
    string? accountId = ();
    
    if existingAccountId is string {
        // Account exists - check conflict resolution
        SalesforceAccount|error existingAccount = salesforceClient->getById("Account", existingAccountId);
        
        if existingAccount is error {
            log:printError("Error retrieving existing account", existingAccount);
            return {
                success: false,
                message: "Error retrieving existing account",
                errorDetails: existingAccount.message()
            };
        }
        
        boolean|error shouldUpdate = shouldUpdateAccount(existingAccount, qbCustomer);
        
        if shouldUpdate is error {
            log:printError("Error in conflict resolution", shouldUpdate);
            return {
                success: false,
                message: "Error in conflict resolution",
                errorDetails: shouldUpdate.message()
            };
        }
        
        if shouldUpdate {
            // Update existing account
            error? updateResult = salesforceClient->update("Account", existingAccountId, sfAccount);
            
            if updateResult is error {
                log:printError("Error updating Salesforce account", updateResult);
                return {
                    success: false,
                    message: "Error updating Salesforce account",
                    errorDetails: updateResult.message()
                };
            }
            
            accountId = existingAccountId;
            log:printInfo(string `Updated Salesforce Account: ${existingAccountId}`);
        } else {
            accountId = existingAccountId;
            log:printInfo(string `Skipped update due to conflict resolution: ${existingAccountId}`);
        }
    } else {
        // Create new account
        salesforce:CreationResponse|error createResult = salesforceClient->create("Account", sfAccount);
        
        if createResult is error {
            log:printError("Error creating Salesforce account", createResult);
            return {
                success: false,
                message: "Error creating Salesforce account",
                errorDetails: createResult.message()
            };
        }
        
        accountId = createResult.id;
        log:printInfo(string `Created Salesforce Account: ${createResult.id}`);
    }
    
    // Create contact if configured
    string? contactId = ();
    if createContact && accountId is string {
        SalesforceContact? sfContact = mapQuickBooksCustomerToSalesforceContact(qbCustomer, accountId);
        
        if sfContact is SalesforceContact {
            salesforce:CreationResponse|error contactResult = salesforceClient->create("Contact", sfContact);
            
            if contactResult is error {
                log:printError("Error creating Salesforce contact", contactResult);
            } else {
                contactId = contactResult.id;
                log:printInfo(string `Created Salesforce Contact: ${contactResult.id}`);
            }
        }
    }
    
    return {
        success: true,
        accountId: accountId,
        contactId: contactId,
        message: "Customer synced successfully"
    };
}
