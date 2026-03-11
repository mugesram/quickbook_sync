# Troubleshooting Guide

## No Logs After Triggering from QuickBooks

**IMPORTANT**: Webhooks do NOT trigger automatically when you start the service. You must:
1. Start the service
2. Make it publicly accessible (ngrok)
3. **Actually create or update a customer in QuickBooks**
4. Then QuickBooks will send a webhook

If you're not seeing any logs after creating/updating a customer in QuickBooks, follow these steps:

### Step 1: Verify Service is Running

1. **Start the service:**
   ```bash
   bal run
   ```

2. **Look for startup logs:**
   ```
   ###################################################################################################
   QUICKBOOKS TO SALESFORCE SYNC SERVICE STARTING
   ###################################################################################################
   Webhook Port: 8080
   Webhook Endpoint: http://localhost:8080/quickbooks/webhook
   ...
   SERVICE READY - Waiting for webhooks...
   ###################################################################################################
   ```

   If you don't see these logs, the service failed to start. Check for errors.

### Step 2: Test Health Check

Open your browser or use curl:

```bash
curl http://localhost:8080/quickbooks/health
```

**Expected response:**
```json
{
  "status": "UP",
  "serviceName": "QuickBooks to Salesforce Sync",
  "timestamp": "..."
}
```

**Expected log:**
```
Health check requested at /quickbooks/health
```

If this doesn't work, your service isn't running or the port is wrong.

### Step 3: Check QuickBooks Webhook Configuration

1. **Go to QuickBooks Developer Portal**
   - Navigate to your app
   - Go to Webhooks section

