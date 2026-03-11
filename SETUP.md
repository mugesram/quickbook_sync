# QuickBooks to Salesforce Sync - Setup Guide

## Problem Fixed

The webhook error has been resolved. The issue was that QuickBooks webhooks only send minimal entity metadata (id, operation, name), not the full customer data. The code was trying to convert this minimal data directly to a `QuickBooksCustomer` record, causing the conversion error.

## Solution Implemented

1. **Created `quickbooks_api.bal`** - Contains `fetchQuickBooksCustomerDetails()` function with proper OAuth 2.0
2. **Updated `main.bal`** - Now fetches full customer data instead of converting webhook entity
3. **Added configuration** - QuickBooks OAuth credentials in `config.bal`
4. **Proper OAuth 2.0** - Automatic token refresh (tokens expire every 1 hour)

## QuickBooks Connection - PROPERLY CONFIGURED ✓

The QuickBooks client is now **correctly configured** with:
- ✅ OAuth 2.0 Refresh Token Grant
- ✅ Automatic token refresh (handles 1-hour expiration)
- ✅ Similar to Salesforce connection pattern
- ✅ Production-ready implementation

## Salesforce Setup

⚠️ **Important:** The integration uses standard Salesforce fields by default (no custom fields required).

📖 **For Salesforce field setup and custom field creation, see [SALESFORCE_SETUP.md](SALESFORCE_SETUP.md)**

## Configuration Required

Create a `Config.toml` file with the following values:

```toml
# Salesforce Configuration
salesforceClientId = "YOUR_SALESFORCE_CLIENT_ID"
salesforceClientSecret = "YOUR_SALESFORCE_CLIENT_SECRET"
salesforceRefreshToken = "YOUR_SALESFORCE_REFRESH_TOKEN"
salesforceRefreshUrl = "https://login.salesforce.com/services/oauth2/token"
salesforceBaseUrl = "https://YOUR_INSTANCE.salesforce.com"

# QuickBooks API Configuration (OAuth 2.0)
quickbooksClientId = "YOUR_QUICKBOOKS_CLIENT_ID"
quickbooksClientSecret = "YOUR_QUICKBOOKS_CLIENT_SECRET"
quickbooksRefreshToken = "YOUR_QUICKBOOKS_REFRESH_TOKEN"
quickbooksRealmId = "YOUR_COMPANY_ID"

# QuickBooks Base URL - REQUIRED: Choose sandbox or production
# For Sandbox (testing):
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"
# For Production (live data):
# quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"

quickbooksTokenUrl = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"

# QuickBooks Webhook Configuration
webhookPort = 8080
webhookVerifyToken = "YOUR_WEBHOOK_VERIFY_TOKEN"

# Sync Configuration
conflictResolution = "SOURCE_WINS"
filterActiveOnly = true
createContact = false
duplicateMatchStrategy = "MATCH_BY_EMAIL"
```

## How to Get QuickBooks OAuth Credentials

1. **Create QuickBooks App**: Go to https://developer.intuit.com/
2. **Get Client ID & Secret**: From your app's Keys & OAuth section
3. **Get Refresh Token**: Use OAuth 2.0 Playground or implement OAuth flow
4. **Get Realm ID**: Your QuickBooks Company ID (found in app settings)

## How It Works Now

1. **Webhook Received** → QuickBooks sends minimal entity data (id, operation, name)
2. **Extract Customer ID** → Code extracts the customer ID and realm ID
3. **Fetch Full Data** → Calls QuickBooks API via `fetchQuickBooksCustomerDetails()` to get complete customer record
4. **Auto Token Refresh** → HTTP client automatically refreshes expired tokens
5. **Sync to Salesforce** → Maps and syncs the full customer data to Salesforce

## Connection Architecture

```
QuickBooks Webhook → Your Service → QuickBooks API (OAuth 2.0) → Fetch Customer
                                  ↓
                            Salesforce API (OAuth 2.0) → Sync Account/Contact
```

Both connections use OAuth 2.0 with automatic token refresh - production ready!
