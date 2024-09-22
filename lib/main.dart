import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  Gemini.init(apiKey: 'API-KEY-HERE');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Math Solving App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? imageQuestion;
  String? answer;
  bool isLoading = false;
  void selectImageFromGallery() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);

    CroppedFile? croppedFile =
        await ImageCropper().cropImage(sourcePath: image!.path, uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Cropper',
        toolbarColor: Colors.deepOrange,
        toolbarWidgetColor: Colors.white,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPresetCustom(),
        ],
      ),
    ]);

    setState(() {
      imageQuestion = XFile(croppedFile!.path);
      isLoading = true;
    });

    final gemini = Gemini.instance;

    gemini.textAndImage(
        text: "Can you solve this equation?",

        /// text
        images: [await imageQuestion!.readAsBytes()]

        /// list of images
        ).then((value) {
      setState(() {
        answer = value?.content?.parts?.last.text ?? '';
        isLoading = false;
      });
      // ignore: invalid_return_type_for_catch_error
    }).catchError((e) => log('textAndImageInput', error: e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b1c1c),
      appBar: AppBar(
        backgroundColor: const Color(0xff1b1c1c),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
              alignment: Alignment.center,
              height: imageQuestion == null ? 300 : null,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Color(0xff242c2c)),
              child: imageQuestion == null
                  ? const Text(
                      'No Image Selected',
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    )
                  : Image.file(
                      File(imageQuestion!.path),
                      fit: BoxFit.fill,
                    )),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue)),
              onPressed: () {
                selectImageFromGallery();
              },
              child: const Text(
                'Select Image',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              )),
          const SizedBox(
            height: 20,
          ),
          isLoading == false && answer == null
              ? const SizedBox.shrink()
              : isLoading != false
                  ? const CircularProgressIndicator(
                      color: Colors.blue,
                    )
                  : Text(
                      answer ?? '',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18.0),
                      textAlign: TextAlign.start,
                    )
        ],
      ),
    );
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
