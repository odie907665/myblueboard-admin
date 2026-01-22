import 'package:flutter/material.dart';
import '../widgets/admin_scaffold.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

class ComposeEmailScreen extends StatefulWidget {
  final List<String> toEmails;
  final String? subject;

  const ComposeEmailScreen({super.key, required this.toEmails, this.subject});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSending = false;
  List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _toController.text = widget.toEmails.join(', ');
    _subjectController.text = widget.subject ?? '';
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Parse email addresses from the to field
      final toEmails = _toController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Prepare attachments
      List<Map<String, String>>? attachmentData;
      if (_attachments.isNotEmpty) {
        attachmentData = [];
        for (var file in _attachments) {
          if (file.bytes != null) {
            final base64Content = base64Encode(file.bytes!);
            attachmentData.add({
              'filename': file.name,
              'content_base64': base64Content,
            });
          }
        }
      }

      // Send email via API
      final success = await _apiService.sendEmail(
        toEmails: toEmails,
        subject: _subjectController.text,
        body: _bodyController.text,
        attachments: attachmentData,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send email. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true, // Important: This loads the file bytes
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Compose Email',
      selectedIndex: 1,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Modern Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF001b3f), Color(0xFF004aad)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compose New Email',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Send a message to admin users',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // To Field with modern styling
                          Text(
                            'Recipients',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[300],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _toController,
                            decoration: InputDecoration(
                              hintText:
                                  'Enter recipient email addresses (comma-separated)',
                              prefixIcon: const Icon(
                                Icons.people_outline,
                                color: Color(0xFF004aad),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF004aad),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter at least one recipient';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Subject Field with modern styling
                          Text(
                            'Subject',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[300],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _subjectController,
                            decoration: InputDecoration(
                              hintText: 'What is this email about?',
                              prefixIcon: const Icon(
                                Icons.subject_outlined,
                                color: Color(0xFF004aad),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF004aad),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a subject';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Body Field with modern styling
                          Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[300],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _bodyController,
                            decoration: InputDecoration(
                              hintText: 'Type your message here...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF004aad),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                            maxLines: 12,
                            minLines: 12,
                            textAlignVertical: TextAlignVertical.top,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a message';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Attachments Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Attachments',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[300],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickFiles,
                                icon: const Icon(Icons.attach_file, size: 18),
                                label: const Text('Add Files'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF004aad),
                                  side: const BorderSide(
                                    color: Color(0xFF004aad),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Attachments List
                          if (_attachments.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _attachments.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, color: Colors.grey[300]),
                                itemBuilder: (context, index) {
                                  final file = _attachments[index];
                                  final sizeInKB = (file.size / 1024)
                                      .toStringAsFixed(1);
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF004aad,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.insert_drive_file,
                                        color: Color(0xFF004aad),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '$sizeInKB KB',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeAttachment(index),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.attachment,
                                    size: 18,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'No attachments',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Modern Footer with actions
                Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[50]
                        : Colors.grey[900],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[200]!
                            : Colors.grey[800]!,
                      ),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      if (isMobile) {
                        // Mobile layout - stacked vertically
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Info text
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${widget.toEmails.length} recipient${widget.toEmails.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSending
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Cancel'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton.icon(
                                    onPressed: _isSending ? null : _sendEmail,
                                    icon: _isSending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 16,
                                          ),
                                    label: Text(
                                      _isSending ? 'Sending...' : 'Send',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF004aad),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      // Desktop layout - horizontal
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Info text
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your email will be sent to ${widget.toEmails.length} recipient${widget.toEmails.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Action buttons
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isSending
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: _isSending ? null : _sendEmail,
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: Text(
                                  _isSending ? 'Sending...' : 'Send Email',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF004aad),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
