import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';
import '../widgets/top_toast.dart';
import 'history_screen.dart';

/// Ecran principal de la calculatrice de pourboire.
///
/// Dispose d'un champ montant, d'un slider/champ pourcentage,
/// et affiche le resultat du calcul avec sauvegarde Firestore.
class CalculatorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const CalculatorScreen({super.key, required this.onToggleTheme});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _billController = TextEditingController();
  final _percentController = TextEditingController(text: '15');
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  double _tipPercentage = 15;
  double _tipAmount = 0;
  double _totalAmount = 0;

  String _currency = 'CFA';
  final List<String> _currencies = ['CFA', '\u20AC', '\$'];

  @override
  void dispose() {
    _billController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  // ── Slider / TextField sync ────────────────────────────────────────────

  void _onSliderChanged(double value) {
    setState(() {
      _tipPercentage = value;
      _percentController.text = value.round().toString();
    });
  }

  void _onPercentFieldChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 100) {
      setState(() {
        _tipPercentage = parsed;
      });
    }
  }

  // ── Calcul ─────────────────────────────────────────────────────────────

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final bill = double.tryParse(_billController.text.replaceAll(',', '.'));
    if (bill == null || bill <= 0) return;

    final tip = bill * _tipPercentage / 100;
    final total = bill + tip;

    setState(() {
      _tipAmount = tip;
      _totalAmount = total;
    });

    // Sauvegarde dans Firestore
    _firestoreService.saveCalculation(
      montant: bill,
      pourcentage: _tipPercentage.round(),
      pourboire: tip,
      total: total,
      devise: _currency,
    );

    TopToast.show(context, 'Calcul enregistr\u00E9 avec succ\u00E8s');
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    const accent = Color(0xFFE89830);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // ── Top bar (Icons and Currency) ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          size: 24,
                        ),
                        onPressed: widget.onToggleTheme,
                        tooltip: 'Changer le th\u00E8me',
                      ),
                      Row(
                        children: [
                          Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _currency,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 16),
                                items: _currencies
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _currency = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 24,
                            ),
                            onPressed: _goToHistory,
                            tooltip: 'Historique',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // ── Title ────────────────────────────────
                          const Text(
                            'Calculer le',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const Text(
                            'pourboire',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ── Result: big number ──────────────────
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Montant du pourboire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: labelColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '$_currency ',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: labelColor,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      child: Text(
                                        _tipAmount.toStringAsFixed(2),
                                        key: ValueKey(_tipAmount),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Summary cards row ───────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryBox(
                                  label: 'Pourboire',
                                  value:
                                      '${_tipAmount.toStringAsFixed(2)} $_currency',
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryBox(
                                  label: 'Total \u00E0 payer',
                                  value:
                                      '${_totalAmount.toStringAsFixed(2)} $_currency',
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // ── Bill amount ─────────────────────────
                          Row(
                            children: [
                              Icon(Icons.receipt_outlined,
                                  size: 16, color: labelColor),
                              const SizedBox(width: 6),
                              Text(
                                'Montant de la facture',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _billController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.,]')),
                            ],
                            decoration: InputDecoration(
                              prefixText: '$_currency  ',
                              hintText: '0.00',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir un montant';
                              }
                              final parsed =
                                  double.tryParse(value.replaceAll(',', '.'));
                              if (parsed == null || parsed <= 0) {
                                return 'Montant invalide';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          // ── Tip percentage ──────────────────────
                          Row(
                            children: [
                              Icon(Icons.percent_outlined,
                                  size: 16, color: labelColor),
                              const SizedBox(width: 6),
                              Text(
                                'Pourcentage',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: labelColor,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 64,
                                height: 40,
                                child: TextField(
                                  controller: _percentController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: InputDecoration(
                                    suffixText: '%',
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                  ),
                                  onChanged: _onPercentFieldChanged,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Slider(
                            value: _tipPercentage.clamp(0, 30),
                            min: 0,
                            max: 30,
                            divisions: 30,
                            onChanged: _onSliderChanged,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '0%',
                                  style: TextStyle(
                                      fontSize: 12, color: labelColor),
                                ),
                                Text(
                                  '30%',
                                  style: TextStyle(
                                      fontSize: 12, color: labelColor),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom Buttons ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _goToHistory,
                          child: const Text('Historique'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _calculate,
                          child: const Text('Calculer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small summary card (Pourboire / Total) ─────────────────────────────────

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;
  final bool isDark;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
