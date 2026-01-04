import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardUser {
  final String uid;
  final String name;
  final String photoUrl;
  final int points;
  final int minutes;

  LeaderboardUser({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.points,
    required this.minutes,
  });

  factory LeaderboardUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LeaderboardUser(
      uid: doc.id,
      name: (data['displayName'] ?? 'User').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      points: _toInt(data['points']),
      minutes: _toInt(data['minutes']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String? _debugText;

  Stream<List<LeaderboardUser>> _leaderboardStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LeaderboardUser.fromDoc(d)).toList());
  }

  Future<void> _pingFirestore() async {
    setState(() => _debugText = "Pinging Firestore...");
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));

      final count = snap.docs.length;
      setState(() => _debugText = "✅ Firestore OK. Top docs: $count");
      for (final d in snap.docs) {
        debugPrint("PING doc=${d.id} data=${d.data()}");
      }
    } catch (e) {
      setState(() => _debugText = "❌ Firestore FAILED: $e");
      debugPrint("❌ Firestore FAILED: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Test Firestore",
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: _pingFirestore,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_debugText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black.withOpacity(0.06),
                ),
                child: Text(
                  _debugText!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            Expanded(
              child: StreamBuilder<List<LeaderboardUser>>(
                stream: _leaderboardStream(),
                builder: (context, snapshot) {
                  // ✅ IMPORTANT: error first
                  if (snapshot.hasError) {
                    return _ErrorState(error: snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) return const _EmptyState();

                  final top1 = users.isNotEmpty ? users[0] : null;
                  final top2 = users.length > 1 ? users[1] : null;
                  final top3 = users.length > 2 ? users[2] : null;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    children: [
                      if (top1 != null)
                        _PodiumCard(top1: top1!, top2: top2, top3: top3),
                      const SizedBox(height: 14),

                      Text(
                        "All ranks",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...List.generate(users.length, (i) {
                        final u = users[i];
                        final rank = i + 1;
                        final highlight = (myUid != null && u.uid == myUid);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RankRow(user: u, rank: rank, highlight: highlight),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- UI WIDGETS ----------------

class _PodiumCard extends StatelessWidget {
  final LeaderboardUser top1;
  final LeaderboardUser? top2;
  final LeaderboardUser? top3;

  const _PodiumCard({
    required this.top1,
    this.top2,
    this.top3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.03),
            Colors.black.withOpacity(0.01),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _PodiumTile(rank: 2, user: top2, big: false)),
          Expanded(child: _PodiumTile(rank: 1, user: top1, big: true)),
          Expanded(child: _PodiumTile(rank: 3, user: top3, big: false)),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final int rank;
  final LeaderboardUser? user;
  final bool big;

  const _PodiumTile({
    required this.rank,
    required this.user,
    required this.big,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    final u = user!;
    final avatarSize = big ? 78.0 : 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$rank",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.70),
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _Avatar(size: avatarSize, url: u.photoUrl),
            Positioned(
              bottom: -12,
              child: _PointsPill(points: u.points, big: big),
            ),
            if (rank == 1)
              Positioned(
                top: -22,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 30,
                  color: Colors.amber.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          u.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          "${u.points} pts",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.55),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardUser user;
  final int rank;
  final bool highlight;

  const _RankRow({
    required this.user,
    required this.rank,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight
        ? Colors.green.withOpacity(0.10)
        : Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: bg,
        border: Border.all(
          color: highlight
              ? Colors.green.withOpacity(0.25)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          _Avatar(size: 48, url: user.photoUrl),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: Colors.black.withOpacity(0.55)),
                    const SizedBox(width: 4),
                    Text(
                      "${user.minutes} mins",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          _PointsPill(points: user.points),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isTop3
            ? Colors.amber.withOpacity(0.18)
            : Colors.black.withOpacity(0.06),
        border: Border.all(
          color: isTop3 ? Colors.amber.withOpacity(0.35) : Colors.transparent,
        ),
      ),
      child: Text(
        "$rank",
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  final int points;
  final bool big;

  const _PointsPill({required this.points, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 12 : 10,
        vertical: big ? 7 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.deepOrange.withOpacity(0.12),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.25)),
      ),
      child: Text(
        "$points",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.deepOrange.shade700,
          fontSize: big ? 13 : 12,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;
  final String url;
  const _Avatar({required this.size, required this.url});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(url, fit: BoxFit.cover)
            : Container(
          color: Colors.black.withOpacity(0.06),
          child: Icon(Icons.person_rounded, size: size * 0.55),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("No leaderboard data yet."),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Failed to load leaderboard:\n$error",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
