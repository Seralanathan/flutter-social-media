import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/profile.dart';
import 'package:social_media/widgets/nav_bar.dart';
import 'auth/auth_provider.dart';
import 'auth/auth_screen.dart';
import 'form/form_provider.dart';
import 'form/form_screen.dart';
import 'home/home.dart';
import 'reels/reels_provider.dart';
import 'reels/reels_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(
    create: (_) => AuthProvider()..restore(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.deepPurple.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
        ),
      ),
      home: auth.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.user == null
          ? const AuthScreen()
          : const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReelsProvider(user.mobile)..load()),
        ChangeNotifierProvider(create: (_) => DynamicFormProvider()..loadFromAsset('assets/form/employee_form.json')),      ],
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _index, children: [
          const HomeScreen(),
          ReelsScreen(tabActive: _index == 1),
          const DynamicFormScreen(),
          const ProfileScreen(),
          // Center(
          //   child: Column(mainAxisSize: MainAxisSize.min, children: [
          //     Text('${user.name}\n${user.mobile}', textAlign: TextAlign.center),
          //     const SizedBox(height: 12),
          //     FilledButton(onPressed: () => context.read<AuthProvider>().logout(), child: const Text('Logout')),
          //   ]),
          // ),
        ]),
        bottomNavigationBar: FancyNavBar(
          selectedIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
            NavItem(Icons.play_circle_outline, Icons.play_circle_rounded, 'Reels'),
            NavItem(Icons.dynamic_form_outlined, Icons.dynamic_form, 'Form'),
            NavItem(Icons.person_outline, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }
}