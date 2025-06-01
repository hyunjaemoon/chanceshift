import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'firebase_options.dart';
import 'intro_game.dart';
import 'chanceshfit_logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Error initializing Firebase
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GenerativeModel _currentModel;
  late ImagenModel _currentImagenModel;
  late ChanceShiftLogic _chanceShiftLogic;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _initializeModel(false);
      _chanceShiftLogic = ChanceShiftLogic(
        imageModel: _currentImagenModel,
        generativeModel: _currentModel,
      );
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing app: $e';
      });
    }
  }

  Future<void> _initializeModel(bool useVertexBackend) async {
    var generationConfig = ImagenGenerationConfig(
      negativePrompt: 'frog',
      numberOfImages: 1,
      aspectRatio: ImagenAspectRatio.square1x1,
      imageFormat: ImagenFormat.jpeg(compressionQuality: 75),
    );

    try {
      if (useVertexBackend) {
        final vertexInstance =
            FirebaseVertexAI.instanceFor(auth: FirebaseAuth.instance);
        _currentModel =
            vertexInstance.generativeModel(model: 'gemini-2.0-flash');
        _currentImagenModel = vertexInstance.imagenModel(
          model: 'imagen-3.0-generate-001',
          generationConfig: generationConfig,
          safetySettings: ImagenSafetySettings(
            ImagenSafetyFilterLevel.blockLowAndAbove,
            ImagenPersonFilterLevel.allowAdult,
          ),
        );
      } else {
        final googleAI = FirebaseAI.googleAI(auth: FirebaseAuth.instance);
        _currentModel = googleAI.generativeModel(model: 'gemini-2.0-flash');
        _currentImagenModel = googleAI.imagenModel(
          model: 'imagen-3.0-generate-001',
          generationConfig: generationConfig,
          safetySettings: ImagenSafetySettings(
            ImagenSafetyFilterLevel.blockLowAndAbove,
            ImagenPersonFilterLevel.allowAdult,
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to initialize AI models: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chanceshift',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _isInitialized
          ? IntroPage(chanceShiftLogic: _chanceShiftLogic)
          : Scaffold(
              body: Center(
                child: _errorMessage != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeApp,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
    );
  }
}
