# Production Deployment Checklist

## ✅ Code Quality
- [x] No compilation errors
- [x] Proper error handling on all API calls
- [x] SOQL injection prevention (single quote escaping)
- [x] Comprehensive logging
- [x] Loop prevention implemented
- [x] OAuth 2.0 with auto-refresh

## ⚠️ Configuration Required

### Salesforce
- [ ] Create Connected App
- [ ] Generate OAuth credentials (Client ID, Secret, Refresh Token)
- [ ] Verify API access permissions
- [ ] Test connection with credentials

### QuickBooks
- [ ] Create app in Developer Portal
- [ ] Generate OAuth credentials (Client ID, Secret, Refresh Token)
- [ ] Get Company/Realm ID
- [ ] Configure webhook subscriptions for Customer entity
- [ ] Set webhook URL to your public endpoint
- [ ] Generate and configure webhook verify token

### Infrastructure
- [ ] Deploy to server with public HTTPS endpoint
- [ ] Configure firewall to allow inbound webhook traffic
- [ ] Set up SSL/TLS certificate
- [ ] Configure environment variables or Config.toml
- [ ] Set up log aggregation/monitoring
- [ ] Configure alerts for errors

## 🔒 Security Checklist

- [ ] Store credentials in secure secrets manager (not in code)
- [ ] Use HTTPS for all webhook endpoints
- [ ] Validate webhook verify token on all requests
- [ ] Rotate OAuth tokens regularly
- [ ] Restrict API permissions to minimum required
- [ ] Enable audit logging
- [ ] Review and limit network access

## 📊 Monitoring & Observability

- [ ] Set up log monitoring (e.g., ELK, Splunk, CloudWatch)
- [ ] Create alerts for:
  - Failed syncs
  - Authentication errors
  - Webhook delivery failures
  - High error rates
- [ ] Monitor API rate limits:
  - QuickBooks: 500 requests/minute
  - Salesforce: Varies by edition
- [ ] Set up health check monitoring
- [ ] Create dashboard for sync metrics

## 🧪 Testing

### Pre-Production Testing
- [ ] Test with sandbox/dev environments first
- [ ] Verify webhook delivery
- [ ] Test customer create scenario
- [ ] Test customer update scenario
- [ ] Test sub-customer (parent-child) scenario
- [ ] Test parent removal scenario
- [ ] Test loop prevention (update from QuickBooks after ID saved)
- [ ] Test with customers containing special characters (quotes, etc.)
- [ ] Test conflict resolution strategies
- [ ] Test with inactive customers (if filterActiveOnly = true)

### Load Testing
- [ ] Test with bulk customer updates
- [ ] Verify performance under load
- [ ] Check memory usage
- [ ] Monitor API rate limit consumption

## 🚀 Deployment Steps

1. **Build the application**
   ```bash
   bal build
   ```

2. **Deploy to production server**
   - Copy executable to server
   - Set up Config.toml with production credentials
   - Configure as system service (systemd, etc.)

3. **Start the service**
   ```bash
   bal run
   ```

4. **Verify deployment**
   - Check health endpoint: `GET https://your-domain.com/quickbooks/health`
   - Verify webhook endpoint: `GET https://your-domain.com/quickbooks/webhook?verifyToken=YOUR_TOKEN`

5. **Configure QuickBooks webhooks**
   - Set webhook URL in QuickBooks Developer Portal
   - Subscribe to Customer entity events
   - Test webhook delivery

6. **Monitor initial syncs**
   - Watch logs for first few syncs
   - Verify data in Salesforce
   - Check custom field population in QuickBooks

## 📝 Configuration Values

### Required Config.toml Values
```toml
# Salesforce
salesforceClientId = "?"
salesforceClientSecret = "?"
salesforceRefreshToken = "?"
salesforceRefreshUrl = "https://login.salesforce.com/services/oauth2/token"
salesforceBaseUrl = "https://yourinstance.salesforce.com"

# QuickBooks
quickbooksClientId = "?"
quickbooksClientSecret = "?"
quickbooksRefreshToken = "?"
quickbooksRealmId = "?"
quickbooksBaseUrl = "https://quickbooks.api.intuit.com/v3/company"  # Production
# quickbooksBaseUrl = "https://sandbox-quickbooks.api.intuit.com/v3/company"  # Sandbox

# Webhook
webhookPort = 8080
webhookVerifyToken = "?"

# Sync Settings
conflictResolution = "SOURCE_WINS"
filterActiveOnly = true
createContact = false
saveSalesforceIdToQuickBooks = true
quickbooksCustomFieldName = "Salesforce Account ID"
```

## 🔧 Troubleshooting

### Common Issues

**Webhook not receiving events**
- Verify URL is publicly accessible
- Check firewall rules
- Verify webhook subscriptions in QuickBooks
- Check webhook verify token matches

**Authentication errors**
- Refresh tokens may expire - regenerate
- Verify client IDs and secrets
- Check OAuth scopes

**Custom field errors**
- Manually create field in QuickBooks if auto-creation fails
- Verify field name matches configuration exactly
- Check field is enabled for Customers

**Duplicate accounts**
- Ensure saveSalesforceIdToQuickBooks = true
- Verify custom field is being populated
- Check loop prevention logs

**Rate limit errors**
- Implement exponential backoff
- Monitor API usage
- Consider batching if needed

## 📞 Support Contacts

- QuickBooks API Support: https://help.developer.intuit.com/
- Salesforce API Support: https://help.salesforce.com/
- Ballerina Documentation: https://ballerina.io/learn/

## 🎯 Success Criteria

- [ ] Webhooks are being received successfully
- [ ] Customers sync to Salesforce within 5 seconds of QuickBooks update
- [ ] Salesforce Account IDs are saved back to QuickBooks
- [ ] No duplicate accounts are created
- [ ] Parent-child relationships are maintained
- [ ] Loop prevention is working (no infinite cycles)
- [ ] Error rate < 1%
- [ ] All logs are being captured
- [ ] Monitoring alerts are configured and working

## 📅 Post-Deployment

- [ ] Monitor for 24 hours
- [ ] Review error logs
- [ ] Verify data accuracy in Salesforce
- [ ] Check custom field population in QuickBooks
- [ ] Document any issues and resolutions
- [ ] Schedule regular OAuth token rotation
- [ ] Plan for disaster recovery/backup
