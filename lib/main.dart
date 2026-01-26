import 'package:ftpulse/app_initializer.dart';
import 'package:ftpulse/core/imports.dart';
import 'package:ftpulse/presentation/pages/home_page.dart';

void main() {
  initApp();
}

class FTPulse extends StatelessWidget {
  const FTPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FTPulse',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            const LiquidBackground(),

            if (child != null) child,
          ],
        );
      },
      home: const HomePage(),
    );
  }
}
