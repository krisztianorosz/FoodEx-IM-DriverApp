import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart';
import 'driverPage.dart'; // Import DriverPage
import 'package:workmanager/workmanager.dart';

import 'main.dart';

class Car {
  final int id;
  final String name;
  final String numberPlate;

  Car({required this.id, required this.name, required this.numberPlate});

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      name: json['name'] as String,
      numberPlate: json['numberplate'] as String,
    );
  }
}

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  final _kmController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _image6;
  File? _image7;
  File? _image8;
  File? _image9;
  File? _image10;
  File? parcursOut;

  bool _isLoading = false; // No longer fetching car details
  String? _errorMessage;
  int? _lastKm;

  @override
  void initState() {
    super.initState();
    getLastKm(Globals.userId, Globals.vehicleID);
  }

  Future<bool> getLastKm(int? driverId, int? vehicleId) async {
    try {
      final response = await http.post(
        Uri.parse('https://vinczefi.com/foodexim/functions.php'),
        headers: <String, String>{
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'get-last-km',
          'driver_id': driverId.toString(),
          'vehicle_id': vehicleId.toString(),
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Response data: $data'); // Debug print to check the response

        if (data is bool && data == false) {
          setState(() {
            _lastKm = 0; // Set to 0 if no data is found
            _errorMessage = null; // Clear any previous error messages
          });
          return true; // Allow the process to continue
        } else if (data != null &&
            (data is int || int.tryParse(data.toString()) != null)) {
          setState(() {
            _lastKm = int.parse(data.toString());
            _errorMessage = null;
          });
          return true;
        } else {
          setState(() {
            _errorMessage = 'Invalid response data';
          });
          return false;
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load last KM: ${response.statusCode}';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching last KM: $e';
      });
      return false;
    }
  }

  Future<void> _getImage(int imageNumber) async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          switch (imageNumber) {
            case 1:
              _image6 = File(pickedFile.path);
              break;
            case 2:
              _image7 = File(pickedFile.path);
              break;
            case 3:
              _image8 = File(pickedFile.path);
              break;
            case 4:
              _image9 = File(pickedFile.path);
              break;
            case 5:
              _image10 = File(pickedFile.path);
              break;
            case 6:
              parcursOut = File(pickedFile.path);
          }
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImage(File? image) {
    if (image == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Picture'),
            content: const Text('There is no picture available.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Image.file(
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageInput(int imageNumber, File? image) {
    String label;
    switch (imageNumber) {
      case 1:
        label = 'Dash/Műszerfal';
        break;
      case 2:
        label = 'Front left';
        break;
      case 3:
        label = 'Front Right';
        break;
      case 4:
        label = 'Rear Left';
        break;
      case 5:
        label = 'Rear Right';
        break;
      case 6:
        label = 'LogBook/Menetlevél';
        break;
      default:
        label = 'Unknown';
    }
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: 150,
      width: screenWidth * 0.4,
      decoration: BoxDecoration(
        color: image != null
            ? const Color.fromARGB(255, 1, 160, 226)
            : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          width: 1,
          color: Colors.black,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black),
                ),
                if (image != null) const Icon(Icons.check, color: Colors.black),
                const SizedBox(height: 8),
              ],
            ),
            ElevatedButton(
              onPressed: () => _getImage(imageNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(
                    color: Color.fromARGB(255, 1, 160, 226), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Take a picture'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showImage(image),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(
                    color: Color.fromARGB(255, 1, 160, 226), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Preview'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoggingOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 1, 160, 226), // Light blue color
                  ),
                ),
                SizedBox(width: 16),
                Text("Logging out of vehicle"),
              ],
            ),
          ),
        );
      },
    );
  }


  void _hideLoggingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _submitData() async {
    if (_kmController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please enter the KM.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_image6 == null ||
        _image7 == null ||
        _image8 == null ||
        _image9 == null ||
        _image10 == null ||
        parcursOut == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please take all required pictures.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    Globals.image6 = _image6;
    Globals.image7 = _image7;
    Globals.image8 = _image8;
    Globals.image9 = _image9;
    Globals.image10 = _image10;
    Globals.kmValue = _kmController.text;
    Globals.parcursOut = parcursOut;

    int? userID = Globals.userId;
    int? carId = Globals.vehicleID;

    bool isKmValid = await getLastKm(userID!, carId!);
    if (!isKmValid) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Invalid KM data. Please check and try again.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Handle user input KM validation
    if (int.tryParse(_kmController.text) != null) {
      int userInputKm = int.parse(_kmController.text);

      // Allow user input KM to be equal to or greater than last KM
      if (userInputKm < _lastKm!) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(
                  'The entered KM must be greater than or equal to the last logged KM.\nLast km: $_lastKm'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    _showLoggingOutDialog(); // Show logging out dialog
    bool loginSuccessful = await loginVehicle();

    if (loginSuccessful) {
      Workmanager().registerOneOffTask(
        "2",
        uploadImageTask,
        inputData: {
          'userId': Globals.userId.toString(),
          'vehicleID': Globals.vehicleID.toString(),
          'km': _kmController.text,
          'image1': Globals.image6?.path,
          'image2': Globals.image7?.path,
          'image3': Globals.image8?.path,
          'image4': Globals.image9?.path,
          'image5': Globals.image10?.path,
          'image6': Globals.parcursOut?.path
        },
      );

      _hideLoggingDialog();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove('vehicleId');
      Globals.vehicleID = null;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DriverPage(),
        ),
      );
    } else {
      _hideLoggingDialog();

      // Show an error message to the user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Failed'),
            content: const Text(
                'There was an error logging in the vehicle. The vehicle data will now be reset.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  //_resetVehicleData(); // Reset vehicle-related data only
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverPage(),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "Logout My Car",
          style: TextStyle(
            color: Colors.white
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 1, 160, 226),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromARGB(255, 1, 160, 226), // Light blue color
                    ),
                  ),
                  SizedBox(width: 16),
                  Text("Fetching vehicle details..."),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.6),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              // Use Column to stack elements vertically
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align children to the start
                              children: [
                                TextField(
                                  controller: _kmController,
                                  cursorColor:
                                      const Color.fromARGB(255, 1, 160, 226),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'KM',
                                    labelStyle: const TextStyle(
                                      color: Color.fromARGB(255, 1, 160, 226),
                                    ),
                                    hintText:
                                        'Last KM: $_lastKm', // Add placeholder text here
                                    hintStyle: TextStyle(
                                      color: Colors.grey
                                          .shade400, // Optional: customize the hint text color
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 1, 160, 226),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Color.fromARGB(255, 1, 160, 226),
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 1, 160, 226),
                                  ),
                                ),

                                const SizedBox(
                                    height:
                                        16), // Space between the TextField and the Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildImageInput(1, _image6),
                                    _buildImageInput(6, parcursOut),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.6),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .center, // Center aligns the icon and text
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 24,
                                    ),
                                    SizedBox(
                                        width:
                                            8), // Space between the icon and the text
                                    Text(
                                      'Photos',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildImageInput(2, _image7),
                                    _buildImageInput(3, _image8),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildImageInput(4, _image9),
                                    _buildImageInput(5, _image10),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 150,
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 1, 160, 226),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              textStyle: const TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }
}
