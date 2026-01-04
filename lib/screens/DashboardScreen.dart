import 'package:flutter/material.dart';
import 'dart:async';
import 'ProfilePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LeaderboardPage.dart';
import '../services/qr_scanner_service.dart';
import '../services/bindiscovery.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trashgold/screens/LoginScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

late AnimationController _breathController;
late Animation<double> _axisX;
late Animation<double> _axisY;
late Animation<double> _breath;




class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin{
  BinTelemetry? _telemetry;
  Timer? _demoTimer;
  List<int> _demoValues = [12, 28, 41, 56, 73];
  void _startDemoShuffle() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        // smooth-ish demo: small random changes
        _demoValues = List.generate(5, (i) {
          final delta = ([-3, -2, -1, 1, 2, 3]..shuffle()).first;
          final next = _demoValues[i] + delta;
          return next.clamp(0, 100);
        });
      });
    });
  }

  void _stopDemoShuffle() {
    _demoTimer?.cancel();
    _demoTimer = null;
  }

  List<Widget> _buildWideCalloutLabels(BinTelemetry? t) {
    final values = t?.compartments ?? [0, 0, 0, 0, 0];
    final names = const ["Plastic", "Paper", "Metal", "Organic", "General"];

    return [
      // LEFT column (3 labels)
      Positioned(
        left: 12,
        top: 0,
        bottom: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalloutLabel(name: names[0], value: values[0]),
            _CalloutLabel(name: names[1], value: values[1]),
            _CalloutLabel(name: names[2], value: values[2]),
          ],
        ),
      ),

      // RIGHT column (2 labels)
      Positioned(
        right: 12,
        top: 0,
        bottom: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _CalloutLabel(name: names[3], value: values[3]),
            _CalloutLabel(name: names[4], value: values[4]),
          ],
        ),
      ),
    ];
  }





  @override
  void initState(){
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breath =Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut)
    );
    _axisX =Tween<double>(begin: -4, end: 4).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut)
    );
    _axisY =Tween<double>(begin: -3, end: 3).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut)
    );

  }
  @override
  void dispose(){
    _discoveryService.stopTelemetryPolling();
    _breathController.dispose();
    super.dispose();
  }

  final BinDiscoveryService _discoveryService = BinDiscoveryService();
  bool isConnected = false;
  String? dustbinBaseUrl;

  Future<void> discoverAndConnectDustbin() async {
    debugPrint("✅ LONG PRESS FIRED");

    // show quick feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Searching TrashGold dustbin...")),
    );

    final ok = await _discoveryService.connect();
    debugPrint("✅ DISCOVERY FINISHED. connected=$ok url=${_discoveryService.baseUrl}");

    if (!mounted) return;
    setState(() {
      isConnected = ok;
      dustbinBaseUrl = _discoveryService.baseUrl;
    });

    // ✅ START TELEMETRY POLLING WHEN CONNECTED
    if (ok) {
      _discoveryService.startTelemetryPolling(
        interval: const Duration(seconds: 1),
        onData: (t) {
          if (!mounted) return;
          setState(() => _telemetry = t);
        },
        onDisconnected: () {
          if (!mounted) return;
          setState(() => _telemetry = null);
        },
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Connected: $dustbinBaseUrl" : "Not found / not reachable"),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          "TrashGold",
          style: TextStyle(fontWeight: FontWeight.w700,
          fontSize: 15),
        ),
        actions: [
          const SizedBox(width: 10),

          // 🔍 QR Scanner
          IconButton(
            tooltip: "Scan QR",
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () async {
              final code = await QrScannerService.scan(context);
              if (!mounted) return;

              if (code != null) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Scanned: $code")),
                );

                // TEMP: test points visually (remove later)
              }
            },
          ),

          // 📡 Bin connect (long press)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onLongPress: discoverAndConnectDustbin,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.wifi_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer:
      Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 190,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF16A34A),
                      Color(0xFF0EA5E9),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // LEFT: avatar above name/email
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white.withOpacity(0.20),
                            backgroundImage:
                            user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null
                                ? Text(
                              (user?.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.displayName ?? 'Guest User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT: points centered vertically
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                              color: Colors.black.withOpacity(0.12),
                            ),
                          ],
                        ),
                       child:  Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 18, color: Colors.white.withOpacity(0.95)),
                            const SizedBox(width: 6),

                            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final points = snapshot.data?.data()?['points'] ?? 0;

                                return Text(
                                  "$points",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 4),
                            Text(
                              "pts",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),

                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Leaderboard',
                style: TextStyle(
                    color: Colors.red
                ),
              ),
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardPage()),
                );

              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
               // await GoogleSignIn().signOut();
                Navigator.pushReplacement(
                    context,
                MaterialPageRoute(builder: (_) => const LoginScreen())
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.all(8),
                child: Text("Welcome To TrashGold")
            ),

            ElevatedButton(
              onPressed: () async {
                try {
                  final snap = await FirebaseFirestore.instance
                      .collection('users')
                      .limit(1)
                      .get();
                  debugPrint("✅ Firestore works. docs=${snap.docs.length}");
                } catch (e) {
                  debugPrint("❌ Firestore error: $e");
                }
              },
              child: const Text("Test Firestore"),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: AnimatedBuilder(
                animation: _breathController,
                  child: SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Center bin image (fixed size)
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Image.asset(
                            'assets/Bin/BinStats.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Lines across full width to margins
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LeaderLinesPainterWideConnected(_telemetry),
                          ),
                        ),

                        // Labels in margins (left/right)
                        ..._buildWideCalloutLabels(_telemetry),
                      ],
                    ),
                  ),


                  builder: (context, child){
                  return Transform.translate(offset: Offset(_axisX.value, _axisY.value),
                  child: Transform.scale(scale: _breath.value,
                  child: child,
                  ),
                  );
                }
              ),
            ),

          ],
        ),
      ),
    );

  }
}


