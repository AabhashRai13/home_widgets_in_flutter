import 'package:flutter/material.dart';

void main() {
  runApp(const BadApp());
}

class BadApp extends StatelessWidget {
  const BadApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded theme-ish styling here and in children (anti-pattern)
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BadScreen(),
    );
  }
}

class BadScreen extends StatefulWidget {
  const BadScreen({super.key});

  @override
  State<BadScreen> createState() => _BadScreenState();
}

class _BadScreenState extends State<BadScreen> {
  int counter = 0;
  bool isSelected = false; 
  final items = List<String>.generate(1000, (i) => "Item $i"); 

  Future<String> fetchData() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return "some data from pretend API";
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Naïve Demo",
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue, 
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  "Counter: $counter",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      counter++; 
                    });
                  },
                  child: const Text("Increment"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      counter = counter > 0 ? counter - 1 : 0;
                    });
                  },
                  child: const Text("Decrement"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FutureBuilder<String>(
              future: fetchData(), // BAD: runs again whenever build() runs
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                return Text(
                  "API: ${snapshot.data}",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: items
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue), // hardcoded
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView(
              children: List.generate(100, (index) {
                return ListTile(
                  title:
                      Text("Row $index", style: const TextStyle(fontSize: 16)),
                  trailing: Switch(
                    value: isSelected, // BAD: every row uses SAME flag
                    onChanged: (val) {
                      setState(() {
                        isSelected = val; // flips ALL rows at once
                      });
                    },
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
