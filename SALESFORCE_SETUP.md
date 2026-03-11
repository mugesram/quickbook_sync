# Salesforce Setup Guide

## Required Configuration

### Option 1: Use Standard Fields (Recommended for Quick Start)

The integration now works with **standard Salesforce fields** out of the box:

**Config.toml:**
```toml
duplicateMatchStrategy = "MATCH_BY_NAME"
```

This matches accounts by the standard `Name` field. No custom fields required!

---

### Option 2: Add Custom Field for Better Tracking (Optional)

If you want to track QuickBooks Customer IDs in Salesforce, create a custom field:

#### Step 1: Create Custom Field

1. **Go to Salesforce Setup**
   - Click the gear icon → Setup

2. **Navigate to Object Manager**
   - Setup → Object Manager → Account

3. **Create Custom Field**
   - Fields & Relationships → New
   - Field Type: **Text**
   - Field Label: `QuickBooks Customer Id`
   - Field Name: `QuickBooks_Customer_Id` (will become `QuickBooks_Customer_Id__c`)
   - Length: 50
   - **Check "External ID"** ✓
   - **Check "Unique"** ✓
   - Click Next → Next → Save

#### Step 2: Update Code

Uncomment the field in `data_mappings.bal`:

```ballerina
SalesforceAccount sfAccount = {
    Name: qbCustomer.DisplayName,
    Phone: phone,
    Website: website,
    // ... other fields ...
    QuickBooks_Customer_Id__c: qbCustomer.Id  // Uncomment this line
};
```

#### Step 3: Update Config

```toml
duplicateMatchStrategy = "MATCH_BY_EXTERNAL_ID"
```

---

## Duplicate Matching Strategies

### MATCH_BY_NAME (Default - No Setup Required)
```toml
duplicateMatchStrategy = "MATCH_BY_NAME"
```
- ✅ Works immediately with standard fields
- ✅ No Salesforce customization needed
- ⚠️ May create duplicates if names change
- **Best for:** Quick start, testing

### MATCH_BY_EMAIL
```toml
duplicateMatchStrategy = "MATCH_BY_EMAIL"
```
- ✅ Works with standard fields
- ✅ More accurate than name matching
- ⚠️ Requires customers to have email addresses
- **Best for:** B2C scenarios where email is always present

### MATCH_BY_EXTERNAL_ID (Requires Custom Field)
```toml
duplicateMatchStrategy = "MATCH_BY_EXTERNAL_ID"
```
- ✅ Most accurate - uses QuickBooks ID
- ✅ Prevents duplicates even if name/email changes
- ⚠️ Requires custom field setup (see above)
- **Best for:** Production use, long-term reliability

---

## Account Type Considerations

### Business Accounts (B2B)
Standard Salesforce Accounts work out of the box:
- Name ✓
- Phone ✓
- Website ✓
- BillingAddress ✓

### Person Accounts (B2C)
If using Person Accounts, you may need to:
1. Enable Person Accounts in Salesforce
2. Adjust field mappings for PersonEmail, PersonPhone, etc.

---

## Field Mapping Reference

| QuickBooks Field | Salesforce Field | Notes |
|-----------------|------------------|-------|
| DisplayName | Name | Standard field ✓ |
| PrimaryPhone.FreeFormNumber | Phone | Standard field ✓ |
| WebAddr.URI | Website | Standard field ✓ |
| BillAddr.Line1 | BillingStreet | Standard field ✓ |
| BillAddr.City | BillingCity | Standard field ✓ |
| BillAddr.CountrySubDivisionCode | BillingState | Standard field ✓ |
| BillAddr.PostalCode | BillingPostalCode | Standard field ✓ |
| BillAddr.Country | BillingCountry | Standard field ✓ |
| CustomerType | Type | Standard field ✓ |
| Id | QuickBooks_Customer_Id__c | **Custom field** (optional) |

---

## Testing Your Setup

### 1. Check Current Configuration
```bash
curl http://localhost:8080/diagnostics
```

### 2. Test with Sample Webhook
```bash
curl -X POST http://localhost:8080/quickbooks/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "eventNotifications": [{
      "realmId": "YOUR_REALM_ID",
      "dataChangeEvent": {
        "entities": [{
          "id": "TEST123",
          "operation": "Create",
          "name": "Customer"
        }]
      }
    }]
  }'
```

### 3. Verify in Salesforce
- Go to Accounts
- Search for the customer name
- Verify all fields are populated correctly

---

## Common Issues

### Error: "No such column 'QuickBooks_Customer_Id__c'"
**Cause:** Custom field doesn't exist
**Solution:** 
- Change to `MATCH_BY_NAME` in Config.toml, OR
- Create the custom field (see Option 2 above)

### Duplicate Accounts Created
**Cause:** Matching strategy not finding existing accounts
**Solution:**
- Use `MATCH_BY_EXTERNAL_ID` with custom field for best results
- Or ensure customer names are consistent

### No Accounts Created
**Cause:** Field mapping errors or permissions
**Solution:**
- Check Salesforce user has Create permission on Account
- Verify all required fields are populated
- Check logs for specific error messages

---

## Recommended Setup for Production

1. **Create Custom Field** (QuickBooks_Customer_Id__c)
2. **Set as External ID and Unique**
3. **Use MATCH_BY_EXTERNAL_ID strategy**
4. **Enable field-level security** for integration user
5. **Test with sandbox first**

This ensures:
- ✅ No duplicate accounts
- ✅ Reliable syncing even if customer details change
- ✅ Easy troubleshooting with QuickBooks ID visible in Salesforce
