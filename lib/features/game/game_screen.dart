import 'package:flutter/material.dart';
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';
import '../widgets/glass_button.dart';
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

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameController _controller;
  late AnimationController _roundBannerAnim;
  late Animation<double> _roundBannerOpacity;
  late Animation<Offset> _roundBannerSlide;

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

    _roundBannerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _roundBannerOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_roundBannerAnim);

    _roundBannerSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _roundBannerAnim,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
    ));

    _roundBannerAnim.forward();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundNumber != widget.roundNumber || oldWidget.location.id != widget.location.id) {
      _controller.startRound(widget.location, widget.roundNumber);
      _roundBannerAnim.reset();
      _roundBannerAnim.forward();
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _roundBannerAnim.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _confirmForfeit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff18221f),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          'Матчтан шығу?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Сіз ағымдағы жекпе-жектен шықсаңыз, рейтингтік ұпайларыңызды жоғалтасыз.',
          style: TextStyle(color: Color(0xffcbd5e1), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Жалғастыру', style: TextStyle(color: Color(0xff34d399))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffdc2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.forceForfeit();
            },
            child: const Text('Шығу'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayerGuessed = _controller.hasSubmitted;
    final hasOpponentGuessed = _controller.opponentHasGuessed;
    final remainingSeconds = _controller.timeRemaining;
    final multiplier = DuelCalculator.getMultiplierForRound(widget.roundNumber);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Fullscreen interactive panorama / 360 photo
          PanoramaViewer(
            location: widget.location,
            imageUrl: widget.location.imageUrl,
            imageAsset: widget.location.imageAsset,
            solid: widget.solid,
          ),

          // 2. Top Header HUD + Action controls (Exit button & Opponent alert)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DuelTopHud(
                    player: widget.player,
                    opponent: widget.opponent,
                    roundNumber: widget.roundNumber,
                    multiplier: multiplier,
                    remainingSeconds: remainingSeconds,
                    solid: widget.solid,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Exit / Forfeit Button
                        GlassButton(
                          icon: Icons.close,
                          label: 'Матчтан шығу',
                          size: 36,
                          solid: widget.solid,
                          onPressed: _confirmForfeit,
                        ),

                        // Opponent Alert banner
                        if (hasOpponentGuessed && !hasPlayerGuessed)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xffdc2626), Color(0xfff59e0b)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 8),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Қарсылас белгіледі! ($remainingSeconds с)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Cinematic Round Intro Banner (Appears at start of round)
          AnimatedBuilder(
            animation: _roundBannerAnim,
            builder: (context, child) {
              if (_roundBannerOpacity.value <= 0.01) return const SizedBox.shrink();
              return Positioned(
                top: 130,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _roundBannerSlide,
                  child: Opacity(
                    opacity: _roundBannerOpacity.value,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xee0e1814),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xff10b981).withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff10b981).withValues(alpha: 0.35),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 16, color: Color(0xff34d399)),
                            const SizedBox(width: 8),
                            Text(
                              'РАУНД ${widget.roundNumber} / 10 · $multiplier× ҰПАЙ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. Waiting indicator if player has confirmed their point
          if (hasPlayerGuessed && !hasOpponentGuessed)
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xeb121c18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xff10b981).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xff34d399),
                      ),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Болжам қабылданды! Қарсыласты күтудеміз...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Floating Expandable Mini-Map at bottom
          Positioned(
            bottom: 12,
            right: 0,
            left: 0,
            child: SafeArea(
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
          ),
        ],
      ),
    );
  }
}
