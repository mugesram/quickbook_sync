# QuickBooks to Salesforce Sync Logic

## ✅ Implementation Overview

The sync logic requires the custom field to exist in QuickBooks BEFORE any syncing occurs.

## Critical Requirement

### Custom Field MUST Exist

**BEFORE syncing can happen:**
1. Custom field "Salesforce Account ID" MUST be created manually in QuickBooks
2. Go to: QuickBooks → Settings → Custom Fields → Add Field → Customers
3. Name: "Salesforce Account ID" (must match `quickbooksCustomFieldName` config)
4. Type: Text

**If custom field doesn't exist:**
- ❌ Sync is SKIPPED entirely
- ❌ No Salesforce operations occur
- ⚠️ Warning logs are generated
- 📝 User must create field manually

## Sync Flow

### Step 1: **Check Custom Field Definition Exists**
```
Before ANY sync operation:
  ↓
Check if custom field definition exists in QuickBooks
  ↓
  ├─ Exists? → Continue to Step 2
  └─ Not found? → SKIP SYNC, log warning, return error
```

### Step 2: **Check Salesforce ID Value in QuickBooks**
```
Custom field definition exists
  ↓
Check custom field VALUE on customer
  ↓
  ├─ Value is empty/null → Go to Step 3a (Create New)
  └─ Value exists (e.g., "001xx...") → Go to Step 3b (Search & Update)
```

### Step 3a: **Create New Salesforce Account** (when value is empty)
```
Salesforce ID custom field is empty
  ↓
Create new Salesforce Account
  ↓
Get new Salesforce ID (e.g., "001xx000003DGb2AAG")
  ↓
Update QuickBooks customer with new Salesforce ID
  ↓
Done ✓
```

### Step 3b: **Search & Update** (when value exists)
```
Salesforce ID exists in QuickBooks (e.g., "001xx000003DGb2AAG")
  ↓
Search Salesforce by ID
  ↓
  ├─ Found? → Update existing account → Update QuickBooks if ID changed
  └─ Not found? → Create new account → Update QuickBooks with new ID
```

## Decision Tree

```
Webhook Event Received
  ↓
Fetch Customer from QuickBooks
  ↓
Check: Does custom field DEFINITION exist?
  ↓
  ├─ NO → SKIP SYNC (log warning) ❌
  └─ YES → Continue
       ↓
       Check: Custom field VALUE
         ↓
         ├─ Empty/Null → CREATE new Salesforce account
         │                ↓
         │                Update QuickBooks with new ID
         │
         └─ Has Value → SEARCH Salesforce by ID
                         ↓
                         ├─ Found → UPDATE account
                         └─ Not Found → CREATE new account
                         ↓
                         Update QuickBooks if ID changed
```

## Configuration

### Required Settings (Config.toml)
```toml
# Custom field name in QuickBooks (MUST match the field you created)
quickbooksCustomFieldName = "Salesforce Account ID"
```

### Manual Setup Required
```
1. QuickBooks → Settings → Custom Fields
2. Add Field → Select "Customers"
3. Name: "Salesforce Account ID"
4. Type: Text
5. Save
```

## Example Scenarios

### Scenario 1: Custom Field Doesn't Exist (SYNC BLOCKED)
```
QuickBooks Customer: "Acme Corp"
Custom Field Definition: NOT FOUND ❌
  ↓
Log: "Skipping sync for customer Acme Corp (ID: 123)"
Log: "Reason: Custom field 'Salesforce Account ID' definition not found in QuickBooks"
Log: "Please create the custom field manually"
  ↓
Return: { success: false, message: "Custom field definition not found. Sync skipped." }
  ↓
NO Salesforce operations occur
```

### Scenario 2: First Sync (Custom Field Exists, Value Empty)
```
QuickBooks Customer: "Acme Corp"
Custom Field Definition: EXISTS ✓
Custom Field Value: EMPTY
  ↓
Create new Salesforce Account: "Acme Corp"
  ↓
Salesforce returns ID: "001xx000003DGb2AAG"
  ↓
Update QuickBooks custom field with ID
  ↓
QuickBooks triggers webhook (update event)
  ↓
Loop prevention: ID already matches → Skip QuickBooks update
```