2. **Verify webhook URL:**
   - Should be: `https://your-domain.com/quickbooks/webhook`
   - For local testing with ngrok: `https://xxxx.ngrok.io/quickbooks/webhook`
   - **NOT** `http://localhost:8080` (QuickBooks can't reach localhost)

3. **Check webhook status:**
   - Should show as "Active" or "Verified"
   - If "Pending", QuickBooks hasn't verified your endpoint yet

4. **Verify entity subscriptions:**
   - Make sure "Customer" entity is checked
   - Operations: Create, Update, Delete

### Step 4: Test Webhook Verification

QuickBooks will send a GET request to verify your webhook:

```bash
curl "http://localhost:8080/quickbooks/webhook?verifyToken=YOUR_VERIFY_TOKEN"
```

**Expected log:**
```
###################################################################################################
WEBHOOK VERIFICATION REQUEST RECEIVED
###################################################################################################
Received verifyToken: YOUR_VERIFY_TOKEN
Expected verifyToken: YOUR_VERIFY_TOKEN
✓ Verification successful
###################################################################################################
```

If verification fails, check your `webhookVerifyToken` in Config.toml matches what you set in QuickBooks.

### Step 5: Use ngrok for Local Testing

QuickBooks webhooks require a public HTTPS URL. Use ngrok:

1. **Install ngrok:**
   ```bash
   # Download from https://ngrok.com/download
   ```

2. **Start ngrok:**
   ```bash
   ngrok http 8080
   ```

3. **Copy the HTTPS URL:**
   ```
   Forwarding  https://xxxx.ngrok.io -> http://localhost:8080
   ```

4. **Update QuickBooks webhook URL:**
   - Go to QuickBooks Developer Portal
   - Navigate to your app → Webhooks
   - Set URL: `https://xxxx.ngrok.io/quickbooks/webhook`
   - Click "Save"
   - Wait for verification (should show "Active")

5. **Trigger a webhook from QuickBooks:**
   - **Go to QuickBooks Online** (not the Developer Portal)
   - **Create a new customer** OR **Edit an existing customer**
   - **Make a change** (e.g., change name, add phone number)
   - **Click Save**
   - **Watch your service logs** - you should see webhook logs within seconds

6. **Check ngrok logs:**
   - Open http://localhost:4040 in your browser
   - You should see POST requests to `/quickbooks/webhook`
   - If you don't see requests, QuickBooks isn't sending webhooks

### Step 6: Check QuickBooks Webhook Logs

1. **Go to QuickBooks Developer Portal**
2. **Navigate to Webhooks → Logs**
3. **Check for:**
   - Delivery attempts
   - Response codes
   - Error messages

**Common issues:**
- **404 Not Found** - Wrong URL path
- **401 Unauthorized** - Verification token mismatch
- **500 Internal Server Error** - Service crashed (check your logs)
- **Timeout** - Service not responding (check if running)

### Step 7: Manual Webhook Test

Use the test file to simulate a webhook:

1. **Edit test_webhook.bal:**
   - Replace `YOUR_TOKEN_HERE` with your verify token
   - Replace `YOUR_REALM_ID` with your QuickBooks company ID

2. **Run the test:**
   ```bash
   bal run test_webhook.bal
   ```

3. **Check service logs** - You should see:
   ```
   ###################################################################################################
   WEBHOOK RECEIVED FROM QUICKBOOKS
   ###################################################################################################
   ```

### Step 8: Check Config.toml

Verify all required fields are set:

```toml
# Salesforce
salesforceClientId = "..."
salesforceClientSecret = "..."
salesforceRefreshToken = "..."
salesforceRefreshUrl = "https://login.salesforce.com/services/oauth2/token"
salesforceBaseUrl = "https://yourinstance.salesforce.com"

# QuickBooks
quickbooksClientId = "..."
quickbooksClientSecret = "..."
quickbooksRefreshToken = "..."
quickbooksRealmId = "..."
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"

# Webhook
webhookPort = 8080
webhookVerifyToken = "..."

# Sync
conflictResolution = "SOURCE_WINS"
filterActiveOnly = true
createContact = false
```

### Step 9: Check Firewall/Network

- **Firewall:** Make sure port 8080 is open
- **Network:** If using ngrok, check it's running
- **VPN:** Some VPNs block webhook traffic

### Step 10: Enable Debug Logging

If still no logs, the issue is likely:

1. **Service not running** - Check terminal for errors
2. **Wrong URL** - QuickBooks is hitting a different endpoint
3. **Network issue** - Webhooks can't reach your service
4. **QuickBooks not sending** - Check webhook is active and subscribed to Customer entity

### Common Mistakes

❌ **Using localhost URL in QuickBooks** - QuickBooks can't reach localhost
✅ **Use ngrok or public domain**

❌ **Wrong webhook path** - `/webhook` instead of `/quickbooks/webhook`
✅ **Use `/quickbooks/webhook`**

❌ **HTTP instead of HTTPS** - QuickBooks requires HTTPS
✅ **Use HTTPS (ngrok provides this)**

❌ **Verify token mismatch** - Different tokens in QuickBooks and Config.toml
✅ **Use same token in both places**

❌ **Service not running** - Forgot to start with `bal run`
✅ **Always check service is running first**

### Still Not Working?

1. **Check service logs** - Any errors on startup?
2. **Check QuickBooks webhook logs** - Is QuickBooks sending webhooks?
3. **Check ngrok logs** - Is traffic reaching your service?
4. **Test health endpoint** - Is service responding at all?
5. **Check Config.toml** - Are all values correct?

### Success Indicators

When everything is working, you should see:

1. **On service start:**
   ```
   SERVICE READY - Waiting for webhooks...
   ```

2. **On customer create/update in QuickBooks:**
   ```
   ###################################################################################################
   WEBHOOK RECEIVED FROM QUICKBOOKS
   ###################################################################################################
   Processing webhook payload...
   Found 1 event notification
   Entity Type: Customer
   Entity ID: 123
   Operation: Create
   ✓ Customer entity with Create operation - will process
   Fetching full customer details from QuickBooks API...
   ✓ Successfully fetched customer: John Doe
   ...
   ================================================================================
   SYNC COMPLETED SUCCESSFULLY
   ================================================================================
   ```

If you see these logs, your integration is working! 🎉
