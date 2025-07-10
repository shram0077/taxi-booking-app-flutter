import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/Phone_Authentication/OTP_Verification.dart';
import 'package:taxi/Utils/texts.dart';

class DriverInfoForm extends StatefulWidget {
  final String phoneNo;
  const DriverInfoForm({
    super.key,
    required this.phoneNo,
  });
  @override
  _DriverInfoFormState createState() => _DriverInfoFormState();
}

class _DriverInfoFormState extends State<DriverInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  bool _isSubmitting = false;

  String? name;
  String? _selectedCarBrand;
  String? _selectedCarModel;
  String? _selectedGender;
  String? _provinceNumebr;
  String? _plateNumber;
  // List of car types
  final List<String> _carBrand = [
    'Nissan',
    'Toyota',
    'Chevrolet',
    'Mazda',
    'Hyundai',
    'Skoda',
  ];
  // Map of car brands and their models
  final Map<String, List<String>> _carModels = {
    'Nissan': [
      'Altima',
      'Sentra',
      'Maxima',
      '370Z',
      'Leaf',
      'Rogue',
      'Murano',
      'Pathfinder',
      'Frontier'
    ],
    'Toyota': [
      'Corolla',
      'Avalon',
      'Yaris',
      'Camry',
      'Prius',
      'RAV4',
      'Highlander',
      'Tacoma',
      'Sienna'
    ],
    'Chevrolet': [
      'Malibu',
      'Impala',
      'Cruze',
      'Camaro',
      'Equinox',
      'Silverado',
      'Traverse',
      'Bolt',
      'Tahoe'
    ],
    'Mazda': [
      'Mazda3',
      'Mazda6',
      'CX-5',
      'CX-9',
      'MX-5 Miata',
      'Mazda2',
      'Mazda CX-30'
    ],
    'Hyundai': [
      'Elantra',
      'Sonata',
      'Tucson',
      'Santa Fe',
      'Kona',
      'Palisade',
      'Accent',
      'Ioniq',
      'Genesis'
    ],
    'Skoda': [
      'Octavia',
      'Superb',
      'Rapid',
      'Fabia',
      'Karoq',
      'Kodiaq',
      'Scala',
      'Kamiq'
    ],
  };

  // List of genders
  final List<String> _genders = [
    'Male',
    'Female',
  ];

  String? _selectedLetter;

  // List of letters (A-Z) for the car plate
  final List<String> _letters =
      List.generate(26, (index) => String.fromCharCode(index + 65));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isSubmitting ? null : submitForm,
        backgroundColor: splashGreenBGColor,
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Icon(CupertinoIcons.arrow_right, color: whiteColor),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: robotoText("Informations", blackColor, 20, FontWeight.w500),
        backgroundColor: whiteColor,
        elevation: 0.8,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 20, top: 10),
            child: robotoText(
                "Tell us a little about yourself and your car, and we’ll get you set up.",
                blackColor.withOpacity(0.6),
                16,
                FontWeight.normal),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    onChanged: (value) {
                      name = value;
                    },
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Ali Kareem',
                      hintStyle: GoogleFonts.roboto(
                          color: blackColor.withOpacity(0.3),
                          fontSize: 14,
                          fontWeight: FontWeight.normal),
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        borderSide:
                            BorderSide(color: splashGreenBGColor, width: 2.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value)) {
                        return 'Only letters and spaces are allowed';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 11,
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    items: _genders.map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a gender';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 11,
                  ),
                  Divider(),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, bottom: 15),
                        child: robotoText("What are you driving?",
                            blackColor.withOpacity(0.6), 17, FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Brand of the cars
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCarBrand,
                          items: _carBrand.map((brand) {
                            return DropdownMenuItem<String>(
                              value: brand,
                              child: Text(brand),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCarBrand = value;
                              _selectedCarModel =
                                  null; // Reset car model when brand changes
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Car Brand',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: splashGreenBGColor, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a car brand';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Model Of Cars
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Container(
                          width: 0.52,
                          height: 38,
                          color: blackColor,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: _selectedCarModel,
                          items: _selectedCarBrand != null
                              ? _carModels[_selectedCarBrand]!.map((model) {
                                  return DropdownMenuItem<String>(
                                    value: model,
                                    child: Text(model),
                                  );
                                }).toList()
                              : [],
                          onChanged: (value) {
                            setState(() {
                              _selectedCarModel = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Car Model',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: splashGreenBGColor, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a car model';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          onChanged: (value) {
                            setState(() {
                              _provinceNumebr = value;
                            });
                          },
                          controller: _provinceController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'province No',
                            hintText: 'e.g. 21',
                            hintStyle: GoogleFonts.roboto(
                                color: blackColor.withOpacity(0.3),
                                fontSize: 14,
                                fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.location_city),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: splashGreenBGColor, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter province number';
                            }
                            final provinceNumber = int.tryParse(value);
                            if (provinceNumber == null || provinceNumber <= 0) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: Container(
                          width: 0.52,
                          height: 38,
                          color: blackColor,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: TextFormField(
                          controller: _plateController,
                          onChanged: (value) {
                            setState(() {
                              _plateNumber = value;
                            });
                          },
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Number',
                            hintText: 'e.g.123456',
                            hintStyle: GoogleFonts.roboto(
                                color: blackColor.withOpacity(0.3),
                                fontSize: 14,
                                fontWeight: FontWeight.normal),
                            prefixIcon: Icon(Icons.car_repair_outlined),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: splashGreenBGColor, width: 2.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a plate number';
                            }
                            if (!RegExp(r'^\d{1,6}$').hasMatch(value)) {
                              return 'Enter a number with up to 6 digits only';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, bottom: 15),
                    child: robotoText("Pick your plate letter.",
                        blackColor.withOpacity(0.6), 17, FontWeight.bold),
                  ),
                  SizedBox(
                    width: 150,
                    child: GestureDetector(
                      onTap: () {
                        _showLetterPicker(context);
                      },
                      child: TextFormField(
                        onChanged: (value) {
                          _selectedLetter = value;
                        },
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: _selectedLetter != null
                              ? "$_selectedLetter"
                              : "e.g.  A",
                          hintStyle: GoogleFonts.roboto(
                              color: blackColor.withOpacity(0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.normal),
                          prefixIcon: Icon(Icons.abc),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                            borderSide: BorderSide(
                                color: splashGreenBGColor, width: 2.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  buildPlate()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPlate() {
    double w = 185;
    double h = 60;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(
            7,
          ),
          color: const Color.fromARGB(255, 244, 242, 242)),
      child: Row(
        children: [
          Flexible(
            child: Container(
              width: 25,
              height: h,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 249, 30, 14),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7),
                      bottomLeft: Radius.circular(7))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "I",
                    style: TextStyle(
                        fontSize: 9.5,
                        color: whiteColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "R",
                    style: TextStyle(
                        fontSize: 9.5,
                        color: whiteColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Q",
                    style: TextStyle(
                        fontSize: 9.5,
                        color: whiteColor,
                        fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 25,
                    color: blackColor.withOpacity(0.9),
                    height: 0.3,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "KR",
                        style: TextStyle(
                            fontSize: 9.7,
                            color: whiteColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 10,
            ),
            child: Row(
              children: [
                Text(
                  "${_provinceNumebr ?? ""} ",
                  style: TextStyle(
                      fontSize: 25,
                      color: blackColor,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _selectedLetter != null ? "$_selectedLetter " : "A ",
                  style: TextStyle(
                      fontSize: 25,
                      color: blackColor,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "${_plateNumber ?? ""} ",
                  style: TextStyle(
                      fontSize: 25,
                      color: blackColor,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Function to show CupertinoPicker
  void _showLetterPicker(BuildContext context) {
    final initialIndex =
        _selectedLetter != null ? _letters.indexOf(_selectedLetter!) : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: CupertinoActionSheet(
            title: robotoText(
                "Pick Your letter", blackColor, 16, FontWeight.normal),
            message: SizedBox(
              height: 150,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 32.0,
                onSelectedItemChanged: (int index) {
                  setState(() {
                    _selectedLetter = _letters[index];
                  });
                },
                children: _letters.map((letter) => Text(letter)).toList(),
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                child: robotoText("Done", blackColor, 16, FontWeight.normal),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void submitForm() {
    if (_isSubmitting) return;

    // Run form validators first
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Please fill out the form correctly.",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Read values from controllers (avoids null mismatch)
    final String name = _nameController.text.trim();
    final String provinceNumber = _provinceController.text.trim();
    final String plateNumber = _plateController.text.trim();

    // Manual validations for dropdowns and picker
    if (_selectedCarBrand == null ||
        _selectedCarModel == null ||
        _selectedGender == null ||
        _selectedLetter == null ||
        name.isEmpty ||
        provinceNumber.isEmpty ||
        plateNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please complete all required fields.",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Show loading and navigate
    setState(() {
      _isSubmitting = true;
    });

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        child: OtpVerification(
          isDriver: true,
          licensePlate:
              "$provinceNumber ${_selectedLetter!.toUpperCase()} $plateNumber",
          carBM: "$_selectedCarBrand,$_selectedCarModel",
          gender: _selectedGender!,
          name: name,
          phoneNo: widget.phoneNo,
          isRegistered: false,
          profilePictureUri: '',
        ),
      ),
    ).then((_) {
      setState(() {
        _isSubmitting = false;
      });
    });
  }
}
