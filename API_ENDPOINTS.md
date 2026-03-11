# QuickBooks API Endpoints Reference

## Where the URL is Defined

### Base URL Configuration
**File:** `config.bal` (line 14)
```ballerina
// MUST be set in Config.toml - no default value
configurable string quickbooksBaseUrl = ?;
```

**In your Config.toml:**
```toml
# For Sandbox
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"

# For Production
quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"
```

### Endpoint Construction
**File:** `quickbooks_api.bal` (line 26)
```ballerina
string endpoint = string `/${realmId}/customer/${customerId}`;
json response = check quickbooksClient->get(endpoint);
```

### Full URL Pattern
```
{quickbooksBaseUrl}/{realmId}/customer/{customerId}
```

**Example:**
```
https://sandbox-quickbooks.api.intuit.com/v3/company/9341456558110612/customer/60
```

---

## Sandbox vs Production

### Sandbox (Testing)
```toml
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"
```
- Use for development and testing
- Requires sandbox OAuth credentials
- Test data only

### Production (Live)
```toml
quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"
```
- Use for live customer data
- Requires production OAuth credentials
- Real QuickBooks company data

---

## How It Works

1. **HTTP Client Initialization** (`quickbooks_api.bal` line 5)
   ```ballerina
   final http:Client quickbooksClient = check new (quickbooksBaseUrl, ...);
   ```
   - Creates HTTP client with base URL
   - Configures OAuth 2.0 authentication

2. **API Call** (`quickbooks_api.bal` line 28)
   ```ballerina
   json response = check quickbooksClient->get(endpoint);
   ```
   - Appends endpoint to base URL
   - Automatically adds OAuth token to request
   - Returns customer data as JSON

3. **Full Request**
   ```
   GET https://sandbox-quickbooks.api.intuit.com/v3/company/9341456558110612/customer/60
   Headers:
     Authorization: Bearer {access_token}
     Accept: application/json
   ```

---

## Changing Between Sandbox and Production

### Option 1: Update Config.toml
```toml
# For Sandbox
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"

# For Production
quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"
```

### Option 2: Update config.bal Default
Edit `config.bal` line 13 to change the default value.

---

## Other QuickBooks API Endpoints

The same pattern works for other QuickBooks entities:

### Invoice
```
GET /{realmId}/invoice/{id}
```

### Payment
```
GET /{realmId}/payment/{id}
```

### Company Info
```
GET /{realmId}/companyinfo/{realmId}
```

### Query (SOQL-like)
```
GET /{realmId}/query?query=SELECT * FROM Customer WHERE Id='60'
```

---

## Debugging URL Issues

### Check Current Configuration
```bash
curl http://localhost:8080/diagnostics
```

Response shows:
```json
{
  "quickbooks": {
    "baseUrl": "https://sandbox-quickbooks.api.intuit.com/v3/company",
    "realmIdConfigured": true
  }
}
```

### Enable Request Logging
The code logs each request:
```
Fetching customer 60 from QuickBooks (Realm: 9341456558110612)
```

### Common URL Errors

**403 Forbidden:**
- Wrong environment (sandbox credentials with production URL)
- Invalid OAuth token
- Realm ID mismatch

**404 Not Found:**
- Customer ID doesn't exist
- Wrong realm ID
- Typo in endpoint

**401 Unauthorized:**
- Expired access token (auto-refreshed by client)
- Invalid OAuth credentials

---

## Summary

**URL Construction:**
```
Base URL (config.bal) + Endpoint (quickbooks_api.bal) = Full URL
```

**Current Setup:**
- Base: `https://sandbox-quickbooks.api.intuit.com/v3/company`
- Endpoint: `/{realmId}/customer/{customerId}`
- Full: `https://sandbox-quickbooks.api.intuit.com/v3/company/9341456558110612/customer/60`

**To Change:** Update `quickbooksBaseUrl` in your `Config.toml` file.
