import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../data/locations_catalog.dart';
import '../../domain/models/location_item.dart';
import '../../data/firebase/firebase_duel_service.dart';
import '../lobby/lobby_screen.dart';
import '../matchmaking/matchmaking_screen.dart';
import '../game/game_screen.dart';
import '../round_result/round_result_screen.dart';
import '../match_result/match_result_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../widgets/glass_container.dart';

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
    name: 'Жүктелуде...',
    rating: 1240,
    health: 6000,
  );
  PlayerState? _opponent;
  String _matchId = '';
  int _roundNumber = 1;
  DuelRoundResult? _lastRoundResult;
  List<LocationItem> _matchLocations = [];
  LocationItem _currentLocation = LocationsCatalog.items.first;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = await FirebaseDuelService.instance.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _player = user;
      });
    } else {
      _player = PlayerState(
        id: 'local_user',
        name: 'Зерттеуші',
        rating: 1240,
        health: 6000,
      );
    }
  }

  void _startMatchmaking() {
    setState(() {
      _inMatchmaking = true;
    });

    FirebaseDuelService.instance.startMatchmaking(
      onMatchFound: (matchId, opponent, locations) {
        if (!mounted || !_inMatchmaking) return;

        setState(() {
          _matchId = matchId;
          _opponent = opponent;
          _roundNumber = 1;
          _player.health = 6000;
          _opponent!.health = 6000;
          _matchLocations = locations;
          _currentLocation = LocationsCatalog.getForRound(1, matchLocations: _matchLocations);
          _inMatchmaking = false;
          _inGame = true;
          _inRoundResult = false;
          _inMatchResult = false;
        });
      },
    );
  }

  void _createRoomDuel() async {
    setState(() => _inMatchmaking = true);
    final code = await FirebaseDuelService.instance.createRoom(
      onMatchFound: (matchId, opponent, locations) {
        if (!mounted) return;
        setState(() {
          _matchId = matchId;
          _opponent = opponent;
          _roundNumber = 1;
          _player.health = 6000;
          _opponent!.health = 6000;
          _matchLocations = locations;
          _currentLocation = LocationsCatalog.getForRound(1, matchLocations: _matchLocations);
          _inMatchmaking = false;
          _inGame = true;
          _inRoundResult = false;
          _inMatchResult = false;
        });
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
        setState(() {
          _matchId = matchId;
          _opponent = opponent;
          _roundNumber = 1;
          _player.health = 6000;
          _opponent!.health = 6000;
          _matchLocations = locations;
          _currentLocation = LocationsCatalog.getForRound(1, matchLocations: _matchLocations);
          _inMatchmaking = false;
          _inGame = true;
          _inRoundResult = false;
          _inMatchResult = false;
        });
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
    setState(() {
      _inMatchmaking = false;
    });
  }

  void _onRoundFinished(DuelRoundResult result) {
    setState(() {
      _lastRoundResult = result;
      // Apply damage to loser
      if (result.playerWon) {
        _opponent!.applyDamage(result.damage);
      } else if (result.opponentWon) {
        _player.applyDamage(result.damage);
      }

      _inGame = false;
      _inRoundResult = true;
    });
  }

  void _nextRound() {
    setState(() {
      _roundNumber++;
      _currentLocation = LocationsCatalog.getForRound(_roundNumber, matchLocations: _matchLocations);
      _inRoundResult = false;
      _inGame = true;
    });
  }

  void _finishMatch() {
    setState(() {
      _inRoundResult = false;
      _inMatchResult = true;
    });
  }

  void _forfeitMatch() {
    setState(() {
      _inGame = false;
      _inRoundResult = false;
      _inMatchResult = false;
      _player.health = 6000;
    });
  }

  void _resetToLobby() {
    setState(() {
      _inMatchmaking = false;
      _inGame = false;
      _inRoundResult = false;
      _inMatchResult = false;
      _player.health = 6000;
    });
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
          // Current Tab Page
          Positioned.fill(
            child: _buildCurrentTab(),
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

    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: InkWell(
        onTap: () => setState(() => _currentTab = tab),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? (isSelected ? 10 : 8) : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AtlasColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
