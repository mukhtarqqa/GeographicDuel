import 'package:flutter/material.dart';
import '../../../core/theme/atlas_theme.dart';
import '../../../domain/models/round_result.dart';

class DamageBanner extends StatelessWidget {
  const DamageBanner({
    super.key,
    required this.result,
  });

  final DuelRoundResult result;

  String _formatNumber(num n) {
    final str = n.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: result.isTie
            ? const Color(0xfff0f2ee)
            : (result.playerWon
                ? const Color(0xfff6ffed)
                : const Color(0xfffff1f0)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isTie
              ? AtlasColors.line
              : (result.playerWon
                  ? const Color(0xffb7eb8f)
                  : const Color(0xffffccc7)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  result.isTie
                      ? 'Зақым жоқ (тең ойын)'
                      : (result.playerWon
                          ? 'Қарсыласқа келген зақым:'
                          : 'Алынған зақым:'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: result.playerWon
                        ? const Color(0xff389e0d)
                        : const Color(0xffcf1322),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result.damage == 0 ? '0 HP' : '−${_formatNumber(result.damage)} HP',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: result.playerWon
                      ? const Color(0xff389e0d)
                      : const Color(0xffcf1322),
                ),
              ),
            ],
          ),
          if (result.multiplier > 1.0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AtlasColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Зақым көбейткіші: ${result.multiplier.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff996600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
