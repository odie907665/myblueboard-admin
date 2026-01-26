# Support Ticketing System Setup Guide

## Summary
A complete support ticketing system that converts emails sent to support@myblueboard.com into tickets viewable in the myblueboard-admin Flutter app.

## Architecture
- **Email Flow**: support@myblueboard.com → Google Workspace forward → support@support.myblueboard.com → AWS SES → SNS → Django webhook → Database
- **Backend**: Django REST API in myblueboard project
- **Frontend**: Flutter admin app

## What Was Created

### Django Backend (myblueboard project)

1. **Models** (`/api/models.py`):
   - `SupportTicket`: Main ticket model with status, priority, customer info
   - `TicketMessage`: Individual messages/replies within tickets

2. **Views** (`/api/support_ticket_views.py`):
   - `ses_email_webhook`: Webhook endpoint for AWS SNS/SES emails
   - `SupportTicketViewSet`: REST API for ticket CRUD operations
   - `TicketMessageViewSet`: REST API for viewing messages

3. **Serializers** (`/api/serializer.py`):
   - `SupportTicketSerializer`
   - `TicketMessageSerializer`

4. **URLs** (`/api/urls.py`):
   - `/api/support-tickets/` - List/create tickets
   - `/api/support-tickets/{id}/` - Ticket detail/update
   - `/api/support-tickets/{id}/add_message/` - Add staff reply
   - `/api/support-tickets/{id}/assign/` - Assign ticket
   - `/api/support-tickets/{id}/close/` - Close ticket
   - `/api/tickets/webhook/email/` - SNS webhook (no auth)

5. **Admin** (`/api/admin.py`):
   - Admin interface for managing tickets

### Flutter Frontend (myblueboard-admin project)

1. **Models** (`/lib/models/support_ticket.dart`):
   - `SupportTicket` class
   - `TicketMessage` class

2. **Service** (`/lib/services/ticket_service.dart`):
   - API methods for all ticket operations

3. **UI** (`/lib/screens/support_tickets_screen.dart`):
   - Ticket list view with filters
   - Ticket detail view with message history
   - Reply interface

## Setup Steps

### 1. Django Database Migration
```bash
cd /path/to/myblueboard
python manage.py makemigrations api
python manage.py migrate api
```

### 2. SNS Subscription
Subscribe your Django webhook to the SNS topic:
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:580250537123:support-email-notifications \
  --protocol https \
  --notification-endpoint https://signup.myblueboard.com/api/tickets/webhook/email/ \
  --region us-east-1
```

**Important**: After running this, AWS will send a confirmation request to your webhook. The webhook will automatically confirm it when it receives the first POST.

### 3. Deploy Django Code
Deploy the updated Django code to your production server (signup.myblueboard.com).

### 4. Google Workspace Email Forwarding
Set up forwarding in Google Workspace:

**Option A: Gmail forwarding** (if support@ is a Gmail account)
1. Log into support@myblueboard.com
2. Settings → Forwarding and POP/IMAP
3. Add forwarding address: support@support.myblueboard.com
4. Confirm and enable

**Option B: Routing rule** (recommended for Google Workspace)
1. Admin Console → Apps → Google Workspace → Gmail
2. Routing → Add another rule
3. From: support@myblueboard.com
4. Forward to: support@support.myblueboard.com

### 5. Test Email Flow
Send a test email to support@myblueboard.com and verify:
1. Email arrives at support@support.myblueboard.com
2. SNS webhook is triggered
3. Ticket is created in Django admin
4. Ticket appears in Flutter app

### 6. Add Tickets to Flutter App Navigation
Update your AdminScaffold navigation to include the Support Tickets screen:

```dart
// In your navigation menu
ListTile(
  leading: const Icon(Icons.support_agent),
  title: const Text('Support Tickets'),
  selected: selectedIndex == 4,
  onTap: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportTicketsScreen(),
      ),
    );
  },
),
```

## AWS Resources Created
- SNS Topic: `arn:aws:sns:us-east-1:580250537123:support-email-notifications`
- SES Receipt Rule Set: `support-tickets-ruleset`
- SES Receipt Rule: `support-email-rule`
- SES Domain Verified: `myblueboard.com`
- Route53 MX Record: `support.myblueboard.com` → SES

## API Endpoints

### Public (No Auth Required)
- `POST /api/tickets/webhook/email/` - SNS webhook for incoming emails

### Authenticated (JWT Required)
- `GET /api/support-tickets/` - List tickets
  - Query params: `status`, `priority`, `assigned_to`
- `GET /api/support-tickets/{id}/` - Get ticket detail
- `PATCH /api/support-tickets/{id}/` - Update ticket
- `POST /api/support-tickets/{id}/add_message/` - Add staff reply
- `POST /api/support-tickets/{id}/assign/` - Assign/unassign ticket
- `POST /api/support-tickets/{id}/close/` - Close ticket
- `GET /api/ticket-messages/?ticket_id={ticket_id}` - Get messages for ticket

## Features

### Current
- ✅ Email-to-ticket conversion
- ✅ Automatic ticket ID generation
- ✅ Status management (new, open, pending, resolved, closed)
- ✅ Priority levels (low, medium, high, urgent)
- ✅ Staff replies
- ✅ Ticket assignment
- ✅ Message threading
- ✅ Flutter admin UI

### Future Enhancements
- Email notifications when staff replies
- File attachments support
- Ticket search
- Ticket tags/categories
- SLA tracking
- Canned responses
- Knowledge base integration

## Security Notes
1. The webhook endpoint (`/api/tickets/webhook/email/`) is public (no auth) to allow SNS to post
2. SNS signature verification is implemented but simplified - enhance for production
3. All other endpoints require JWT authentication
4. Webhook should verify requests are from AWS SNS

## Troubleshooting

### Emails not creating tickets
1. Check Django logs for webhook errors
2. Verify SNS subscription is confirmed
3. Check SES receipt rules are active
4. Test with AWS SES test email

### Flutter app not loading tickets
1. Verify API endpoints are accessible
2. Check JWT token is valid
3. Look for CORS issues
4. Check network logs in Flutter DevTools

### Replies not working
1. Verify user is authenticated
2. Check ticket status (can't reply to closed tickets)
3. Verify API endpoint URL is correct

## Cost Estimate (AWS)
- SES: Free for first 1,000 emails received per month
- SNS: First 1,000 publishes free, then $0.50 per million
- Route53: $0.50/month per hosted zone (already have this)
- **Total additional cost**: ~$0-5/month for typical support volume

## Next Steps
1. Run Django migrations
2. Deploy to production
3. Subscribe SNS webhook
4. Set up Google Workspace forwarding
5. Test end-to-end flow
6. Add navigation to Flutter app
7. Train staff on ticket system
