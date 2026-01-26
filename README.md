# myblueboard_admin

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


### Test iOS Flutter App

<code>flutter run -d "iPhone 17 Pro"</code>
<code>flutter run -d macos</code>

### Build Release for macos
<code>flutter clean</code>
<code>flutter build macos --release</code>

### Deploy to iPhone 
<code>cd /Users/patrickodonnell/Git/myblueboard-admin && flutter run --release -d judoPhone</code>



"VerificationToken": "syYn5X3wEu20T3qDct6BpHYWTqeALk6WCRaTVd1Q4Qg=" # Note the verification token returned - add this as TXT record in DNS

aws ses create-receipt-rule \
  --rule-set-name support-tickets-ruleset \
  --rule '{
    "Name": "support-email-rule",
    "Enabled": true,
    "TlsPolicy": "Optional",
    "Recipients": ["support@myblueboard.com"],
    "Actions": [
      {
        "SNSAction": {
          "TopicArn": "arn:aws:sns:us-east-1:580250537123:support-email-notifications",
          "Encoding": "UTF-8"
        }
      }
    ],
    "ScanEnabled": true
  }' \
  --region us-east-1


  aws route53 change-resource-record-sets \
  --hosted-zone-id /hostedzone/Z084383137NHG9SJ6RRN1 \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "myblueboard.com",
        "Type": "MX",
        "TTL": 300,
        "ResourceRecords": [{"Value": "10 inbound-smtp.us-east-1.amazonaws.com"}]
      }
    }]
  }'