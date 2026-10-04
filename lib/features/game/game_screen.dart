import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';
import '../../data/firebase/firebase_duel_service.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import 'widgets/duel_top_hud.dart';
import 'widgets/panorama_viewer.dart';
import 'widgets/floating_guess_map.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.matchId,
    required this.player,
    required this.opponent,
    required this.location,
    required this.roundNumber,
    required this.onRoundFinished,
    required this.onForfeit,
    this.solid = false,
  });

  final String matchId;
  final PlayerState player;
  final PlayerState opponent;
  final LocationItem location;
  final int roundNumber;
  final ValueChanged<DuelRoundResult> onRoundFinished;
  final VoidCallback onForfeit;
  final bool solid;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _playerHasGuessed = false;
  bool _opponentHasGuessed = false;
  GeoPoint? _playerGuess;
  bool _isResolving = false;

  double get _multiplier =>
      DuelCalculator.getMultiplierForRound(widget.roundNumber);

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 60;
    _startCountdown();
    _listenToOpponentGuess();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _resolveRound();
        }
      });
    });
  }

  void _listenToOpponentGuess() {
    FirebaseDuelService.instance.listenToOpponentGuess(
      matchId: widget.matchId,
      roundNumber: widget.roundNumber,
      onOpponentGuessed: () {
        if (!mounted) return;
        setState(() {
          _opponentHasGuessed = true;
        });

        // Fast forward timer or resolve immediately if both guessed
        if (_playerHasGuessed) {
          _resolveRound();
        } else if (_remainingSeconds > 15) {
          // GeoGuessr mechanic: when opponent guesses, timer goes down to 15s
          setState(() {
            _remainingSeconds = 15;
          });
        }
      },
    );
  }

  void _onPlayerConfirmGuess(GeoPoint guess) {
    if (_playerHasGuessed) return;
    setState(() {
      _playerHasGuessed = true;
      _playerGuess = guess;
    });

    // If opponent already guessed, we resolve
    if (_opponentHasGuessed) {
      _resolveRound();
    } else {
      // Initiate submit but don't finish screen until opponent guesses
      FirebaseDuelService.instance
          .submitGuess(
            matchId: widget.matchId,
            roundNumber: widget.roundNumber,
            playerGuess: _playerGuess,
            location: widget.location,
            playerHealth: widget.player.health,
            opponentHealth: widget.opponent.health,
            multiplier: _multiplier,
          )
          .then((result) {
            if (mounted && !_isResolving) {
              _isResolving = true;
              widget.onRoundFinished(result);
            }
          });
    }
  }

  Future<void> _resolveRound() async {
    if (_isResolving) return;
    _isResolving = true;
    _countdownTimer?.cancel();

    final result = await FirebaseDuelService.instance.submitGuess(
      matchId: widget.matchId,
      roundNumber: widget.roundNumber,
      playerGuess: _playerGuess,
      location: widget.location,
      playerHealth: widget.player.health,
      opponentHealth: widget.opponent.health,
      multiplier: _multiplier,
    );

    if (mounted) {
      widget.onRoundFinished(result);
    }
  }
  void _confirmForfeit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        title: const Text('Сдаться в матче?'),
        content: const Text(
          'Вы покинете текущую дуэль и потеряете рейтинговые очки.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Продолжить игру',
              style: TextStyle(color: AtlasColors.ink),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.rust,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onForfeit();
            },
            child: const Text('Покинуть дуэль'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen interactive panorama / 360 photo
          PanoramaViewer(
            imageAsset: widget.location.imageAsset,
            solid: widget.solid,
          ),

          // 2. Top Header HUD with Health, Round, Multiplier and Timer
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: DuelTopHud(
                player: widget.player,
                opponent: widget.opponent,
                roundNumber: widget.roundNumber,
                multiplier: _multiplier,
                remainingSeconds: _remainingSeconds,
                solid: widget.solid,
              ),
            ),
          ),

          // 3. Exit / Forfeit Button (Top-left below HUD)
          Positioned(
            top: 86,
            left: 16,
            child: GlassButton(
              icon: Icons.close,
              label: 'Покинуть матч',
              size: 42,
              solid: widget.solid,
              onPressed: _confirmForfeit,
            ),
          ),

          // 4. Waiting indicator if player has confirmed their point
          if (_playerHasGuessed && !_opponentHasGuessed)
            Align(
              alignment: Alignment.center,
              child: GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xffe9ef9c),
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Ответ принят! Ожидаем соперника...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_opponentHasGuessed && !_playerHasGuessed)
            Align(
              alignment: Alignment.center,
              child: GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 20,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Icon(Icons.warning, color: Colors.amber, size: 20),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Соперник дал ответ! Поторопитесь!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Floating Expandable Mini-Map in bottom right corner (GeoGuessr Style)
          FloatingGuessMap(
            initialGuess: _playerGuess,
            opponentHasGuessed: _opponentHasGuessed,
            solid: widget.solid,
            onGuessConfirmed: _onPlayerConfirmGuess,
          ),
        ],
      ),
    );
  }
}
