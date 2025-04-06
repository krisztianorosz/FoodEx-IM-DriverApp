import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:foodex/deliveryInfo.dart';
import 'package:foodex/driverPage.dart';
import 'package:foodex/globals.dart';
import 'package:foodex/models/company.dart';
import 'package:foodex/models/contact_person.dart';
import 'package:foodex/models/order.dart';
import 'package:foodex/models/product.dart';
import 'package:foodex/models/warehouse.dart';
import 'package:foodex/services/order_services.dart';
import 'package:foodex/shiftsPage.dart';
import 'package:foodex/widgets/shared_indicators.dart';
import 'package:intl/intl.dart'; // To format dates
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum OrderFilter { all, active, inactive }

final defaultPickupWarehouse = Warehouse(
  warehouseName: 'Unknown Pickup Warehouse',
  warehouseAddress: 'N/A',
  type: 'pickup',
  coordinates: 'N/A', id: 0,
);

final defaultCompany = Company(
  companyName: 'Unknown',
  type: 'unknown', id: 0,
);

final defaultContactPerson = ContactPerson(
  name: 'Unknown',
  telephone: 'Unknown',
  type: 'unknown',
);

class MyRoutesPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const MyRoutesPage({
    Key? key,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _MyRoutesPageState createState() => _MyRoutesPageState();
}

class _MyRoutesPageState extends State<MyRoutesPage>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();

  OrderFilter _currentFilter = OrderFilter.all;
  bool isLoading = true;
  bool isFiltered = false;
  String? errorMessage;

  List<Order> get _filteredOrders {
    switch (_currentFilter) {
      case OrderFilter.all:
        return _orderService.allOrders;
      case OrderFilter.active:
        return _orderService.activeOrders;
      case OrderFilter.inactive:
        return _orderService.inactiveOrders;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInitialOrders();
  }

  Future<void> fetchInitialOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    DateTime fromDate = widget.startDate;
    DateTime toDate = widget.endDate;

    // Format dates exactly as expected by the backend
    String formattedFromDate = DateFormat('yyyy-MM-dd').format(fromDate);
    String formattedToDate = DateFormat('yyyy-MM-dd').format(toDate);

    try {
      await _orderService.fetchAllOrders(
        fromDate: formattedFromDate,
        toDate: formattedToDate,
      );
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching initial orders: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load orders';
      });
    }
  }

  Widget _filterButton(OrderFilter filter, String text) {
    final isSelected = _currentFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.transparent,
        foregroundColor:
            isSelected ? const Color.fromARGB(255, 1, 160, 226) : Colors.white,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: Colors.white,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  //listfunctions

  @override
  void dispose() {
    // Dispose all animation controllers
    super.dispose();
  }

// Keep the original buildProductsTable for compatibility with existing checks

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ShiftsPage()),
        );

        // Prevent default back behavior since we're handling navigation
      },
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ShiftsPage()),
                );
              },
            ),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${Globals.getText('routesTitle')}',
                    style: TextStyle(color: Colors.white)),
                Text(
                  '${DateFormat('MMM dd').format(widget.startDate)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 1, 160, 226),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filterButton(
                        OrderFilter.all, '${Globals.getText('routesAll')}'),
                    _filterButton(OrderFilter.active,
                        '${Globals.getText('routesActive')}'),
                    _filterButton(OrderFilter.inactive,
                        '${Globals.getText('routesDelivered')}'),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: fetchInitialOrders,
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null || _filteredOrders.isEmpty
                  ? Center(
                      child: Text(
                        errorMessage != null
                            ? 'No orders available for this interval.'
                            : 'No ${_currentFilter.name} orders available.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: errorMessage != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        //physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final pickupWarehouse = order.warehouses.firstWhere(
                              (wh) => wh.type == 'pickup',
                              orElse: () => defaultPickupWarehouse);
                          final deliveryWarehouse = order.warehouses.firstWhere(
                              (wh) => wh.type == 'delivery',
                              orElse: () => defaultPickupWarehouse);
                          final pickupCompany = order.companies.firstWhere(
                              (comp) => comp.type == 'pickup',
                              orElse: () => defaultCompany);
                          final deliveryCompany = order.companies.firstWhere(
                              (comp) => comp.type == 'delivery',
                              orElse: () => defaultCompany);
                          final pickupContact = order.contactPeople.firstWhere(
                              (cp) => cp.type == 'pickup',
                              orElse: () => defaultContactPerson);
                          final deliveryContact = order.contactPeople
                              .firstWhere((cp) => cp.type == 'delivery',
                                  orElse: () => defaultContactPerson);

                          return GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DeliveryInfo(
                                        orderId: order.orderId,
                                        myRoutesPage: true,
                                      )),
                            ),
                            child: Stack(
                              children: [
                                Card(
                                  color: order.pickedUp == '0000-00-00 00:00:00'
                                      ? const Color.fromARGB(255, 255, 189,
                                          189) // Changed to red tint for pickup
                                      : Color.fromARGB(255, 166, 250, 118),
                                  elevation: 2.0,
                                  margin: EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: isSmallScreen ? 2.0 : 8.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                        color: Colors.black, width: 1.0),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                        isSmallScreen ? 6.0 : 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                                '${Globals.getText('orderPartner')}: ',
                                                style: TextStyle(
                                                    fontSize: 14.0,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(pickupCompany.companyName,
                                                style: const TextStyle(
                                                    fontSize: 14.0,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8.0),
                                        // Pickup Info
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white, // Changed to red tint
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                            border: Border.all(
                                                color: Colors
                                                    .black), // Changed to red border
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      pickupCompany.companyName,
                                                      style: TextStyle(
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .red)), // Changed to red
                                                  Text(
                                                      DateFormat('MM-dd HH:mm')
                                                          .format(DateTime
                                                              .parse(order
                                                                  .pickupTime)),
                                                      style: const TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${Globals.getText('orderAddress')}: ${pickupWarehouse.warehouseAddress}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12.0))),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SharedIndicators.buildIcon(
                                                          Icons.note_rounded,
                                                          order.upNotes
                                                                  .isNotEmpty
                                                              ? Colors.green
                                                              : Colors.red),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      SharedIndicators
                                                          .buildContactStatus(
                                                        name:
                                                            pickupContact.name,
                                                        telephone: pickupContact
                                                            .telephone,
                                                        isSmallScreen:
                                                            isSmallScreen,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        // Delivery Info
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 6.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white, // Kept green tint
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                            border: Border.all(
                                                color: Colors
                                                    .black), // Kept green border
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      deliveryCompany
                                                          .companyName,
                                                      style: const TextStyle(
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .green)), // Kept green
                                                  Text(
                                                      DateFormat('MM-dd HH:mm')
                                                          .format(DateTime
                                                              .parse(order
                                                                  .deliveryTime)),
                                                      style: const TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${Globals.getText('orderAddress')}: ${deliveryWarehouse.warehouseAddress}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12.0))),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      SharedIndicators.buildIcon(
                                                          Icons.note_rounded,
                                                          order.downNotes
                                                                  .isNotEmpty
                                                              ? Colors.green
                                                              : Colors.red),
                                                      const SizedBox(
                                                          width: 4.0),
                                                      SharedIndicators
                                                          .buildContactStatus(
                                                        name: deliveryContact
                                                            .name,
                                                        telephone:
                                                            deliveryContact
                                                                .telephone,
                                                        isSmallScreen:
                                                            isSmallScreen,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        // Bottom indicators
                                        Wrap(
                                          spacing: 6.0,
                                          runSpacing: 4.0,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    '${order.getTotalOrderedQuantity()} kg',
                                                    style: const TextStyle(
                                                        fontSize: 14.0,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Wrap(
                                                  spacing:
                                                      isSmallScreen ? 8 : 10,
                                                  children: [
                                                    SharedIndicators
                                                        .buildDocumentIndicator(
                                                            'UIT',
                                                            order.uit
                                                                .isNotEmpty),
                                                    SharedIndicators
                                                        .buildDocumentIndicator(
                                                            'EKR',
                                                            order.ekr
                                                                .isNotEmpty),
                                                    SharedIndicators
                                                        .buildDocumentIndicator(
                                                            '${Globals.getText('orderInvoice')}',
                                                            order.invoice
                                                                .isNotEmpty),
                                                    SharedIndicators
                                                        .buildDocumentIndicator(
                                                            'CMR',
                                                            order.cmr
                                                                .isNotEmpty),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Status Arrow
                                if (order.delivered ==
                                    '0000-00-00 00:00:00') ...[
                                  Positioned(
                                    top: 0,
                                    right: isSmallScreen ? 4.0 : 8.0,
                                    child: order.pickedUp ==
                                            '0000-00-00 00:00:00'
                                        ? Icon(Icons.keyboard_arrow_up,
                                            color: Colors.red,
                                            size: isSmallScreen ? 48 : 54)
                                        : order.delivered ==
                                                '0000-00-00 00:00:00'
                                            ? Icon(Icons.keyboard_arrow_down,
                                                color: Colors.green,
                                                size: isSmallScreen ? 48 : 54)
                                            : Container(),
                                  ),
                                ] else
                                  Positioned(
                                      top: isSmallScreen ? 10 : 12,
                                      right: isSmallScreen ? 8 : 12,
                                      child: Text(
                                        "DELIVERED",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      )),
                              ],
                            ),
                          );
                        },
                      ))),
    );
  }
}
