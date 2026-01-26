import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService = ApiService();

  static const String baseUrl = '${ApiConfig.baseUrl}/api/support-tickets';

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    // Get auth token from ApiService if available
    if (_apiService._accessToken != null) {
      headers['Authorization'] = 'Bearer ${_apiService._accessToken}';
    }
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

      final response = await http.get(Uri.parse(url), headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => SupportTicket.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tickets');
      }
    } catch (e) {
      throw Exception('Failed to fetch tickets: $e');
    }
  }

  Future<SupportTicket> getTicket(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id/'),
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
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (assignedTo != null) body['assigned_to'] = assignedTo;

      final response = await http.patch(
        Uri.parse('$baseUrl/$id/'),
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

  Future<TicketMessage> addMessage(int ticketId, String bodyText) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$ticketId/add_message/'),
        headers: _getHeaders(),
        body: jsonEncode({'body_text': bodyText}),
      );

      if (response.statusCode == 200) {
        return TicketMessage.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add message');
      }
    } catch (e) {
      throw Exception('Failed to add message: $e');
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
}
