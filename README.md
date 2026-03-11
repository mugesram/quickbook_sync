# QuickBooks to Salesforce Sync

A production-ready Ballerina integration that syncs QuickBooks customers to Salesforce accounts in real-time via webhooks.

## Features

✅ **Real-time Sync** - Webhook-based synchronization from QuickBooks to Salesforce  
✅ **Bidirectional Linking** - Stores Salesforce Account ID in QuickBooks custom field  
✅ **Parent-Child Relationships** - Handles QuickBooks sub-customers → Salesforce account hierarchy  
✅ **Loop Prevention** - Smart logic prevents infinite webhook cycles  
✅ **Conflict Resolution** - Configurable strategies (SOURCE_WINS, DESTINATION_WINS, MOST_RECENT)  
✅ **Custom Field Validation** - Ensures custom field exists before syncing  
✅ **OAuth 2.0** - Secure authentication with automatic token refresh  

## Prerequisites

- Ballerina Swan Lake (2201.x or later)
- QuickBooks Online account with API access
- Salesforce account with API access
- Public HTTPS endpoint for webhooks (use ngrok for local testing)

## Configuration

Create a `Config.toml` file:

```toml
# Salesforce Configuration
salesforceClientId = "YOUR_SALESFORCE_CLIENT_ID"
salesforceClientSecret = "YOUR_SALESFORCE_CLIENT_SECRET"
salesforceRefreshToken = "YOUR_SALESFORCE_REFRESH_TOKEN"
salesforceRefreshUrl = "https://login.salesforce.com/services/oauth2/token"
salesforceBaseUrl = "https://yourinstance.salesforce.com"

# QuickBooks Configuration
quickbooksClientId = "YOUR_QUICKBOOKS_CLIENT_ID"
quickbooksClientSecret = "YOUR_QUICKBOOKS_CLIENT_SECRET"
quickbooksRefreshToken = "YOUR_QUICKBOOKS_REFRESH_TOKEN"
quickbooksRealmId = "YOUR_COMPANY_ID"
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"
# For production: quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"

# Webhook Configuration
webhookPort = 8080
webhookVerifyToken = "YOUR_WEBHOOK_VERIFY_TOKEN"

# Sync Configuration
conflictResolution = "SOURCE_WINS"  # Options: SOURCE_WINS, DESTINATION_WINS, MOST_RECENT
filterActiveOnly = true              # Only sync active customers
createContact = false                # Create Salesforce contacts from customer data
saveSalesforceIdToQuickBooks = true  # Save Salesforce ID back to QuickBooks
quickbooksCustomFieldName = "Salesforce Account ID"
```

## Setup

### 1. Salesforce Setup

1. Create a Connected App in Salesforce
2. Enable OAuth settings
3. Add required scopes: `api`, `refresh_token`, `offline_access`
4. Get Client ID, Client Secret, and Refresh Token

### 2. QuickBooks Setup

1. Create an app in QuickBooks Developer Portal
2. Enable OAuth 2.0
3. Add webhook subscriptions for Customer entity
4. Get Client ID, Client Secret, and Refresh Token
5. Configure webhook URL: `https://your-domain.com/quickbooks/webhook`

### 3. Custom Field (REQUIRED - Manual Setup)

**IMPORTANT**: You MUST create the custom field in QuickBooks before syncing.

1. Go to QuickBooks → Settings → Custom Fields
2. Add Field → Select "Customers"
3. Name: "Salesforce Account ID" (must match `quickbooksCustomFieldName` in Config.toml)
4. Type: Text

**If the custom field doesn't exist**:
- Sync will be skipped entirely
- Warning logs will be generated
- No Salesforce operations will occur
- You must create the field manually to enable syncing

## Running

```bash
# Build
bal build

# Run
bal run
```

**IMPORTANT**: Webhooks will NOT trigger automatically when the service starts. You must:
1. Start the service (`bal run`)
2. Make the service publicly accessible (use ngrok for local testing)
3. **Trigger a change in QuickBooks** (create or update a customer)
4. Then QuickBooks will send a webhook to your service

## API Endpoints

- `GET /` - Health check
- `GET /quickbooks/health` - Service health check
- `GET /quickbooks/webhook?verifyToken=TOKEN` - Webhook verification
- `POST /quickbooks/webhook` - Webhook event receiver

## Sync Behavior

### ID-Based Matching
- **If Salesforce ID exists in QuickBooks** → Search by ID and update
- **If no Salesforce ID** → Create new account
- **After sync** → Save Salesforce ID to QuickBooks