class _CalloutLabel extends StatelessWidget {
  final String name;
  final int value;

  const _CalloutLabel({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    final isWarning = value >= 80;

    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$value%",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isWarning ? Colors.redAccent : Colors.white.withOpacity(0.92),
            ),
          ),

        ],
      ),
    );
  }
}

class _LeaderLinesPainterWideConnected extends CustomPainter {
  final BinTelemetry? telemetry;
  _LeaderLinesPainterWideConnected(this.telemetry);

  @override
  void paint(Canvas canvas, Size size) {
    final values = telemetry?.compartments ?? [0, 0, 0, 0, 0];

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Bin centered
    const binSize = 220.0;
    final binLeft = (size.width - binSize) / 2;
    final binTop = (size.height - binSize) / 2;

    Offset binAnchor(double fx, double fy) {
      return Offset(binLeft + fx * binSize, binTop + fy * binSize);
    }

    // Anchor points on bin image
    final anchors = <Offset>[
      binAnchor(0.34, 0.28), // Plastic
      binAnchor(0.36, 0.44), // Paper
      binAnchor(0.40, 0.62), // Metal
      binAnchor(0.64, 0.36), // Organic
      binAnchor(0.62, 0.62), // General
    ];

    // Match Column(spaceEvenly): y = H/(count+1) * (i+1)
    double yEven(int i, int count) => (size.height / (count + 1)) * (i + 1);

    // Your label widget width in _CalloutLabel
    const labelW = 92.0;
    const edgePad = 4.0;

    // Endpoints: hit the label box edge near its vertical center
    final leftYs = [yEven(0, 3), yEven(1, 3), yEven(2, 3)];
    final rightYs = [yEven(0, 2), yEven(1, 2)];

    final ends = <Offset>[
      Offset(edgePad + labelW, leftYs[0]),               // right edge of left label
      Offset(edgePad + labelW, leftYs[1]),
      Offset(edgePad + labelW, leftYs[2]),
      Offset(size.width - (edgePad + labelW), rightYs[0]), // left edge of right label
      Offset(size.width - (edgePad + labelW), rightYs[1]),
    ];

    for (int i = 0; i < 5; i++) {
      final start = anchors[i];
      final end = ends[i];

      final mid = Offset((start.dx + end.dx) / 2, start.dy);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, linePaint);
      canvas.drawCircle(start, 3.0, dotPaint);

      // Highlight warning dot (optional)
      if (values[i] >= 80) {
        final warnPaint = Paint()..color = Colors.redAccent.withOpacity(0.95);
        canvas.drawCircle(start, 3.8, warnPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderLinesPainterWideConnected oldDelegate) => true;
}


