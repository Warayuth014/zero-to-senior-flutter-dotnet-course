import 'package:flutter/material.dart';

void main() {
  runApp(const WarehouseCounterApp());
}

class WarehouseCounterApp extends StatelessWidget {
  const WarehouseCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warehouse Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WarehouseCounterScreen(),
    );
  }
}

class WarehouseCounterScreen extends StatefulWidget {
  const WarehouseCounterScreen({super.key});

  @override
  State<WarehouseCounterScreen> createState() => _WarehouseCounterScreenState();
}

class _WarehouseCounterScreenState extends State<WarehouseCounterScreen> {
  int _itemCount = 0;

  void _addItem() {
    setState(() {
      _itemCount++;
    });
  }

  void _addFiveItems() {
    setState(() {
      _itemCount += 5;
    });
  }

  void _clearItems() {
    setState(() {
      _itemCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 72),
                const SizedBox(height: 20),
                const Text(
                  'สินค้าที่นับได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '$_itemCount รายการ',
                  key: const Key('item-count'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  key: const Key('add-one'),
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('เพิ่มสินค้า'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('add-five'),
                  onPressed: _addFiveItems,
                  child: const Text('เพิ่ม 5 รายการ'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('clear-count'),
                  onPressed: _itemCount == 0 ? null : _clearItems,
                  child: const Text('ล้างจำนวน'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
