import 'package:flutter/material.dart';
import '../models/support_ticket.dart';
import '../services/ticket_service.dart';
import '../widgets/admin_scaffold.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final TicketService _ticketService = TicketService();
  List<SupportTicket> tickets = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedStatus = 'all';
  String selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedTickets = await _ticketService.getTickets(
        status: selectedStatus != 'all' ? selectedStatus : null,
        priority: selectedPriority != 'all' ? selectedPriority : null,
      );

      if (mounted) {
        setState(() {
          tickets = fetchedTickets;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'open':
        return Colors.orange;
      case 'pending':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'urgent':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedIndex: 4, // Adjust based on your menu structure
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Support Tickets',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadTickets,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                // Status Filter
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Statuses'),
                      ),
                      DropdownMenuItem(value: 'new', child: Text('New')),
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Resolved'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                        _loadTickets();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Priority Filter
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Priorities'),
                      ),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPriority = value;
                        });
                        _loadTickets();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading tickets',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tickets found',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticketId: ticket.id),
            ),
          ).then((_) => _loadTickets()); // Refresh after returning
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Ticket ID
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.ticketId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ticket.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(ticket.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ticket.statusDisplay,
                      style: TextStyle(
                        color: _getStatusColor(ticket.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        ticket.priority,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor(ticket.priority),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ticket.priorityDisplay,
                      style: TextStyle(
                        color: _getPriorityColor(ticket.priority),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Time
                  Text(
                    ticket.timeSinceCreated,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject
              Text(
                ticket.subject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // Customer info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    ticket.customerName ?? ticket.customerEmail,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    ticket.customerEmail,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer row
              Row(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket.messageCount} message${ticket.messageCount != 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (ticket.assignedToName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.assignment_ind,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.assignedToName!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _replyController = TextEditingController();
  SupportTicket? ticket;
  bool isLoading = true;
  String? errorMessage;
  bool isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedTicket = await _ticketService.getTicket(widget.ticketId);

      if (mounted) {
        setState(() {
          ticket = fetchedTicket;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      setState(() {
        isSendingReply = true;
      });

      await _ticketService.addMessage(widget.ticketId, _replyController.text);
      _replyController.clear();

      // Reload ticket to show new message
      await _loadTicket();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
        setState(() {
          isSendingReply = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
        setState(() {
          isSendingReply = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _ticketService.updateTicket(widget.ticketId, status: newStatus);
      await _loadTicket();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.ticketId ?? 'Loading...'),
        actions: [
          if (ticket != null && ticket!.status != 'closed')
            PopupMenuButton<String>(
              onSelected: _updateStatus,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'new', child: Text('Mark as New')),
                const PopupMenuItem(value: 'open', child: Text('Mark as Open')),
                const PopupMenuItem(
                  value: 'pending',
                  child: Text('Mark as Pending'),
                ),
                const PopupMenuItem(
                  value: 'resolved',
                  child: Text('Mark as Resolved'),
                ),
                const PopupMenuItem(
                  value: 'closed',
                  child: Text('Close Ticket'),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : _buildTicketDetail(),
    );
  }

  Widget _buildTicketDetail() {
    if (ticket == null) return const SizedBox();

    return Column(
      children: [
        // Ticket Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket!.subject,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('From: ${ticket!.customerName ?? ticket!.customerEmail}'),
              Text('Email: ${ticket!.customerEmail}'),
              Text('Status: ${ticket!.statusDisplay}'),
              Text('Priority: ${ticket!.priorityDisplay}'),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ticket!.messages.length,
            itemBuilder: (context, index) {
              final message = ticket!.messages[index];
              return _buildMessageCard(message);
            },
          ),
        ),

        // Reply Box
        if (ticket!.status != 'closed')
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your reply...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isSendingReply ? null : _sendReply,
                  icon: isSendingReply
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMessageCard(TicketMessage message) {
    final isStaff = message.isStaffMessage;

    return Align(
      alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Card(
          color: isStaff ? Colors.blue[50] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.fromNameDisplay,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(message.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(message.bodyText),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
