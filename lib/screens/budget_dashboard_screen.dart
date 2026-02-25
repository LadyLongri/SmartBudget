import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stats_models.dart';
import '../models/transaction_model.dart';
import '../services/dashboard_feature_service.dart';
import '../widgets/feature_state_banner.dart';
import 'auth_screen.dart';

class BudgetDashboardScreen extends StatefulWidget {
  const BudgetDashboardScreen({super.key});

  static const String routeName = '/budget-dashboard';

  @override
  State<BudgetDashboardScreen> createState() => _BudgetDashboardScreenState();
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.backgroundA,
            palette.backgroundB,
            palette.backgroundC,
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          _orb(
            alignment: const Alignment(-1.2, -0.8),
            size: 320,
            color: palette.accent.withValues(alpha: 0.18),
          ),
          _orb(
            alignment: const Alignment(1.1, -0.2),
            size: 300,
            color: const Color(0xFFE63B4A).withValues(alpha: 0.14),
          ),
          _orb(
            alignment: const Alignment(1.0, 1.0),
            size: 360,
            color: const Color(0xFF8D5CFF).withValues(alpha: 0.14),
          ),
        ],
      ),
    );
  }

  Widget _orb({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: size * 0.45),
          ],
        ),
      ),
    );
  }
}

class _RingGauge extends StatelessWidget {
  const _RingGauge({
    required this.value,
    required this.palette,
    this.centerText,
  });

  final double value;
  final _Palette palette;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    final String label = centerText ?? '${(value * 100).toStringAsFixed(0)}%';
    return CustomPaint(
      painter: _RingGaugePainter(value: value, palette: palette),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: palette.textStrong,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _RingGaugePainter extends CustomPainter {
  const _RingGaugePainter({required this.value, required this.palette});

  final double value;
  final _Palette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2 - 10;
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    const double start = -math.pi / 2;
    final double sweep = 2 * math.pi * value.clamp(0, 1);

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = palette.ringBase;
    canvas.drawArc(rect, start, 2 * math.pi, false, base);

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = palette.glow.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(rect, start, sweep, false, glow);

    final Paint active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF4A84FF),
          Color(0xFFE63B4A),
          Color(0xFF8D5CFF),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, start, sweep, false, active);
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.palette != palette;
  }
}

class _ComparisonChartPainter extends CustomPainter {
  const _ComparisonChartPainter({
    required this.incomePoints,
    required this.expensePoints,
    required this.incomeColor,
    required this.expenseColor,
    required this.axisColor,
  });

  final List<double> incomePoints;
  final List<double> expensePoints;
  final Color incomeColor;
  final Color expenseColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (incomePoints.isEmpty || expensePoints.isEmpty) return;
    final Paint axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final double leftPad = 8;
    final double rightPad = 8;
    final double topPad = 8;
    final double bottomPad = 16;

    for (int i = 0; i < 4; i++) {
      final double y = topPad + ((size.height - topPad - bottomPad) / 3) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        axisPaint,
      );
    }

    final double maxIncome = incomePoints.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    final double maxExpense = expensePoints.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    final double maxValue = math.max(1, math.max(maxIncome, maxExpense));

    Path buildLine(List<double> points) {
      final Path path = Path();
      final int count = points.length;
      for (int i = 0; i < count; i++) {
        final double x =
            leftPad + ((size.width - leftPad - rightPad) * i / (count - 1));
        final double ratio = points[i] / maxValue;
        final double y =
            size.height -
            bottomPad -
            (ratio * (size.height - topPad - bottomPad));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final Paint incomePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = incomeColor;
    final Paint expensePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = expenseColor;

    final Path incomePath = buildLine(incomePoints);
    final Path expensePath = buildLine(expensePoints);

    final Paint incomeGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = incomeColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final Paint expenseGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = expenseColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(incomePath, incomeGlow);
    canvas.drawPath(expensePath, expenseGlow);
    canvas.drawPath(incomePath, incomePaint);
    canvas.drawPath(expensePath, expensePaint);
  }

  @override
  bool shouldRepaint(covariant _ComparisonChartPainter oldDelegate) {
    return oldDelegate.incomePoints != incomePoints ||
        oldDelegate.expensePoints != expensePoints ||
        oldDelegate.incomeColor != incomeColor ||
        oldDelegate.expenseColor != expenseColor ||
        oldDelegate.axisColor != axisColor;
  }
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter({
    required this.values,
    required this.palette,
    required this.emptyColor,
  });

  final List<double> values;
  final List<Color> palette;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = math.min(size.width, size.height) / 2 - 8;
    final Rect rect = Rect.fromCircle(center: c, radius: r);
    const double gap = 0.07;
    final double total = values.fold<double>(0, (double a, double b) => a + b);

    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = emptyColor;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, base);

    if (total <= 0) return;
    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final double part = values[i];
      if (part <= 0) continue;
      final double sweep = (2 * math.pi * (part / total)) - gap;
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = palette[i % palette.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.palette != palette ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class _BudgetTx {
  const _BudgetTx({
    required this.title,
    required this.category,
    required this.source,
    required this.amount,
    required this.isExpense,
    required this.colorValue,
    required this.date,
  });

  final String title;
  final String category;
  final String source;
  final double amount;
  final bool isExpense;
  final int colorValue;
  final DateTime date;

  factory _BudgetTx.fromMap(Map<String, dynamic> map) {
    final dynamic rawDate = map['date'];
    DateTime parsed = DateTime.now();
    if (rawDate is Timestamp) parsed = rawDate.toDate();
    if (rawDate is int) parsed = DateTime.fromMillisecondsSinceEpoch(rawDate);
    if (rawDate is String) parsed = DateTime.tryParse(rawDate) ?? parsed;
    return _BudgetTx(
      title: (map['title'] as String?) ?? 'Transaction',
      category: (map['category'] as String?) ?? 'Autres',
      source: (map['source'] as String?) ?? 'cash',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      isExpense: map['isExpense'] == true,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF4A84FF,
      date: parsed,
    );
  }

  Map<String, dynamic> toMap({required bool forCloud}) {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'source': source,
      'amount': amount,
      'isExpense': isExpense,
      'colorValue': colorValue,
      'date': forCloud ? Timestamp.fromDate(date) : date.toIso8601String(),
    };
  }
}

class _LinkedAccount {
  const _LinkedAccount({
    required this.id,
    required this.institution,
    required this.accountType,
    required this.alias,
    required this.linked,
    required this.colorValue,
  });

  final String id;
  final String institution;
  final String accountType;
  final String alias;
  final bool linked;
  final int colorValue;

