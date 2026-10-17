import 'package:flutter/material.dart';
import 'routes/app_pages.dart'; // Sesuaikan path file AppPages kamu

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // PASTI-KAN menggunakan .router !
    return MaterialApp.router(
      title: 'Field Survey',
      debugShowCheckedModeBanner: false,
      routerConfig: AppPages.router, // <--- Hubungkan di sini
    );
  }
}