### Parent-Child Relationships
- QuickBooks sub-customers → Salesforce child accounts
- Parent accounts are synced first (recursive)
- Parent relationships are maintained

### Loop Prevention
- Checks if Salesforce ID already matches before updating QuickBooks
- Only updates when ID changes or is initially set
- Prevents infinite webhook cycles

## Conflict Resolution Strategies

- **SOURCE_WINS** - QuickBooks data always overwrites Salesforce
- **DESTINATION_WINS** - Salesforce data is never overwritten
- **MOST_RECENT** - Most recently modified record wins

## Logging

All operations are logged with timestamps:
- INFO: Normal operations
- WARN: Non-critical issues
- ERROR: Failures (sync continues)

## Production Considerations

✅ **Security**
- Use HTTPS for webhooks
- Rotate OAuth tokens regularly
- Store credentials securely (environment variables or secrets manager)

✅ **Monitoring**
- Monitor logs for errors
- Set up alerts for failed syncs
- Track webhook delivery failures

✅ **Performance**
- Webhook processing is synchronous but fast
- Parent customer syncs may cause cascading API calls
- Consider rate limits (QuickBooks: 500 req/min, Salesforce: varies by edition)

✅ **Error Handling**
- Failed QuickBooks updates don't fail the entire sync
- Comprehensive error logging
- Graceful degradation

## Testing the Integration

### Step 1: Start the Service
```bash
bal run
```

You should see:
```
###################################################################################################
QUICKBOOKS TO SALESFORCE SYNC SERVICE STARTING
###################################################################################################
SERVICE READY - Waiting for webhooks...
###################################################################################################
```

### Step 2: Make Service Publicly Accessible

**For Local Testing (using ngrok):**
```bash
# In a new terminal
ngrok http 8080
```

Copy the HTTPS URL (e.g., `https://xxxx.ngrok.io`)

### Step 3: Configure QuickBooks Webhook

1. Go to QuickBooks Developer Portal
2. Navigate to your app → Webhooks
3. Set webhook URL: `https://xxxx.ngrok.io/quickbooks/webhook`
4. Subscribe to "Customer" entity
5. Save and verify

### Step 4: Trigger a Webhook

**Webhooks are NOT sent automatically!** You must trigger them by:

1. **Go to QuickBooks Online**
2. **Create a new customer** OR **Update an existing customer**
3. **Save the changes**
4. **Check your service logs** - you should see:
   ```
   ###################################################################################################
   WEBHOOK RECEIVED FROM QUICKBOOKS
   ###################################################################################################
   ```

If you don't see logs, the webhook wasn't sent or didn't reach your service.

## Troubleshooting

### No Logs After Creating/Updating Customer in QuickBooks

**Common causes:**

1. **Service not running** - Check terminal shows "SERVICE READY"
2. **ngrok not running** - Check ngrok terminal shows "Forwarding"
3. **Wrong webhook URL in QuickBooks** - Must use ngrok HTTPS URL
4. **Webhook not verified** - Check QuickBooks Developer Portal shows "Active"
5. **Customer entity not subscribed** - Check webhook subscriptions include "Customer"

**How to verify:**

1. **Check service is running:**
   ```bash
   curl http://localhost:8080/quickbooks/health
   ```
   Should return: `{"status":"UP",...}`

2. **Check ngrok is forwarding:**
   - Open ngrok web interface: http://localhost:4040
   - You should see requests when you trigger webhooks

3. **Check QuickBooks webhook logs:**
   - Go to QuickBooks Developer Portal → Webhooks → Logs
   - Look for delivery attempts and response codes

### Webhook Not Receiving Events
- **Verify webhook URL is publicly accessible** (use ngrok HTTPS URL, not localhost)
- **Check QuickBooks webhook subscriptions are active** (should show "Active" status)
- **Verify `webhookVerifyToken` matches** between Config.toml and QuickBooks
- **Actually create/update a customer in QuickBooks** (webhooks don't trigger automatically)

### Custom Field Errors
- **Sync skipped** - Check logs for "Custom field definition not found" warnings
- Manually create the field in QuickBooks: Settings → Custom Fields → Add Field → Customers
- Ensure field name matches `quickbooksCustomFieldName` exactly (default: "Salesforce Account ID")
- Field type must be "Text"
- Field must be enabled for Customers
- Once created, restart the service or wait for next webhook event

### Duplicate Accounts
- Ensure `saveSalesforceIdToQuickBooks = true`
- Check custom field is being populated
- Verify loop prevention is working (check logs)

### Authentication Errors
- Refresh tokens may expire - regenerate them
- Verify client IDs and secrets are correct
- Check OAuth scopes are sufficient

## License

MIT