### Scenario 3: Subsequent Sync (Custom Field Exists, Value Exists)
```
QuickBooks Customer: "Acme Corp"
Custom Field Definition: EXISTS ✓
Custom Field Value: "001xx000003DGb2AAG"
  ↓
Search Salesforce by ID: "001xx000003DGb2AAG"
  ↓
Found existing account → Update account
  ↓
Check if ID changed: No (still "001xx000003DGb2AAG")
  ↓
Skip QuickBooks update (loop prevention)
```

### Scenario 4: Salesforce Account Deleted
```
QuickBooks Customer: "Acme Corp"
Custom Field Definition: EXISTS ✓
Custom Field Value: "001xx000003DGb2AAG"
  ↓
Search Salesforce by ID: "001xx000003DGb2AAG"
  ↓
Not found (account was deleted)
  ↓
Create new Salesforce Account: "Acme Corp"
  ↓
Salesforce returns new ID: "001xx000003DGb3AAG"
  ↓
Update QuickBooks with new ID (ID changed)
  ↓
QuickBooks triggers webhook
  ↓
Loop prevention: ID already matches → Skip update
```

## Logging

### When Custom Field Doesn't Exist
```
WARN: Skipping sync for customer Acme Corp (ID: 123)
WARN: Reason: Custom field 'Salesforce Account ID' definition not found in QuickBooks
WARN: Please create the custom field manually: QuickBooks → Settings → Custom Fields → Add Field → Customers
WARN: Field name: 'Salesforce Account ID', Type: Text
```

### When Custom Field Exists
```
INFO: ✓ Custom field 'Salesforce Account ID' definition exists in QuickBooks. Proceeding with sync.
INFO: Search strategy: No Salesforce ID in QuickBooks custom field
INFO: Will create new account and save Salesforce ID back to QuickBooks
INFO: ✓ No existing account found in Salesforce
INFO: Action: Will create new account and save Salesforce ID to QuickBooks custom field
INFO: Created Salesforce Account: 001xx000003DGb2AAG
INFO: ✓ Saving Salesforce Account ID 001xx000003DGb2AAG to QuickBooks custom field 'Salesforce Account ID' for the first time
INFO: ✓ Successfully saved Salesforce Account ID to QuickBooks customer 123
```

## Key Implementation Details

### File: `functions.bal` → `syncCustomerToSalesforce()`
```ballerina
// CRITICAL: Check if custom field definition exists BEFORE syncing
error? definitionCheckResult = ensureCustomFieldDefinitionExists();
if definitionCheckResult is error {
    // SKIP SYNC - Log warning and return error
    return {
        success: false,
        message: "Custom field definition not found. Sync skipped."
    };
}
// Continue with sync only if field exists
```

### File: `quickbooks_api.bal` → `ensureCustomFieldDefinitionExists()`
```ballerina
// Query QuickBooks for custom field definition
// Returns error if not found (does NOT create it)
// Sets the DefinitionId if found
```

### File: `quickbooks_api.bal` → `updateQuickBooksCustomerWithSalesforceId()`
```ballerina
// Uses the already-resolved DefinitionId
// Should never fail since we check before syncing
```

## Verification Checklist

- ✅ Custom field definition MUST exist before sync
- ✅ Sync is SKIPPED if definition not found
- ✅ If value is empty → Create new Salesforce account
- ✅ If value exists → Search by ID and update or create
- ✅ Always updates QuickBooks with Salesforce ID after sync
- ✅ Loop prevention (checks if ID already matches)
- ✅ Preserves other custom fields during update
- ✅ Handles parent-child relationships (sub-customers)
- ✅ Conflict resolution strategies (SOURCE_WINS, DESTINATION_WINS, MOST_RECENT)
- ✅ Comprehensive error handling and logging

## Conclusion

The implementation now **requires** the custom field to exist in QuickBooks before any syncing occurs:

1. ✅ Custom field definition check happens FIRST
2. ✅ If not found → Sync is SKIPPED entirely
3. ✅ If found and value empty → Create new Salesforce account
4. ✅ If found and value exists → Search by ID and update/create
5. ✅ Always updates QuickBooks with Salesforce ID
6. ✅ Loop prevention ensures no infinite cycles
