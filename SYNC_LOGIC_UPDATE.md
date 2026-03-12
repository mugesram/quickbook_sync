# Sync Logic Update Summary

## Changes Made

### 1. **Updated Sync Behavior**

**Previous Behavior:**
- Searched Salesforce accounts by name for both Create and Update operations
- Could create duplicate accounts if names didn't match exactly

**New Behavior:**
- **Create Operation**: Creates new account without searching (no duplicates from name matching)
- **Update Operation**: Searches by `QuickbooksSync__c` field (QuickBooks customer ID)
  - If found: Updates the account
  - If not found: Logs "User not found in Salesforce" and skips update

### 2. **Custom Field Requirement**

**Salesforce Custom Field (REQUIRED):**
- **Field Label**: Quickbooks Sync
- **Field Name**: QuickbooksSync
- **API Name**: `QuickbooksSync__c`
- **Type**: Text (255 characters)
- **Purpose**: Stores QuickBooks customer ID for matching during updates

**Setup Instructions:**
1. Go to Salesforce Setup → Object Manager → Account → Fields & Relationships
2. Click "New"
3. Select "Text" field type
4. Field Label: "Quickbooks Sync"
5. Field Name: "QuickbooksSync" (auto-generates API name `QuickbooksSync__c`)
6. Length: 255
7. Save and add to page layouts

### 3. **Error Handling**

**Missing Custom Field:**
- Error message: "You have to set custom field in Salesforce Account with 'QuickbooksSync__c' as field name to update customer with sync"
- Update operations will fail until field is created
- Create operations continue to work

**User Not Found:**
- Warning message: "User not found in Salesforce for QuickBooks ID: {id}"
- Occurs when updating a QuickBooks customer that doesn't exist in Salesforce
- Solution: Create the customer first or manually add the account in Salesforce

### 4. **Code Changes**

**Modified Files:**
- `functions.bal`: 
  - Renamed `findAccountByName()` to `findAccountByQuickBooksId()`
  - Updated `syncCustomerToSalesforce()` to accept `operation` parameter
  - Added logic to differentiate Create vs Update operations
  - Added custom field validation and error handling
  
- `data_mappings.bal`:
  - Added `QuickbooksSync__c: qbCustomer.Id` to account mapping

- `types.bal`:
  - Changed field name from `QuickBooks_Customer_Id__c` to `QuickbooksSync__c`

- `main.bal`:
  - Passed `operation` parameter to `syncCustomerToSalesforce()`

- `README.md`:
  - Updated sync behavior documentation
  - Added custom field setup instructions
  - Updated troubleshooting section

### 5. **Benefits**

✅ **No More Duplicate Accounts**: Create operations don't search by name
✅ **Reliable Updates**: Uses unique QuickBooks ID instead of name matching
✅ **Better Error Messages**: Clear guidance when custom field is missing
✅ **Cleaner Logic**: Separate handling for Create vs Update operations
✅ **Parent-Child Support**: Parent lookup also uses QuickBooks ID

## Testing Checklist

- [ ] Create custom field `QuickbooksSync__c` in Salesforce Account object
- [ ] Test Create operation: Create new customer in QuickBooks
- [ ] Verify `QuickbooksSync__c` field is populated in Salesforce
- [ ] Test Update operation: Update existing customer in QuickBooks
- [ ] Verify account is found and updated in Salesforce
- [ ] Test Update without custom field: Verify error message
- [ ] Test Update for non-existent customer: Verify "User not found" message
- [ ] Test parent-child relationships: Create sub-customer in QuickBooks

## Migration Notes

**For Existing Deployments:**

If you have existing Salesforce accounts created by the old sync logic:

1. **Create the custom field** in Salesforce Account object
2. **Backfill existing accounts**: Run a one-time script to populate `QuickbooksSync__c` with QuickBooks customer IDs
3. **Or**: Delete and recreate customers in QuickBooks to trigger fresh Create operations

**SOQL Query to Find Accounts Without QuickBooks ID:**
```sql
SELECT Id, Name FROM Account WHERE QuickbooksSync__c = null AND Description LIKE '%Created by QuickBooks%'
```

## Configuration Changes

**Removed from Config.toml:**
- `saveSalesforceIdToQuickBooks` - No longer needed
- `quickbooksCustomFieldName` - No longer needed

**Still Required:**
- `salesforceClientId`
- `salesforceClientSecret`
- `salesforceRefreshToken`
- `salesforceRefreshUrl`
- `salesforceBaseUrl`
- `quickbooksClientId`
- `quickbooksClientSecret`
- `quickbooksRefreshToken`
- `quickbooksRealmId`
- `quickbooksBaseUrl`
- `webhookPort`
- `webhookVerifyToken`
- `conflictResolution`
- `filterActiveOnly`
- `createContact`
