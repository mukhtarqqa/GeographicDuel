import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/atlas_theme.dart';
import 'domain/models/player_state.dart';
import 'domain/models/round_result.dart';
import 'data/locations_catalog.dart';
import 'domain/models/location_item.dart';
import 'data/firebase/firebase_duel_service.dart';
import 'features/lobby/lobby_screen.dart';
import 'features/matchmaking/matchmaking_screen.dart';
import 'features/game/game_screen.dart';
import 'features/round_result/round_result_screen.dart';
import 'features/match_result/match_result_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/widgets/glass_container.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const GeographicDuelApp());
}

class GeographicDuelApp extends StatelessWidget {
  final bool testMode;
  const GeographicDuelApp({super.key, this.testMode = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geographic Duel',
      debugShowCheckedModeBanner: false,
      theme: AtlasTheme.theme,
      home: testMode ? const DuelShell() : const SplashScreen(),
    );
  }
}

enum AppTab { duel, leaderboard, profile }

class DuelShell extends StatefulWidget {
  const DuelShell({super.key});

  @override
  State<DuelShell> createState() => _DuelShellState();
}

class _DuelShellState extends State<DuelShell> {
  // Navigation & Game State
  AppTab _currentTab = AppTab.duel;
  bool _inMatchmaking = false;
  bool _inGame = false;
  bool _inRoundResult = false;
  bool _inMatchResult = false;

  // Settings
  bool _solid = false;
  bool _reduceMotion = false;

  // Active Match Data
  PlayerState _player = PlayerState(
    id: 'local_user',
    name: 'Ойыншы',
    rating: 1200,
    health: 6000,
  );
  PlayerState? _opponent;
  String _matchId = '';
  int _roundNumber = 1;
  DuelRoundResult? _lastRoundResult;
  List<LocationItem> _matchLocations = [];
  LocationItem _currentLocation = LocationsCatalog.items.first;

