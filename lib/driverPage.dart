import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodex/ServerUpdate.dart';
import 'package:foodex/deliveryInfo.dart';
import 'package:foodex/expense_log_page.dart';
import 'package:foodex/loginPage.dart';
import 'package:foodex/logoutPage.dart';
import 'package:foodex/main.dart';
import 'package:foodex/models/company.dart';
import 'package:foodex/models/contact_person.dart';
import 'package:foodex/models/user.dart';
import 'package:foodex/models/warehouse.dart';
import 'package:foodex/myLogs.dart';
import 'package:foodex/services/delivery_service.dart';
import 'package:foodex/services/order_services.dart';
import 'package:foodex/services/shorebird_service.dart';
import 'package:foodex/services/user_service.dart';
import 'package:foodex/shiftsPage.dart';
import 'package:foodex/shorebirdUpdateScreen.dart';
import 'package:foodex/vehicleData.dart';
import 'package:foodex/vehicleExpensePage.dart';
import 'package:foodex/widgets/shared_indicators.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'globals.dart';

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

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  StreamSubscription? _ordersSubscription;
  bool _isLoggedIn = false;
  bool _vehicleLoggedIn = false;
  bool hasOrders = false;
  bool _isLoading = true;

  User? _user;

  final OrderService _orderService = OrderService();
  final deliveryService = DeliveryService();
  final userService = UserService(baseUrl: 'https://vinczefi.com');
  String? errorMessage;
  final ShorebirdCodePush _shorebirdCodePush = ShorebirdCodePush();

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _initializeData();
    _setupOrdersListener();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _checkForUpdates() async {
    try {
      final isUpdateAvailable =
          await _shorebirdCodePush.isNewPatchAvailableForDownload();
      if (isUpdateAvailable) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(Globals.getText('newVersionAvailable')),
            content: Text(Globals.getText('wouldYouLikeToUpdate')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(Globals.getText('later')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Globals.getText('downloadingUpdate')),
                    ),
                  );
                  await _shorebirdCodePush.downloadUpdateIfAvailable();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(Globals.getText('updateComplete')),
                      ),
                    );
                  }
                },
                child: Text(Globals.getText('updateNow')),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Globals.getText('noUpdatesAvailable')),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupOrdersListener() {
    _ordersSubscription = _orderService.ordersStream.listen((orders) {
      setState(() {
        hasOrders = orders.isNotEmpty;
      });
    });
  }

  Future<void> _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedLanguage = prefs.getString('language') ?? 'en';
    setState(() {
      Globals.currentLanguage = savedLanguage;
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    try {
      await _checkLoginStatus();
      final user = await userService.loadUser(Globals.userId!);
      setState(() {
        _user = user;
      });
      await _syncVehicleStatus();
      if (_isLoggedIn && _vehicleLoggedIn) {
        await fetchInitialOrders();
      }
    } catch (e) {
      debugPrint('Error in initialization: $e');
      setState(() {
        errorMessage = 'Error initializing: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncVehicleStatus() async {
    if (Globals.vehicleID != null) {
      setState(() {
        _vehicleLoggedIn = true;
      });
      return;
    }

    try {
      final vehicleId = await _orderService.checkVehicleLogin();
      setState(() {
        _vehicleLoggedIn = vehicleId != null;
      });
    } catch (e) {
      setState(() {
        _vehicleLoggedIn = false;
      });
    }
  }

  Future<void> fetchInitialOrders() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime pastDate = DateTime(today.year, today.month, today.day, 0, 1);
    String formattedPastDate = DateFormat('yyyy-MM-dd').format(pastDate);

    try {
      await _orderService.fetchAllOrders(
          fromDate: formattedPastDate, toDate: formattedPastDate);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        hasOrders = false;
        errorMessage = 'No orders found for today.';
      });
    }
  }

  Future<void> _refreshOrderData() async {
    try {
      // Show loading state if needed
      setState(() {
        _isLoading = true;
      });

      // Refresh orders
      await fetchInitialOrders();

      // Update loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle any errors during refresh
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      _isLoggedIn = false;
      _vehicleLoggedIn = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  Widget _buildBody() {
    final themeColor = const Color.fromARGB(255, 1, 160, 226);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    int? vehicleId = Globals.vehicleID;
    final orders = _orderService.activeOrders;

    Widget buildDateRange() {
      final now = DateTime.now();
      return Column(
        children: [
          Text(
            DateFormat('yyyy-MM-dd').format(now), // Shows date as YYYY-MM-DD
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 20,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE')
                .format(now), // Shows full day name (e.g., "Monday")
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: themeColor,
          strokeWidth: 3,
        ),
      );
    }

    // If we have orders, show the orders list
    if (hasOrders && vehicleId != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderService.activeOrders.length,
          itemBuilder: (context, index) {
            final order = _orderService.activeOrders[index];
            final pickupWarehouse = order.warehouses.firstWhere(
                (wh) => wh.type == 'pickup',
                orElse: () => defaultPickupWarehouse);
            final deliverWarehouse = order.warehouses.firstWhere(
                (wh) => wh.type == 'delivery',
                orElse: () => defaultPickupWarehouse);
            order.warehouses.firstWhere((wh) => wh.type == 'delivery',
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
            final deliveryContact = order.contactPeople.firstWhere(
                (cp) => cp.type == 'delivery',
                orElse: () => defaultContactPerson);

            return GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => DeliveryInfo(orderId: order.orderId)),
              ),
              child: Stack(
                children: [
                  Card(
                    color: order.pickedUp == '0000-00-00 00:00:00'
                        ? const Color.fromARGB(255, 255, 189,
                            189) // Changed to red tint for pickup
                        : Color.fromARGB(255, 166, 250,
                            118), // Changed to green tint for delivery
                    elevation: 2.0,
                    margin: EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: isSmallScreen ? 2.0 : 8.0,
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.black, width: 1.0),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 6.0 : 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${Globals.getText('partner')}: ',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold)),
                              Text(pickupCompany.companyName,
                                  style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          // Pickup Info
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(pickupCompany.companyName,
                                        style: TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .red)), // Changed to red for pickup
                                    Text(
                                        '${Globals.getText(DateFormat('E').format(DateTime.parse(order.pickupTime)))} ${DateFormat('dd.MM').format(DateTime.parse(order.pickupTime))},  ${DateFormat('HH:mm').format(DateTime.parse(order.pickupTime))}',
                                        style: const TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            '${Globals.getText('address')}: ${pickupWarehouse.warehouseAddress}',
                                            style: const TextStyle(
                                                fontSize: 12.0))),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SharedIndicators.buildIcon(
                                            Icons.note_rounded,
                                            order.upNotes.isNotEmpty
                                                ? Colors.green
                                                : Colors.red),
                                        const SizedBox(width: 4.0),
                                        SharedIndicators.buildContactStatus(
                                          name: pickupContact.name,
                                          telephone: pickupContact.telephone,
                                          isSmallScreen: isSmallScreen,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: Colors.black),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(deliveryCompany.companyName,
                                        style: const TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors
                                                .green)), // Changed to green for delivery
                                    Text(
                                        '${Globals.getText(DateFormat('E').format(DateTime.parse(order.deliveryTime)))} ${DateFormat('dd.MM').format(DateTime.parse(order.deliveryTime))},  ${DateFormat('HH:mm').format(DateTime.parse(order.deliveryTime))}',
                                        style: const TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: Text(
                                            '${Globals.getText('address')}: ${deliverWarehouse.warehouseAddress}',
                                            style: const TextStyle(
                                                fontSize: 12.0))),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SharedIndicators.buildIcon(
                                            Icons.note_rounded,
                                            order.downNotes.isNotEmpty
                                                ? Colors.green
                                                : Colors.red),
                                        const SizedBox(width: 4.0),
                                        SharedIndicators.buildContactStatus(
                                          name: deliveryContact.name,
                                          telephone: deliveryContact.telephone,
                                          isSmallScreen: isSmallScreen,
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
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${order.getTotalOrderedQuantity()} kg',
                                      style: const TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold)),
                                  Wrap(
                                    spacing: isSmallScreen ? 8 : 10,
                                    children: [
                                      SharedIndicators.buildDocumentIndicator(
                                          'UIT', order.uit.isNotEmpty),
                                      SharedIndicators.buildDocumentIndicator(
                                          'EKR', order.ekr.isNotEmpty),
                                      SharedIndicators.buildDocumentIndicator(
                                          '${Globals.getText('orderInvoice')}',
                                          order.invoice.isNotEmpty),
                                      SharedIndicators.buildDocumentIndicator(
                                          'CMR', order.cmr.isNotEmpty),
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
                  Positioned(
                    top: 0,
                    right: isSmallScreen ? 4.0 : 8.0,
                    child: order.pickedUp == '0000-00-00 00:00:00'
                        ? Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.red, // Shows red for pickup state
                            size: isSmallScreen ? 48 : 54,
                          )
                        : order.delivered == '0000-00-00 00:00:00'
                            ? Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors
                                    .green, // Shows green for delivery state
                                size: isSmallScreen ? 48 : 54,
                              )
                            : Container(),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // If no orders but vehicle is logged in, show "No orders found"
    if (vehicleId != null) {
      return Center(
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: themeColor,
                      size: isSmallScreen ? 40 : 48,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    buildDateRange(),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'No orders found for today',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              ElevatedButton.icon(
                onPressed: _refreshOrderData,
                icon: Icon(Icons.refresh, size: isSmallScreen ? 20 : 24),
                label: Text(
                  'Check Again',
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If no vehicle logged in, show vehicle login prompt
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car_filled_outlined,
                    color: themeColor,
                    size: isSmallScreen ? 40 : 48,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Text(
                    '${Globals.getText('pleaseLoginVehicle')}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              icon: Icon(Icons.login, size: isSmallScreen ? 20 : 24),
              label: Text(
                '${Globals.getText('loginVehicleButton')}',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(Globals.getText('driverPage'),
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 1, 160, 226),
        actions: [
          if (_vehicleLoggedIn) // Add refresh button when vehicle is logged in
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshOrderData,
              tooltip: 'Refresh Orders',
            ),
        ],
        iconTheme:
            const IconThemeData(color: Colors.white), // For hamburger icon
      ),
      drawer: _buildDrawer(),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                      padding: const EdgeInsets.all(8.0),
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _buildBody()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 1, 160, 226),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  if (_user != null) // Add null check here
                    Text(
                      _user!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.list, color: Color.fromARGB(255, 1, 160, 226)),
            title: Text(Globals.getText('myLogs')),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyLogPage()),
              );
            },
          ),
          if (_vehicleLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.directions_car,
                  color: Color.fromARGB(255, 1, 160, 226)),
              title: Text(Globals.getText("myCar")),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VehicleDataPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money,
                  color: Color.fromARGB(255, 1, 160, 226)),
              title: Text(Globals.getText('expense')),
              onTap: () {
                Navigator.pop(context);
                _showExpenseDialog();
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.punch_clock_rounded,
                color: Color.fromARGB(255, 1, 160, 226)),
            title: Text(Globals.getText('shifts')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ShiftsPage()),
              );
            },
          ),
          const Divider(),
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              int? vehicleId = Globals.vehicleID;
              String label = vehicleId != null
                  ? Globals.getText('logoutVehicle')
                  : Globals.getText('loginVehicle');
              IconData icon = vehicleId != null ? Icons.logout : Icons.login;
              return ListTile(
                leading:
                    Icon(icon, color: const Color.fromARGB(255, 1, 160, 226)),
                title: Text(label),
                onTap: () {
                  Navigator.pop(context);
                  if (vehicleId != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LogoutPage()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  }
                },
              );
            },
          ),
          
          if (!_vehicleLoggedIn) ...[
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                int? userId = Globals.userId;
                String label =
                    userId != null ? 'Logout Account' : 'Login Account';
                IconData icon =
                    userId != null ? Icons.person_off : Icons.person;

                return ListTile(
                  leading:
                      Icon(icon, color: const Color.fromARGB(255, 1, 160, 226)),
                  title: Text(label),
                  onTap: () {
                    _logoutUser();
                  },
                );
              },
            ),
          ],
          const Divider(),

          ListTile(
            leading: const Icon(Icons.system_update,
                color: Color.fromARGB(255, 1, 160, 226)),
            title: Text(
                Globals.getText('checkServerUpdate') ?? 'Check Server Update'),
            onTap: () {
              Navigator.pop(context);
              Globals.isUpdateDialogShowing = true;
              showDialog(
                context: context,
                builder: (BuildContext context) => const ServerUpdateDialog(),
              );
            },
          ),
          const Spacer(),
          //const Divider(),
          // Language Selection SectionG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLanguageButton('en'),
                    _buildLanguageButton('hu'),
                    _buildLanguageButton('ro'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: Text(
              'Version 1.3.11',
              style: TextStyle(
                color: Colors.black,
                fontSize: isSmallScreen ? 16.0 : 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String languageCode) {
    // Flag emojis are created by combining regional indicator symbols
    // Each country code consists of two letters that get converted to regional indicators
    final Map<String, String> flagEmojis = {
      'en': '🇬🇧', // UK flag for English
      'hu': '🇭🇺', // Hungarian flag
      'ro': '🇷🇴', // Romanian flag
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () async {
          // Save selected language to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('language', languageCode);

          // Update current language in Globals
          setState(() {
            Globals.currentLanguage = languageCode;
          });

          debugPrint('Language changed to: $languageCode');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Globals.currentLanguage == languageCode
              ? const Color.fromARGB(255, 1, 160, 226)
              : Colors.grey[300],
          padding: const EdgeInsets.all(12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: Globals.currentLanguage == languageCode
                  ? const Color.fromARGB(255, 1, 160, 226)
                  : Colors.transparent,
              width: 2.0,
            ),
          ),
          minimumSize:
              const Size(48, 48), // Makes buttons square and consistent size
        ),
        child: Text(
          flagEmojis[languageCode] ??
              '🏳️', // Default to white flag if language code not found
          style: const TextStyle(
            fontSize: 24.0, // Make flags larger
          ),
        ),
      ),
    );
  }

  void _showExpenseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'submit_expense',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VehicleExpensePage()),
                  );
                },
                backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    Text(
                      '${Globals.getText('submit')}',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
              FloatingActionButton(
                heroTag: 'expense_log',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ExpenseLogPage()),
                  );
                },
                backgroundColor: const Color.fromARGB(255, 1, 160, 226),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list, color: Colors.white),
                    Text(
                      '${Globals.getText('logs')}',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
