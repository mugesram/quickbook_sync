import ballerinax/salesforce;
import ballerina/log;
import ballerina/time;

// Check if customer should be synced based on filters
public isolated function shouldSyncCustomer(QuickBooksCustomer qbCustomer) returns boolean {
    
    // Filter by active status if configured
    if filterActiveOnly {
        boolean? active = qbCustomer?.Active;
        if active is boolean && !active {
            return false;
        }
    }
    
    return true;
}

// Find Salesforce Account by Name
public isolated function findAccountByName(string accountName) returns string?|error {
    
    // Escape single quotes in account name for SOQL
    string:RegExp singleQuote = re `'`;
    string escapedName = singleQuote.replaceAll(accountName, "\\'");
    string soqlQuery = string `SELECT Id FROM Account WHERE Name = '${escapedName}' LIMIT 1`;
    
    stream<record {}, error?> resultStream = check salesforceClient->query(soqlQuery);
    
    record {|record {} value;|}? result = check resultStream.next();
    check resultStream.close();
    
    if result is record {|record {} value;|} {
        record {} accountRecord = result.value;
        anydata idValue = accountRecord["Id"];
        if idValue is string {
            return idValue;
        }
    }
    
    return ();
}



// Resolve conflict based on strategy
public isolated function shouldUpdateAccount(SalesforceAccount existingAccount, QuickBooksCustomer qbCustomer) returns boolean|error {
    
    if conflictResolution == SOURCE_WINS {
        return true;
    } else if conflictResolution == DESTINATION_WINS {
        return false;
    } else if conflictResolution == MOST_RECENT {
        // Compare last modified dates
        string? sfLastModified = existingAccount?.LastModifiedDate;
        MetaData? qbMetadata = qbCustomer?.MetaData;
        
        if sfLastModified is () || qbMetadata is () {
            return true;
        }
        
        string? qbLastUpdated = qbMetadata?.LastUpdatedTime;
        if qbLastUpdated is () {
            return true;
        }
        
        // Parse Salesforce date and compare
        time:Utc sfTime = check time:utcFromString(sfLastModified);
        time:Utc qbTime = check time:utcFromString(qbLastUpdated);
        
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
    
    // Handle parent account relationship for sub-customers
    ParentRef? parentRef = qbCustomer?.ParentRef;
    
    if parentRef is ParentRef {
        string? parentCustomerId = parentRef?.value;
        string? parentName = parentRef?.name;
        
        // If parent name is not available, fetch parent customer from QuickBooks to get the name
        if parentCustomerId is string {
            if parentName is () {
                QuickBooksCustomer|error parentCustomerResult = fetchQuickBooksCustomerDetails(parentCustomerId);
                
                if parentCustomerResult is error {
                    log:printError(string `Failed to fetch parent customer ${parentCustomerId}`);
                } else {
                    QuickBooksCustomer parentCustomer = parentCustomerResult;
                    parentName = parentCustomer.DisplayName;
                }
            }
            
            if parentName is string {
                // Check if parent account exists in Salesforce
                string?|error parentAccountId = findAccountByName(parentName);
            
                if parentAccountId is string {
                    sfAccount.ParentId = parentAccountId;
                } else if parentAccountId is error {
                    log:printError(string `Error finding parent account: ${parentName}`);
                    return {
                        success: false,
                        message: string `Error finding parent account: ${parentName}`,
                        errorDetails: parentAccountId.message()
                    };
                } else {
                    // Parent does not exist in Salesforce - create it first
                    QuickBooksCustomer|error parentCustomerResult = fetchQuickBooksCustomerDetails(parentCustomerId);
                    
                    if parentCustomerResult is error {
                        log:printError(string `Failed to fetch parent customer ${parentCustomerId}`);
                        return {
                            success: false,
                            message: string `Failed to fetch parent customer ${parentName}`,
                            errorDetails: parentCustomerResult.message()
                        };
                    }
                    
                    QuickBooksCustomer parentCustomer = parentCustomerResult;
                    SyncResult parentSyncResult = syncCustomerToSalesforce(parentCustomer);
                    
                    if !parentSyncResult.success {
                        return {
                            success: false,
                            message: string `Failed to sync parent customer ${parentName}`,
                            errorDetails: parentSyncResult?.errorDetails
                        };
                    }
                    
                    string? createdParentId = parentSyncResult?.accountId;
                    if createdParentId is string {
                        sfAccount.ParentId = createdParentId;
                    }
                }
            }
        }
    } else {
        sfAccount.ParentId = ();
    }
    
    // Check for existing account by name
    string?|error existingAccountId = findAccountByName(qbCustomer.DisplayName);
    
    if existingAccountId is error {
        return {
            success: false,
            message: "Error finding existing account",
            errorDetails: existingAccountId.message()
        };
    }
    
    string? accountId = ();
    
    if existingAccountId is string {
        // Account exists - check conflict resolution
        string queryStr = string `SELECT Id, Name, LastModifiedDate FROM Account WHERE Id = '${existingAccountId}' LIMIT 1`;
        stream<record {}, error?>|error accountStreamResult = salesforceClient->query(queryStr);
        
        if accountStreamResult is error {
            return {
                success: false,
                message: "Error querying account",
                errorDetails: accountStreamResult.message()
            };
        }
        
        stream<record {}, error?> accountStream = accountStreamResult;
        record {|record {} value;|}|error? accountResult = accountStream.next();
        error? closeResult = accountStream.close();
        
        if accountResult is error {
            return {
                success: false,
                message: "Error reading account",
                errorDetails: accountResult.message()
            };
        }
        
        if accountResult is () {
            return {
                success: false,
                message: "Account not found"
            };
        }
        
        record {} existingAccountRecord = accountResult.value;
        SalesforceAccount|error existingAccountResult = existingAccountRecord.cloneWithType(SalesforceAccount);
        if existingAccountResult is error {
            return {
                success: false,
                message: "Error converting account record",
                errorDetails: existingAccountResult.message()
            };
        }
        
        SalesforceAccount existingAccount = existingAccountResult;
        boolean|error shouldUpdate = shouldUpdateAccount(existingAccount, qbCustomer);
        
        if shouldUpdate is error {
            return {
                success: false,
                message: "Error in conflict resolution",
                errorDetails: shouldUpdate.message()
            };
        }
        
        if shouldUpdate {
            error? updateResult = salesforceClient->update("Account", existingAccountId, sfAccount);
            
            if updateResult is error {
                return {
                    success: false,
                    message: "Error updating Salesforce account",
                    errorDetails: updateResult.message()
                };
            }
            
            accountId = existingAccountId;
        } else {
            accountId = existingAccountId;
        }
    } else {
        // Create new account
        salesforce:CreationResponse|error createResult = salesforceClient->create("Account", sfAccount);
        
        if createResult is error {
            return {
                success: false,
                message: "Error creating Salesforce account",
                errorDetails: createResult.message()
            };
        }
        
        accountId = createResult.id;
    }
    
    // Create contact if configured
    string? contactId = ();
    if createContact && accountId is string {
        SalesforceContact? sfContact = mapQuickBooksCustomerToSalesforceContact(qbCustomer, accountId);
        
        if sfContact is SalesforceContact {
            salesforce:CreationResponse|error contactResult = salesforceClient->create("Contact", sfContact);
            
            if contactResult is salesforce:CreationResponse {
                contactId = contactResult.id;
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
