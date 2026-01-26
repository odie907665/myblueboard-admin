class SupportTicket {
  final int id;
  final String ticketId;
  final String subject;
  final String customerEmail;
  final String? customerName;
  final String status;
  final String priority;
  final int? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<TicketMessage> messages;
  final int messageCount;
  final DateTime lastMessageAt;
  final String timeSinceCreated;

  SupportTicket({
    required this.id,
    required this.ticketId,
    required this.subject,
    required this.customerEmail,
    this.customerName,
    required this.status,
    required this.priority,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    required this.messages,
    required this.messageCount,
    required this.lastMessageAt,
    required this.timeSinceCreated,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      ticketId: json['ticket_id'],
      subject: json['subject'],
      customerEmail: json['customer_email'],
      customerName: json['customer_name'],
      status: json['status'],
      priority: json['priority'],
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      messages:
          (json['messages'] as List?)
              ?.map((msg) => TicketMessage.fromJson(msg))
              .toList() ??
          [],
      messageCount: json['message_count'] ?? 0,
      lastMessageAt: DateTime.parse(json['last_message_at']),
      timeSinceCreated: json['time_since_created'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'subject': subject,
      'customer_email': customerEmail,
      'customer_name': customerName,
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'message_count': messageCount,
      'last_message_at': lastMessageAt.toIso8601String(),
      'time_since_created': timeSinceCreated,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'new':
        return 'New';
      case 'open':
        return 'Open';
      case 'pending':
        return 'Pending';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }
}

class TicketMessage {
  final int id;
  final int ticket;
  final String fromEmail;
  final String fromName;
  final String fromNameDisplay;
  final String messageType;
  final String bodyText;
  final String bodyHtml;
  final int? createdBy;
  final DateTime createdAt;
  final String? messageId;
  final String? inReplyTo;

  TicketMessage({
    required this.id,
    required this.ticket,
    required this.fromEmail,
    required this.fromName,
    required this.fromNameDisplay,
    required this.messageType,
    required this.bodyText,
    required this.bodyHtml,
    this.createdBy,
    required this.createdAt,
    this.messageId,
    this.inReplyTo,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'],
      ticket: json['ticket'],
      fromEmail: json['from_email'],
      fromName: json['from_name'] ?? '',
      fromNameDisplay: json['from_name_display'] ?? '',
      messageType: json['message_type'],
      bodyText: json['body_text'] ?? '',
      bodyHtml: json['body_html'] ?? '',
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      messageId: json['message_id'],
      inReplyTo: json['in_reply_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket': ticket,
      'from_email': fromEmail,
      'from_name': fromName,
      'from_name_display': fromNameDisplay,
      'message_type': messageType,
      'body_text': bodyText,
      'body_html': bodyHtml,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'message_id': messageId,
      'in_reply_to': inReplyTo,
    };
  }

  bool get isStaffMessage => messageType == 'staff';
  bool get isCustomerMessage => messageType == 'customer';
  bool get isSystemMessage => messageType == 'system';
}
