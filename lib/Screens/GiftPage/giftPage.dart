import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class FavoriteScreen extends StatefulWidget {
  final String currentUserId;

  const FavoriteScreen({super.key, required this.currentUserId});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  // --- UI & Theming Constants ---
  static const _primaryColor = Color(0xFF00A86B); // Jade Green
  static const _redIndicatorColor = Colors.red;
  static const _confettiDuration = Duration(seconds: 2);
  static const _spinCooldown = Duration(hours: 24);

  // --- Wheel & Prize Configuration ---
  static final _prizes = <String>[
    "Free Ride",
    "10% Off",
    "Bonus Credits",
    "Free Coupon",
    "Try Again",
    "5% Off",
    "Extra Ride",
    "20% Off",
  ];
  // A pastel, distinct color scheme for the wheel segments.
  static final _colors = <Color>[
    Colors.teal.shade300,
    Colors.blue.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.lightBlue.shade300,
    Colors.green.shade300,
    Colors.pink.shade300,
  ];

  // --- State Controllers & Services ---
  final _wheelNotifier = BehaviorSubject<int>();
  late final ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AudioCache _audioCache; // For pre-caching sounds
  final _firestore = FirebaseFirestore.instance;

  // --- State Variables ---
  String _currentPrize = '';
  bool _isSpinning = false;
  DateTime? _lastSpinTime;

  // This Duration will now be managed by the separate timer widget.
  Duration _timeLeft = Duration.zero;
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: _confettiDuration);
    _audioCache = AudioCache(prefix: 'assets/sounds/');

    _initializeAsync(); // Call async setup separately
    _loadLastSpinTime();
  }

  Future<void> _initializeAsync() async {
    try {
      await _audioCache.loadAll(['spin_sound.mp3', 'win_sound.mp3']);
    } catch (e) {
      print("Error preloading sounds: $e");
    }
  }

  @override
  void dispose() {
    _wheelNotifier.close();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLastSpinTime() async {
    try {
      final doc = await _firestore
          .collection('spinHistory')
          .doc(widget.currentUserId)
          .get();
      if (doc.exists && doc.data()?.containsKey('lastSpin') == true) {
        _lastSpinTime = (doc.data()!['lastSpin'] as Timestamp).toDate();
        final nextAllowedSpin = _lastSpinTime!.add(_spinCooldown);
        final now = DateTime.now();
        setState(() {
          _timeLeft = nextAllowedSpin.isAfter(now)
              ? nextAllowedSpin.difference(now)
              : Duration.zero;
        });
      }
    } catch (e, s) {
      print("Error loading spin time: $e\n$s");
      _showErrorSnackBar("Could not load spin data. Please try again later.");
    }
  }

  Future<void> _spinWheel() async {
    if (_isSpinning || _timeLeft > Duration.zero) return;

    setState(() {
      _isSpinning = true;
      _currentPrize = '';
    });

    _playSound('sounds/spin_sound.mp3');

    final randomIndex = Fortune.randomInt(0, _prizes.length);
    _wheelNotifier.add(randomIndex);
  }

  Future<void> _finalizeSpin() async {
    final selectedIndex = _wheelNotifier.valueOrNull;

    if (selectedIndex == null || selectedIndex >= _prizes.length) {
      _showErrorSnackBar("Invalid spin result. Please try again.");
      setState(() => _isSpinning = false);
      return;
    }

    final prize = _prizes[selectedIndex];

    try {
      if (prize != "Try Again") {
        _playSound('sounds/win_sound.mp3');
        _confettiController.play();
      }

      final now = DateTime.now();
      final userDocRef =
          _firestore.collection('spinHistory').doc(widget.currentUserId);
      final historyDocRef = userDocRef.collection('history').doc();
      final batch = _firestore.batch();

      batch.set(
          userDocRef,
          {
            'lastSpin': Timestamp.fromDate(now),
          },
          SetOptions(merge: true));

      batch.set(historyDocRef, {
        'reward': prize,
        'date': DateFormat.yMd().add_jm().format(now),
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      _lastSpinTime = now;

      final nextAllowedSpin = _lastSpinTime!.add(_spinCooldown);
      final now2 = DateTime.now();

      setState(() {
        _timeLeft = nextAllowedSpin.isAfter(now2)
            ? nextAllowedSpin.difference(now2)
            : Duration.zero;
      });
    } catch (e, s) {
      print("Error finalizing spin: $e\n$s");
      _showErrorSnackBar(
          "There was an error saving your spin. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _currentPrize = prize;
        });
      }
    }
  }

  Future<void> _clearSpinHistory() async {
    try {
      final historyCollection = _firestore
          .collection('spinHistory')
          .doc(widget.currentUserId)
          .collection('history');
      final snapshots = await historyCollection.get();
      if (snapshots.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _showSuccessSnackBar("Spin history cleared successfully.");
    } catch (e, s) {
      print("Error clearing history: $e\n$s");
      _showErrorSnackBar("Failed to clear history. Please try again.");
    }
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e, s) {
      print("Error playing sound '$assetPath': $e\n$s");
      _showErrorSnackBar("Could not play sound effect.");
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Spin History",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure? This action cannot be undone.",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: _primaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSpinHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child:
                Text("Clear", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: _primaryColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Daily Rewards",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: _primaryColor)),
        backgroundColor: Colors.white,
        elevation: 1.0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFortuneWheel(),
                  const SizedBox(height: 24),
                  _buildPrizeDisplay(),
                  const SizedBox(height: 32),
                  TimerWidget(
                    timeLeft: _timeLeft,
                    onSpinPressed: _spinWheel,
                    isSpinning: _isSpinning,
                    primaryColor: _primaryColor,
                  ),
                  const SizedBox(height: 48),
                  HistorySection(
                    currentUserId: widget.currentUserId,
                    firestore: _firestore,
                    primaryColor: _primaryColor,
                    onClearPressed: _showClearHistoryDialog,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: _colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneWheel() {
    return SizedBox(
      height: 250,
      width: 250,
      child: FortuneWheel(
        selected: _wheelNotifier.stream,
        onAnimationEnd: _finalizeSpin,
        physics: CircularPanPhysics(
            duration: const Duration(seconds: 1), curve: Curves.decelerate),
        indicators: const <FortuneIndicator>[
          FortuneIndicator(
            alignment: Alignment.topCenter,
            child: TriangleIndicator(
                color: _redIndicatorColor, width: 20, height: 20, elevation: 8),
          ),
        ],
        items: [
          for (var i = 0; i < _prizes.length; i++)
            FortuneItem(
              child: Text(_prizes[i].replaceAll(' ', '\n'),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white)),
              style: FortuneItemStyle(
                  color: _colors[i],
                  borderColor: Colors.white,
                  borderWidth: 2.5),
            ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildPrizeDisplay() {
    return AnimatedSwitcher(
      duration: 500.ms,
      transitionBuilder: (child, animation) {
        return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child));
      },
      child: _currentPrize.isEmpty
          ? const SizedBox(key: ValueKey('empty'), height: 60)
          : Column(
              key: ValueKey(_currentPrize),
              children: [
                Text("You won:",
                    style: GoogleFonts.poppins(
                        fontSize: 18, color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  _currentPrize,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _currentPrize == "Try Again"
                        ? Colors.grey.shade700
                        : _primaryColor,
                  ),
                ),
              ],
            ),
    );
  }
}

// Separate widget just for the countdown timer and spin button to avoid rebuilds affecting other UI parts.
class TimerWidget extends StatefulWidget {
  final Duration timeLeft;
  final VoidCallback onSpinPressed;
  final bool isSpinning;
  final Color primaryColor;

  const TimerWidget({
    super.key,
    required this.timeLeft,
    required this.onSpinPressed,
    required this.isSpinning,
    required this.primaryColor,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Duration _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.timeLeft;
    if (_timeLeft > Duration.zero) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeLeft != oldWidget.timeLeft) {
      _timeLeft = widget.timeLeft;
      if (_timeLeft > Duration.zero && (_timer == null || !_timer!.isActive)) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= Duration.zero) {
        timer.cancel();
      } else {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final canSpin = _timeLeft <= Duration.zero && !widget.isSpinning;

    if (!canSpin) {
      return Column(
        children: [
          Text("Next spin in:",
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_timeLeft),
            style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      );
    }

    return SizedBox(
      width: 240,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.isSpinning ? Colors.grey.shade500 : widget.primaryColor,
          shape: const StadiumBorder(),
          elevation: 8.0,
          shadowColor: widget.primaryColor.withOpacity(0.5),
        ),
        onPressed: widget.isSpinning ? null : widget.onSpinPressed,
        child: Text(
          widget.isSpinning ? "SPINNING..." : "SPIN NOW!",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    )
        .animate(
            onPlay: (c) => c.repeat(reverse: true),
            target: widget.isSpinning ? 0 : 1)
        .scaleXY(end: 1.05, duration: 900.ms, curve: Curves.easeInOut)
        .then(delay: 900.ms);
  }
}

// Separate widget for the history list to avoid rebuilding on timer ticks.
class HistorySection extends StatelessWidget {
  final String currentUserId;
  final FirebaseFirestore firestore;
  final Color primaryColor;
  final VoidCallback onClearPressed;

  const HistorySection({
    super.key,
    required this.currentUserId,
    required this.firestore,
    required this.primaryColor,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Your History",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: onClearPressed,
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: Colors.redAccent, size: 20),
              label: Text("Clear",
                  style: GoogleFonts.poppins(color: Colors.redAccent)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('spinHistory')
                .doc(currentUserId)
                .collection('history')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.green));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No spin history yet.",
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey)),
                );
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final reward = data['reward'] ?? 'Unknown';
                  return Card(
                    elevation: 1.5,
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        reward == "Try Again"
                            ? Icons.sentiment_dissatisfied
                            : Icons.emoji_events,
                        color: reward == "Try Again"
                            ? Colors.grey
                            : Colors.amber.shade700,
                      ),
                      title: Text(reward,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(data['date'] ?? '',
                          style: GoogleFonts.poppins(color: Colors.black54)),
                    ),
                  )
                      .animate(delay: (index * 80).ms)
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.1, curve: Curves.easeOut);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
