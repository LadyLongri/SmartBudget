import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class DashboardShowcaseScreen extends StatefulWidget {
  const DashboardShowcaseScreen({super.key});
  static const String routeName = '/dashboard';

  @override
  State<DashboardShowcaseScreen> createState() =>
      _DashboardShowcaseScreenState();
}

class _DashboardShowcaseScreenState extends State<DashboardShowcaseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeLeft;
  late final Animation<Offset> _slideLeft;
  late final Animation<double> _fadeRight;
  late final Animation<Offset> _slideRight;
  bool _loadingData = false;
  String? _errorMessage;
  _DashboardData _data = _DashboardData.zero();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeLeft = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
    );
    _slideLeft =
        Tween<Offset>(
          begin: const Offset(-0.08, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _fadeRight = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.95, curve: Curves.easeOutCubic),
    );
    _slideRight =
        Tween<Offset>(
          begin: const Offset(0.08, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _loadingData = false;
      _errorMessage = null;
      _data = _DashboardData.zero();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool desktop = constraints.maxWidth >= 980;
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _fadeLeft,
                                    child: SlideTransition(
                                      position: _slideLeft,
                                      child: _WalletPanel(
                                        data: _data,
                                        loading: _loadingData,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _fadeRight,
                                    child: SlideTransition(
                                      position: _slideRight,
                                      child: _StatisticPanel(
                                        data: _data,
                                        loading: _loadingData,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                FadeTransition(
                                  opacity: _fadeRight,
                                  child: SlideTransition(
                                    position: _slideRight,
                                    child: _StatisticPanel(
                                      data: _data,
                                      loading: _loadingData,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FadeTransition(
                                  opacity: _fadeLeft,
                                  child: SlideTransition(
                                    position: _slideLeft,
                                    child: _WalletPanel(
                                      data: _data,
                                      loading: _loadingData,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Row(
              children: [
                if (_errorMessage != null)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC2D4FF)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFF284071),
                        fontSize: 12,
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _loadingData ? null : _loadDashboardData,
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D8FF)),
                      ),
                      child: _loadingData
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF5A82E8),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: Color(0xFF4B75DF),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFEAF2FF),
            Color(0xFFDCE8FF),
            Color(0xFFF3E9FF),
          ],
          stops: <double>[0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -180,
            top: -120,
            child: _blurOrb(
              size: 420,
              color: const Color(0xFF4A84FF).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            right: -190,
            bottom: -200,
            child: _blurOrb(
              size: 520,
              color: const Color(0xFF9B58FF).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            right: 60,
            top: 80,
            child: _blurOrb(
              size: 220,
              color: const Color(0xFFFF4A4A).withValues(alpha: 0.12),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _LightStreamPainter()),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _blurOrb({required double size, required Color color}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            blurRadius: size * 0.35,
            spreadRadius: size * 0.05,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _LightStreamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF5B82EA).withValues(alpha: 0.18);

    for (int i = -2; i < 9; i++) {
      final double x = size.width * 0.17 * i;
      final Path path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + 18, size.height * 0.5, x - 8, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalletPanel extends StatefulWidget {
  const _WalletPanel({required this.data, required this.loading});

  final _DashboardData data;
  final bool loading;

  @override
  State<_WalletPanel> createState() => _WalletPanelState();
}

class _WalletPanelState extends State<_WalletPanel> {
  final List<_CardData> _cards = const [
    _CardData(
      brand: "HRTBT",
      numberTop: "5303 6084",
      numberBottom: "2402 3649",
      expiry: "09/24",
      glow: Color(0xFF4F7BFF),
      gradientA: Color(0xFFF6FAFF),
      gradientB: Color(0xFFE2ECFF),
    ),
    _CardData(
      brand: "ALTRX",
      numberTop: "9088 4421",
      numberBottom: "6234 1110",
      expiry: "04/27",
      glow: Color(0xFFFF5B5B),
      gradientA: Color(0xFFFFF5F5),
      gradientB: Color(0xFFFFE5EC),
    ),
    _CardData(
      brand: "NEBLA",
      numberTop: "7712 2309",
      numberBottom: "9921 4478",
      expiry: "12/29",
      glow: Color(0xFF8D6DFF),
      gradientA: Color(0xFFF4EEFF),
      gradientB: Color(0xFFE5DBFF),
    ),
  ];

  late final PageController _pageController;
  Timer? _autoPager;
  double _page = 0;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_onScroll);
    _autoPager = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || _cards.length < 2) return;
      final int next = (_active + 1) % _cards.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPager?.cancel();
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double rawPage = _pageController.hasClients
        ? (_pageController.page ?? _pageController.initialPage.toDouble())
        : 0;
    final int rounded = rawPage.round().clamp(0, _cards.length - 1);
    if (_page != rawPage || _active != rounded) {
      setState(() {
        _page = rawPage;
        _active = rounded;
      });
    }
  }

  String _formatMoney(double value) {
    final String fixed = value.toStringAsFixed(2);
    final List<String> parts = fixed.split(".");
    final String raw = parts[0];
    final String decimals = parts[1];
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int reverseIndex = raw.length - i;
      out.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        out.write(",");
      }
    }
    return "\$ ${out.toString()}.$decimals";
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassTile(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                const _RedToggle(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Notify about\nnew services",

                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFCDD7E6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _GlassTile(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
              child: Column(
                children: [
                  SizedBox(
                    height: 392,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _cards.length,
                      itemBuilder: (BuildContext context, int index) {
                        final double delta = index - _page;
                        final double absDelta = delta.abs();
                        final double rotateY = (delta * 0.26).clamp(
                          -0.34,
                          0.34,
                        );
                        final double scale = (1 - absDelta * 0.12).clamp(
                          0.84,
                          1,
                        );
                        final double opacity = (1 - absDelta * 0.35).clamp(
                          0.45,
                          1,
                        );

                        return Transform(
                          alignment: delta >= 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(rotateY)
                            ..scaleByDouble(scale, scale, 1, 1),
                          child: Opacity(
                            opacity: opacity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: _BankCard(data: _cards[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      _cards.length,
                      (int i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _DotIndicator(active: i == _active),
                      ),
                    ),
                  ),
                  if (widget.loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Color(0xFF1B2738),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF7F9BC4),
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text(
                          "Balance",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          _formatMoney(widget.data.balance),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: const Color(0xFFE7EEF9),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: widget.data.creditLimit <= 0
                            ? 0
                            : (widget.data.creditUsed / widget.data.creditLimit)
                                  .clamp(0, 1),
                        minHeight: 14,
                        backgroundColor: const Color(0xFF1A2534),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF394961),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text(
                          "Credit limit",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: const Color(0xFF8E9BB1)),
                        ),
                        const Spacer(),
                        Text(
                          "${_formatMoney(widget.data.creditUsed)} / ${_formatMoney(widget.data.creditLimit)}",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF9DAAC0),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticPanel extends StatefulWidget {
  const _StatisticPanel({required this.data, required this.loading});

  final _DashboardData data;
  final bool loading;

  @override
  State<_StatisticPanel> createState() => _StatisticPanelState();
}

class _StatisticPanelState extends State<_StatisticPanel> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final int next = (_pageController.page ?? 0).round().clamp(0, 1);
    if (next != _pageIndex) {
      setState(() => _pageIndex = next);
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _pageIndex == 0 ? "Statistic" : "Insights";
    return _PhoneShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconButton(icon: Icons.arrow_back_rounded),
              const SizedBox(width: 8),
              _iconButton(icon: Icons.grid_view_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (Widget child, Animation<double> anim) {
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    title,
                    key: ValueKey<String>(title),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFE9F0FC),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _GlassTile(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Text(
                  "Period:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF8C9AB0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _pageIndex == 0 ? widget.data.periodLabel : "Last 12 weeks",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFDCE8FA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  height: 38,
                  width: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A2638),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF95A7C5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PageView(
              controller: _pageController,
              children: [
                _DonutStatsPage(data: widget.data, loading: widget.loading),
                _TrendStatsPage(data: widget.data),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _pageIndex == 0
                ? _ExpenseTile(data: widget.data)
                : _SavingTile(data: widget.data),
          ),
          const SizedBox(height: 14),
          _GlassTile(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavIcon(
                  icon: Icons.home_outlined,
                  active: _pageIndex == 0,
                  onTap: () => _goToPage(0),
                ),
                const _BottomNavIcon(icon: Icons.add_rounded),
                _BottomNavIcon(
                  icon: Icons.copy_outlined,
                  active: _pageIndex == 0,
                  onTap: () => _goToPage(0),
                ),
                _BottomNavIcon(
                  icon: Icons.insights_outlined,
                  active: _pageIndex == 1,
                  onTap: () => _goToPage(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({required IconData icon}) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF121C2A),
        border: Border.all(color: const Color(0xFF2A3446)),
      ),
      child: Icon(icon, color: const Color(0xFF7D90AE), size: 20),
    );
  }
}

class _DonutStatsPage extends StatelessWidget {
  const _DonutStatsPage({required this.data, required this.loading});

  final _DashboardData data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 330,
        height: 330,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(330),
              painter: _DonutPainter(
                value: data.topCategoryPercent,
                baseColor: const Color(0xFF212E41),
                accentColor: const Color(0xFFFF8D24),
              ),
            ),
            Text(
              "${(data.topCategoryPercent * 100).toStringAsFixed(0)}%",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF6D4D2B),
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (loading)
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0xFF202D40),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8BA6CF)),
                ),
              ),
            Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: <Color>[Color(0xFFFF4F42), Color(0xFFD91D14)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2C1A).withValues(alpha: 0.65),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.north_east_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendStatsPage extends StatelessWidget {
  const _TrendStatsPage({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _GlassTile(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cashflow trend",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFEAF1FD),
                      fontSize: 23,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Swipe between pages",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF8EA0BC),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _MiniTrendChart(values: data.trendPoints)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      key: const ValueKey<String>("expense-tile"),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.local_cafe_outlined, color: Color(0xFF7B8CA7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.topCategoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF9CA8BE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${(data.topCategoryPercent * 100).toStringAsFixed(0)}%",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFC7D3E7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(data.topCategoryAmount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFEFF4FD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) => "\$ ${value.toStringAsFixed(2)}";
}

class _SavingTile extends StatelessWidget {
  const _SavingTile({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return _GlassTile(
      key: const ValueKey<String>("saving-tile"),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Color(0xFF8DA7FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Savings",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF9CA8BE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${data.transactionCount} transactions",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFB6C9FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(data.totalIncome),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFEFF4FD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) => "\$ ${value.toStringAsFixed(2)}";
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.66,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 820),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF1A2433), Color(0xFF0A121E)],
          ),
          border: Border.all(color: const Color(0xFF263247)),
          boxShadow: [
            BoxShadow(
              blurRadius: 60,
              offset: const Offset(0, 35),
              color: Colors.black.withValues(alpha: 0.55),
            ),
            BoxShadow(
              blurRadius: 30,
              spreadRadius: -4,
              color: const Color(0xFF163256).withValues(alpha: 0.3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1C2737), Color(0xFF111A27)],
        ),
        border: Border.all(color: const Color(0xFF263247)),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RedToggle extends StatelessWidget {
  const _RedToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      width: 148,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF111A26),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                "ON",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFC8D5E9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            width: 68,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFF3B22), Color(0xFFE81B0E)],
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  spreadRadius: 3,
                  color: const Color(0xFFFF2C1A).withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.data});

  final _CardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 372,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[data.gradientA, data.gradientB],
        ),
        border: Border.all(color: const Color(0xFF2E3A50)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -35,
            bottom: -56,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    data.glow.withValues(alpha: 0.9),
                    data.glow.withValues(alpha: 0.45),
                    data.glow.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Row(
              children: [
                Text(
                  data.brand,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFD7E3F8),
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF1F2A3B),
                    border: Border.all(color: const Color(0xFF334359)),
                  ),
                  child: const Icon(
                    Icons.view_array_rounded,
                    size: 28,
                    color: Color(0xFF6D809E),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 120,
            child: Text(
              "${data.numberTop}\n${data.numberBottom}",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF8FA0BD),
                letterSpacing: 2.2,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 28,
            child: Text(
              data.expiry,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF7F90AE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF60708D)),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A374B),
                      border: Border.all(color: const Color(0xFF3D4D66)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({required this.icon, this.active = false, this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: active ? const Color(0xFF151E2B) : const Color(0xFF172131),
          border: Border.all(
            color: active ? const Color(0xFF5C6D8A) : const Color(0xFF28364B),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    blurRadius: 18,
                    color: const Color(0xFF111F35).withValues(alpha: 0.75),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: active ? const Color(0xFFDCE7FA) : const Color(0xFF6D7D98),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 12 : 10,
      height: active ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFFB8C9E7) : const Color(0xFF4A5973),
        boxShadow: active
            ? [
                BoxShadow(
                  blurRadius: 10,
                  color: const Color(0xFF7894C4).withValues(alpha: 0.5),
                ),
              ]
            : null,
      ),
    );
  }
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(values: values),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF4F6589).withValues(alpha: 0.16);

    for (int i = 0; i < 5; i++) {
      final double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final List<double> points = _normalize(values);
    final Path line = Path();
    for (int i = 0; i < points.length; i++) {
      final double x = size.width * (i / (points.length - 1));
      final double y = size.height * (1 - points[i]);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 12
      ..color = const Color(0xFF438BFF).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(line, glow);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF7AB4FF),
          Color(0xFF8A6CFF),
          Color(0xFFFF8E2A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(line, stroke);

    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFF438BFF).withValues(alpha: 0.26),
          const Color(0xFF438BFF).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values;

  List<double> _normalize(List<double> source) {
    if (source.length < 2) {
      return const <double>[0.28, 0.46, 0.33, 0.56, 0.49, 0.72, 0.67, 0.85];
    }

    final double minValue = source.reduce(math.min);
    final double maxValue = source.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.0001) {
      return List<double>.filled(source.length, 0.5, growable: false);
    }

    return source
        .map(
          (double point) =>
              ((point - minValue) / (maxValue - minValue)).clamp(0.08, 0.94),
        )
        .toList(growable: false);
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.value,
    required this.baseColor,
    required this.accentColor,
  });

  final double value;
  final Color baseColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width * 0.39;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final double startAngle = -math.pi / 2;
    const double sweepGap = 0.07;
    final double activeSweep = 2 * math.pi * value;
    final double segmentSweep = (2 * math.pi - 4 * sweepGap) / 4;

    final Paint basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round
      ..color = baseColor;

    for (int i = 0; i < 4; i++) {
      final double segmentStart = startAngle + i * (segmentSweep + sweepGap);
      canvas.drawArc(rect, segmentStart, segmentSweep, false, basePaint);
    }

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 46
      ..strokeCap = StrokeCap.round
      ..color = accentColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawArc(rect, startAngle + 2.15, activeSweep, false, glowPaint);

    final Paint activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 42
      ..strokeCap = StrokeCap.round
      ..color = accentColor;
    canvas.drawArc(rect, startAngle + 2.15, activeSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor;
  }
}

class _DashboardData {
  const _DashboardData({
    required this.periodLabel,
    required this.balance,
    required this.creditUsed,
    required this.creditLimit,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    required this.topCategoryName,
    required this.topCategoryAmount,
    required this.topCategoryPercent,
    required this.trendPoints,
    required this.categoriesCount,
    required this.transactionsCount,
  });

  final String periodLabel;
  final double balance;
  final double creditUsed;
  final double creditLimit;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final String topCategoryName;
  final double topCategoryAmount;
  final double topCategoryPercent;
  final List<double> trendPoints;
  final int categoriesCount;
  final int transactionsCount;

  factory _DashboardData.zero() {
    return const _DashboardData(
      periodLabel: "Last 30 days",
      balance: 0,
      creditUsed: 0,
      creditLimit: 0,
      totalExpense: 0,
      totalIncome: 0,
      transactionCount: 0,
      topCategoryName: "No category",
      topCategoryAmount: 0,
      topCategoryPercent: 0,
      trendPoints: <double>[0, 0, 0, 0, 0, 0, 0, 0],
      categoriesCount: 0,
      transactionsCount: 0,
    );
  }
}

class _CardData {
  const _CardData({
    required this.brand,
    required this.numberTop,
    required this.numberBottom,
    required this.expiry,
    required this.glow,
    required this.gradientA,
    required this.gradientB,
  });

  final String brand;
  final String numberTop;
  final String numberBottom;
  final String expiry;
  final Color glow;
  final Color gradientA;
  final Color gradientB;
}
