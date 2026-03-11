# Quick Start Guide

## Why No Webhooks When Service Starts?

**Webhooks are event-driven** - they only trigger when something changes in QuickBooks. Starting your service does NOT automatically trigger webhooks.

## How to Test the Integration

### 1. Start Your Service
```bash
bal run
```

**Expected output:**
```
###################################################################################################
QUICKBOOKS TO SALESFORCE SYNC SERVICE STARTING
###################################################################################################
Webhook Port: 8080
SERVICE READY - Waiting for webhooks...
###################################################################################################
```

✅ Service is now running and waiting for webhooks

### 2. Make Service Publicly Accessible

**Open a NEW terminal** and run:
```bash
ngrok http 8080
```

**Expected output:**
```
Forwarding  https://abc123.ngrok.io -> http://localhost:8080
```

✅ Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)

### 3. Configure QuickBooks Webhook

1. Go to https://developer.intuit.com
2. Select your app
3. Click "Webhooks" in the left menu
4. Enter webhook URL: `https://abc123.ngrok.io/quickbooks/webhook`
5. Enter verify token (same as in your Config.toml)
6. Check "Customer" entity
7. Click "Save"
8. Wait for status to show "Active" ✅

### 4. Trigger a Webhook

**Go to QuickBooks Online** (your actual QuickBooks account):

1. Click "Sales" → "Customers"
2. Click "New customer" OR click an existing customer
3. Make a change:
   - Add/change name
   - Add phone number
   - Add email
   - Any change works!
4. Click "Save"

### 5. Check Logs

**Within 1-5 seconds**, you should see in your service terminal:

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
================================================================================
STARTING SYNC FOR CUSTOMER: John Doe (ID: 123)
================================================================================
...
================================================================================
SYNC COMPLETED SUCCESSFULLY
================================================================================
Salesforce Account ID: 001XXXXXXXXXXXXXXX
```

✅ **Success!** Your integration is working!

## If You Don't See Logs

### Check 1: Is Service Running?
```bash
curl http://localhost:8080/quickbooks/health
```
Should return: `{"status":"UP",...}`

### Check 2: Is ngrok Running?
Open http://localhost:4040 in your browser
- Should show ngrok web interface
- Should show requests when you trigger webhooks

### Check 3: Did You Actually Change Something in QuickBooks?
- Webhooks only trigger on CREATE or UPDATE
- Just viewing a customer doesn't trigger a webhook
- You must SAVE a change

### Check 4: Is Webhook Active in QuickBooks?
Go to QuickBooks Developer Portal → Webhooks
- Status should show "Active" (green)
- If "Pending" or "Failed", fix the URL and verify token

### Check 5: Check QuickBooks Webhook Logs
Go to QuickBooks Developer Portal → Webhooks → Logs
- Should show delivery attempts
- Check response codes:
  - 200 = Success ✅
  - 404 = Wrong URL ❌
  - 401 = Wrong verify token ❌
  - 500 = Service error ❌

## Common Mistakes

❌ **Expecting webhooks when service starts**
- Webhooks only trigger on actual changes in QuickBooks

❌ **Using localhost URL in QuickBooks**
- QuickBooks can't reach localhost
- Must use ngrok HTTPS URL

❌ **Not actually changing anything in QuickBooks**
- Just viewing a customer doesn't trigger webhook
- Must create new customer or update existing one

❌ **Forgetting to save changes in QuickBooks**
- Changes must be saved to trigger webhook

❌ **Wrong webhook URL**
- Must be: `https://your-ngrok-url/quickbooks/webhook`
- NOT: `/webhook` or `/quickbooks` alone

## Testing Without QuickBooks

If you want to test without QuickBooks, use the test file:

1. Edit `test_webhook.bal`:
   - Replace `YOUR_TOKEN_HERE` with your verify token
   - Replace `YOUR_REALM_ID` with your QuickBooks company ID

2. Run:
   ```bash
   bal run test_webhook.bal
   ```

This will send a test webhook to your service.

## Next Steps

Once you see successful logs:

1. ✅ Create more customers in QuickBooks
2. ✅ Update existing customers
3. ✅ Check Salesforce to see synced accounts
4. ✅ Test parent-child relationships (sub-customers)
5. ✅ Monitor logs for any errors

## Need Help?

See `TROUBLESHOOTING.md` for detailed debugging steps.
