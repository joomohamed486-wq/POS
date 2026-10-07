
import 'package:flutter/material.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/pos/presentation/pages/pos_page.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'features/sales/presentation/pages/sales_page.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام إدارة المحل',
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    PosPage(),
    ProductsPage(),
    ReportsPage(),
    SalesPage(),
  ];

  final labels = const [
    'الرئيسية',
    'الكاشير',
    'المنتجات',
    'التقارير',
    'المبيعات',
  ];

  final icons = const [
    Icons.dashboard_outlined,
    Icons.point_of_sale,
    Icons.inventory_2_outlined,
    Icons.analytics_outlined,
    Icons.receipt_long_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: List.generate(
          labels.length,
          (i) => NavigationDestination(
            icon: Icon(icons[i]),
            selectedIcon: Icon(icons[i]),
            label: labels[i],
          ),
        ),
      ),
    );
  }
}
