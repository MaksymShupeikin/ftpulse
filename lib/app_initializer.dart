import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/main.dart';

Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storageService = StorageService();

  final savedConnections = await storageService.loadConnections();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConnectionsProvider(
            initialConnections: savedConnections,
          ),
        ),
      ],
      child: FTPulse(),
    ),
  );
}
