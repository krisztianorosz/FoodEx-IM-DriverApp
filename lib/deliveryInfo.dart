// ignore: file_names
import 'dart:convert';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'package:foodex/driverPage.dart';
import 'package:foodex/globals.dart';
import 'package:foodex/models/colections.dart';
import 'package:foodex/models/product.dart';
import 'package:foodex/my_routes_page.dart';
import 'package:foodex/services/delivery_service.dart';
import 'package:foodex/services/order_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:foodex/models/order.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:foodex/models/company.dart';
import 'package:foodex/models/contact_person.dart';
import 'package:foodex/models/warehouse.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryInfo extends StatefulWidget {
  final int orderId;
  final bool? myRoutesPage;

  const DeliveryInfo(
      {super.key, required this.orderId, this.myRoutesPage = false});

  @override
  State<DeliveryInfo> createState() => _DeliveryInfoState();
}

class _DeliveryInfoState extends State<DeliveryInfo> {
  final deliveryService = DeliveryService();
  final orderService = OrderService();

  String collectionUnitsData = "";

  late Order order = Order.empty();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadCollections();

    widget.myRoutesPage;
  }

  Future<void> _loadCollections() async {
    try {
      final response = await http.post(
        Uri.parse('https://vinczefi.com/foodexim/functions.php'),
        body: {
          'action': 'get-order-collection-units',
          'order-id': widget.orderId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['success'] == true) {
          setState(() {
            collectionUnitsData = decodedResponse['data'];
          });
        }
      }
    } catch (e) {
      print('Error loading collections: $e');
    }
  }

  Future<void> _loadOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orderData = await orderService.getOrderById(widget.orderId);

      if (mounted) {
        setState(() {
          order = orderData ?? Order.empty();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildUserNotes(BuildContext context) {
    final bool isNoteEmpty = order.orderNote.isEmpty;
    final Color borderColor = isNoteEmpty ? Colors.red : Colors.blue;
    final Color backgroundColor = isNoteEmpty
        ? Colors.red.withOpacity(0.1)
        : const Color.fromARGB(255, 213, 236, 255);

    return GestureDetector(
      onTap: () {
        if (isNoteEmpty) {
          editUserNotes(context, order.orderId, _loadOrder, order.orderNote);
        } else {
          openNotesUser(context, order.orderNote, _loadOrder);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.note,
                    color: isNoteEmpty ? Colors.red : Colors.blue,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    '${Globals.getText('orderNotesTitle')}:',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              isNoteEmpty
                  ? '${Globals.getText('noOrderNotes')}'
                  : order.orderNote,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  void openNotesUser(BuildContext context, String notes, Function reloadPage) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.note_rounded,
                        color: Colors.blue.shade700,
                        size: isSmallScreen ? 50 : 56,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      notes,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 28.0 : 32.0,
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        editUserNotes(context, order.orderId, reloadPage,
                            order.orderNote);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 20 : 24,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 10), // Add some spacing between buttons
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 20 : 24,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                        backgroundColor: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${Globals.getText('orderClose')}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void editUserNotes(BuildContext context, int orderId, Function reloadPage,
      String orderNote) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    String? newUserNote;

    // Initialize a TextEditingController with the existing order note
    final TextEditingController _controller =
        TextEditingController(text: orderNote);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${Globals.getText('orderUpdate')} ${Globals.getText('orderNotesTitle')}",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20.0 : 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller:
                      _controller, // Set the controller to auto-fill the text
                  decoration: InputDecoration(
                    hintText: '${Globals.getText('orderUserNotes')}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  maxLines:
                      null, // Allow the TextField to expand based on content
                  onChanged: (value) => newUserNote = value,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '${Globals.getText('orderCancel')}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (newUserNote?.isNotEmpty ?? false) {
                          try {
                            await DeliveryService()
                                .updateOrderNote(orderId, newUserNote!);
                            Navigator.pop(context);
                            reloadPage(); // Call the reloadPage function to refresh the page

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('User Notes updated successfully')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('${Globals.getText('orderUpdate')}',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsTable(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    // Define breakpoints
    final isSmallScreen = screenWidth < 360; // Extra small devices
    final isMediumScreen = screenWidth < 480; // Small to medium devices

    // Adjust font sizes based on screen size
    final double headerFontSize =
        isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 16.0);
    final double contentFontSize =
        isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 14.0);

    // Adjust spacing based on screen size
    final double horizontalMargin =
        isSmallScreen ? 8.0 : (isMediumScreen ? 12.0 : 24.0);
    final double columnSpacing =
        isSmallScreen ? 8.0 : (isMediumScreen ? 12.0 : 24.0);

    // Calculate dynamic constraints for product name column
    final double maxNameWidth =
        screenWidth * (isSmallScreen ? 0.25 : (isMediumScreen ? 0.3 : 0.4));

    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.black,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              // Set minimum width to prevent squishing
              constraints: BoxConstraints(
                minWidth: screenWidth,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    dataRowMinHeight: isSmallScreen ? 40 : 48,
                    dataRowMaxHeight:
                        textScaleFactor * (isSmallScreen ? 56 : 64),
                    headingRowHeight: isSmallScreen ? 48 : 56,
                    dividerThickness: 1.0,
                  ),
                ),
                child: DataTable(
                  showCheckboxColumn: false, // This hides the checkbox column
                  columnSpacing: columnSpacing,
                  horizontalMargin: horizontalMargin,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Colors.transparent),
                    verticalInside: BorderSide(color: Colors.transparent),
                  ),
                  headingTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                    fontSize: headerFontSize,
                  ),
                  dataTextStyle: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: contentFontSize,
                  ),
                  columns: [
                    DataColumn(
                      label: Container(
                        width: maxNameWidth,
                        alignment: Alignment.center,
                        child: Text(
                          Globals.getText('orderName'),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        alignment: Alignment.center,
                        child: Text(
                          Globals.getText('productTableQuantity'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        alignment: Alignment.center,
                        child: Text(
                          Globals.getText('collection_unit'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        alignment: Alignment.center,
                        child: Text(
                          '${Globals.getText('order_received')} (kg)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    ...order.products
                        .where((product) => product.productType == 'product')
                        .map((product) {
                      return DataRow(
                        onSelectChanged: (_) => updateProductDetails(
                          context,
                          product.productId,
                          product.productName,
                          widget.orderId,
                          _loadOrder,
                          product.collection,
                          product.quantity.toDouble(),
                        ),
                        cells: [
                          DataCell(
                            Container(
                              width: maxNameWidth,
                              alignment: Alignment.center,
                              child: Text(
                                product.productName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: isSmallScreen ? 1 : 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              alignment: Alignment.center,
                              child: Text(
                                product.productUnit.toLowerCase() == 'kg'
                                    ? '${product.ordered}kg'
                                    : '${product.ordered}pc',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${product.collection}',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.productUnit.toLowerCase() == 'kg'
                                        ? '${product.quantity}kg'
                                        : '${product.quantity}pc',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    // Summary Row
                    DataRow(
                      color: MaterialStateProperty.all(
                        const Color.fromARGB(255, 177, 177, 177),
                      ),
                      cells: [
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${Globals.getText('orderSummary')}:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${order.getTotalOrderedQuantity()}kg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${order.getTotalCollection()}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              '${order.getTotalRecievedWeight()}kg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
  //UIT,EKR, INVOICE, CMR

  Widget _buildUitEkrInvCmr(
    BuildContext context,
    String Uit,
    String Ekr,
    String Invoice,
    String Cmr,
    bool isSmallScreen,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uit number display
          GestureDetector(
            onTap: () {
              if (Uit.isNotEmpty) {
                showUitEkr(context, Uit, null, order.orderId, _loadOrder);
              } else {
                print("Uit update for orderID ${order.orderId}");
                updateUit(context, order.orderId, _loadOrder);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Uit.isNotEmpty
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Uit.isNotEmpty ? Colors.green : Colors.red,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.numbers_rounded,
                    size: isSmallScreen ? 20 : 22,
                    color: Uit.isNotEmpty
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Uit:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    Uit,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.0),
          // Ekr number display
          GestureDetector(
            onTap: () {
              if (Ekr.isNotEmpty) {
                showUitEkr(context, null, Ekr, order.orderId, _loadOrder);
              } else {
                updateEkr(context, order.orderId, _loadOrder);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Ekr.isNotEmpty
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Ekr.isNotEmpty ? Colors.green : Colors.red,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.numbers_rounded,
                    size: isSmallScreen ? 20 : 22,
                    color: Ekr.isNotEmpty
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Ekr:',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    Ekr,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.0),
          // Invoice and CMR boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (Invoice.isNotEmpty) {
                      ShowInvoiceCmr(
                          context, Invoice, _loadOrder, order.orderId);
                    } else {
                      print("Invoice update for order ${order.orderId}");
                      updateInvoice(context, order.orderId, _loadOrder);
                    }
                  },
                  child: Container(
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Invoice.isNotEmpty
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Invoice.isNotEmpty ? Colors.green : Colors.red,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: isSmallScreen ? 24 : 28,
                          color: Invoice.isNotEmpty
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '${Globals.getText('orderInvoice')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                // Moved Expanded here
                child: GestureDetector(
                  onTap: () {
                    if (Cmr.isNotEmpty) {
                      ShowInvoiceCmr(context, Cmr, _loadOrder, order.orderId);
                    } else {
                      print("Cmr update for order ${order.orderId}");
                      updateCmr(context, order.orderId, _loadOrder);
                    }
                  },
                  child: Container(
                    // Removed the Expanded from here
                    height: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Cmr.isNotEmpty
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Cmr.isNotEmpty ? Colors.green : Colors.red,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_copy_outlined,
                          size: isSmallScreen ? 24 : 28,
                          color: Cmr.isNotEmpty
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'CMR',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //CONTAINER OPTIONS
  Widget _buildContainerStatus(BuildContext context, bool isSmallScreen) {
    print('Collection Units:');
    for (var unit in order.collectionUnits) {
      print(
          'ID: ${unit.id}, Type: ${unit.type}, Name: ${unit.name}, Quantity: ${unit.quantity}');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  updatePalets(context, order.orderId, _loadOrder, order),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.collectionUnits.any(
                          (unit) => unit.type.toLowerCase().contains('pallet'))
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: order.collectionUnits.any((unit) =>
                            unit.type.toLowerCase().contains('pallet'))
                        ? Colors.green
                        : Colors.red,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/palet.jpg',
                      height: isSmallScreen ? 56 : 60,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      Globals.getText('orderPalets'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  updateCrates(context, order.orderId, _loadOrder, order),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: order.collectionUnits.any(
                          (unit) => unit.type.toLowerCase().contains('crate'))
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: order.collectionUnits.any(
                            (unit) => unit.type.toLowerCase().contains('crate'))
                        ? Colors.green
                        : Colors.red,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/crate.jpg',
                      height: isSmallScreen ? 56 : 60,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      Globals.getText('orderCrates'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (order.collectionUnits.any((unit) =>
                        unit.name.toLowerCase().contains('crate'))) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        order.collectionUnits
                            .where((unit) =>
                                unit.name.toLowerCase().contains('crate'))
                            .map((unit) => '${unit.quantity} ${unit.name}')
                            .join(', '),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12.0 : 14.0,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //PICKUP/DELIVER BUTTON
  Widget _buildActionButton(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 1, 160, 226),
          minimumSize: Size(double.infinity, isSmallScreen ? 48 : 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => showConfirmationDialog(
          context,
          order,
          () async {
            try {
              if (order.pickedUp == '0000-00-00 00:00:00') {
                await DeliveryService().pickupOrder(order.orderId, false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${Globals.getText('orderPickupFeedback')}')),
                  );
                }
              } else if (order.delivered == '0000-00-00 00:00:00') {
                await DeliveryService().deliverOrder(order.orderId, false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${Globals.getText('orderDeliveryFeedback')}')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            }
          },
          collectionUnitsData, // Add this line to pass the data
        ),
        child: Text(
          order.pickedUp == '0000-00-00 00:00:00'
              ? '${Globals.getText('orderPickup')}'
              : order.delivered == '0000-00-00 00:00:00'
                  ? '${Globals.getText('orderDeliver')}'
                  : '',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void showCompanyDetails(BuildContext context, Company company) async {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    try {
      final companyData = await deliveryService.getPartnerDetails(company.id);
      print(companyData);
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Company Name and Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            size: isSmallScreen ? 24 : 30,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            companyData['name'] ?? '',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20.0 : 24.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Photos Gallery Section
                    if ((companyData['photos'] as List?)?.isNotEmpty ??
                        false) ...[
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (companyData['photos'] as List).length,
                            itemBuilder: (context, index) {
                              String photoUrl =
                                  'https://vinczefi.com/foodexim/' +
                                      companyData['photos'][index];
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            InteractiveViewer(
                                              panEnabled: true,
                                              boundaryMargin:
                                                  EdgeInsets.all(20),
                                              minScale: 0.5,
                                              maxScale: 4,
                                              child: Image.network(
                                                photoUrl,
                                                fit: BoxFit.contain,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: IconButton(
                                                icon: Container(
                                                  padding: EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.close,
                                                      color: Colors.white),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  margin: EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Contact Information Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (companyData['address']?.isNotEmpty ?? false)
                            GestureDetector(
                              onTap: () async {
                                final address =
                                    companyData['coordinates']?.isNotEmpty ??
                                            false
                                        ? companyData['coordinates']
                                        : companyData['address'];
                                final Uri launchUri = Uri(
                                  scheme: 'geo',
                                  path: '0,0',
                                  queryParameters: {'q': address},
                                );
                                try {
                                  await launchUrl(launchUri);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Could not open Google Maps.')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        companyData['address'] ?? '',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14.0 : 16.0,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (companyData['telephone']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () =>
                                  openDialer(context, companyData['telephone']),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 12),
                                    Text(
                                      companyData['telephone'] ?? '',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14.0 : 16.0,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Contact People Section
                    if (companyData['contact_people'] is List &&
                        companyData['contact_people'].isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Contact People',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16.0 : 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        companyData['contact_people'].length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: () => openDialer(
                                context,
                                companyData['contact_people'][index]
                                    ['telephone']),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person,
                                        color: Colors.grey.shade700, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          companyData['contact_people'][index]
                                              ['name'],
                                          style: TextStyle(
                                            fontSize:
                                                isSmallScreen ? 14.0 : 16.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          companyData['contact_people'][index]
                                              ['telephone'],
                                          style: TextStyle(
                                            fontSize:
                                                isSmallScreen ? 12.0 : 14.0,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.phone,
                                      color: Colors.green.shade700),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    // Close Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${Globals.getText('orderClose')}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading company details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    final pickupWarehouse = order.warehouses.firstWhere(
      (wh) => wh.type == 'pickup',
      orElse: () => Warehouse(
        warehouseName: 'Unknown',
        warehouseAddress: 'N/A',
        type: 'pickup',
        coordinates: 'N/A',
      ),
    );

    final deliveryWarehouse = order.warehouses.firstWhere(
      (wh) => wh.type == 'delivery',
      orElse: () => Warehouse(
        warehouseName: 'Unknown',
        warehouseAddress: 'N/A',
        type: 'delivery',
        coordinates: 'N/A',
      ),
    );

    final pickupCompany = order.companies.firstWhere(
      (comp) => comp.type == 'pickup',
      orElse: () => Company(
        companyName: 'Unknown',
        type: 'pickup',
        id: 0,
      ),
    );

    final deliveryCompany = order.companies.firstWhere(
      (comp) => comp.type == 'delivery',
      orElse: () => Company(
        companyName: 'Unknown',
        type: 'delivery',
        id: 0,
      ),
    );

    final pickupContact = order.contactPeople.firstWhere(
      (cp) => cp.type == 'pickup',
      orElse: () => ContactPerson(
        name: 'Unknown',
        telephone: 'N/A',
        type: 'pickup',
      ),
    );

    final deliveryContact = order.contactPeople.firstWhere(
      (cp) => cp.type == 'delivery',
      orElse: () => ContactPerson(
        name: 'Unknown',
        telephone: 'N/A',
        type: 'delivery',
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Handle the navigation back with order refresh
        final startDate = Globals.startDate;
        final endDate = Globals.endDate;
        Globals.clearRouteDates();

        if (widget.myRoutesPage != null && widget.myRoutesPage!) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyRoutesPage(
                startDate: startDate ?? DateTime.now(),
                endDate: endDate ?? DateTime.now(),
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverPage()),
          );
        }
        // Prevent default back behavior since we're handling navigation
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              final startDate = Globals.startDate;
              final endDate = Globals.endDate;
              Globals.clearRouteDates();

              if (widget.myRoutesPage != null && widget.myRoutesPage!) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyRoutesPage(
                      startDate: startDate ?? DateTime.now(),
                      endDate: endDate ?? DateTime.now(),
                    ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverPage()),
                );
              }
            },
          ),
          title: Center(
            child: Text(
              '${Globals.getText('orderTitle')}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 1, 160, 226),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: isSmallScreen ? 8.0 : 16.0),
              child: order.pickedUp == '0000-00-00 00:00:00'
                  ? Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.red,
                      size: isSmallScreen ? 56 : 62,
                    )
                  : order.delivered == '0000-00-00 00:00:00'
                      ? Icon(
                          Icons.keyboard_arrow_down,
                          color: const Color.fromARGB(255, 108, 226, 112),
                          size: isSmallScreen ? 56 : 62,
                        )
                      : Container(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null ||
                    order == Order.empty() // Check if order is empty
                ? Center(
                    child: Text(
                      "Couldn't load order",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => showCompanyDetails(
                                          context, pickupCompany),
                                      child: Text(
                                        pickupCompany.companyName,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18.0 : 22.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${Globals.getText(DateFormat('E').format(DateTime.parse(order.pickupTime)))} ${DateFormat('dd.MM').format(DateTime.parse(order.pickupTime))},  ${DateFormat('HH:mm').format(DateTime.parse(order.pickupTime))}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14.0 : 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  children: [
                                    Text(
                                      '${Globals.getText('orderAddress')}: ',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 16.0 : 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final String address = pickupWarehouse
                                                    .coordinates?.isNotEmpty ==
                                                true
                                            ? pickupWarehouse.coordinates!
                                            : pickupWarehouse.warehouseAddress;

                                        final Uri launchUri = Uri(
                                          scheme: 'geo',
                                          path: '0,0',
                                          queryParameters: {'q': address},
                                        );

                                        try {
                                          await launchUrl(launchUri);
                                        } catch (e) {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Could not open Google Maps.')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        pickupWarehouse.warehouseAddress,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16.0 : 18.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (pickupContact
                                                .telephone.isNotEmpty &&
                                            pickupContact.telephone != "N/A") {
                                          openContactPerson(
                                              context,
                                              pickupContact.name,
                                              pickupContact.telephone);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (pickupContact
                                                      .name.isNotEmpty &&
                                                  pickupContact.name != "N/A" &&
                                                  pickupContact
                                                      .telephone.isNotEmpty &&
                                                  pickupContact.telephone !=
                                                      "N/A")
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: (pickupContact
                                                        .name.isNotEmpty &&
                                                    pickupContact.name !=
                                                        "N/A" &&
                                                    pickupContact
                                                        .telephone.isNotEmpty &&
                                                    pickupContact.telephone !=
                                                        "N/A")
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.person_rounded,
                                                size: isSmallScreen ? 20 : 22,
                                                color: (pickupContact
                                                            .name.isNotEmpty &&
                                                        pickupContact.name !=
                                                            "N/A" &&
                                                        pickupContact.telephone
                                                            .isNotEmpty &&
                                                        pickupContact
                                                                .telephone !=
                                                            "N/A")
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 12.0),
                                              Text(
                                                '${Globals.getText('orderPickupContact')}',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 14.0
                                                      : 16.0,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            12.0), // Spacing between containers
                                    GestureDetector(
                                      onTap: () {
                                        if (order.upNotes != null &&
                                            order.upNotes.isNotEmpty) {
                                          openNotes(context, order.upNotes);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (order.upNotes != null &&
                                                  order.upNotes.isNotEmpty)
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: (order.upNotes != null &&
                                                    order.upNotes.isNotEmpty)
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.note_rounded,
                                                size: isSmallScreen ? 20 : 22,
                                                color: (order.upNotes != null &&
                                                        order
                                                            .upNotes.isNotEmpty)
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 12.0),
                                              Text(
                                                '${Globals.getText('orderNotes')}',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 14.0
                                                      : 16.0,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),

                          //DELIVER LOCATION
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => showCompanyDetails(
                                          context, deliveryCompany),
                                      child: Text(
                                        deliveryCompany.companyName,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 18.0 : 22.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${Globals.getText(DateFormat('E').format(DateTime.parse(order.deliveryTime)))} ${DateFormat('dd.MM').format(DateTime.parse(order.deliveryTime))},  ${DateFormat('HH:mm').format(DateTime.parse(order.deliveryTime))}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14.0 : 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  children: [
                                    Text(
                                      '${Globals.getText('orderAddress')}: ',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 16.0 : 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        final String address = deliveryWarehouse
                                                    .coordinates?.isNotEmpty ==
                                                true
                                            ? deliveryWarehouse.coordinates!
                                            : deliveryWarehouse
                                                .warehouseAddress;

                                        final Uri launchUri = Uri(
                                          scheme: 'geo',
                                          path: '0,0',
                                          queryParameters: {'q': address},
                                        );

                                        try {
                                          await launchUrl(launchUri);
                                        } catch (e) {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Could not open Google Maps.')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        deliveryWarehouse.warehouseAddress,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16.0 : 18.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (deliveryContact
                                                .telephone.isNotEmpty &&
                                            deliveryContact.telephone !=
                                                "N/A") {
                                          openContactPerson(
                                              context,
                                              deliveryContact.name,
                                              deliveryContact.telephone);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (deliveryContact
                                                      .name.isNotEmpty &&
                                                  deliveryContact.name !=
                                                      "N/A" &&
                                                  deliveryContact
                                                      .telephone.isNotEmpty &&
                                                  deliveryContact.telephone !=
                                                      "N/A")
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: (deliveryContact
                                                        .name.isNotEmpty &&
                                                    deliveryContact.name !=
                                                        "N/A" &&
                                                    deliveryContact
                                                        .telephone.isNotEmpty &&
                                                    deliveryContact.telephone !=
                                                        "N/A")
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.person_rounded,
                                                size: isSmallScreen ? 20 : 22,
                                                color: (deliveryContact
                                                            .name.isNotEmpty &&
                                                        deliveryContact.name !=
                                                            "N/A" &&
                                                        deliveryContact
                                                            .telephone
                                                            .isNotEmpty &&
                                                        deliveryContact
                                                                .telephone !=
                                                            "N/A")
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 12.0),
                                              Text(
                                                '${Globals.getText('orderDeliveryContact')}',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 14.0
                                                      : 16.0,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    GestureDetector(
                                      onTap: () {
                                        if (order.downNotes != null &&
                                            order.downNotes.isNotEmpty) {
                                          openNotes(context, order.downNotes);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: (order.downNotes != null &&
                                                  order.downNotes.isNotEmpty)
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: (order.downNotes != null &&
                                                    order.downNotes.isNotEmpty)
                                                ? Colors.green
                                                : Colors.red,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.note_rounded,
                                                size: isSmallScreen ? 20 : 22,
                                                color:
                                                    (order.downNotes != null &&
                                                            order.downNotes
                                                                .isNotEmpty)
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                              ),
                                              const SizedBox(width: 12.0),
                                              Text(
                                                '${Globals.getText('orderNotes')}',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 14.0
                                                      : 16.0,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          //USER NOTES
                          const SizedBox(height: 16),
                          _buildUserNotes(context),
                          //PRODUCTS AND CONTAINERS TABLES
                          const SizedBox(height: 16),
                          _buildProductsTable(context),
                          const SizedBox(height: 16),
                          _buildContainerStatus(context, isSmallScreen),
                          //UIT,EKR, INVOICE, CMR
                          const SizedBox(height: 16),
                          _buildUitEkrInvCmr(context, order.uit, order.ekr,
                              order.invoice, order.cmr, isSmallScreen),

                          //CONTAINERS

                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: Colors.black, width: 1.0),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => updatePhotos(
                                      context, order.orderId, _loadOrder),
                                  icon: Icon(Icons.camera_alt,
                                      color: Colors.white),
                                  label: Text(
                                    '${Globals.getText('orderUploadPhoto')}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 1, 160, 226),
                                    minimumSize: Size(double.infinity,
                                        isSmallScreen ? 44 : 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                if (order.existsPhotos) ...[
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      openPhotos(
                                          context, order.orderId, _loadOrder);
                                      print(order.existsPhotos);
                                    },
                                    icon: Icon(Icons.photo_library,
                                        color: Colors.white),
                                    label: Text(
                                      '${Globals.getText('orderPrewviewPhoto')}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 1, 160, 226),
                                      minimumSize: Size(double.infinity,
                                          isSmallScreen ? 44 : 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),

                          //DELIVER/PICKUP BUTTON
                          if (Globals.vehicleID != null) ...[
                            if (order.pickedUp == '0000-00-00 00:00:00' ||
                                order.delivered == '0000-00-00 00:00:00') ...[
                              const SizedBox(height: 16),
                              _buildActionButton(context, isSmallScreen),
                            ]
                          ]
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

void openContactPerson(BuildContext context, String name, String telephone) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person_rounded,
                        size: isSmallScreen ? 50 : 56,
                        color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20.0 : 24.0,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    telephone,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28.0 : 32.0,
                      color: Colors.grey.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => openDialer(context, telephone),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: Text(
                      '${Globals.getText('orderCall')}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      backgroundColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${Globals.getText('orderClose')}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void openDialer(BuildContext context, String telephone) async {
  final Uri launchUri = Uri.parse('tel:$telephone');
  try {
    await launchUrl(launchUri);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not launch dialer.')),
    );
  }
}

void openNotes(BuildContext context, String notes) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          //width: double.infinity,
          //height: double.minPositive,
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note_rounded,
                      color: Colors.green.shade700,
                      size: isSmallScreen ? 50 : 56,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    notes,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28.0 : 32.0,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 24,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    backgroundColor: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${Globals.getText('orderClose')}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14.0 : 16.0,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showUitEkr(BuildContext context, String? uit, String? ekr, int orderId,
    Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  // Determine which value to show
  String? valueToShow;
  String labelToShow;
  if (uit != null && uit.isNotEmpty) {
    valueToShow = uit;
    labelToShow = 'UIT';
  } else if (ekr != null && ekr.isNotEmpty) {
    valueToShow = ekr;
    labelToShow = 'EKR';
  } else {
    valueToShow = null;
    labelToShow = '';
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (valueToShow != null) ...[
                Text(
                  labelToShow,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 30.0 : 34.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      valueToShow,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 28.0 : 32.0,
                        height: 1.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (uit != null && uit.isNotEmpty) {
                        updateUit(context, orderId, reloadPage);
                      } else {
                        updateEkr(context, orderId, reloadPage);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      backgroundColor: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 20 : 24,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      backgroundColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${Globals.getText('orderClose')}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14.0 : 16.0,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void ShowInvoiceCmr(BuildContext context, String relativePdfUrl,
    Function reloadPage, int orderId) async {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  // Show loading dialog immediately
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              const SizedBox(height: 16),
              const Text(
                'Loading document...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    // Define the base URL for your server
    String baseUrl = 'https://vinczefi.com/foodexim/';
    String fullUrl = baseUrl + relativePdfUrl;
    final encodedUrl = Uri.encodeFull(fullUrl);

    // Check file type from URL
    bool isImage = fullUrl.toLowerCase().endsWith('.jpg') ||
        fullUrl.toLowerCase().endsWith('.jpeg') ||
        fullUrl.toLowerCase().endsWith('.png');

    // Get document type from URL for title
    String documentType = 'Document';
    if (relativePdfUrl.toLowerCase().contains('invoice')) {
      documentType = 'Invoice';
    } else if (relativePdfUrl.toLowerCase().contains('cmr')) {
      documentType = 'CMR';
    }

    // Generate a unique filename using timestamp and document type
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String uniqueFileName =
        '${documentType.toLowerCase()}_$timestamp${isImage ? '.jpg' : '.pdf'}';

    // Download the file from the server
    final response = await http.get(Uri.parse(encodedUrl));

    if (response.statusCode == 200) {
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$uniqueFileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Close loading dialog
      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Show the appropriate viewer in a dialog
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing by tapping outside
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    documentType,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: isImage
                          ? Image.file(
                              file,
                              fit: BoxFit.contain,
                              // Disable caching for this image
                              cacheWidth: null,
                              cacheHeight: null,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    'Error loading image: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                );
                              },
                            )
                          : PDFView(
                              filePath: file.path,
                              enableSwipe: true,
                              swipeHorizontal: true,
                              autoSpacing: true,
                              onError: (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading PDF: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (documentType == 'Invoice') {
                            updateInvoice(context, orderId, reloadPage);
                          } else {
                            updateCmr(context, orderId, reloadPage);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 20 : 24,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          backgroundColor: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 20 : 24,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${Globals.getText('orderClose')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Clean up the temporary file after dialog is closed
      if (file.existsSync()) {
        await file.delete();
      }
    } else {
      // Close loading dialog before showing error
      if (!context.mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load document: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    // Close loading dialog before showing error
    if (!context.mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error loading document: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void updateUit(BuildContext context, int orderId, Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  String? newUit;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${Globals.getText('orderUpdate')} UIT",
                style: TextStyle(
                  fontSize: isSmallScreen ? 30.0 : 34.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: '${Globals.getText('orderUit')}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) => newUit = value,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '${Globals.getText('orderCancel')}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (newUit?.isNotEmpty ?? false) {
                        try {
                          await DeliveryService()
                              .updateOrderUit(orderId, newUit!);
                          Navigator.pop(context);
                          reloadPage();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('UIT updated successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('${Globals.getText('orderUpdate')}',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void updateEkr(BuildContext context, int orderId, Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  String? newEkr;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${Globals.getText('orderUpdate')} EKR",
                style: TextStyle(
                  fontSize: isSmallScreen ? 30.0 : 34.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: '${Globals.getText('orderEkr')}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) => newEkr = value,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '${Globals.getText('orderCancel')}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (newEkr?.isNotEmpty ?? false) {
                        try {
                          await DeliveryService()
                              .updateOrderEkr(orderId, newEkr!);
                          Navigator.pop(context);
                          reloadPage();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('EKR updated successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('${Globals.getText('orderUpdate')}',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void updateInvoice(BuildContext context, int orderId, Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  List<File> selectedFiles = [];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenSize.width * 0.8,
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: isSmallScreen ? 40 : 44,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '${Globals.getText('orderInvoice')}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28.0 : 32.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera Button
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera);
                          if (image != null) {
                            setState(() {
                              selectedFiles.add(File(image.path));
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                      // Gallery Button
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final List<XFile> images =
                              await picker.pickMultiImage();
                          if (images.isNotEmpty) {
                            setState(() {
                              selectedFiles.addAll(
                                  images.map((image) => File(image.path)));
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 1, 160, 226),
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Icon(Icons.photo_library,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8.0),
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedFiles[index],
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedFiles.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '${Globals.getText('orderClose')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: selectedFiles.isEmpty
                            ? null
                            : () async {
                                try {
                                  await DeliveryService().updateOrderInvoice(
                                      orderId, selectedFiles);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Invoices uploaded successfully')),
                                  );
                                  reloadPage();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error: ${e.toString()}')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${Globals.getText('orderUpload')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void updateCmr(BuildContext context, int orderId, Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  List<File> selectedFiles = [];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenSize.width * 0.8,
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.file_copy_outlined,
                        size: isSmallScreen ? 40 : 44,
                        color: Colors.blue.shade700,
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'CMR',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28.0 : 32.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera Button
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.camera);
                          if (image != null) {
                            setState(() {
                              selectedFiles.add(File(image.path));
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child:
                            const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                      // Gallery Button
                      ElevatedButton(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final List<XFile> images =
                              await picker.pickMultiImage();
                          if (images.isNotEmpty) {
                            setState(() {
                              selectedFiles.addAll(
                                  images.map((image) => File(image.path)));
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 1, 160, 226),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: const Icon(Icons.photo_library,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8.0),
                                width: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedFiles[index],
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedFiles.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '${Globals.getText('orderClose')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: selectedFiles.isEmpty
                            ? null
                            : () async {
                                try {
                                  await DeliveryService()
                                      .updateOrderCmr(orderId, selectedFiles);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('CMR uploaded successfully')),
                                  );
                                  reloadPage();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error: ${e.toString()}')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${Globals.getText('orderUpload')}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void updatePhotos(BuildContext context, int orderId, Function reloadPage) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  List<File> selectedFiles = [];
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenSize.width * 0.8,
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: isSmallScreen ? 40 : 44,
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(width: 12.0),
                            Text(
                              '${Globals.getText('orderUploadPhoto')}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 28.0 : 32.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32.0),
                        CircularProgressIndicator(
                          color: const Color.fromARGB(255, 1, 160, 226),
                          strokeWidth: 5.0,
                        ),
                        SizedBox(height: 24.0),
                        Text(
                          '${Globals.getText('orderUploading')}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: isSmallScreen ? 16.0 : 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '${Globals.getText('orderPleaseWait')}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                          ),
                        ),
                        SizedBox(height: 24.0),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.all_inbox,
                              size: isSmallScreen ? 40 : 44,
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(width: 12.0),
                            Text(
                              '${Globals.getText('orderUploadPhoto')}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 28.0 : 32.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Camera Button
                            ElevatedButton(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 70,
                                );
                                if (image != null) {
                                  setState(() {
                                    selectedFiles.add(File(image.path));
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.all(12),
                                shape: CircleBorder(),
                              ),
                              child:
                                  Icon(Icons.camera_alt, color: Colors.white),
                            ),
                            // Gallery Button
                            ElevatedButton(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final List<XFile> images =
                                    await picker.pickMultiImage(
                                  imageQuality: 70,
                                );
                                if (images.isNotEmpty) {
                                  setState(() {
                                    selectedFiles.addAll(
                                      images.map((image) => File(image.path)),
                                    );
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 1, 160, 226),
                                padding: EdgeInsets.all(12),
                                shape: CircleBorder(),
                              ),
                              child: Icon(Icons.photo_library,
                                  color: Colors.white),
                            )
                          ],
                        ),
                        if (selectedFiles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedFiles.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade400),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          selectedFiles[index],
                                          height: 180,
                                          width: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedFiles.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.8),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 20 : 24,
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${Globals.getText('orderCancel')}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14.0 : 16.0,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: selectedFiles.isEmpty
                                  ? null
                                  : () async {
                                      setState(() {
                                        isLoading = true;
                                      });
                                      try {
                                        await DeliveryService()
                                            .updateOrderPhotos(
                                                orderId, selectedFiles);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Succes'),
                                          ),
                                        );
                                        reloadPage();
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Error: ${e.toString()}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 1, 160, 226),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 20 : 24,
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                '${Globals.getText('orderUpload')}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14.0 : 16.0,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
            ),
          );
        },
      );
    },
  );
}

void openPhotos(BuildContext context, int orderId, Function reloadPage) async {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  try {
    // Show a loading indicator while fetching photos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Fetch photos using the getPhotos function
    List<String> photoUrls = await DeliveryService().getPhotos(orderId);

    // Close the loading dialog
    Navigator.of(context).pop();

    // Check if photos were found
    if (photoUrls.isNotEmpty) {
      // Show the photos in a popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Photos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: photoUrls
                  .map((url) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.network(url, fit: BoxFit.cover),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '${Globals.getText('orderCancel')}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14.0 : 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Handle case where no photos are found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos found')),
      );
    }
  } catch (e) {
    // Handle any other errors
    Navigator.of(context).pop(); // Close the loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching photos: $e')),
    );
  }
}

void updateCrates(
    BuildContext context, int orderId, Function reloadPage, Order order) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  String? selectedCrateType;
  int crateQuantity = 0;
  List<Map<String, dynamic>> crateTypes = [];
  bool isLoading = true;

  // Get existing crate data from the order
  final existingCrates = order.collectionUnits
      .where((unit) => unit.type.toLowerCase().contains('crate'))
      .toList();

  // Initialize with first crate's values if it exists
  if (existingCrates.isNotEmpty) {
    selectedCrateType = existingCrates[0].id.toString();
    crateQuantity = existingCrates[0].quantity;
  }

  // Initialize the controller with the current quantity
  final crateQuantityController = TextEditingController(
      text: crateQuantity > 0 ? crateQuantity.toString() : '');

  Future<void> loadCrateTypes(StateSetter setState) async {
    try {
      final types = await DeliveryService().getCollectionUnits('crate', '');
      setState(() {
        crateTypes = types;
        isLoading = false;
      });
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading crate types: $error')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            loadCrateTypes(setState);
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with current value if exists
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'lib/assets/images/crate.jpg',
                          height: isSmallScreen ? 40 : 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Globals.getText('orderCratesTitle'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (crateTypes.isEmpty)
                          Center(
                            child: Text(
                              'No crate types available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: selectedCrateType,
                            hint: Text(Globals.getText('orderCratesType')),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: crateTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['id'].toString(),
                                child: Text(type['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCrateType = value;
                                // Find matching existing crate and set quantity
                                if (value != null) {
                                  final existingCrate =
                                      existingCrates.firstWhere(
                                    (crate) => crate.id.toString() == value,
                                    orElse: () => CollectionUnit(
                                        id: 0, type: '', name: '', quantity: 0),
                                  );
                                  if (existingCrate.id != 0) {
                                    // Check if we found a real crate
                                    crateQuantity = existingCrate.quantity;
                                    crateQuantityController.text =
                                        crateQuantity.toString();
                                  } else {
                                    crateQuantity = 0;
                                    crateQuantityController.text = '';
                                  }
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: crateQuantityController,
                          decoration: InputDecoration(
                            labelText: Globals.getText('orderCratesQuantity'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                              () => crateQuantity = int.tryParse(value) ?? 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Value Display
                  if (existingCrates.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: isSmallScreen ? 18 : 20,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...existingCrates
                              .map(
                                (crate) => Padding(
                                  padding: const EdgeInsets.only(
                                      left: 26, bottom: 4),
                                  child: Text(
                                    '${crate.quantity} ${crate.name}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          Globals.getText('orderCancel'),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (selectedCrateType == null ||
                                crateQuantity <= 0)
                            ? null
                            : () async {
                                try {
                                  await DeliveryService().updateCrates(
                                    orderId,
                                    crateQuantity,
                                    selectedCrateType!,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(Globals.getText(
                                            'orderCratesUpdateSuccess')),
                                      ),
                                    );
                                    reloadPage();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 1, 160, 226),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          Globals.getText('orderUpdate'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// void updateCollectionUnit(BuildContext context, int productId,
//     String productName, int orderId, Function reloadPage) {
//   final screenSize = MediaQuery.of(context).size;
//   final isSmallScreen = screenSize.width < 600;
//   TextEditingController numberController = TextEditingController();

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16.0),
//         ),
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Icon(
//                       Icons.warehouse_rounded,
//                       size: isSmallScreen ? 40 : 44,
//                       color: Colors.blue.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 productName,
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 20.0 : 24.0,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey.shade800,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: TextField(
//                   controller: numberController,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                   decoration: InputDecoration(
//                     labelText: 'Collection Update',
//                     filled: true,
//                     fillColor: Colors.white,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     style: TextButton.styleFrom(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isSmallScreen ? 20 : 24,
//                         vertical: isSmallScreen ? 10 : 12,
//                       ),
//                       backgroundColor: Colors.grey.shade50,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       '${Globals.getText('orderCancel')}',
//                       style: TextStyle(
//                         fontSize: isSmallScreen ? 14.0 : 16.0,
//                         color: Colors.grey.shade700,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   ElevatedButton(
//                     onPressed: () async {
//                       final newValue = int.tryParse(numberController.text);
//                       if (newValue != null) {
//                         try {
//                           await DeliveryService().updateProductCollection(
//                             orderId,
//                             productId,
//                             newValue,
//                           );
//                           if (context.mounted) {
//                             Navigator.pop(context);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(Globals.getText(
//                                     'orderPaletsUpdateSuccess')),
//                               ),
//                             );
//                             reloadPage();
//                           }
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('Error: ${e.toString()}'),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 1, 160, 226),
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isSmallScreen ? 20 : 24,
//                         vertical: isSmallScreen ? 10 : 12,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       '${Globals.getText('orderUpdate')}',
//                       style: const TextStyle(
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
void updateProductDetails(
    BuildContext context,
    int productId,
    String productName,
    int orderId,
    Function reloadPage,
    int currentCollection,
    double currentQuantity) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  // Controllers for the input fields
  TextEditingController quantityController =
      TextEditingController(text: currentQuantity.toString());
  TextEditingController collectionController =
      TextEditingController(text: currentCollection.toString());

  String? selectedContainerType;
  List<Map<String, dynamic>> containerTypes = [];
  bool isLoading = true;
  bool updatedSomething = false;

  Future<void> loadContainerTypes(StateSetter setState) async {
    try {
      final types = await DeliveryService()
          .getCollectionUnits('crate', productId.toString());
      setState(() {
        containerTypes = types;
        // Autofill with first element if available
        if (types.isNotEmpty) {
          selectedContainerType = types[0]['id'].toString();
        }
        isLoading = false;
      });
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading container types: $error')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  // Using showGeneralDialog instead of showDialog to have more control
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            loadContainerTypes(setState);
          }

          Future<void> processUpdate() async {
            try {
              // Dismiss keyboard first to prevent context issues
              FocusScope.of(context).unfocus();

              // Parse the values from input fields
              final double receivedQuantity =
                  double.tryParse(quantityController.text) ?? currentQuantity;
              final int collectionQuantity =
                  int.tryParse(collectionController.text) ?? currentCollection;

              // First try to update the collection/container if needed
              if (selectedContainerType != null) {
                try {
                  await DeliveryService().updateProductCollection(
                    orderId,
                    productId,
                    collectionQuantity,
                    selectedContainerType!,
                  );
                  updatedSomething = true;
                } catch (e) {
                  // If collection update fails but it's not the only update, continue
                  if (receivedQuantity == currentQuantity) {
                    throw e; // Rethrow if this is the only update
                  }
                  // Otherwise log and continue with quantity update
                  print('Warning: Collection update failed: $e');
                }
              }

              // Then, separately update the received quantity if needed
              if (receivedQuantity != currentQuantity) {
                try {
                  await DeliveryService().updateProductReceivedQuantity(
                    orderId,
                    productId,
                    receivedQuantity,
                  );
                  updatedSomething = true;
                } catch (e) {
                  // If already updated collection, show warning but don't fail
                  if (updatedSomething) {
                    print('Warning: Quantity update failed: $e');
                  } else {
                    throw e; // Rethrow if nothing was updated
                  }
                }
              }

              if (context.mounted) {
                Navigator.of(context).pop();
                if (updatedSomething) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product details updated successfully'),
                    ),
                  );
                  reloadPage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No changes were made'),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return SafeArea(
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              // Set insetPadding to control dialog position and ensure it stays accessible
              insetPadding:
                  EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: SingleChildScrollView(
                // Wrap in SingleChildScrollView to allow scrolling when keyboard appears
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: isSmallScreen ? 40 : 44,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20.0 : 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Form fields container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Container unit selection
                            if (isLoading)
                              Center(child: CircularProgressIndicator())
                            else if (containerTypes.isEmpty)
                              Center(
                                child: Text(
                                  'No container types available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${Globals.getText('collection_unit')}:',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14.0 : 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selectedContainerType,
                                    hint: Text('Select container type'),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                    items: containerTypes.map((type) {
                                      return DropdownMenuItem(
                                        value: type['id'].toString(),
                                        child: Text(type['name']),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedContainerType = value;
                                      });
                                    },
                                  ),
                                ],
                              ),

                            SizedBox(height: 16),

                            // Collection quantity input
                            Text(
                              '${Globals.getText('collection_unit')} ${Globals.getText('productTableQuantity')}:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: collectionController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter collection quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              // Add onSubmitted to support keyboard update
                              onSubmitted: (_) {
                                processUpdate();
                              },
                            ),

                            SizedBox(height: 16),

                            // Received quantity input
                            Text(
                              '${Globals.getText('order_received')} (kg):',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                hintText: 'Enter received quantity',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              // Add onSubmitted to support keyboard update
                              onSubmitted: (_) {
                                processUpdate();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Dismiss keyboard before closing dialog
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 20 : 24,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              backgroundColor: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '${Globals.getText('orderCancel')}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: processUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 1, 160, 226),
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 20 : 24,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              '${Globals.getText('orderUpdate')}',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void updatePalets(
    BuildContext context, int orderId, Function reloadPage, Order order) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;
  String? selectedPaletType;
  int paletQuantity = 0;
  List<Map<String, dynamic>> paletTypes = [];
  bool isLoading = true;

  // Get existing pallet data from the order
  final existingPallets = order.collectionUnits
      .where((unit) => unit.type.toLowerCase().contains('pallet'))
      .toList();

  // Initialize with first pallet's values if it exists
  if (existingPallets.isNotEmpty) {
    selectedPaletType = existingPallets[0].id.toString();
    paletQuantity = existingPallets[0].quantity;
  }

  // Initialize the controller with the current quantity
  final paletQuantityController = TextEditingController(
      text: paletQuantity > 0 ? paletQuantity.toString() : '');

  Future<void> loadPaletTypes(StateSetter setState) async {
    try {
      final types = await DeliveryService().getCollectionUnits('pallet', '');
      setState(() {
        paletTypes = types;
        isLoading = false;
      });
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pallet types: $error')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            loadPaletTypes(setState);
          }

          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with current value if exists
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'lib/assets/images/palet.jpg',
                          height: isSmallScreen ? 40 : 44,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Globals.getText('orderPaletsTitle'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (paletTypes.isEmpty)
                          Center(
                            child: Text(
                              'No pallet types available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: selectedPaletType,
                            hint: Text(Globals.getText('orderPaletsType')),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: paletTypes.map((type) {
                              return DropdownMenuItem(
                                value: type['id'].toString(),
                                child: Text(type['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPaletType = value;
                                // Find matching existing pallet and set quantity
                                if (value != null) {
                                  final existingPallet =
                                      existingPallets.firstWhere(
                                    (pallet) => pallet.id.toString() == value,
                                    orElse: () => CollectionUnit(
                                        id: 0, type: '', name: '', quantity: 0),
                                  );
                                  if (existingPallet.id != 0) {
                                    // Check if we found a real pallet
                                    paletQuantity = existingPallet.quantity;
                                    paletQuantityController.text =
                                        paletQuantity.toString();
                                  } else {
                                    paletQuantity = 0;
                                    paletQuantityController.text = '';
                                  }
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: paletQuantityController,
                          decoration: InputDecoration(
                            labelText: Globals.getText('orderPaletsQuantity'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                              () => paletQuantity = int.tryParse(value) ?? 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Value Display
                  if (existingPallets.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: isSmallScreen ? 18 : 20,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...existingPallets
                              .map(
                                (pallet) => Padding(
                                  padding: const EdgeInsets.only(
                                      left: 26, bottom: 4),
                                  child: Text(
                                    '${pallet.quantity} ${pallet.name}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          Globals.getText('orderCancel'),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (selectedPaletType == null ||
                                paletQuantity <= 0)
                            ? null
                            : () async {
                                try {
                                  await DeliveryService().updatePallets(
                                    orderId,
                                    paletQuantity,
                                    selectedPaletType!,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(Globals.getText(
                                            'orderPaletsUpdateSuccess')),
                                      ),
                                    );
                                    reloadPage();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 1, 160, 226),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          Globals.getText('orderUpdate'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void showConfirmationDialog(BuildContext context, Order order,
    Function onConfirm, String collectionUnits) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    order.pickedUp == '0000-00-00 00:00:00'
                        ? Icons.local_shipping
                        : Icons.location_on,
                    size: isSmallScreen ? 48 : 56,
                    color: const Color.fromARGB(255, 1, 160, 226),
                  ),
                  const SizedBox(width: 8),
                  if (order.pickedUp == '0000-00-00 00:00:00') ...[
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.red,
                      size: isSmallScreen ? 74 : 80,
                    )
                  ] else
                    order.delivered == '0000-00-00 00:00:00'
                        ? Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.green,
                            size: isSmallScreen ? 74 : 80,
                          )
                        : Container(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                order.pickedUp == '0000-00-00 00:00:00'
                    ? '${Globals.getText('orderConfirmPickupTitle')}'
                    : '${Globals.getText('orderConfirmDeliveryTitle')}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                order.pickedUp == '0000-00-00 00:00:00'
                    ? '${Globals.getText('orderConfirmPickupText')}'
                    : '${Globals.getText('orderConfirmDeliveryText')}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.grey.shade600,
                ),
              ),

              // Collection Units Section
              if (collectionUnits.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: isSmallScreen ? 20 : 24,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${Globals.getText('collectionRequirements')}:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        collectionUnits,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                    child: Text(
                      '${Globals.getText('orderCancel')}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DriverPage()),
                      );
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${Globals.getText('OrderConfirm')}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
