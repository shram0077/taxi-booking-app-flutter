import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:taxi/Constant/colors.dart';
import 'package:taxi/Screens/Phone_Authentication/Information_pages/VIewModels/passenger_info_models.dart';
import 'package:taxi/Utils/texts.dart';

class PassenersInformaion extends StatelessWidget {
  final String phoneNo;
  const PassenersInformaion({super.key, required this.phoneNo});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PassengerInfoViewModel(phoneNo: phoneNo),
      child: Consumer<PassengerInfoViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: robotoText("Information", blackColor, 20, FontWeight.w500),
              backgroundColor: whiteColor,
              elevation: 0.8,
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 12),
                robotoText(
                    "Create Your Profile", blackColor, 32, FontWeight.normal),
                const SizedBox(height: 5),
                robotoText(
                  "Tell us a little about yourself, and we’ll get you set up.",
                  blackColor.withOpacity(0.6),
                  16,
                  FontWeight.normal,
                ),
                const SizedBox(height: 18),
                _ProfileImagePicker(),
                const SizedBox(height: 50),
                _PassengerForm(),
                const SizedBox(height: 40),
              ],
            ),
            floatingActionButton: _SubmitButton(),
          );
        },
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PassengerInfoViewModel>();
    return Center(
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              border: Border.all(
                  width: 4, color: Theme.of(context).scaffoldBackgroundColor),
              boxShadow: [
                BoxShadow(
                  spreadRadius: 2,
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 10),
                ),
              ],
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: viewModel.image == null
                    ? const AssetImage("assets/images/user_avatar.png")
                        as ImageProvider
                    : FileImage(viewModel.image!),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => viewModel.pickImage(ImageSource.gallery),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 4,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  color: Colors.green,
                ),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerForm extends StatelessWidget {
  final List<String> _genders = ['Male', 'Female'];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PassengerInfoViewModel>();
    return Form(
      key: viewModel.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: viewModel.nameController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Ali Kareem',
              hintStyle: GoogleFonts.roboto(
                  color: blackColor.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: splashGreenBGColor, width: 2.0),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: viewModel.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'e.g. example@gmail.com',
              hintStyle: GoogleFonts.roboto(
                  color: blackColor.withOpacity(0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: splashGreenBGColor, width: 2.0),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              final pattern =
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
              final regex = RegExp(pattern);
              if (!regex.hasMatch(value.trim())) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: context.watch<PassengerInfoViewModel>().selectedGender,
            items: _genders
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) {
              context.read<PassengerInfoViewModel>().setGender(value);
            },
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
            ),
            validator: (value) =>
                value == null ? 'Please select a gender' : null,
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PassengerInfoViewModel>();
    return FloatingActionButton(
      onPressed: viewModel.isLoading ? null : () => viewModel.submit(context),
      backgroundColor: splashGreenBGColor,
      child: viewModel.isLoading
          ? Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  value: viewModel.uploadProgress,
                  strokeWidth: 3,
                ),
                Text(
                  '${(viewModel.uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            )
          : const Icon(CupertinoIcons.arrow_right, color: Colors.white),
    );
  }
}
