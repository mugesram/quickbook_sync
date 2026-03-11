# Config.toml Template

Copy this content to create your `Config.toml` file:

```toml
# ============================================
# Salesforce Configuration
# ============================================
salesforceClientId = "YOUR_SALESFORCE_CLIENT_ID"
salesforceClientSecret = "YOUR_SALESFORCE_CLIENT_SECRET"
salesforceRefreshToken = "YOUR_SALESFORCE_REFRESH_TOKEN"
salesforceRefreshUrl = "https://login.salesforce.com/services/oauth2/token"
salesforceBaseUrl = "https://YOUR_INSTANCE.salesforce.com"

# ============================================
# QuickBooks API Configuration
# ============================================
quickbooksClientId = "YOUR_QUICKBOOKS_CLIENT_ID"
quickbooksClientSecret = "YOUR_QUICKBOOKS_CLIENT_SECRET"
quickbooksRefreshToken = "YOUR_QUICKBOOKS_REFRESH_TOKEN"
quickbooksRealmId = "YOUR_QUICKBOOKS_REALM_ID"

# IMPORTANT: QuickBooks Base URL - REQUIRED
# Choose ONE based on your environment:

# For Sandbox (Testing):
quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"

# For Production (Live Data) - Uncomment and comment out sandbox URL above:
# quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"

# Token URL (same for both sandbox and production)
quickbooksTokenUrl = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"

# ============================================
# QuickBooks Webhook Configuration
# ============================================
webhookPort = 8080
webhookVerifyToken = "YOUR_WEBHOOK_VERIFY_TOKEN"

# ============================================
# Sync Configuration
# ============================================
# Conflict Resolution: SOURCE_WINS, DESTINATION_WINS, or MOST_RECENT
conflictResolution = "SOURCE_WINS"

# Filter Settings
filterActiveOnly = true
createContact = false

# Duplicate Match Strategy: MATCH_BY_EMAIL, MATCH_BY_NAME, or MATCH_BY_EXTERNAL_ID
duplicateMatchStrategy = "MATCH_BY_EMAIL"
```

## Important Notes

### QuickBooks Base URL - REQUIRED

The `quickbooksBaseUrl` **MUST** be set in your `Config.toml`. There is no default value.

**Sandbox vs Production:**

| Environment | Base URL |
|------------|----------|
| **Sandbox** (Testing) | `https://sandbox-quickbooks.api.intuit.com/v3/company` |
| **Production** (Live) | `https://quickbooks.api.intuit.com/v3/company` |

**Important:** Make sure your OAuth credentials match the environment:
- Sandbox credentials → Use sandbox URL
- Production credentials → Use production URL

Mismatched credentials and URLs will cause **403 Forbidden** errors.

## Quick Setup Steps

1. Copy the template above
2. Create a file named `Config.toml` in your project root
3. Paste the template
4. Replace all `YOUR_*` placeholders with actual values
5. Choose sandbox or production URL
6. Save the file
7. Run `bal run`

## Verification

After creating your `Config.toml`, verify it's correct:

```bash
# Start the service
bal run

# Check configuration
curl http://localhost:8080/diagnostics
```

All values should show `true` if configured correctly.
