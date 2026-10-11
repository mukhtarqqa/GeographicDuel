import 'package:flutter/material.dart';
import '../../core/theme/atlas_theme.dart';
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_container.dart';
import 'widgets/duel_top_hud.dart';
import 'widgets/panorama_viewer.dart';
import 'widgets/floating_guess_map.dart';
import 'controllers/game_controller.dart';

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
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      matchId: widget.matchId,
      player: widget.player,
      opponent: widget.opponent,
      onRoundFinished: widget.onRoundFinished,
      onForfeit: widget.onForfeit,
    );
    _controller.startRound(widget.location, widget.roundNumber);
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundNumber != widget.roundNumber || oldWidget.location.id != widget.location.id) {
      _controller.startRound(widget.location, widget.roundNumber);
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _confirmForfeit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AtlasColors.paper,
        title: const Text('Матчтан бас тарту?'),
        content: const Text(
          'Сіз ағымдағы жекпе-жектен шығып, рейтингтік ұпайларыңызды жоғалтасыз.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ойынды жалғастыру', style: TextStyle(color: AtlasColors.ink)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AtlasColors.rust,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.forceForfeit();
            },
            child: const Text('Жекпе-жектен шығу'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayerGuessed = _controller.playerGuess != null;
    final hasOpponentGuessed = _controller.opponentHasGuessed;
    final remainingSeconds = _controller.timeRemaining;
    final multiplier = DuelCalculator.getMultiplierForRound(widget.roundNumber);

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
                multiplier: multiplier,
                remainingSeconds: remainingSeconds,
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
              label: 'Матчтан шығу',
              size: 42,
              solid: widget.solid,
              onPressed: _confirmForfeit,
            ),
          ),

          // 4. Waiting indicator if player has confirmed their point
          if (hasPlayerGuessed && !hasOpponentGuessed)
            Align(
              alignment: Alignment.center,
              child: GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        'Жауап қабылданды! Қарсыласты күтудеміз...',
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

          // 4b. Alert banner if opponent guessed first
          if (hasOpponentGuessed && !hasPlayerGuessed)
            Positioned(
              top: 86,
              right: 16,
              child: GlassContainer(
                dark: true,
                solid: widget.solid,
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AtlasColors.rust),
                    const SizedBox(width: 6),
                    Text(
                      'Қарсылас таңдау жасады! ($remainingSeconds с)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Floating Expandable Mini-Map in bottom right corner
          Positioned(
            bottom: 110,
            right: 0,
            left: 0,
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingGuessMap(
                initialGuess: _controller.playerGuess,
                opponentHasGuessed: hasOpponentGuessed,
                solid: widget.solid,
                onGuessConfirmed: (guess) {
                  _controller.setGuess(guess);
                  _controller.submitGuess();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
