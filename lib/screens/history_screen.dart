import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../widgets/top_toast.dart';

/// Ecran d'historique : graphique en barres des derniers pourboires
/// suivi de la liste complete des calculs enregistres dans Firestore.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    const accent = Color(0xFFE89830);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getCalculations(),
        builder: (context, snapshot) {
          // ── Loading ────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Empty state ────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: labelColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun historique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vos calculs appara\u00EEtront ici',
                      style: TextStyle(fontSize: 14, color: labelColor),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Data ───────────────────────────────────────────────────
          final docs = snapshot.data!.docs;
          // Derniers 10 calculs pour le graphique (chronologique)
          final chartDocs = docs.take(10).toList().reversed.toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  // ── Chart section ──────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 18, color: labelColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Aper\u00E7u des pourboires',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: _buildChart(
                        chartDocs, accent, labelColor, isDark),
                  ),

                  const SizedBox(height: 32),

                  // ── List section ───────────────────────────────────
                  Row(
                    children: [
                      Icon(Icons.list_alt_outlined,
                          size: 18, color: labelColor),
                      const SizedBox(width: 6),
                      const Text(
                        'Tous les calculs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${docs.length} enregistrement${docs.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 13, color: labelColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Calculation cards ──────────────────────────────
                  ...docs.map((doc) => _buildHistoryCard(
                        context,
                        doc,
                        firestoreService,
                        accent,
                        labelColor,
                        isDark,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bar chart ──────────────────────────────────────────────────────────

  Widget _buildChart(
    List<QueryDocumentSnapshot> docs,
    Color accent,
    Color labelColor,
    bool isDark,
  ) {
    if (docs.isEmpty) return const SizedBox.shrink();

    final barGroups = docs.asMap().entries.map((entry) {
      final data = entry.value.data() as Map<String, dynamic>;
      final pourboire = (data['pourboire'] as num?)?.toDouble() ?? 0;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: pourboire,
            color: accent,
            width: 18,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: null,
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(barGroups),
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox.shrink();
                }
                  return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    '${value.toInt()}', // removed hardcoded Euro
                    style: TextStyle(fontSize: 11, color: labelColor),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= docs.length) {
                  return const SizedBox.shrink();
                }
                final data =
                    docs[idx].data() as Map<String, dynamic>;
                final date =
                    (data['date'] as Timestamp?)?.toDate();
                final label = date != null
                    ? DateFormat('dd/MM').format(date)
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: labelColor),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(2)}', // removed hardcoded Euro
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _gridInterval(List<BarChartGroupData> groups) {
    if (groups.isEmpty) return 10;
    final maxVal =
        groups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 10) return 2;
    if (maxVal <= 50) return 10;
    if (maxVal <= 200) return 50;
    return 100;
  }

  // ── History card ───────────────────────────────────────────────────────

  Widget _buildHistoryCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    FirestoreService service,
    Color accent,
    Color labelColor,
    bool isDark,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final montant = (data['montant'] as num?)?.toDouble() ?? 0;
    final pourcentage = (data['pourcentage'] as num?)?.toInt() ?? 0;
    final pourboire = (data['pourboire'] as num?)?.toDouble() ?? 0;
    final total = (data['total'] as num?)?.toDouble() ?? 0;
    final devise = data['devise'] as String? ?? '\u20AC';
    final date = (data['date'] as Timestamp?)?.toDate();
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy  HH:mm').format(date)
        : '--';

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer'),
            content: const Text(
                'Voulez-vous supprimer cet enregistrement ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        service.deleteCalculation(doc.id);
        TopToast.show(context, 'Enregistrement supprim\u00E9');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            // ── Top row: montant + totaux ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${montant.toStringAsFixed(2)} $devise',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$pourcentage% de pourboire',
                        style:
                            TextStyle(fontSize: 13, color: labelColor),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pourboire : ${pourboire.toStringAsFixed(2)} $devise',
                      style:
                          TextStyle(fontSize: 13, color: labelColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total : ${total.toStringAsFixed(2)} $devise',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Bottom row: date + delete ─────────────────────
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: labelColor),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: labelColor),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Supprimer'),
                        content: const Text(
                            'Voulez-vous supprimer cet enregistrement ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Supprimer',
                              style:
                                  TextStyle(color: Colors.red.shade400),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      service.deleteCalculation(doc.id);
                      TopToast.show(context, 'Enregistrement supprim\u00E9');
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
