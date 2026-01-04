import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;


class BinTelemetry{
  final List<int> compartments;
  final int ts;

  BinTelemetry({required this.compartments, required this.ts});

  factory BinTelemetry.fromJson(Map<String, dynamic> json){
    return BinTelemetry(compartments: (json['compartments'] as List).map((e) => e as int).toList(),
        ts: (json['ts'] is int) ? json['ts'] as int : int.parse('${json['ts']}'),
    );
  }

}

class BinDiscoveryService {
  String? _baseUrl;
  String? get baseUrl => _baseUrl;

  // --- 1) Quick direct test (your known ESP32 IP)
  Future<bool> tryDirect(String ip, {int port = 80}) async {
    final url = 'http://$ip:$port';
    final ok = await _pingHealth(url);
    if (ok) _baseUrl = url;
    return ok;
  }

  // --- 2) Discover by scanning the phone's Wi-Fi subnet (most reliable)
  Future<String?> discoverBySubnetScan({
    int port = 80,
    int concurrency = 40,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final subnet = await _getWifiSubnetPrefix(); // e.g. "192.168.0"
    if (subnet == null) return null;

    // Generate IPs: 192.168.0.1 .. 192.168.0.254
    final ips = List<String>.generate(254, (i) => '$subnet.${i + 1}');

    bool found = false;
    String? foundUrl;
    int index = 0;

    Future<void> worker() async {
      while (!found) {
        final i = index++;
        if (i >= ips.length) return;

        final ip = ips[i];
        final url = 'http://$ip:$port';
        final ok = await _pingHealth(url);
        if (ok && !found) {
          found = true;
          foundUrl = url;
        }
      }
    }

    final futures = List.generate(concurrency, (_) => worker());

    try {
      await Future.any([
        Future.wait(futures),
        Future.delayed(timeout),
      ]);
    } catch (_) {}

    if (foundUrl != null) {
      _baseUrl = foundUrl;
      return foundUrl;
    }
    return null;
  }

  // --- 3) Connect = direct first, then scan
  Future<bool> connect() async {
    // ✅ Because you already know ESP32 IP from Serial Monitor
    // Try direct first (fastest)
    final directOk = await tryDirect('192.168.0.100', port: 80);
    if (directOk) return true;

    // If IP changed, scan the subnet
    final url = await discoverBySubnetScan(port: 80);
    return url != null;
  }

  // ---------------- helpers ----------------
  Future<bool> _pingHealth(String baseUrl) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200 && res.body.trim() == 'OK';
    } catch (_) {
      return false;
    }
  }

  /// Returns "192.168.0" from the phone's Wi-Fi IPv4 like "192.168.0.23"
  Future<String?> _getWifiSubnetPrefix() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          // skip weird ones
          if (ip.startsWith('169.254')) continue; // link-local
          final parts = ip.split('.');
          if (parts.length == 4) {
            return '${parts[0]}.${parts[1]}.${parts[2]}';
          }
        }
      }
    } catch (_) {}
    return null;
  }
// --- 4) Shares Telemetry to the app


  Timer? _telemetryTimer;

  Future<BinTelemetry?> fetchTelemetry() async {
    final b = baseUrl;
    if (b == null) return null;

    try {
      final res = await http
          .get(Uri.parse('$b/telemetry'))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode != 200) return null;

      final jsonMap = json.decode(res.body) as Map<String, dynamic>;
      return BinTelemetry.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  void startTelemetryPolling({
    Duration interval = const Duration(seconds: 2),
    required void Function(BinTelemetry t) onData,
    void Function()? onDisconnected,
  }) {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(interval, (_) async {
      final t = await fetchTelemetry();
      if (t == null) {
        onDisconnected?.call();
      } else {
        onData(t);
      }
    });
  }

  void stopTelemetryPolling() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
  }

}
