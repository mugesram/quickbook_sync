# QuickBooks to Salesforce Sync Logic

## ✅ Implementation Verified

The sync logic has been reviewed and confirmed to be **correctly implemented**. Here's how it works:

## Sync Flow

### 1. **Check for Salesforce ID in QuickBooks**
```
QuickBooks Customer → CustomField array → Search for "Salesforce Account ID" field
```

### 2. **Decision Tree**

#### **Case A: Salesforce ID EXISTS in QuickBooks**
```
✓ Salesforce ID found in custom field (e.g., "001xx000003DGb2AAG")
  ↓
Search Salesforce by ID
  ↓
  ├─ Found? → Update existing account (subject to conflict resolution)
  └─ Not found? → Create new account (ID was deleted from Salesforce)
```

#### **Case B: Salesforce ID is NULL/EMPTY in QuickBooks**
```
✗ No Salesforce ID in custom field (null or empty string)
  ↓
Create new account in Salesforce
  ↓
Save new Salesforce ID back to QuickBooks custom field
```

### 3. **Bidirectional Linking (Loop Prevention)**

After sync completes:
```
Compare IDs:
  Current ID in QuickBooks: "001xx000003DGb2AAG"
  New ID from Salesforce:   "001xx000003DGb2AAG"
  
  ├─ IDs match? → Skip QuickBooks update (loop prevention)
  └─ IDs differ? → Update QuickBooks with new ID
```

**Why this matters:**
- Updating QuickBooks triggers a webhook
- Loop prevention ensures we don't create infinite webhook cycles
- Only updates when ID actually changes or is set for the first time

## Code Implementation

### Key Functions

#### `findExistingAccount()` - Search Logic
```ballerina
// Returns Salesforce Account ID if:
// 1. Salesforce ID exists in QuickBooks custom field AND
// 2. Account with that ID exists in Salesforce
//
// Returns () (null) if:
// 1. No Salesforce ID in QuickBooks OR
// 2. Salesforce ID not found in Salesforce
```

#### `syncCustomerToSalesforce()` - Main Sync Logic
```ballerina
1. Check if customer should be synced (filters)
2. Map QuickBooks customer to Salesforce account
3. Handle parent-child relationships (sub-customers)
4. Search for existing account by Salesforce ID
5. If found → Update (with conflict resolution)
   If not found → Create new
6. Save Salesforce ID back to QuickBooks (with loop prevention)
```

#### `updateQuickBooksCustomerWithSalesforceId()` - Write Back
```ballerina
1. Fetch current customer from QuickBooks
2. Discover/create custom field definition (lazy, on first use)
3. Preserve all OTHER custom fields
4. Set/update Salesforce Account ID field
5. Send update to QuickBooks API
```

## Configuration

### Required Settings (Config.toml)
```toml
# Enable bidirectional linking (REQUIRED for ID-based sync)
saveSalesforceIdToQuickBooks = true

# Custom field name in QuickBooks
quickbooksCustomFieldName = "Salesforce Account ID"
```

### Custom Field Auto-Setup
- **No manual setup required** in QuickBooks UI
- Field is auto-discovered or created on first sync
- Fallback to DefinitionId "1" if auto-creation fails

## Example Scenarios

### Scenario 1: First Sync (New Customer)
```
QuickBooks Customer: "Acme Corp" (no Salesforce ID)
  ↓
Create new Salesforce Account: "Acme Corp"
  ↓
Salesforce returns ID: "001xx000003DGb2AAG"
  ↓
Save ID to QuickBooks custom field
  ↓
QuickBooks triggers webhook (update event)
  ↓
Loop prevention: ID already matches → Skip update
```

### Scenario 2: Subsequent Sync (Existing Customer)
```
QuickBooks Customer: "Acme Corp" (Salesforce ID: "001xx000003DGb2AAG")
  ↓
Search Salesforce by ID: "001xx000003DGb2AAG"
  ↓
Found existing account → Update account
  ↓
Check if ID changed: No (still "001xx000003DGb2AAG")
  ↓
Skip QuickBooks update (loop prevention)
```

### Scenario 3: Deleted Salesforce Account
```
QuickBooks Customer: "Acme Corp" (Salesforce ID: "001xx000003DGb2AAG")
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

The implementation includes detailed logging at each step:

```
✓ Search strategy: Salesforce ID exists in QuickBooks custom field (ID: 001xx...)
✓ Will search by Salesforce ID and update if found
✓ Account found in Salesforce by ID: 001xx...
✓ Action: Will update existing account
✓ Updated Salesforce Account: 001xx...
✓ Salesforce Account ID already saved in QuickBooks - skipping update (loop prevention)
```

## Verification Checklist

- ✅ Searches by Salesforce ID if exists in QuickBooks
- ✅ Creates new account if Salesforce ID is null/empty
- ✅ Saves Salesforce ID back to QuickBooks after sync
- ✅ Loop prevention (checks if ID already matches)
- ✅ Preserves other custom fields during update
- ✅ Auto-discovers or creates custom field definition
- ✅ Handles parent-child relationships (sub-customers)
- ✅ Conflict resolution strategies (SOURCE_WINS, DESTINATION_WINS, MOST_RECENT)
- ✅ Comprehensive error handling and logging

## Conclusion

The implementation is **correct and complete**. The sync logic follows the exact requirements:

1. ✅ If Salesforce ID exists → Search by ID and update
2. ✅ If Salesforce ID is null → Create new and save ID to QuickBooks
3. ✅ Loop prevention ensures no infinite webhook cycles
4. ✅ Bidirectional linking maintains relationship between systems
