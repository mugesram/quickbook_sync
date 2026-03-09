// Salesforce Configuration
configurable string salesforceClientId = ?;
configurable string salesforceClientSecret = ?;
configurable string salesforceRefreshToken = ?;
configurable string salesforceRefreshUrl = ?;
configurable string salesforceBaseUrl = ?;

// QuickBooks Webhook Configuration
configurable int webhookPort = 8080;
configurable string webhookVerifyToken = ?;

// Sync Configuration
configurable ConflictResolution conflictResolution = SOURCE_WINS;
configurable boolean filterActiveOnly = true;
configurable boolean createContact = false;
configurable DuplicateMatchStrategy duplicateMatchStrategy = MATCH_BY_EMAIL;
