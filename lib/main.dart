import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'prayer_day.dart';

// ====== Constants you MUST customize ======
const String kAppGroupId = 'group.homeTestScreenApp'; // iOS App Group
const String kIOSWidgetKind = 'MyHomeWidget';
const String kAndroidWidgetProvider =
    'MyHomeWidget'; // see Android provider name
const String kAddress = 'Sydney NSW, Australia';  
// A unique name for WorkManager periodic task
const String kWorkName = 'prayer_times_update';
const String kWorkTask = 'updatePrayerTimes';

// ========== Background callback ===========
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background task started: $task');
      if (task == kWorkTask) {
        final prayerDay = await fetchPrayerDayBackground(kAddress);
        await updateWidgetBackground(prayerDay);
        debugPrint('Prayer times updated in background');
      }
      return Future.value(true);
    } catch (e, st) {
      debugPrint('Background task failed: $e\n$st');
      return Future.value(false);
    }
  });
}

// ====== Network fetch helpers (BG-safe) ======
Uri _buildUri(String address) => Uri.https(
      'apis.sadaqawelfarefund.ngo',
      '/api/get_prayer_times',
      {'address': address},
    );

Future<PrayerDay> fetchPrayerDayBackground(String address) async {
  final resp = await http.get(
    _buildUri(address),
    headers: const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
  }
  final decoded = jsonDecode(resp.body);
  final List dataList = decoded is List
      ? decoded
      : (decoded['data'] ?? decoded['days'] ?? decoded['prayer_times'] ?? [])
          as List;
  if (dataList.isEmpty) throw Exception('Empty response list');

  // Debug: log all items to see what we have
  for (int i = 0; i < dataList.length; i++) {
    final item = dataList[i] as Map<String, dynamic>;
    log('Item $i: is_current_day = ${item['is_current_day']}');
  }

  final Map<String, dynamic> chosen = (dataList.firstWhere(
    (e) => e is Map && e['is_current_day'] == true,
    orElse: () => dataList.first,
  )) as Map<String, dynamic>;
  log('chosen: $chosen');
  return PrayerDay.fromJson(chosen);
}

// Save to shared storage + ping widgets (BG-safe)
Future<void> updateWidgetBackground(PrayerDay d) async {
  log('updateWidgetBackground: $d');
  for (final entry in d.asStrings().entries) {
    await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
  }
  // Optional metadata
  final now = DateTime.now();
  await HomeWidget.saveWidgetData<String>('last_updated',
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
  await HomeWidget.saveWidgetData<String>(
      'company_name', 'Sadaqa Welfare Fund');

  // Nudge both platforms
  await HomeWidget.updateWidget(
    iOSName: kIOSWidgetKind,
    androidName: kAndroidWidgetProvider,
  );
}

// ============ App ===============
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set App Group for iOS
  HomeWidget.setAppGroupId(kAppGroupId);

  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatcher);

  // Register periodic (Android real periodic; iOS = opportunistic)
  await Workmanager().registerPeriodicTask(
    kWorkName,
    kWorkTask,
    frequency: const Duration(
        hours: 6), // >= 15 minutes on Android; iOS ignored cadence
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    // Note: for iOS Workmanager just wraps BGTask; schedule is best-effort.
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Widget Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _primeOnce();
  }

  Future<void> _primeOnce() async {
    try {
      final d = await fetchPrayerDayBackground(kAddress);
      log('d: ${d.date}');
      await updateWidgetBackground(d);
      setState(() => _status = 'Primed widget for ${d.date}');
    } catch (e) {
      setState(() => _status = 'Prime failed: $e');
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _status = 'Refreshing...');
    try {
      final d = await fetchPrayerDayBackground(kAddress);
      await updateWidgetBackground(d);
      setState(() => _status = 'Updated at ${DateTime.now()}');
    } catch (e) {
      setState(() => _status = 'Refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prayer Home Widget Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status ?? 'Ready'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _manualRefresh,
              child: const Text('Manual refresh (test BG path)'),
            ),
          ],
        ),
      ),
    );
  }
}