  _LinkedAccount copyWith({
    String? id,
    String? institution,
    String? accountType,
    String? alias,
    bool? linked,
    int? colorValue,
  }) {
    return _LinkedAccount(
      id: id ?? this.id,
      institution: institution ?? this.institution,
      accountType: accountType ?? this.accountType,
      alias: alias ?? this.alias,
      linked: linked ?? this.linked,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  factory _LinkedAccount.fromMap(Map<String, dynamic> map) {
    return _LinkedAccount(
      id: (map['id'] as String?) ?? '',
      institution: (map['institution'] as String?) ?? 'Institution',
      accountType: (map['accountType'] as String?) ?? 'checking',
      alias: (map['alias'] as String?) ?? '',
      linked: map['linked'] == true,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF4A84FF,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'institution': institution,
      'accountType': accountType,
      'alias': alias,
      'linked': linked,
      'colorValue': colorValue,
    };
  }
}

class _Palette {
  const _Palette({
    required this.dark,
    required this.accent,
    required this.glowLevel,
  });

  final bool dark;
  final Color accent;
  final double glowLevel;

  Color get backgroundA =>
      dark ? const Color(0xFF0B1426) : const Color(0xFFEAF2FF);
  Color get backgroundB =>
      dark ? const Color(0xFF091225) : const Color(0xFFDCE8FF);
  Color get backgroundC =>
      dark ? const Color(0xFF08101F) : const Color(0xFFF2ECFF);
  Color get panelTop =>
      dark ? const Color(0xFF1A2435) : const Color(0xFFF8FBFF);
  Color get panelBottom =>
      dark ? const Color(0xFF101A29) : const Color(0xFFE9F0FF);
  Color get border => dark ? const Color(0xFF27344A) : const Color(0xFFC6D9FF);
  Color get shadow => dark
      ? Colors.black.withValues(alpha: 0.45)
      : const Color(0xFF7A9CDB).withValues(alpha: 0.18);
  Color get textStrong =>
      dark ? const Color(0xFFEAF0FA) : const Color(0xFF1C2F57);
  Color get textMuted =>
      dark ? const Color(0xFF99ABC7) : const Color(0xFF5D739E);
  Color get danger => const Color(0xFFE65B5B);
  Color get success => const Color(0xFF2DB177);
  Color get ringBase =>
      dark ? const Color(0xFF253448) : const Color(0xFFD8E6FF);
  Color get glow => accent.withValues(alpha: 0.25 + (0.35 * glowLevel));
}

enum _ApiDashboardState { idle, loading, success, empty, error }

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _expenseCategories = <String>[
    'Alimentation',
    'Restaurant',
    'Transport',
    'Carburant',
    'Eau',
    'Electricite',
    'Telecom',
    'Internet',
    'Loyer',
    'Sante',
    'Sante familiale',
    'Scolarite',
    'Logement',
    'Factures',
    'Shopping',
    'Loisirs',
    'Education',
    'Voyage',
    'Imprevus',
    'Autres',
  ];
  static const List<String> _incomeCategories = <String>[
    'Salaire',
    'Freelance',
    'Business',
    'Commerce',
    'Commission',
    'Prime',
    'Remboursement',
    'Aides familiales',
    'Interets',
    'Location',
    'Vente',
    'Cadeau',
    'Autres revenus',
  ];
  static const List<String> _expenseSources = <String>[
    'visa',
    'bank_account',
    'mobile_money',
    'airtel_money',
    'orange_money',
    'mpesa',
    'cash',
    'caisse',
  ];
  static const List<String> _incomeSources = <String>[
    'bank_account',
    'mobile_money',
    'airtel_money',
    'orange_money',
    'mpesa',
    'cash',
    'caisse',
  ];
  static const Map<String, int> _expenseCategoryPalette = <String, int>{
    'Alimentation': 0xFF3B82F6,
    'Restaurant': 0xFFE53935,
    'Transport': 0xFFFF9800,
    'Carburant': 0xFFFF7043,
    'Eau': 0xFF29B6F6,
    'Electricite': 0xFFFFCA28,
    'Telecom': 0xFF26C6DA,
    'Loyer': 0xFF6D4C41,
    'Sante': 0xFF26A69A,
    'Sante familiale': 0xFF4DB6AC,
    'Scolarite': 0xFF5C6BC0,
    'Logement': 0xFF8D6E63,
    'Factures': 0xFFAB47BC,
    'Internet': 0xFF29B6F6,
    'Shopping': 0xFFEC407A,
    'Loisirs': 0xFF7E57C2,
    'Education': 0xFF5C6BC0,
    'Voyage': 0xFF66BB6A,
    'Imprevus': 0xFF78909C,
    'Autres': 0xFF90A4AE,
  };
  static const Map<String, int> _incomeCategoryPalette = <String, int>{
    'Salaire': 0xFF2DB177,
    'Freelance': 0xFF26A69A,
    'Business': 0xFF5C6BC0,
    'Commerce': 0xFF42A5F5,
    'Commission': 0xFFFFB300,
    'Prime': 0xFF8D5CFF,
    'Remboursement': 0xFF29B6F6,
    'Aides familiales': 0xFF7E57C2,
    'Interets': 0xFF66BB6A,
    'Location': 0xFF4CAF50,
    'Vente': 0xFFFF9800,
    'Cadeau': 0xFFEC407A,
    'Autres revenus': 0xFF90A4AE,
  };
  static const List<String> _statsPeriodOptions = <String>[
    '7j',
    '30j',
    '90j',
    '12m',
    'Tout',
    'Custom',
  ];
  static const String _localStateKey = 'sb_local_state_v2';
  static const List<List<int>> _paletteShades = <List<int>>[
    <int>[
      0xFFB9D2FF,
      0xFF8FB6FF,
      0xFF5A8EFF,
      0xFF2E73E8,
      0xFF1F5BC2,
      0xFF15449A,
    ],
    <int>[
      0xFFCBE5FF,
      0xFF99CCFF,
      0xFF5EABFF,
      0xFF2F88F5,
      0xFF1D6CC9,
      0xFF1453A0,
    ],
    <int>[
      0xFFFFC8CE,
      0xFFFFA0AB,
      0xFFFF7A8A,
      0xFFE63B4A,
      0xFFBA1D33,
      0xFF8F1427,
    ],
    <int>[
      0xFFE1CCFF,
      0xFFC9A8FF,
      0xFFB18CFF,
      0xFF8D5CFF,
      0xFF6A3DCC,
      0xFF512E9C,
    ],
    <int>[
      0xFFCFF5E3,
      0xFFA8EBCF,
      0xFF61CC98,
      0xFF2BAE73,
      0xFF1F8659,
      0xFF156644,
    ],
    <int>[
      0xFFC7F1F2,
      0xFF9CE6E8,
      0xFF59CAD2,
      0xFF2FA8B2,
      0xFF1F7E87,
      0xFF155E65,
    ],
    <int>[
      0xFFFFE2B9,
      0xFFFFCC8A,
      0xFFFFB45A,
      0xFFF4931F,
      0xFFC97313,
      0xFF9A560C,
    ],
    <int>[
      0xFFFFD0E3,
      0xFFFFA6CB,
      0xFFFF79AF,
      0xFFE44A8F,
      0xFFB62D69,
      0xFF861F4D,
    ],
    <int>[
      0xFFD8E0EE,
      0xFFB8C4D8,
      0xFF90A3C1,
      0xFF667B9B,
      0xFF485A78,
      0xFF2F3D55,
    ],
  ];
  static const List<String> _accountTypes = <String>[
    'checking',
    'savings',
    'mobile',
    'credit',
  ];

  int _tab = 0;
  bool _monthlyView = false;
  int _selectedDay = DateTime.now().day.clamp(1, 28);
  bool _loadingCloud = true;
  String? _syncMessage;
  DateTime? _lastCloudSyncAt;
  DateTime? _localUpdatedAt;
  String _statsPeriod = '30j';
  DateTimeRange? _customStatsRange;
  _ApiDashboardState _apiState = _ApiDashboardState.idle;
  String? _apiErrorMessage;
  String _apiMonth =
      '${DateTime.now().year.toString().padLeft(4, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}';
  String _apiCurrency = 'USD';
  StatsSummaryModel? _apiSummary;
  List<CategoryStatItemModel> _apiCategoryItems = <CategoryStatItemModel>[];
  List<StatsTrendPointModel> _apiTrendItems = <StatsTrendPointModel>[];
  List<TransactionModel> _apiTransactions = <TransactionModel>[];
  Map<String, String> _apiCategoryNameById = <String, String>{};

  double _budgetTotal = 0;
  double _visaBalance = 0;
  double _mobileMoneyBalance = 0;
  double _cashBalance = 0;

  bool _darkMode = false;
  double _glowLevel = 0.6;
  int _accentValue = _paletteShades[0][2];
  int _paletteIndex = 0;
  int _shadeIndex = 2;
  String _currency = 'USD';

  final List<_BudgetTx> _transactions = <_BudgetTx>[];
  final List<_LinkedAccount> _linkedAccounts = <_LinkedAccount>[
    const _LinkedAccount(
      id: 'american_express',
      institution: 'American Express',
      accountType: 'credit',
      alias: 'Amex',
      linked: false,
      colorValue: 0xFF5A8EFF,
    ),
    const _LinkedAccount(
      id: 'bank_of_africa',
      institution: 'Bank of Africa',
      accountType: 'checking',
      alias: 'BOA',
      linked: false,
      colorValue: 0xFF2BAE73,
    ),
    const _LinkedAccount(
      id: 'capital_one',
      institution: 'Capital One',
      accountType: 'credit',
      alias: 'Capital',
      linked: false,
      colorValue: 0xFF8D5CFF,
    ),
    const _LinkedAccount(
      id: 'chase',
      institution: 'Chase',
      accountType: 'checking',
      alias: 'Chase',
      linked: false,
      colorValue: 0xFFE63B4A,
    ),
    const _LinkedAccount(
      id: 'mobile_money',
      institution: 'Mobile Money',
      accountType: 'mobile',
      alias: 'MM',
      linked: true,
      colorValue: 0xFFE63B4A,
    ),
  ];
  late final AnimationController _entryController;
  late final DashboardFeatureService _featureService;
  StreamSubscription<User?>? _authSub;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _featureService = DashboardFeatureService();
    _loadLocalData();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _loadCloudData();
      _loadApiDashboard();
    });
    _loadCloudData();
    _loadApiDashboard();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _authSub?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  _Palette get _palette => _Palette(
    dark: _darkMode,
    accent: Color(_accentValue),
    glowLevel: _glowLevel,
  );

  double get _expenses => _transactions
      .where((_BudgetTx tx) => tx.isExpense)
      .fold<double>(0, (double s, _BudgetTx t) => s + t.amount);

  double get _incomes => _transactions
      .where((_BudgetTx tx) => !tx.isExpense)
      .fold<double>(0, (double s, _BudgetTx t) => s + t.amount);

  double get _walletTotal => _visaBalance + _mobileMoneyBalance + _cashBalance;
  double get _netFlow => _incomes - _expenses;
  int get _expenseCount =>
      _transactions.where((_BudgetTx tx) => tx.isExpense).length;
  int get _incomeCount =>
      _transactions.where((_BudgetTx tx) => !tx.isExpense).length;
  double get _remainingBudget => _budgetTotal - _expenses;
  double get _budgetUsage =>
      _budgetTotal <= 0 ? 0 : (_expenses / _budgetTotal).clamp(0, 1);
  List<int> get _availableStatColors => _paletteShades
      .map((List<int> shades) => shades[shades.length > 2 ? 2 : 0])
      .toList(growable: false);

  List<String> _categoriesFor(bool isExpense) {
    return isExpense ? _expenseCategories : _incomeCategories;
  }

  List<String> _sourcesFor(bool isExpense) {
    return isExpense ? _expenseSources : _incomeSources;
  }

  DateTimeRange? _statsRangeForPeriod() {
    final DateTime now = DateTime.now();
    final DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_statsPeriod) {
      case '7j':
        return DateTimeRange(
          start: end.subtract(const Duration(days: 6)),
          end: end,
        );
      case '30j':
        return DateTimeRange(
          start: end.subtract(const Duration(days: 29)),
          end: end,
        );
      case '90j':
        return DateTimeRange(
          start: end.subtract(const Duration(days: 89)),
          end: end,
        );
      case '12m':
        return DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: end,
        );
      case 'Custom':
        return _customStatsRange;
      default:
        return null;
    }
  }

  bool _inActiveStatsRange(DateTime date) {
    final DateTimeRange? range = _statsRangeForPeriod();
    if (range == null) return true;
    final DateTime dayDate = DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
    return !dayDate.isBefore(range.start) && !dayDate.isAfter(range.end);
  }

  List<_BudgetTx> get _statsTransactions => _transactions
      .where((_BudgetTx tx) => _inActiveStatsRange(tx.date))
      .toList(growable: false);

  double get _statsExpenses {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiSummary != null) {
      return _apiSummary!.totalExpense;
    }
    return _statsTransactions
        .where((_BudgetTx tx) => tx.isExpense)
        .fold<double>(0, (double s, _BudgetTx t) => s + t.amount);
  }

  double get _statsIncomes {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiSummary != null) {
      return _apiSummary!.totalIncome;
    }
    return _statsTransactions
        .where((_BudgetTx tx) => !tx.isExpense)
        .fold<double>(0, (double s, _BudgetTx t) => s + t.amount);
  }

  String get _statsPeriodLabel {
    if (_statsPeriod != 'Custom') return _statsPeriod;
    final DateTimeRange? range = _customStatsRange;
    if (range == null) return 'Custom';
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  List<String> _apiMonthOptions() {
    final DateTime now = DateTime.now();
    final List<String> values = <String>[];
    for (int i = 0; i < 12; i++) {
      final DateTime d = DateTime(now.year, now.month - i, 1);
      final String month =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
      values.add(month);
    }
    if (!values.contains(_apiMonth)) {
      values.add(_apiMonth);
    }
    return values;
  }

  Future<void> _loadApiDashboard() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _apiState = _ApiDashboardState.idle;
        _apiErrorMessage = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _apiState = _ApiDashboardState.loading;
      _apiErrorMessage = null;
    });

    try {
      final DashboardFeatureSnapshot snapshot = await _featureService.fetch(
        month: _apiMonth,
        currency: _apiCurrency,
        granularity: _monthlyView ? 'week' : 'day',
      );
      if (!mounted) return;
      setState(() {
        _apiSummary = snapshot.summary;
        _apiCategoryItems = snapshot.byCategory;
        _apiTrendItems = snapshot.trend;
        _apiTransactions = snapshot.transactions;
        _apiCategoryNameById = snapshot.categoryNameById;
        _apiState = snapshot.isEmpty
            ? _ApiDashboardState.empty
            : _ApiDashboardState.success;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _apiState = _ApiDashboardState.error;
        _apiErrorMessage = '$error';
      });
    }
  }

  Map<String, double> get _apiCategoryTotals {
    final Map<String, double> totals = <String, double>{
      for (final String c in _expenseCategories) c: 0,
    };
    for (final CategoryStatItemModel item in _apiCategoryItems) {
      totals[item.categoryName] = item.total;
    }
    return totals;
  }

  Map<String, int> get _apiCategoryColors {
    final Map<String, int> colors = <String, int>{
      for (final String c in _expenseCategories)
        c: _defaultColorForCategory(c, isExpense: true),
    };
    for (final CategoryStatItemModel item in _apiCategoryItems) {
      colors[item.categoryName] = _defaultColorForCategory(
        item.categoryName,
        isExpense: true,
      );
    }
    return colors;
  }

  List<double> get _apiTrendExpenses {
    if (_apiTrendItems.isEmpty) return _trendExpenses;
    return _apiTrendItems
        .map((StatsTrendPointModel p) => p.totalExpense)
        .toList(growable: false);
  }

  List<double> get _apiTrendIncomes {
    if (_apiTrendItems.isEmpty) return _trendIncomes;
    return _apiTrendItems
        .map((StatsTrendPointModel p) => p.totalIncome)
        .toList(growable: false);
  }

  String _apiCategoryLabel(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Sans categorie';
    return _apiCategoryNameById[categoryId] ?? categoryId;
  }

  int _defaultColorForCategory(String category, {required bool isExpense}) {
    if (isExpense) {
      return _expenseCategoryPalette[category] ?? _accentValue;
    }
    return _incomeCategoryPalette[category] ?? _accentValue;
  }

  Map<String, double> get _categoryTotals {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiSummary != null) {
      return _apiCategoryTotals;
    }
    final Map<String, double> out = <String, double>{
      for (final String c in _expenseCategories) c: 0,
    };
    for (final _BudgetTx tx in _statsTransactions) {
      if (!tx.isExpense) continue;
      out[tx.category] = (out[tx.category] ?? 0) + tx.amount;
    }
    return out;
  }

  List<double> get _trendExpenses {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiTrendItems.isNotEmpty) {
      return _apiTrendExpenses;
    }
    final int count = _monthlyView ? 6 : 7;
    final List<double> values = List<double>.filled(count, 0);
    for (final _BudgetTx tx in _statsTransactions) {
      if (!tx.isExpense) continue;
      final int bucket = _monthlyView
          ? ((tx.date.day - 1) ~/ 5).clamp(0, count - 1)
          : tx.date.weekday - 1;
      values[bucket] += tx.amount;
    }
    return values;
  }

  List<double> get _trendIncomes {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiTrendItems.isNotEmpty) {
      return _apiTrendIncomes;
    }
    final int count = _monthlyView ? 6 : 7;
    final List<double> values = List<double>.filled(count, 0);
    for (final _BudgetTx tx in _statsTransactions) {
      if (tx.isExpense) continue;
      final int bucket = _monthlyView
          ? ((tx.date.day - 1) ~/ 5).clamp(0, count - 1)
          : tx.date.weekday - 1;
      values[bucket] += tx.amount;
    }
    return values;
  }

  List<int> get _trendColors {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiTrendItems.isNotEmpty) {
      return _apiTrendItems
          .map((StatsTrendPointModel p) {
            if (p.totalExpense > p.totalIncome) return 0xFFE65B5B;
            if (p.totalIncome > 0) return 0xFF2DB177;
            return _accentValue;
          })
          .toList(growable: false);
    }
    final int count = _monthlyView ? 6 : 7;
    final List<int> values = List<int>.filled(count, _accentValue);
    for (final _BudgetTx tx in _statsTransactions) {
      if (!tx.isExpense) continue;
      final int bucket = _monthlyView
          ? ((tx.date.day - 1) ~/ 5).clamp(0, count - 1)
          : tx.date.weekday - 1;
      values[bucket] = _defaultColorForCategory(tx.category, isExpense: true);
    }
    return values;
  }

  Map<String, int> get _categoryColors {
    if ((_apiState == _ApiDashboardState.success ||
            _apiState == _ApiDashboardState.empty) &&
        _apiSummary != null) {
      return _apiCategoryColors;
    }
    final Map<String, int> values = <String, int>{
      for (final String category in _expenseCategories)
        category: _defaultColorForCategory(category, isExpense: true),
    };
    for (final _BudgetTx tx in _statsTransactions) {
      if (!tx.isExpense) continue;
      values[tx.category] = _defaultColorForCategory(
        tx.category,
        isExpense: true,
      );
    }
    return values;
  }

  MapEntry<String, double> get _topCategory {
    MapEntry<String, double> best = const MapEntry<String, double>('Aucune', 0);
    for (final MapEntry<String, double> entry in _categoryTotals.entries) {
      if (entry.value > best.value) best = entry;
    }
    return best;
  }

  String _money(double value) {
    final String symbol = switch (_currency) {
      'CDF' => 'FC',
      'EUR' => 'EUR',
      _ => '\$',
    };
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String raw = parts[0];
    final String decimals = parts[1];
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int rev = raw.length - i;
      buf.write(raw[i]);
      if (rev > 1 && rev % 3 == 1) buf.write(' ');
    }
    return '$symbol ${buf.toString()}.$decimals';
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'visa':
        return 'Visa';
      case 'bank_account':
        return 'Compte bancaire';
      case 'mobile_money':
        return 'Mobile Money';
      case 'airtel_money':
        return 'Airtel Money';
      case 'orange_money':
        return 'Orange Money';
      case 'mpesa':
        return 'M-Pesa';
      case 'caisse':
        return 'Caisse';
      default:
        return 'Cash';
    }
  }

  String _formatHourMinute(DateTime date) {
    final String hh = date.hour.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _cloudPendingMessage() {
    if (_lastCloudSyncAt == null) {
      return 'Cloud indisponible pour le moment, sauvegarde locale active';
    }
    return 'Cloud en attente, derniere sync ${_formatHourMinute(_lastCloudSyncAt!)}';
  }

  DateTime? _parseUpdatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Future<void> _pickCustomStatsRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initial =
        _customStatsRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _statsPeriod = 'Custom';
      _customStatsRange = picked;
    });
    _queueSave();
  }

  String _csvEscape(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _buildTransactionsCsv() {
    final StringBuffer csv = StringBuffer();
    csv.writeln('type,titre,categorie,compte,montant,devise,date');
    final List<_BudgetTx> ordered = <_BudgetTx>[..._transactions]
      ..sort((_BudgetTx a, _BudgetTx b) => b.date.compareTo(a.date));
    for (final _BudgetTx tx in ordered) {
      csv.writeln(
        '${tx.isExpense ? "depense" : "revenu"},'
        '${_csvEscape(tx.title)},'
        '${_csvEscape(tx.category)},'
        '${_csvEscape(_sourceLabel(tx.source))},'
        '${tx.amount.toStringAsFixed(2)},'
        '$_currency,'
        '${tx.date.toIso8601String()}',
      );
    }
    return csv.toString();
  }

  Future<void> _exportCsvToClipboard() async {
    final String csv = _buildTransactionsCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV copie dans le presse-papiers')),
    );
  }

  String _sourceAccountKey(String source) {
    switch (source) {
      case 'visa':
      case 'bank_account':
        return 'visa';
      case 'mobile_money':
      case 'airtel_money':
      case 'orange_money':
      case 'mpesa':
        return 'mobile_money';
      default:
        return 'cash';
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double? _parseAmount(String input) {
    String value = input.trim().toUpperCase();
    value = value.replaceAll(_currency.toUpperCase(), '').replaceAll(' ', '');
    value = value.replaceAll(',', '.');
    value = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (value.isEmpty || value == '-' || value == '.' || value == '-.') {
      return null;
    }
    if (value.split('.').length > 2) {
      final List<String> parts = value.split('.');
      value = '${parts.sublist(0, parts.length - 1).join()}.${parts.last}';
    }
    return double.tryParse(value);
  }

  double _accountBalance(String source) {
    switch (_sourceAccountKey(source)) {
      case 'visa':
        return _visaBalance;
      case 'mobile_money':
        return _mobileMoneyBalance;
      default:
        return _cashBalance;
    }
  }

  void _applyToAccount(String source, double delta) {
    final String account = _sourceAccountKey(source);
    if (account == 'visa') {
      _visaBalance += delta;
      return;
    }
    if (account == 'mobile_money') {
      _mobileMoneyBalance += delta;
      return;
    }
    _cashBalance += delta;
  }

  String _formatDate(DateTime date) {
    final String dd = date.day.toString().padLeft(2, '0');
    final String mm = date.month.toString().padLeft(2, '0');
    final String yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Map<String, dynamic> _buildStateMap({required bool includeServerTimestamp}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'budgetTotal': _budgetTotal,
      'visaBalance': _visaBalance,
      'mobileMoneyBalance': _mobileMoneyBalance,
      'cashBalance': _cashBalance,
      'selectedDay': _selectedDay,
      'monthlyView': _monthlyView,
      'transactions': _transactions
          .map((_BudgetTx tx) => tx.toMap(forCloud: includeServerTimestamp))
          .toList(growable: false),
      'linkedAccounts': _linkedAccounts
          .map((_LinkedAccount account) => account.toMap())
          .toList(growable: false),
      'settings': <String, dynamic>{
        'darkMode': _darkMode,
        'glowLevel': _glowLevel,
        'accentValue': _accentValue,
        'currency': _currency,
        'paletteIndex': _paletteIndex,
        'shadeIndex': _shadeIndex,
        'statsPeriod': _statsPeriod,
        'customStatsStart': _customStatsRange?.start.toIso8601String(),
        'customStatsEnd': _customStatsRange?.end.toIso8601String(),
        'apiMonth': _apiMonth,
        'apiCurrency': _apiCurrency,
      },
    };
    if (includeServerTimestamp) {
      map['updatedAt'] = FieldValue.serverTimestamp();
    } else {
      map['updatedAt'] = DateTime.now().toIso8601String();
    }
    return map;
  }

  void _applyStateMap(Map<String, dynamic> data) {
    final Map<String, dynamic> settings =
        (data['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> rawTx =
        data['transactions'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawLinked =
        data['linkedAccounts'] as List<dynamic>? ?? <dynamic>[];

    _budgetTotal = _toDouble(data['budgetTotal']);
    _visaBalance = _toDouble(data['visaBalance']);
    _mobileMoneyBalance = _toDouble(data['mobileMoneyBalance']);
    _cashBalance = _toDouble(data['cashBalance']);
    _selectedDay = _toInt(data['selectedDay']).clamp(1, 28);
    _monthlyView = data['monthlyView'] == true;
    _darkMode = settings['darkMode'] == true;
    _glowLevel = _toDouble(settings['glowLevel']).clamp(0.1, 1.0);
    _paletteIndex = _toInt(
      settings['paletteIndex'],
    ).clamp(0, _paletteShades.length - 1);
    _shadeIndex = _toInt(
      settings['shadeIndex'],
    ).clamp(0, _paletteShades[_paletteIndex].length - 1);
    final int savedAccent = _toInt(settings['accentValue']);
    _accentValue = savedAccent == 0
        ? _paletteShades[_paletteIndex][_shadeIndex]
        : savedAccent;
    _currency = (settings['currency'] as String?) ?? 'USD';
    final String loadedPeriod =
        (settings['statsPeriod'] as String?) ?? _statsPeriod;
    _statsPeriod = _statsPeriodOptions.contains(loadedPeriod)
        ? loadedPeriod
        : '30j';
    final DateTime? customStart = _parseUpdatedAt(settings['customStatsStart']);
    final DateTime? customEnd = _parseUpdatedAt(settings['customStatsEnd']);
    _customStatsRange = (customStart != null && customEnd != null)
        ? DateTimeRange(start: customStart, end: customEnd)
        : null;
    final String? savedApiMonth = settings['apiMonth'] as String?;
    if (savedApiMonth != null &&
        RegExp(r'^\d{4}\-\d{2}$').hasMatch(savedApiMonth)) {
      _apiMonth = savedApiMonth;
    }
    final String? savedApiCurrency = settings['apiCurrency'] as String?;
    if (savedApiCurrency != null && savedApiCurrency.isNotEmpty) {
      _apiCurrency = savedApiCurrency;
    }
    _localUpdatedAt = _parseUpdatedAt(data['updatedAt']) ?? _localUpdatedAt;
    _transactions
      ..clear()
      ..addAll(
        rawTx
            .whereType<Map<String, dynamic>>()
            .map(_BudgetTx.fromMap)
            .toList(growable: false),
      );
    if (rawLinked.isNotEmpty) {
      _linkedAccounts
        ..clear()
        ..addAll(
          rawLinked
              .whereType<Map<String, dynamic>>()
              .map(_LinkedAccount.fromMap)
              .toList(growable: false),
        );
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_localStateKey);
      if (raw == null || raw.isEmpty) return;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        _applyStateMap(decoded);
        _loadingCloud = false;
        _syncMessage = 'Sauvegarde locale chargee';
      });
      _loadApiDashboard();
    } catch (_) {
      // Ignore local decode errors and keep defaults.
    }
  }

  Future<void> _saveLocalData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String payload = jsonEncode(
      _buildStateMap(includeServerTimestamp: false),
    );
    await prefs.setString(_localStateKey, payload);
    _localUpdatedAt = DateTime.now();
  }

  void _queueSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), _persistState);
  }

  Future<void> _persistState() async {
    await _saveLocalData();
    await _saveCloudData();
  }

  Future<void> _manualCloudSync() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _syncMessage = 'Connecte-toi pour activer la sauvegarde cloud');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const AuthScreen(),
        ),
      );
      return;
    }
    setState(() {
      _loadingCloud = true;
      _syncMessage = 'Resynchronisation cloud...';
    });
    await _saveCloudData();
    await _loadCloudData();
  }

  Future<void> _loadCloudData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loadingCloud = false;
        _syncMessage = 'Mode local actif (connecte-toi pour le cloud)';
      });
      return;
    }

    setState(() {
      _loadingCloud = true;
      _syncMessage = 'Synchronisation...';
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .collection('smartbudget')
          .doc('state')
          .get();

      if (!mounted) return;
      if (!doc.exists) {
        setState(() {
          _loadingCloud = false;
          _syncMessage = 'Compte cloud initialise';
        });
        await _saveCloudData();
        return;
      }

      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
      final DateTime? cloudUpdatedAt = _parseUpdatedAt(data['updatedAt']);
      final bool keepLocal = _localUpdatedAt != null &&
          (cloudUpdatedAt == null || _localUpdatedAt!.isAfter(cloudUpdatedAt));
      if (keepLocal) {
        setState(() {
          _loadingCloud = false;
          _syncMessage = 'Local plus recent, cloud mis a jour';
        });
        await _saveCloudData();
        return;
      }
      setState(() {
        _applyStateMap(data);
        _loadingCloud = false;
        _lastCloudSyncAt = cloudUpdatedAt ?? DateTime.now();
        _syncMessage = 'Cloud synchronise a ${_formatHourMinute(_lastCloudSyncAt!)}';
      });
      await _saveLocalData();
      _loadApiDashboard();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCloud = false;
        _syncMessage = _cloudPendingMessage();
      });
    }
  }

  Future<void> _saveCloudData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(
        () => _syncMessage = 'Sauvegarde locale active (non connecte)',
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('smartbudget')
          .doc('state')
          .set(
          _buildStateMap(includeServerTimestamp: true),
          SetOptions(merge: true),
        );
      if (!mounted) return;
      setState(() {
        _lastCloudSyncAt = DateTime.now();
        _localUpdatedAt = _lastCloudSyncAt;
        _syncMessage = 'Sauvegarde cloud a ${_formatHourMinute(_lastCloudSyncAt!)}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _syncMessage = _cloudPendingMessage());
    }
  }

  Future<void> _showTransactionDialog({bool? forceExpense}) async {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();
    bool isExpense = forceExpense ?? true;
    String category = _categoriesFor(isExpense).first;
    String source = _sourcesFor(isExpense).first;
    DateTime txDate = DateTime.now();
    int statColor = _defaultColorForCategory(category, isExpense: isExpense);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setD) {
            final List<String> categoryOptions = _categoriesFor(isExpense);
            final List<String> sourceOptions = _sourcesFor(isExpense);
            if (!categoryOptions.contains(category)) {
              category = categoryOptions.first;
              statColor = _defaultColorForCategory(category, isExpense: isExpense);
            }
            if (!sourceOptions.contains(source)) {
              source = sourceOptions.first;
            }
            return AlertDialog(
              title: const Text('Nouvelle transaction'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SwitchListTile(
                      value: isExpense,
                      onChanged: (bool v) => setD(() {
                        isExpense = v;
                        category = _categoriesFor(isExpense).first;
                        source = _sourcesFor(isExpense).first;
                        statColor = _defaultColorForCategory(
                          category,
                          isExpense: isExpense,
                        );
                        error = null;
                      }),
                      title: Text(isExpense ? 'Depense' : 'Revenu'),
                    ),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titre'),
                    ),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Montant',
                        hintText: 'Ex: 25.5',
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      items: categoryOptions
                          .map(
                            (String c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? v) {
                        if (v != null) {
                          setD(() {
                            category = v;
                            if (isExpense) {
                              statColor = _defaultColorForCategory(
                                category,
                                isExpense: true,
                              );
                            }
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: isExpense
                            ? 'Categorie depense'
                            : 'Categorie revenu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      items: sourceOptions
                          .map(
                            (String s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(_sourceLabel(s)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? v) {
                        if (v != null) setD(() => source = v);
                      },
                      decoration: InputDecoration(
                        labelText: isExpense
                            ? 'Compte de depense'
                            : 'Compte de revenu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.calendar_month_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Date: ${_formatDate(txDate)}')),
                        TextButton(
                          onPressed: () async {
                            final DateTime now = DateTime.now();
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: txDate,
                              firstDate: DateTime(now.year - 3),
                              lastDate: DateTime(now.year + 3),
                            );
                            if (picked != null) {
                              setD(() => txDate = picked);
                            }
                          },
                          child: const Text('Changer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isExpense) ...<Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Couleur statistique (automatique par categorie)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(statColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$category = repere couleur fixe',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ] else ...<Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Couleur statistique',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _availableStatColors
                            .map(
                              (int color) => InkWell(
                                onTap: () => setD(() => statColor = color),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(color),
                                    border: Border.all(
                                      color: statColor == color
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    final double? amount = _parseAmount(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      setD(() => error = 'Montant invalide');
                      return;
                    }
                    if (isExpense && _accountBalance(source) < amount) {
                      setD(() => error = 'Solde insuffisant sur ce compte');
                      return;
                    }
                    setState(() {
                      _applyToAccount(source, isExpense ? -amount : amount);
                      final int txColor = isExpense
                          ? _defaultColorForCategory(category, isExpense: true)
                          : statColor;
                      _transactions.insert(
                        0,
                        _BudgetTx(
                          title: titleCtrl.text.trim().isEmpty
                              ? category
                              : titleCtrl.text.trim(),
                          category: category,
                          source: source,
                          amount: amount,
                          isExpense: isExpense,
                          colorValue: txColor,
                          date: txDate,
                        ),
                      );
                    });
                    _queueSave();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _adjustAccount(String source, bool add) async {
    final TextEditingController amountCtrl = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setD) {
            return AlertDialog(
              title: Text(
                '${add ? "Crediter" : "Debiter"} ${_sourceLabel(source)}',
              ),
              content: TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Montant',
                  errorText: error,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    final double? amount = _parseAmount(amountCtrl.text);
                    if (amount == null || amount <= 0) {
                      setD(() => error = 'Montant invalide');
                      return;
                    }
                    if (!add && _accountBalance(source) < amount) {
                      setD(() => error = 'Solde insuffisant');
                      return;
                    }
                    setState(
                      () => _applyToAccount(source, add ? amount : -amount),
                    );
                    _queueSave();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editLinkedAccount(int index) async {
    final _LinkedAccount current = _linkedAccounts[index];
    final TextEditingController aliasCtrl = TextEditingController(
      text: current.alias,
    );
    String accountType = current.accountType;
    bool linked = current.linked;
    int colorValue = current.colorValue;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setD) {
            return AlertDialog(
              title: Text(current.institution),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: aliasCtrl,
                      decoration: const InputDecoration(labelText: 'Alias'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: accountType,
                      decoration: const InputDecoration(
                        labelText: 'Type compte',
                      ),
                      items: _accountTypes
                          .map(
                            (String type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value != null) setD(() => accountType = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: linked,
                      onChanged: (bool value) => setD(() => linked = value),
                      title: const Text('Compte connecte'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableStatColors
                              .map(
                                (int color) => InkWell(
                                  onTap: () => setD(() => colorValue = color),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(color),
                                      border: Border.all(
                                        color: colorValue == color
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                    ),
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFC62828)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    final String alias = aliasCtrl.text.trim();
                    if (alias.isEmpty) {
                      setD(() => error = 'Alias requis');
                      return;
                    }
                    setState(() {
                      _linkedAccounts[index] = current.copyWith(
                        alias: alias,
                        linked: linked,
                        accountType: accountType,
                        colorValue: colorValue,
                      );
                    });
                    _queueSave();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeTransaction(int index) {
    final _BudgetTx tx = _transactions.removeAt(index);
    _applyToAccount(tx.source, tx.isExpense ? tx.amount : -tx.amount);
    _queueSave();
  }

  Widget _glass(_Palette p, Widget child, {EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[p.panelTop, p.panelBottom],
        ),
        border: Border.all(color: p.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: p.shadow,
          ),
          BoxShadow(
            blurRadius: 22,
            spreadRadius: -2,
            color: p.glow.withValues(alpha: 0.12 + (0.18 * p.glowLevel)),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _Palette p = _palette;
    return Scaffold(
      backgroundColor: p.backgroundA,
      body: Stack(
        children: <Widget>[
          _AmbientBackground(palette: p),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final bool desktop = c.maxWidth >= 1020;
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: Curves.easeOutCubic,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _entryController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: desktop ? _desktopLayout(p) : _mobileLayout(p),
                  ),
                );
              },
            ),
          ),
          if (_loadingCloud)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width >= 1020
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (int i) => setState(() => _tab = i),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Portefeuille',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  label: 'Reglages',
                ),
              ],
            ),
    );
  }

  Widget _mobileLayout(_Palette p) {
    final List<Widget> tabs = <Widget>[
      _homeTab(p),
      _statsTab(p),
      _walletTab(p),
      _settingsTab(p),
    ];
    return Column(
      children: <Widget>[
        _header(p, compact: true),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: KeyedSubtree(key: ValueKey<int>(_tab), child: tabs[_tab]),
          ),
        ),
      ],
    );
  }

  Widget _desktopLayout(_Palette p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: <Widget>[
              _header(p, compact: false),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _homeTab(p)),
                  const SizedBox(width: 18),
                  Expanded(child: _statsTab(p)),
                  const SizedBox(width: 18),
                  SizedBox(width: 340, child: _walletAndSettingsColumn(p)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletAndSettingsColumn(_Palette p) {
    return Column(
      children: <Widget>[
        _walletCard(p, 'Visa', _visaBalance, 'visa', const <Color>[
          Color(0xFF2E7CFF),
          Color(0xFF885CFF),
        ]),
        const SizedBox(height: 12),
        _walletCard(
          p,
          'Mobile Money',
          _mobileMoneyBalance,
          'mobile_money',
          const <Color>[Color(0xFFE63B4A), Color(0xFF8D5CFF)],
        ),
        const SizedBox(height: 12),
        _walletCard(p, 'Cash', _cashBalance, 'cash', const <Color>[
          Color(0xFF2F3E58),
          Color(0xFF1E2A3E),
        ]),
        const SizedBox(height: 12),
        _linkedAccountsCard(p),
        const SizedBox(height: 12),
        _settingsTab(p),
      ],
    );
  }

  Widget _header(_Palette p, {required bool compact}) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 4, 4, compact ? 14 : 4, 4),
      child: Row(
        children: <Widget>[
          Container(
            height: compact ? 44 : 52,
            width: compact ? 44 : 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[p.accent, const Color(0xFF8E5BFF)],
              ),
              boxShadow: <BoxShadow>[BoxShadow(color: p.glow, blurRadius: 24)],
            ),
            child: Text(
              'SB',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SB',
                  style: TextStyle(
                    color: p.textStrong,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 20 : 26,
                  ),
                ),
                if (_syncMessage != null)
                  Text(
                    _syncMessage!,
                    style: TextStyle(color: p.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: _showTransactionDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Transaction',
          ),
          if (user == null) ...<Widget>[
            const SizedBox(width: 6),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const AuthScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Connexion'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _homeTab(_Palette p) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        _glass(
          p,
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Budget total', style: TextStyle(color: p.textMuted)),
                    Text(
                      _money(_budgetTotal),
                      style: TextStyle(
                        color: p.textStrong,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Restant: ${_money(_remainingBudget)}',
                      style: TextStyle(
                        color: _remainingBudget < 0 ? p.danger : p.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Flux net: ${_money(_netFlow)}',
                      style: TextStyle(
                        color: _netFlow < 0 ? p.danger : p.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                width: 120,
                child: _RingGauge(value: _budgetUsage, palette: p),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _glass(
          p,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Portefeuille',
                    style: TextStyle(
                      color: p.textStrong,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _money(_walletTotal),
                    style: TextStyle(
                      color: p.textStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _walletQuickPill(
                    p,
                    icon: Icons.credit_card,
                    label: 'Visa',
                    amount: _visaBalance,
                    tint: const Color(0xFF2E7CFF),
                  ),
                  _walletQuickPill(
                    p,
                    icon: Icons.phone_android,
                    label: 'Mobile Money',
                    amount: _mobileMoneyBalance,
                    tint: const Color(0xFFE63B4A),
                  ),
                  _walletQuickPill(
                    p,
                    icon: Icons.wallet,
                    label: 'Cash',
                    amount: _cashBalance,
                    tint: const Color(0xFF667B9B),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _metricTile(
                      p,
                      label: 'Transactions',
                      value: '${_transactions.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(
                      p,
                      label: 'Depenses',
                      value: '$_expenseCount',
                      valueColor: p.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(
                      p,
                      label: 'Revenus',
                      value: '$_incomeCount',
                      valueColor: p.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _glass(
          p,
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showTransactionDialog(forceExpense: true),
                  icon: const Icon(Icons.remove),
                  label: const Text('Depense'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showTransactionDialog(forceExpense: false),
                  icon: const Icon(Icons.add),
                  label: const Text('Revenu'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _glass(
          p,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'Transactions recentes',
                    style: TextStyle(
                      color: p.textStrong,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_transactions.length}',
                    style: TextStyle(color: p.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_transactions.isEmpty)
                Text(
                  'Aucune transaction pour le moment',
                  style: TextStyle(color: p.textMuted),
                )
              else
                ...List<Widget>.generate(math.min(_transactions.length, 6), (
                  int i,
                ) {
                  final _BudgetTx tx = _transactions[i];
                  final int txColor = tx.isExpense
                      ? _defaultColorForCategory(tx.category, isExpense: true)
                      : tx.colorValue;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Color(txColor).withValues(alpha: 0.2),
                      child: Icon(
                        tx.isExpense
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: tx.isExpense ? p.danger : p.success,
                      ),
                    ),
                    title: Text(
                      tx.title,
                      style: TextStyle(color: p.textStrong),
                    ),
                    subtitle: Text(
                      '${tx.category} - ${_sourceLabel(tx.source)} - ${_formatDate(tx.date)}',
                      style: TextStyle(color: p.textMuted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${tx.isExpense ? '-' : '+'}${_money(tx.amount)}',
                          style: TextStyle(
                            color: tx.isExpense ? p.danger : p.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _removeTransaction(i)),
                          icon: Icon(Icons.delete_outline, color: p.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _walletQuickPill(
    _Palette p, {
    required IconData icon,
    required String label,
    required double amount,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: p.panelTop.withValues(alpha: 0.7),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Text(
            '$label: ${_money(amount)}',
            style: TextStyle(color: p.textStrong, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    _Palette p, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: p.panelTop.withValues(alpha: 0.74),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? p.textStrong,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedAccountsCard(_Palette p) {
    return _glass(
      p,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Comptes lies',
                style: TextStyle(
                  color: p.textStrong,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Icon(Icons.link_rounded, color: p.accent),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(_linkedAccounts.length, (int index) {
            final _LinkedAccount account = _linkedAccounts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: p.panelTop.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: ListTile(
                onTap: () => _editLinkedAccount(index),
                leading: CircleAvatar(
                  backgroundColor: Color(
                    account.colorValue,
                  ).withValues(alpha: 0.2),
                  child: Icon(
                    account.linked
                        ? Icons.link_rounded
                        : Icons.link_off_rounded,
                    color: Color(account.colorValue),
                  ),
                ),
                title: Text(
                  account.alias,
                  style: TextStyle(
                    color: p.textStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${account.institution} - ${account.accountType}',
                  style: TextStyle(color: p.textMuted),
                ),
                trailing: Icon(
                  Icons.edit_rounded,
                  color: p.textMuted,
                  size: 20,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            'Chaque bouton est interactif: touche un compte pour modifier ses attributs.',
            style: TextStyle(color: p.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _statsTab(_Palette p) {
    final MapEntry<String, double> top = _topCategory;
    final double statsExpenses = _statsExpenses;
    final double statsIncomes = _statsIncomes;
    final double topPercent = statsExpenses <= 0
        ? 0
        : (top.value / statsExpenses).clamp(0, 1);
    final List<double> bars = _trendExpenses;
    final List<int> barColors = _trendColors;
    final double maxBar = bars.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        _glass(
          p,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Vue ${_monthlyView ? "mensuelle" : "hebdomadaire"}',
                      style: TextStyle(
                        color: p.textStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const <ButtonSegment<bool>>[
                      ButtonSegment<bool>(value: false, label: Text('Semaine')),
                      ButtonSegment<bool>(value: true, label: Text('Mois')),
                    ],
                    selected: <bool>{_monthlyView},
                    onSelectionChanged: (Set<bool> set) {
                      setState(() => _monthlyView = set.first);
                      _loadApiDashboard();
                      _queueSave();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _apiMonth,
                      decoration: const InputDecoration(labelText: 'Mois API'),
                      items: _apiMonthOptions()
                          .map(
                            (String month) => DropdownMenuItem<String>(
                              value: month,
                              child: Text(month),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value == null) return;
                        setState(() => _apiMonth = value);
                        _loadApiDashboard();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _apiCurrency,
                      decoration: const InputDecoration(labelText: 'Devise API'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(value: 'USD', child: Text('USD')),
                        DropdownMenuItem<String>(value: 'CDF', child: Text('CDF')),
                        DropdownMenuItem<String>(value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (String? value) {
                        if (value == null) return;
                        setState(() => _apiCurrency = value);
                        _loadApiDashboard();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _apiState == _ApiDashboardState.loading
                        ? null
                        : _loadApiDashboard,
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Recharger API',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Periode stats: $_statsPeriodLabel',
                style: TextStyle(
                  color: p.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statsPeriodOptions.map((String option) {
                  final bool active = _statsPeriod == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: active,
                    onSelected: (bool selected) {
                      if (!selected) return;
                      if (option == 'Custom') {
                        _pickCustomStatsRange();
                        return;
                      }
                      setState(() => _statsPeriod = option);
                      _queueSave();
                    },
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_apiState == _ApiDashboardState.idle)
          _glass(
            p,
            const FeatureStateBanner(
              stateLabel: 'API',
              message: 'Connecte-toi pour charger les donnees API backend.',
              icon: Icons.cloud_off_rounded,
            ),
          ),
        if (_apiState == _ApiDashboardState.loading)
          _glass(
            p,
            const FeatureStateBanner(
              stateLabel: 'API',
              message: 'Chargement des statistiques API...',
              icon: Icons.sync_rounded,
            ),
          ),
        if (_apiState == _ApiDashboardState.error)
          _glass(
            p,
            FeatureStateBanner(
              stateLabel: 'Erreur API',
              message: _apiErrorMessage ?? 'Erreur API',
              icon: Icons.error_outline_rounded,
              onRetry: _loadApiDashboard,
            ),
          ),
        if (_apiState == _ApiDashboardState.empty)
          _glass(
            p,
            FeatureStateBanner(
              stateLabel: 'API',
              message:
                  'API repond mais aucune donnee pour $_apiMonth ($_apiCurrency).',
              icon: Icons.inbox_outlined,
            ),
          ),
        if (_apiState == _ApiDashboardState.success && _apiSummary != null)
          _glass(
            p,
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Source API active: ${_apiSummary!.transactionCount} transactions',
                    style: TextStyle(color: p.textMuted),
                  ),
                ),
                if (_apiTransactions.isNotEmpty)
                  Text(
                    _apiCategoryLabel(_apiTransactions.first.categoryId),
                    style: TextStyle(
                      color: p.textStrong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _glass(
          p,
          Row(
            children: <Widget>[
              SizedBox(
                height: 170,
                width: 170,
                child: _RingGauge(
                  value: topPercent,
                  palette: p,
                  centerText: '${(topPercent * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Categorie dominante',
                      style: TextStyle(color: p.textMuted),
                    ),
                    Text(
                      top.key,
                      style: TextStyle(
                        color: p.textStrong,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(top.value),
                      style: TextStyle(
                        color: p.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Depenses: ${_money(statsExpenses)}',
                      style: TextStyle(color: p.danger),
                    ),
                    Text(
                      'Revenus: ${_money(statsIncomes)}',
                      style: TextStyle(color: p.success),
                    ),
                    Text(
                      'Solde portefeuille: ${_money(_walletTotal)}',
                      style: TextStyle(color: p.textStrong),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _glass(
          p,
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List<Widget>.generate(bars.length, (int i) {
                final double h = maxBar <= 0
                    ? 20
                    : 20 + ((bars[i] / maxBar) * 120);
                return Container(
                  width: 24,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(barColors[i]).withValues(alpha: 0.72),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _comparisonChartCard(p),
        const SizedBox(height: 12),
        _categoryBreakdownCard(p),
      ],
    );
  }

  Widget _comparisonChartCard(_Palette p) {
    final List<double> incomes = _trendIncomes;
    final List<double> expenses = _trendExpenses;
    return _glass(
      p,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Comparaison Revenus / Depenses',
            style: TextStyle(
              color: p.textStrong,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _monthlyView
                ? 'Vue par periode mensuelle'
                : 'Vue par jour de semaine',
            style: TextStyle(color: p.textMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _ComparisonChartPainter(
                incomePoints: incomes,
                expensePoints: expenses,
                incomeColor: p.success,
                expenseColor: p.danger,
                axisColor: p.textMuted.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _legendDot(p.success, 'Revenus'),
              const SizedBox(width: 14),
              _legendDot(p.danger, 'Depenses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryBreakdownCard(_Palette p) {
    final Map<String, double> categories = _categoryTotals;
    final double statsExpenses = _statsExpenses;
    final Map<String, int> categoryColors = _categoryColors;
    final List<MapEntry<String, double>> ordered = categories.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });
    return _glass(
      p,
      Row(
        children: <Widget>[
          SizedBox(
            height: 170,
            width: 170,
            child: CustomPaint(
              painter: _CategoryDonutPainter(
                values: ordered
                    .map((MapEntry<String, double> e) => e.value)
                    .toList(growable: false),
                palette: ordered
                    .map(
                      (MapEntry<String, double> entry) => Color(
                        categoryColors[entry.key] ?? _accentValue,
                      ).withValues(alpha: 0.82),
                    )
                    .toList(growable: false),
                emptyColor: p.ringBase,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ordered
                  .take(5)
                  .map((MapEntry<String, double> entry) {
                    final double pct = statsExpenses <= 0
                        ? 0
                        : (entry.value / statsExpenses * 100).clamp(0, 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(
                                categoryColors[entry.key] ?? _accentValue,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: p.textStrong,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            _money(entry.value),
                            style: TextStyle(
                              color: p.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: p.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _walletTab(_Palette p) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        _walletCard(p, 'Visa', _visaBalance, 'visa', const <Color>[
          Color(0xFF2E7CFF),
          Color(0xFF885CFF),
        ]),
        const SizedBox(height: 12),
        _walletCard(
          p,
          'Mobile Money',
          _mobileMoneyBalance,
          'mobile_money',
          const <Color>[Color(0xFFE63B4A), Color(0xFF8D5CFF)],
        ),
        const SizedBox(height: 12),
        _walletCard(p, 'Cash', _cashBalance, 'cash', const <Color>[
          Color(0xFF2E3C54),
          Color(0xFF1A2537),
        ]),
        const SizedBox(height: 12),
        _linkedAccountsCard(p),
      ],
    );
  }

  Widget _walletCard(
    _Palette p,
    String label,
    double amount,
    String source,
    List<Color> colors,
  ) {
    return _glass(
      p,
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: colors),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 22,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _money(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => _adjustAccount(source, false),
                  icon: const Icon(Icons.remove, color: Colors.white),
                  label: const Text(
                    'Debiter',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _adjustAccount(source, true),
                  icon: const Icon(Icons.add),
                  label: const Text('Crediter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors.first,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTab(_Palette p) {
    final User? user = FirebaseAuth.instance.currentUser;
    return _glass(
      p,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Parametres',
            style: TextStyle(
              color: p.textStrong,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _darkMode,
            onChanged: (bool v) {
              setState(() => _darkMode = v);
              _queueSave();
            },
            title: Text('Mode sombre', style: TextStyle(color: p.textStrong)),
          ),
          const SizedBox(height: 8),
          Text('Palette de nuances', style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(_paletteShades.length, (
              int paletteIdx,
            ) {
              final List<int> shades = _paletteShades[paletteIdx];
              final bool active = _paletteIndex == paletteIdx;
              return InkWell(
                onTap: () {
                  setState(() {
                    _paletteIndex = paletteIdx;
                    _shadeIndex = _shadeIndex.clamp(0, shades.length - 1);
                    _accentValue = shades[_shadeIndex];
                  });
                  _queueSave();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? Color(shades[2]) : p.border,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: shades
                        .map(
                          (int c) => Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(c),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text('Nuance active', style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List<Widget>.generate(
              _paletteShades[_paletteIndex].length,
              (int shadeIdx) {
                final int c = _paletteShades[_paletteIndex][shadeIdx];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _shadeIndex = shadeIdx;
                      _accentValue = c;
                    });
                    _queueSave();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: shadeIdx == _shadeIndex
                            ? Colors.black
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text('Intensite glow', style: TextStyle(color: p.textMuted)),
          Slider(
            value: _glowLevel,
            min: 0.1,
            max: 1,
            onChanged: (double v) => setState(() => _glowLevel = v),
            onChangeEnd: (_) => _queueSave(),
          ),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Devise'),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'USD', child: Text('USD')),
              DropdownMenuItem<String>(value: 'CDF', child: Text('CDF')),
              DropdownMenuItem<String>(value: 'EUR', child: Text('EUR')),
            ],
            onChanged: (String? v) {
              if (v == null) return;
              setState(() => _currency = v);
              _queueSave();
            },
          ),
          const SizedBox(height: 8),
          if (user != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  setState(() => _syncMessage = 'Compte deconnecte');
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Se deconnecter'),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _manualCloudSync,
              icon: const Icon(Icons.cloud_sync_outlined),
              label: const Text('Resynchroniser cloud'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportCsvToClipboard,
              icon: const Icon(Icons.table_view_rounded),
              label: const Text('Exporter transactions CSV'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _budgetTotal = 0;
                _visaBalance = 0;
                _mobileMoneyBalance = 0;
                _cashBalance = 0;
                _transactions.clear();
              });
              _queueSave();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset a zero'),
          ),
        ],
      ),
    );
  }
}
