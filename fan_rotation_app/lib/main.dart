import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:video_player/video_player.dart';

void main() {
  runApp(FanRotationApp());
}

class FanRotationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fan Rotation Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: StartPage(),
    );
  }
}

// 🔶 START PAGE
class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "കാറ്റെഷ്",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Image.network(
                  'https://thumbs.dreamstime.com/b/table-fan-cartoon-vector-illustration-44305067.jpg',
                  width: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                "നിങ്ങളുടെ വീട്ടിൽ ഫാൻ ഉണ്ടോ?",
                style: TextStyle(fontSize: 22, color: Colors.black87),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => FanCounterPage()));
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: const Color.fromARGB(255, 212, 92, 13),
                ),
                child: Text(
                  "ഇവിടെ അമർത്തുക",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔶 FAN COUNTER PAGE
class FanCounterPage extends StatefulWidget {
  @override
  _FanCounterPageState createState() => _FanCounterPageState();
}

class _FanCounterPageState extends State<FanCounterPage> {
  String result = "";
  File? selectedVideo;
  bool isProcessing = false;
  VideoPlayerController? _videoController;

  Future<void> uploadVideo() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (picked != null) {
      File file = File(picked.files.single.path!);
      setState(() {
        selectedVideo = file;
        result = "";
        isProcessing = true;
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            setState(() {});
            _videoController!.play();
          });
      });

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.120.169:5000/upload'), // Update your server IP
      );
      request.files.add(await http.MultipartFile.fromPath('video', file.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        var json = jsonDecode(data);

        int rotations = int.parse(double.parse(json['rotations'].toString()).round().toString());

        setState(() {
          result = "$rotations";
          isProcessing = false;
        });
      } else {
        setState(() {
          result = "❌ Error: ${response.statusCode}";
          isProcessing = false;
        });
      }
    } else {
      setState(() {
        result = "❌ No video selected.";
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("കാറ്റെഷ്"),
        backgroundColor: const Color.fromARGB(255, 212, 92, 13),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: uploadVideo,
                  icon: Icon(Icons.upload_file),
                  label: Text("നിങ്ങളുടെ ഫാൻ വീഡിയോ അപ്‌ലോഡ് ചെയ്യുക"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 229, 91, 6),
                  ),
                ),
                SizedBox(height: 20),
                if (_videoController != null &&
                    _videoController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                SizedBox(height: 30),
                if (isProcessing)
                  Text(
                    "ദയവായി കാത്തിരിക്കൂ...",
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                SizedBox(height: 20),
                if (result.isNotEmpty && !isProcessing)
                  Text.rich(
                    TextSpan(
                      text: 'എത്ര തവണ ഫാൻ റൊട്ടേറ്റ് ചെയ്തു: ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: result,
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