  StreamSubscription<DocumentSnapshot>? _matchSubscription;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = await FirebaseDuelService.instance.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _player = user;
      });
    }
  }

  void _setupMatch(String matchId, PlayerState opponent, List<LocationItem> locations) {
    _matchSubscription?.cancel();
    _matchLocations = locations;
    _matchId = matchId;
    _opponent = opponent;
    _roundNumber = 1;
    _player.health = 6000;
    _opponent!.health = 6000;
    _currentLocation = LocationsCatalog.getForRound(1, matchLocations: _matchLocations);
    _inMatchmaking = false;
    _inGame = true;
    _inRoundResult = false;
    _inMatchResult = false;

    // Listen to live Firestore match document for synchronized rounds and finish state
    _matchSubscription = FirebaseDuelService.instance.streamMatch(matchId)?.listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      final isPlayer1 = data['player1'] == _player.id;
      final myHp = (isPlayer1 ? data['player1Health'] : data['player2Health']) as num?;
      final oppHp = (isPlayer1 ? data['player2Health'] : data['player1Health']) as num?;

      if (myHp != null) {
        _player.health = myHp.toInt();
      }
      if (oppHp != null && _opponent != null) {
        _opponent!.health = oppHp.toInt();
      }

      final status = data['status'] as String? ?? 'playing';
      if (status == 'finished') {
        _finishMatch();
        return;
      }

      final serverRound = (data['currentRound'] as num?)?.toInt() ?? 1;
      if (serverRound > _roundNumber) {
        setState(() {
          _roundNumber = serverRound;
          _currentLocation = LocationsCatalog.getForRound(_roundNumber, matchLocations: _matchLocations);
          _inRoundResult = false;
          _inGame = true;
        });
      }
    });

    setState(() {});
  }

  void _startMatchmaking() {
    setState(() {
      _inMatchmaking = true;
    });

    FirebaseDuelService.instance.startMatchmaking(
      onMatchFound: (matchId, opponent, locations) {
        if (!mounted || !_inMatchmaking) return;
        _setupMatch(matchId, opponent, locations);
      },
    );
  }

  void _createRoomDuel() async {
    setState(() => _inMatchmaking = true);
    final code = await FirebaseDuelService.instance.createRoom(
      onMatchFound: (matchId, opponent, locations) {
        if (!mounted) return;
        _setupMatch(matchId, opponent, locations);
      },
    );

    if (code != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бөлме құрылды! Код: $code (досыңызға беріңіз)'),
          backgroundColor: AtlasColors.green,
          duration: const Duration(seconds: 15),
        ),
      );
    }
  }

  void _joinRoomDuel(String code) {
    setState(() => _inMatchmaking = true);
    FirebaseDuelService.instance.joinRoom(
      roomCode: code,
      onMatchFound: (matchId, opponent, locations) {
        if (!mounted) return;
        _setupMatch(matchId, opponent, locations);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _inMatchmaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      },
    );
  }

  void _cancelMatchmaking() {
    FirebaseDuelService.instance.cancelMatchmaking();
    _matchSubscription?.cancel();
    _matchSubscription = null;
    setState(() {
      _inMatchmaking = false;
    });
  }

  void _onRoundFinished(DuelRoundResult result) {
    setState(() {
      _lastRoundResult = result;
      // Sync remaining health from round result
      _player.health = result.playerHealthRemaining;
      _opponent?.health = result.opponentHealthRemaining;

      _inGame = false;
      _inRoundResult = true;
    });
  }

  void _nextRound() {
    if (_roundNumber >= 10 || _player.health <= 0 || (_opponent?.health ?? 0) <= 0) {
      _finishMatch();
      return;
    }

    if (_matchId.startsWith('bot_') || _matchId.startsWith('offline_')) {
      setState(() {
        _roundNumber++;
        _currentLocation = LocationsCatalog.getForRound(_roundNumber, matchLocations: _matchLocations);
        _inRoundResult = false;
        _inGame = true;
      });
      return;
    }

    FirebaseDuelService.instance.signalNextRoundReady(
      matchId: _matchId,
      roundNumber: _roundNumber,
    );
  }

  void _finishMatch() async {
    if (_inMatchResult) return;
    _matchSubscription?.cancel();
    _matchSubscription = null;

    final won = _player.health > (_opponent?.health ?? 0);
    final eloDelta = await FirebaseDuelService.instance.recordMatchResult(
      matchId: _matchId,
      won: won,
      myRating: _player.rating,
      oppRating: _opponent?.rating ?? 1200,
    );

    if (!mounted) return;
    setState(() {
      _player = _player.copyWith(rating: math.max(100, _player.rating + eloDelta));
      _inGame = false;
      _inRoundResult = false;
      _inMatchResult = true;
    });
  }

  void _forfeitMatch() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    setState(() {
      _inGame = false;
      _inRoundResult = false;
      _inMatchResult = false;
      _player.health = 6000;
    });
  }

  void _resetToLobby() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    setState(() {
      _inMatchmaking = false;
      _inGame = false;
      _inRoundResult = false;
      _inMatchResult = false;
      _player.health = 6000;
    });
  }

  Future<void> _handleLogout() async {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    await AuthService.instance.signOut();
    (FirebaseDuelService.instance as FirebaseDuelService).clearSession();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. In Matchmaking
    if (_inMatchmaking) {
      return MatchmakingScreen(onCancel: _cancelMatchmaking);
    }

    // 2. Active Round (GeoGuessr Arena)
    if (_inGame && _opponent != null) {
      return GameScreen(
        matchId: _matchId,
        player: _player,
        opponent: _opponent!,
        location: _currentLocation,
        roundNumber: _roundNumber,
        solid: _solid,
        onRoundFinished: _onRoundFinished,
        onForfeit: _forfeitMatch,
      );
    }

    // 3. Round Result
    if (_inRoundResult && _lastRoundResult != null && _opponent != null) {
      return RoundResultScreen(
        result: _lastRoundResult!,
        player: _player,
        opponent: _opponent!,
        solid: _solid,
        onNextRound: _nextRound,
        onFinishMatch: _finishMatch,
      );
    }

    // 4. Final Match Result (Victory / Defeat)
    if (_inMatchResult && _opponent != null) {
      return MatchResultScreen(
        player: _player,
        opponent: _opponent!,
        totalRounds: _roundNumber,
        onPlayAgain: _startMatchmaking,
        onGoHome: _resetToLobby,
      );
    }

    // 5. Main App Shell (Lobby, Leaderboard, Profile with Bottom Dock)
    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: Stack(
        children: [
          // Current Tab Page with Smooth Transition Animation
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: _reduceMotion ? 0 : 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentTab),
                child: _buildCurrentTab(),
              ),
            ),
          ),

          // Floating Glass Bottom Navigation Dock
          Positioned(
            bottom: 20,
            left: 8,
            right: 8,
            child: Center(
              child: GlassContainer(
                dark: false,
                solid: _solid,
                radius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDockItem(
                      tab: AppTab.duel,
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: 'Дуэль',
                    ),
                    const SizedBox(width: 6),
                    _buildDockItem(
                      tab: AppTab.leaderboard,
                      icon: Icons.leaderboard_outlined,
                      activeIcon: Icons.leaderboard,
                      label: 'Рейтинг',
                    ),
                    const SizedBox(width: 6),
                    _buildDockItem(
                      tab: AppTab.profile,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Профиль',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentTab) {
      case AppTab.duel:
        return LobbyScreen(
          onStartDuel: _startMatchmaking,
          onCreateRoom: _createRoomDuel,
          onJoinRoom: _joinRoomDuel,
          playerRating: _player.rating,
          solid: _solid,
          onLogout: _handleLogout,
        );
      case AppTab.leaderboard:
        return const LeaderboardScreen();
      case AppTab.profile:
        return ProfileScreen(
          player: _player,
          solid: _solid,
          reduceMotion: _reduceMotion,
          onToggleSolid: (v) => setState(() => _solid = v),
          onToggleReduceMotion: (v) => setState(() => _reduceMotion = v),
          onLogout: _handleLogout,
          onUserUpdated: _initUser,
        );
    }
  }

  Widget _buildDockItem({
    required AppTab tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentTab == tab;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 380;

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: InkWell(
        onTap: () => setState(() => _currentTab = tab),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? (isSelected ? 8 : 6) : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AtlasColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 18,
                color: isSelected ? Colors.white : AtlasColors.ink,
              ),
              if (!isNarrow || isSelected) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isNarrow ? 10 : 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AtlasColors.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
