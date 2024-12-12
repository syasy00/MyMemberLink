import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:my_member_link/myconfig.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String startDateTime = "", endDateTime = "";
  String dropdowndefaultvalue = 'Conference';
  var items = [
    'Conference',
    'Exhibition',
    'Seminar',
    'Hackathon',
  ];
  late double screenWidth, screenHeight;

  File? _image;
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventLocationController =
      TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Event"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image picker area
              GestureDetector(
                onTap: () {
                  showSelectionDialog();
                },
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.contain,
                      image: _image == null
                          ? const AssetImage("assets/camera.jpg")
                          : FileImage(_image!) as ImageProvider,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey),
                  ),
                  height: screenHeight * 0.4,
                ),
              ),
              const SizedBox(height: 10),
              // Form fields
              TextFormField(
                controller: _eventTitleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  hintText: "Event Title",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    child: Column(
                      children: [
                        const Text("Select Start Date"),
                        Text(startDateTime),
                      ],
                    ),
                    onTap: () {
                      _selectDateTime(true);
                    },
                  ),
                  GestureDetector(
                    child: Column(
                      children: [
                        const Text("Select End Date"),
                        Text(endDateTime),
                      ],
                    ),
                    onTap: () {
                      _selectDateTime(false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _eventLocationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  hintText: "Event Location",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                value: dropdowndefaultvalue,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: items.map((String item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdowndefaultvalue = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _eventDescriptionController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  hintText: "Event Description",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              MaterialButton(
                elevation: 10,
                onPressed: _insertEvent,
                minWidth: screenWidth,
                height: 50,
                color: Theme.of(context).colorScheme.secondary,
                child: Text(
                  "Insert",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select from"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(screenWidth / 4, screenHeight / 8),
                ),
                child: const Text('Gallery'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectFromGallery();
                },
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(screenWidth / 4, screenHeight / 8),
                ),
                child: const Text('Camera'),
                onPressed: () {
                  print("Camera button clicked");
                  Navigator.of(context).pop();
                  _selectFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectFromCamera() async {
    PermissionStatus cameraPermission = await Permission.camera.request();
    if (cameraPermission.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 800,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        cropImage();
      }
    } else {
      _showPermissionError('Camera permission is required.');
    }
  }

  Future<void> _selectFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 800,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      cropImage();
    }
  }

  Future<void> cropImage() async {
    final ImageCropper imageCropper = ImageCropper();
    CroppedFile? croppedFile = await imageCropper.cropImage(
      sourcePath: _image!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Please Crop Your Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _image = File(croppedFile.path);
      });
    }
  }

  Future<void> _insertEvent() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (startDateTime.isEmpty || endDateTime.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both start and end dates')),
        );
        return;
      }

      String eventTitle = _eventTitleController.text;
      String eventLocation = _eventLocationController.text;
      String eventDescription = _eventDescriptionController.text;
      String imagePath = _image?.path ?? "";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${MyConfig.servername}/memberlink/api/insert_event.php"),
      );

      request.fields['title'] = eventTitle;
      request.fields['location'] = eventLocation;
      request.fields['description'] = eventDescription;
      request.fields['start_datetime'] = startDateTime;
      request.fields['end_datetime'] = endDateTime;
      request.fields['event_type'] = dropdowndefaultvalue;

      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      var response = await request.send();

      // Get the response body for better error handling
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added successfully!')),
        );
      } else {
        print(
            "Failed to add event. Response: $responseBody"); // Log response body
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add event. $responseBody')),
        );
      }
    }
  }

  Future<void> _selectDateTime(bool isStartDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ));

        setState(() {
          if (isStartDate) {
            startDateTime = formattedDate;
          } else {
            endDateTime = formattedDate;
          }
        });
      }
    }
  }

  void _showPermissionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}