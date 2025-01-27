import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:foodex/globals.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderService {
  List<Order> _activeOrders = [];
  List<Order> _inactiveOrders = [];

  List<Order> get activeOrders => _activeOrders;
  List<Order> get inactiveOrders => _inactiveOrders;
  List<Order> get allOrders => [..._activeOrders, ..._inactiveOrders];

  Future<List<Order>> _processOrderStatus(String status,
      {String? fromDate, String? toDate}) async {
    try {
      // Use 'from' and 'to' as expected by the backend
      final body = {
        'action': 'show-orders-flutter',
        'order-status': status,
        'driver': Globals.userId.toString()
      };

      if (fromDate != null) body['from'] = fromDate;
      if (toDate != null) body['to'] = toDate;

      debugPrint('Sending request with params: $body');

      final response = await http.post(
        Uri.parse('https://vinczefi.com/foodexim/functions.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      debugPrint('Response for $status orders: ${response.body}');

      if (!data['success']) {
        throw Exception(data['message'] ?? 'API request failed');
      }

      if (data['data'] == null || data['data'].isEmpty) {
        debugPrint('No $status orders found - empty data');
        return [];
      }

      // Handle single null order case
      if (data['data'].length == 1) {
        final firstOrder = data['data'][0];
        if (firstOrder['order_number'] == null &&
            (firstOrder['order_details'] == null ||
                json.decode(firstOrder['order_details'])['order_id'] == null)) {
          debugPrint('No $status orders found - null order');
          return [];
        }
      }

      List<Order> orders = [];
      for (var orderJson in data['data']) {
        try {
          // Parse order details
          final orderDetails = orderJson['order_details'] != null
              ? json.decode(orderJson['order_details'])
              : {};

          if (orderDetails['order_id'] == null) continue;

          // Parse related data with proper error handling
          final companies = _safeJsonDecode(orderJson['companies'], '[]');
          final warehouses = _safeJsonDecode(orderJson['warehouses'], '[]');
          final products = _safeJsonDecode(orderJson['products'], '[]');
          final contactPeople = orderJson['contact_people'] != null &&
                  orderJson['contact_people'] != 'null'
              ? _safeJsonDecode(orderJson['contact_people'], '[]')
              : [];

          final order = Order.fromJson({
            ...orderDetails,
            'companies': companies,
            'warehouses': warehouses,
            'products': products,
            'contact_people': contactPeople,
          });

          orders.add(order);
        } catch (e) {
          debugPrint('Error processing order: $e');
          continue;
        }
      }

      // Sort orders by pickup time
      orders.sort((a, b) => a.pickupTime.compareTo(b.pickupTime));

      debugPrint('Processed ${orders.length} $status orders');
      return orders;
    } catch (e) {
      debugPrint('Error in _processOrderStatus: $e');
      throw e;
    }
  }

  dynamic _safeJsonDecode(String? jsonString, String defaultValue) {
    if (jsonString == null || jsonString.isEmpty)
      return json.decode(defaultValue);
    try {
      return json.decode(jsonString);
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return json.decode(defaultValue);
    }
  }

  Future<void> fetchActiveOrders({String? fromDate, String? toDate}) async {
    _activeOrders =
        await _processOrderStatus('active', fromDate: fromDate, toDate: toDate);
    Globals.ordersNumber = _activeOrders.length;
    _debugPrintOrderInfo(_activeOrders, 'active');
  }

  Future<void> fetchInactiveOrders({String? fromDate, String? toDate}) async {
    _inactiveOrders = await _processOrderStatus('inactive',
        fromDate: fromDate, toDate: toDate);
    _debugPrintOrderInfo(_inactiveOrders, 'inactive');
  }

  Future<void> fetchAllOrders({String? fromDate, String? toDate}) async {
    try {
      Globals.ordersNumber = 0;

      final results = await Future.wait([
        _processOrderStatus('active', fromDate: fromDate, toDate: toDate),
        _processOrderStatus('inactive', fromDate: fromDate, toDate: toDate)
      ]);

      _activeOrders = results[0];
      _inactiveOrders = results[1];
      Globals.ordersNumber = _activeOrders.length + _inactiveOrders.length;

      debugPrint('Date range: $fromDate to $toDate');
      debugPrint('Total orders: ${Globals.ordersNumber}');
      _debugPrintOrderInfo(_activeOrders, 'active');
      _debugPrintOrderInfo(_inactiveOrders, 'inactive');
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      throw e;
    }
  }

  /// Returns an order by its ID from all orders (both active and inactive)
  /// Returns null if no order is found with the given ID

  void _debugPrintOrderInfo(List<Order> orders, String type) {
    debugPrint('Total $type orders: ${orders.length}');
    for (var order in orders) {
      debugPrint('$type Order ID: ${order.orderId}, '
          'Total Product Quantity: ${order.getTotalQuantity()}');
      for (var contact in order.contactPeople) {
        debugPrint('Contact for $type order ${order.orderId}: '
            'Name: ${contact.name}, Tel: ${contact.telephone}, Type: ${contact.type}');
      }
    }
  }

  /// Fetches a specific order by its ID from the backend.
  /// Returns the order if found, or null if not.
  Future<Order?> getOrderById(int orderId) async {
    try {
      final body = {
        'action': 'show-orders-flutter-id',
        'order_id': orderId.toString(),
        'driver': Globals.userId.toString(),
      };

      debugPrint('Fetching order with ID: $orderId, request: $body');

      final response = await http.post(
        Uri.parse('https://vinczefi.com/foodexim/functions.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      debugPrint('Response for order ID $orderId: ${response.body}');

      if (!data['success']) {
        debugPrint('Failed to fetch order: ${data['message']}');
        return null;
      }

      if (data['data'] == null || data['data'].isEmpty) {
        debugPrint('No order found with ID $orderId');
        return null;
      }

      // Parse the order data from the backend
      final orderJson = data['data'][0];

      final orderDetails = orderJson['order_details'] != null
          ? json.decode(orderJson['order_details'])
          : {};

      if (orderDetails['order_id'] == null) {
        debugPrint('Order details are invalid for ID $orderId');
        return null;
      }

      // Parse related data (companies, warehouses, products, etc.)
      final companies = _safeJsonDecode(orderJson['companies'], '[]');
      final warehouses = _safeJsonDecode(orderJson['warehouses'], '[]');
      final products = _safeJsonDecode(orderJson['products'], '[]');
      final contactPeople = orderJson['contact_people'] != null &&
              orderJson['contact_people'] != 'null'
          ? _safeJsonDecode(orderJson['contact_people'], '[]')
          : [];

      // Create and return the order object
      final order = Order.fromJson({
        ...orderDetails,
        'companies': companies,
        'warehouses': warehouses,
        'products': products,
        'contact_people': contactPeople,
      });

      debugPrint('Fetched order: ${order.orderId}');
      return order;
    } catch (e) {
      debugPrint('Error in getOrderById: $e');
      return null;
    }
  }

  Future<int?> checkVehicleLogin() async {
    try {
      final body = {
        'action': 'get-vehicle-id',
        'driver': Globals.userId.toString()
      };

      final response = await http.post(
        Uri.parse('https://vinczefi.com/foodexim/functions.php'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Raw vehicle response: ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final vehicleData = data['data'];
          final vehicleId = vehicleData['vehicle_id'];

          if (vehicleId != null) {
            int? parsedVehicleId;
            if (vehicleId is String) {
              parsedVehicleId = int.tryParse(vehicleId);
            } else if (vehicleId is int) {
              parsedVehicleId = vehicleId;
            }

            if (parsedVehicleId != null) {
              Globals.vehicleID = parsedVehicleId;
              debugPrint('Successfully stored vehicle ID: $parsedVehicleId');

              if (vehicleData['photos'] != null) {
                final List<dynamic> photos = json.decode(vehicleData['photos']);
                debugPrint('Found ${photos.length} photos');
              }

              return parsedVehicleId;
            }
          }

          debugPrint('No valid vehicle ID found in response');
          return null;
        }

        debugPrint(
            'Response indicates failure or missing data: ${data['message']}');
        return null;
      }

      debugPrint('HTTP Error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error in checkVehicleLogin: $e');
      return null;
    }
  }

  bool isOrderDelivered(Order order) {
    return order.delivered != '0000-00-00 00:00:00';
  }
}
