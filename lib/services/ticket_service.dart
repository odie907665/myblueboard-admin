import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket.dart';
import '../models/ticket_category.dart';
import '../models/ticket_tag.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService = ApiService();

  static String get baseUrl =>
      '${ApiConfig.baseUrl}/api/admin/support-tickets/';

  Map<String, String> _getHeaders() {
    final headers = _apiService.getAuthHeaders();
    // Explicitly set Accept header to ensure JSON response
    headers['Accept'] = 'application/json';
    return headers;
  }

  Future<List<SupportTicket>> getTickets({
    String? status,
    String? priority,
    String? assignedTo,
  }) async {
    try {
      var url = baseUrl;
      final params = <String, String>{};

      if (status != null) params['status'] = status;
      if (priority != null) params['priority'] = priority;
      if (assignedTo != null) params['assigned_to'] = assignedTo;

      if (params.isNotEmpty) {
        url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      // Use a fresh client to avoid cookie persistence issues
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse(url),
          headers: _getHeaders(),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => SupportTicket.fromJson(json)).toList();
        } else {
          throw Exception(
            'Failed to load tickets: ${response.statusCode} - ${response.body}',
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  Future<SupportTicket> getTicket(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$id/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return SupportTicket.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load ticket');
      }
    } catch (e) {
      throw Exception('Failed to fetch ticket: $e');
    }
  }

  Future<SupportTicket> updateTicket(
    int id, {
    String? status,
    String? priority,
    int? assignedTo,
    List<int>? categoryIds,
    List<int>? tagIds,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (assignedTo != null) body['assigned_to'] = assignedTo;
      if (categoryIds != null) body['category_ids'] = categoryIds;
      if (tagIds != null) body['tag_ids'] = tagIds;

      final response = await http.patch(
        Uri.parse('$baseUrl$id/'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return SupportTicket.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update ticket');
      }
    } catch (e) {
      throw Exception('Failed to update ticket: $e');
    }
  }

  Future<TicketMessage> addMessage(
    int ticketId,
    String bodyText, {
    String? bodyHtml,
    bool sendToUser = false,
    List<String>? filePaths,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$ticketId/messages/');
      final request = http.MultipartRequest('POST', uri);

      // Add headers (get auth headers from _getHeaders which uses ApiService)
      final headers = _getHeaders();
      request.headers.addAll(headers);

      // Add text fields
      request.fields['body_text'] = bodyText;
      request.fields['body_html'] = bodyHtml ?? bodyText;
      request.fields['send_to_user'] = sendToUser.toString();

      // Add file attachments
      if (filePaths != null && filePaths.isNotEmpty) {
        for (final filePath in filePaths) {
          final file = await http.MultipartFile.fromPath(
            'attachments',
            filePath,
          );
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return TicketMessage.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add message');
      }
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  Future<TicketMessage> editMessage(
    int ticketId,
    int messageId,
    String bodyText, {
    String? bodyHtml,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/support-tickets/$ticketId/messages/$messageId/',
        ),
        headers: _getHeaders(),
        body: jsonEncode({
          'body_text': bodyText,
          'body_html': bodyHtml ?? bodyText,
        }),
      );

      if (response.statusCode == 200) {
        return TicketMessage.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to edit message');
      }
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessage(int ticketId, int messageId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/admin/support-tickets/$ticketId/messages/$messageId/',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> assignTicket(int ticketId, int? userId) async {
    try {
      final body = userId != null ? {'user_id': userId} : {};

      final response = await http.post(
        Uri.parse('$baseUrl/$ticketId/assign/'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to assign ticket');
      }
    } catch (e) {
      throw Exception('Failed to assign ticket: $e');
    }
  }

  Future<SupportTicket> closeTicket(int ticketId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$ticketId/close/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return SupportTicket.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to close ticket');
      }
    } catch (e) {
      throw Exception('Failed to close ticket: $e');
    }
  }

  Future<void> deleteTicket(int ticketId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/support-tickets/$ticketId/'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete ticket');
      }
    } catch (e) {
      throw Exception('Failed to delete ticket: $e');
    }
  }

  Future<List<TicketMessage>> getTicketMessages(String ticketId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/ticket-messages/?ticket_id=$ticketId',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TicketMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<List<TicketCategory>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-categories/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TicketCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<List<TicketTag>> getTags() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-tags/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TicketTag.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tags');
      }
    } catch (e) {
      throw Exception('Failed to fetch tags: $e');
    }
  }

  Future<TicketCategory> createCategory(
    String name,
    String description,
    String color,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-categories/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'color': color,
        }),
      );

      if (response.statusCode == 201) {
        return TicketCategory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<TicketCategory> updateCategory(
    int id,
    String name,
    String description,
    String color,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-categories/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'id': id,
          'name': name,
          'description': description,
          'color': color,
        }),
      );

      if (response.statusCode == 200) {
        return TicketCategory.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-categories/?id=$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Future<TicketTag> createTag(String name, String color) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-tags/'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'color': color}),
      );

      if (response.statusCode == 201) {
        return TicketTag.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create tag');
      }
    } catch (e) {
      throw Exception('Failed to create tag: $e');
    }
  }

  Future<TicketTag> updateTag(int id, String name, String color) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-tags/'),
        headers: _getHeaders(),
        body: jsonEncode({'id': id, 'name': name, 'color': color}),
      );

      if (response.statusCode == 200) {
        return TicketTag.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update tag');
      }
    } catch (e) {
      throw Exception('Failed to update tag: $e');
    }
  }

  Future<void> deleteTag(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/ticket-tags/?id=$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete tag');
      }
    } catch (e) {
      throw Exception('Failed to delete tag: $e');
    }
  }

  /// Register device token for push notifications
  Future<void> registerDeviceToken(String token, String platform) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/register-device/'),
        headers: _getHeaders(),
        body: jsonEncode({
          'device_token': token,
          'platform': platform, // 'ios', 'android', or 'macos'
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to register device token: ${response.body}');
      } else {
        print('Device token registered successfully');
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }

  /// Get count of tickets with 'new' status
  Future<int> getNewTicketCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?status=new'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.length;
      }
      return 0;
    } catch (e) {
      print('Error getting new ticket count: $e');
      return 0;
    }
  }
}
