import ballerina/http;
import ballerina/log;

// HTTP Listener for QuickBooks Webhooks
listener http:Listener webhookListener = check new (webhookPort);

// QuickBooks Webhook Service
service /quickbooks on webhookListener {
    
    // Webhook verification endpoint (GET)
    resource function get webhook(@http:Query string verifyToken) returns string|http:Unauthorized {
        if verifyToken == webhookVerifyToken {
            return "Webhook verified successfully";
        }
        return http:UNAUTHORIZED;
    }
    
    // Webhook event receiver (POST)
    resource function post webhook(@http:Payload json webhookPayload) returns http:Ok|http:InternalServerError {
        
        log:printInfo("Received QuickBooks webhook event");
        
        // Process webhook event asynchronously
        error? processResult = processQuickBooksWebhook(webhookPayload);
        
        if processResult is error {
            log:printError("Error processing webhook", processResult);
            return http:INTERNAL_SERVER_ERROR;
        }
        
        return http:OK;
    }
}

// Process QuickBooks Webhook Event
function processQuickBooksWebhook(json webhookPayload) returns error? {
    
    // Parse webhook payload
    json[] eventNotifications = <json[]>check webhookPayload.eventNotifications;
    
    foreach json notification in eventNotifications {
        string realmId = check notification.realmId;
        json[] dataChangeEvents = <json[]>check notification.dataChangeEvent;
        
        foreach json changeEvent in dataChangeEvents {
            json[] entities = <json[]>check changeEvent.entities;
            
            foreach json entity in entities {
                string entityName = check entity.name;
                string entityId = check entity.id;
                string operation = check entity.operation;
                
                // Process only Customer entities
                if entityName == "Customer" && (operation == "Create" || operation == "Update") {
                    log:printInfo(string `Processing ${operation} event for Customer ID: ${entityId}`);
                    
                    // Fetch customer details from QuickBooks
                    // Note: In a real implementation, you would call QuickBooks API here
                    // For this example, we'll simulate with the entity data
                    QuickBooksCustomer qbCustomer = check entity.cloneWithType();
                    
                    // Sync to Salesforce
                    SyncResult result = syncCustomerToSalesforce(qbCustomer);
                    
                    if result.success {
                        string? message = result?.message;
                        log:printInfo(string `Successfully synced customer ${entityId}: ${message ?: ""}`);
                    } else {
                        string? message = result?.message;
                        log:printError(string `Failed to sync customer ${entityId}: ${message ?: ""}`);
                    }
                }
            }
        }
    }
}
