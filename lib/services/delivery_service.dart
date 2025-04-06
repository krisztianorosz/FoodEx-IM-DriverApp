import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DeliveryService {
  final String baseUrl = 'https://vinczefi.com/foodexim/functions.php';

  Future<Map<String, dynamic>> getPartnerDetails(int partnerId) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'get-company-details',
        'company-id': partnerId.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load partner details');
    }

    final decodedResponse = json.decode(response.body);
    if (decodedResponse['success'] == true) {
      final data = decodedResponse['data'];

      if (data['contact_people'] is String) {
        data['contact_people'] = json.decode(data['contact_people'] ?? '[]');
      }

      if (data['photos'] is String && data['photos'] != null) {
        
        final photosString = data['photos'] as String;
        if (photosString.isNotEmpty) {
          data['photos'] = photosString
              .split(',')
              .where((String p) => p.isNotEmpty)
              .toList();
        } else {
          data['photos'] = [];
        }
      } else if (data['photos'] == null) {
        data['photos'] = [];
      }

      return data;
    }

    throw Exception(
        decodedResponse['message'] ?? 'Failed to load partner details');
  }
  
  Future<Map<String, dynamic>> getWarehouseDetails(int warehouseId) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'get-warehouse-details',
        'warehouse-id': warehouseId.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load warehouse details');
    }

    final decodedResponse = json.decode(response.body);
    if (decodedResponse['success'] == true) {
      final data = decodedResponse['data'];

      if (data['contact_people'] is String) {
        data['contact_people'] = json.decode(data['contact_people'] ?? '[]');
      }

      if (data['photos'] is String && data['photos'] != null) {
        final photosString = data['photos'] as String;
        if (photosString.isNotEmpty) {
          data['photos'] = photosString
              .split(',')
              .where((String p) => p.isNotEmpty)
              .toList();
        } else {
          data['photos'] = [];
        }
      } else if (data['photos'] == null) {
        data['photos'] = [];
      }

      return data;
    }

    throw Exception(
        decodedResponse['message'] ?? 'Failed to load warehouse details');
  }

  Future<void> pickupOrder(int orderId, bool isAdmin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-order.php'),
      body: {
        'action': 'pickup-order',
        'order': orderId.toString(),
        'admin': isAdmin.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to pickup order');
    }
  }

  Future<void> deliverOrder(int orderId, bool isAdmin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update-order.php'),
      body: {
        'action': 'deliver-order',
        'order': orderId.toString(),
        'admin': isAdmin.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to deliver order');
    }
  }

  Future<void> updateOrderUit(int orderId, String uit) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'update-order',
          'type': 'uit',
          'order-id': orderId.toString(),
          'uit': uit,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update UIT/EKR');
      }
    } catch (e) {
      print('Error updating UIT/EKR: $e');
      throw e;
    }
  }

  Future<void> updateOrderEkr(int orderId, String ekr) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'update-order',
          'type': 'ekr',
          'order-id': orderId.toString(),
          'ekr': ekr,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update UIT/EKR');
      }
    } catch (e) {
      print('Error updating UIT/EKR: $e');
      throw e;
    }
  }

  Future<void> updateOrderInvoice(int orderId, List<File> invoiceFiles) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'action': 'update-order',
        'type': 'invoice',
        'order-id': orderId.toString(),
      });

      for (var file in invoiceFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'invoice[]', // Changed to array notation
          file.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result is List && result.isNotEmpty && !result[0]['success']) {
          throw Exception(result[0]['message']);
        }
      } else {
        throw Exception('Failed to update invoice');
      }
    } catch (e) {
      print('Error updating invoice: $e');
      throw e;
    }
  }

  Future<void> updateOrderNote(int orderId, String note) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'update-order',
          'type': 'notes',
          'order-id': orderId.toString(),
          'notes': note,
        },
      );
      print('Response: ${response.body}');
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update note');
      }
    } catch (e) {
      print('Error updating note: $e');
      throw e;
    }
  }

  Future<List<String>> getPhotos(int orderId) async {
    const baseUrl =
        'https://vinczefi.com/foodexim/functions.php'; // Replace with your actual API endpoint

    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'action': 'get-order-photos',
        'order-id': orderId.toString(),
      });

      // Send the request
      var response = await request.send();

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response body
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseBody);

        if (jsonResponse['success']) {
          print('Response Data: ${jsonResponse['data']}');
          // Extract the photo URLs from the response
          List<String> photoUrls = (jsonResponse['data'] as List)
              .map((photo) =>
                  photo['path']?.toString() ??
                  '') // Ensure it's a string or fallback to empty
              .where((url) => url.isNotEmpty) // Filter out empty values
              .toList();
          print("Final Image URLs: $photoUrls");

          // Construct full URLs

          photoUrls = photoUrls.map((url) {
            // Ensure the baseUrl ends with a '/' and the url does not start with a '/'
            String base =
                'https://vinczefi.com/foodexim/'; // Remove functions.php
            String path = url.startsWith('/') ? url.substring(1) : url;
            return Uri.parse('$base$path').toString();
          }).toList();

          return photoUrls; // Return the list of photo URLs
        } else {
          // Handle case where no photos are found
          print('No photos found: ${jsonResponse['message']}');
          return []; // Return an empty list
        }
      } else {
        // Handle HTTP error
        print('HTTP Error: ${response.statusCode}');
        return []; // Return an empty list
      }
    } catch (e) {
      print("Error getting order photos: $e");
      return [];
    }
  }

  Future<void> updateOrderCmr(int orderId, List<File> cmrFiles) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'action': 'update-order',
        'type': 'cmr',
        'order-id': orderId.toString(),
      });

      for (var file in cmrFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'cmr[]', // Changed to array notation
          file.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result is List && result.isNotEmpty && !result[0]['success']) {
          throw Exception(result[0]['message']);
        }
      } else {
        throw Exception('Failed to update CMR');
      }
    } catch (e) {
      print('Error updating CMR: $e');
      throw e;
    }
  }

  Future<void> updateCrates(
      int orderId, int quantity, String containerId) async {
    try {
      final body = {
        'action': 'update-order',
        'type': 'container',
        'order-id': orderId.toString(),
        'quantity': quantity.toString(),
        'container-id': containerId,
      };

      print('Sending update crates request: $body');

      final response = await http.post(
        Uri.parse(baseUrl),
        body: body,
      );

      print('Crates response status: ${response.statusCode}');
      print('Crates response body: ${response.body}');

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response received');
        }

        final responseData = json.decode(responseBody);
        if (responseData == null) {
          throw Exception('Failed to decode response');
        }

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == false) {
          throw Exception(responseData['message'] ?? 'Failed to update crates');
        }
      } else {
        throw Exception('Failed to update crates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating crates: $e');
      throw Exception('Failed to update crates: $e');
    }
  }

  Future<void> updatePallets(
      int orderId, int quantity, String containerId) async {
    try {
      final body = {
        'action': 'update-order',
        'type': 'container',
        'order-id': orderId.toString(),
        'quantity': quantity.toString(),
        'container-id': containerId,
      };

      print('Sending update pallets request: $body');

      final response = await http.post(
        Uri.parse(baseUrl),
        body: body,
      );

      print('Pallets response status: ${response.statusCode}');
      print('Pallets response body: ${response.body}');

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response received');
        }

        final responseData = json.decode(responseBody);
        if (responseData == null) {
          throw Exception('Failed to decode response');
        }

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == false) {
          throw Exception(
              responseData['message'] ?? 'Failed to update pallets');
        }
      } else {
        throw Exception('Failed to update pallets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating pallets: $e');
      throw Exception('Failed to update pallets: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionUnits(
      String type, String productId) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'get-collection-units',
          'type': type,
          'product_id': productId
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Decode the response body first
        final decodedResponse = json.decode(response.body);

        // Check if the response is a success and contains data
        if (decodedResponse is Map && decodedResponse.containsKey('success')) {
          if (decodedResponse['success'] == true &&
              decodedResponse.containsKey('data')) {
            final List<dynamic> data = decodedResponse['data'];
            return List<Map<String, dynamic>>.from(data);
          } else {
            throw Exception(decodedResponse['message'] ??
                'Failed to load collection units');
          }
        } else if (decodedResponse is List) {
          // If the response is directly a list
          return List<Map<String, dynamic>>.from(decodedResponse);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load collection units: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching collection units: $e');
    }
  }

  Future<void> updateProductCollection(
      int orderId, int productId, int received, String containerId) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'update-order',
          'type': 'received-containers',
          'order-id': orderId.toString(),
          'product-id': productId.toString(),
          'received': received.toString(),
          'container-id': containerId,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update product collection container');
      }
    } catch (e) {
      print('Error updating product collection container: $e');
      throw e;
    }
  }

  Future<void> updateProductReceivedQuantity(
      int orderId, int productId, double received) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'update-order',
          'type': 'received-product',
          'order-id': orderId.toString(),
          'product-id': productId.toString(),
          'received': received.toString(),
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update product received quantity');
      }
    } catch (e) {
      print('Error updating product received quantity: $e');
      throw e;
    }
  }

  Future<void> updateOrderPhotos(int orderId, List<File> photoFiles) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields.addAll({
        'action': 'update-order',
        'type': 'photo',
        'order-id': orderId.toString(),
      });

      print(
          'Starting photo upload for order #$orderId with ${photoFiles.length} files');

      for (var file in photoFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'photos[]',
          file.path,
        ));
        print('Added file: ${file.path}');
      }

      print('Sending request to server...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Decoded response: $result');

        if (result is List && result.isNotEmpty) {
          for (var item in result) {
            print(
                'Upload result: ${item['success'] ? 'Success' : 'Failed'} - ${item['message']}');
          }

          if (!result[0]['success']) {
            throw Exception(result[0]['message']);
          }
          print('Photo upload completed successfully for order #$orderId');
        }
      } else {
        print('Upload failed with status code: ${response.statusCode}');
        throw Exception('Failed to upload photos');
      }
    } catch (e) {
      print('Error updating photos: $e');
      throw e;
    }
  }
}
