import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_widget.dart';

class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  // ── Supported currencies ──────────────────────────────────────────
  static const List<Map<String, String>> _currencies = [
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'USD', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'flag': '🇨🇭'},
    {'code': 'ALL', 'name': 'Albanian Lek', 'flag': '🇦🇱'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'flag': '🇸🇪'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'flag': '🇳🇴'},
    {'code': 'DKK', 'name': 'Danish Krone', 'flag': '🇩🇰'},
    {'code': 'PLN', 'name': 'Polish Zloty', 'flag': '🇵🇱'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'flag': '🇨🇿'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'flag': '🇭🇺'},
    {'code': 'RON', 'name': 'Romanian Leu', 'flag': '🇷🇴'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'flag': '🇹🇷'},
    {'code': 'MKD', 'name': 'Macedonian Denar', 'flag': '🇲🇰'},
    {'code': 'RSD', 'name': 'Serbian Dinar', 'flag': '🇷🇸'},
    {'code': 'BAM', 'name': 'Bosnian Mark', 'flag': '🇧🇦'},
  ];

  String _fromCurrency = 'EUR';
  String _toCurrency = 'ALL';
  final TextEditingController _amountController = TextEditingController(
    text: '1',
  );

  Map<String, double> _rates = {};
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastUpdated;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _dio.get(
        'https://open.er-api.com/v6/latest/$_fromCurrency',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final ratesRaw = data['rates'] as Map<String, dynamic>;
          final Map<String, double> parsed = {};
          ratesRaw.forEach((key, value) {
            parsed[key] = (value as num).toDouble();
          });
          setState(() {
            _rates = parsed;
            _lastUpdated = DateTime.now();
            _isLoading = false;
          });
        } else {
          _setError('API returned an error. Please try again.');
        }
      } else {
        _setError('Failed to fetch rates (${response.statusCode}).');
      }
    } on DioException catch (e) {
      _setError(
        e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout
            ? 'Connection timed out. Check your internet connection.'
            : 'Network error. Please try again.',
      );
    } catch (_) {
      _setError('Unexpected error. Please try again.');
    }
  }

  void _setError(String message) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = message;
    });
  }

  double get _inputAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
  }

  double get _convertedAmount {
    if (_rates.isEmpty || !_rates.containsKey(_toCurrency)) return 0.0;
    return _inputAmount * _rates[_toCurrency]!;
  }

  double get _liveRate {
    if (_rates.isEmpty || !_rates.containsKey(_toCurrency)) return 0.0;
    return _rates[_toCurrency]!;
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _fetchRates();
  }

  Map<String, String> _currencyInfo(String code) {
    return _currencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'code': code, 'name': code, 'flag': '🏳️'},
    );
  }

  String _formatAmount(double value, String currencyCode) {
    if (currencyCode == 'JPY' ||
        currencyCode == 'HUF' ||
        currencyCode == 'ALL' ||
        currencyCode == 'MKD' ||
        currencyCode == 'RSD' ||
        currencyCode == 'CZK') {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatLastUpdated() {
    if (_lastUpdated == null) return '';
    final now = DateTime.now();
    final diff = now.difference(_lastUpdated!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: KriketAppBar(
        title: 'Exchange Rates',
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchRates,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
            tooltip: 'Refresh rates',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live indicator ──────────────────────────────────────
            _buildLiveIndicator(),
            const SizedBox(height: 20),

            // ── Converter card ──────────────────────────────────────
            _buildConverterCard(),
            const SizedBox(height: 16),

            // ── Rate display ────────────────────────────────────────
            if (!_hasError && _rates.isNotEmpty) ...[
              _buildRateDisplay(),
              const SizedBox(height: 16),
            ],

            // ── Error state ─────────────────────────────────────────
            if (_hasError) ...[_buildErrorCard(), const SizedBox(height: 16)],

            // ── Disclaimer ──────────────────────────────────────────
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isLoading
                ? AppTheme.warning
                : _hasError
                ? AppTheme.error
                : AppTheme.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    (_isLoading
                            ? AppTheme.warning
                            : _hasError
                            ? AppTheme.error
                            : AppTheme.success)
                        .withAlpha(120),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isLoading
              ? 'Fetching live rates…'
              : _hasError
              ? 'Could not load rates'
              : 'Live rates · Updated ${_formatLastUpdated()}',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildConverterCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── From ─────────────────────────────────────────────────
          _buildCurrencyRow(
            label: 'From',
            selectedCode: _fromCurrency,
            isFrom: true,
          ),
          const SizedBox(height: 12),

          // ── Divider with swap button ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: const Color(0xFF2A2A3A)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isLoading ? null : _swapCurrencies,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withAlpha(80)),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(height: 1, color: const Color(0xFF2A2A3A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── To ───────────────────────────────────────────────────
          _buildCurrencyRow(
            label: 'To',
            selectedCode: _toCurrency,
            isFrom: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow({
    required String label,
    required String selectedCode,
    required bool isFrom,
  }) {
    final info = _currencyInfo(selectedCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMutedDark,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Currency selector
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _showCurrencyPicker(isFrom: isFrom),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Row(
                    children: [
                      Text(info['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCode,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryDark,
                              ),
                            ),
                            Text(
                              info['name']!,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: AppTheme.textMutedDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondaryDark,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Amount field
            Expanded(
              flex: 3,
              child: isFrom
                  ? TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryDark,
                      ),
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.manrope(
                          color: AppTheme.textMutedDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariantDark,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A3A),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2A2A3A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha(60),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                          : Text(
                              _hasError
                                  ? '—'
                                  : _formatAmount(
                                      _convertedAmount,
                                      _toCurrency,
                                    ),
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppTheme.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Rate',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 $_fromCurrency = ${_formatAmount(_liveRate, _toCurrency)} $_toCurrency',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
              ],
            ),
          ),
          if (_lastUpdated != null)
            Text(
              _formatLastUpdated(),
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.textMutedDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.error),
            ),
          ),
          TextButton(
            onPressed: _fetchRates,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.textMutedDark,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rates shown are indicative and for reference only. No real money is exchanged. Powered by open.er-api.com.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.textMutedDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker({required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return _CurrencyPickerSheet(
          currencies: _currencies,
          selectedCode: isFrom ? _fromCurrency : _toCurrency,
          onSelected: (code) {
            Navigator.of(ctx).pop();
            setState(() {
              if (isFrom) {
                _fromCurrency = code;
              } else {
                _toCurrency = code;
              }
            });
            _fetchRates();
          },
        );
      },
    );
  }
}

// ── Currency picker bottom sheet ──────────────────────────────────────────────
class _CurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';

  List<Map<String, String>> get _filtered {
    if (_search.isEmpty) return widget.currencies;
    final q = _search.toLowerCase();
    return widget.currencies.where((c) {
      return c['code']!.toLowerCase().contains(q) ||
          c['name']!.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Select Currency',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppTheme.textPrimaryDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search currency…',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textMutedDark,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariantDark,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF2A2A3A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isSelected = c['code'] == widget.selectedCode;
                  return ListTile(
                    onTap: () => widget.onSelected(c['code']!),
                    leading: Text(
                      c['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      c['code']!,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textPrimaryDark,
                      ),
                    ),
                    subtitle: Text(
                      c['name']!,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppTheme.textMutedDark,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected
                        ? AppTheme.primaryContainer
                        : Colors.transparent,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
