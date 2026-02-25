import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'budget_dashboard_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0B1426),
              Color(0xFF101D33),
              Color(0xFF0B1630),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool desktop = constraints.maxWidth >= 980;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      children: <Widget>[
                        _topBar(context),
                        const SizedBox(height: 16),
                        desktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(flex: 5, child: _heroCard(context)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: <Widget>[
                                        _accountPreviewCard(),
                                        const SizedBox(height: 14),
                                        _statsPreviewCard(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: <Widget>[
                                  _heroCard(context),
                                  const SizedBox(height: 14),
                                  _accountPreviewCard(),
                                  const SizedBox(height: 14),
                                  _statsPreviewCard(),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF13213E), Color(0xFF1E3B74)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Text(
            'SB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'SB',
            style: TextStyle(
              color: Color(0xFFF3F7FF),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A2A49),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111C30).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2B3A56)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final bool compact = c.maxWidth < 700;
          return compact
              ? Column(
                  children: <Widget>[
                    _introVisual(),
                    const SizedBox(height: 16),
                    _heroTextBlock(context, compact: true),
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: _introVisual()),
                    const SizedBox(width: 16),
                    Expanded(child: _heroTextBlock(context, compact: false)),
                  ],
                );
        },
      ),
    );
  }

  Widget _introVisual() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 320,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0D1A33),
              Color(0xFF17315D),
              Color(0xFF244A8F),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.black.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Image.asset(
                  'assets/images/smartbudget_logo.png',
                  width: 188,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroTextBlock(BuildContext context, {required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bienvenue sur SB',
          style: TextStyle(
            color: const Color(0xFFF0F5FF),
            fontSize: compact ? 30 : 36,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Inspiration premium: comptes, analytics et suivi visuel en temps reel.',
          style: TextStyle(color: Color(0xFFA6B7D8), height: 1.35),
        ),
        const SizedBox(height: 14),
        _kpiRow(),
        const SizedBox(height: 14),
        _bullet('Comptes lies: Visa, Mobile Money, Cash'),
        _bullet('Graphiques: courbes + donut + progression budget'),
        _bullet('Theme moderne glass / neumorph'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      const BudgetDashboardScreen(),
                ),
              );
            },
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text("Entrer dans l'application"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFF2D73EC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, color: Color(0xFF2E73E8), size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD4E0F8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiRow() {
    return Row(
      children: const <Widget>[
        Expanded(
          child: _KpiTile(label: 'Wallet', value: '\$ 4 280'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _KpiTile(label: 'Revenus', value: '\$ 2 640'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _KpiTile(label: 'Depenses', value: '\$ 1 180'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _KpiTile(label: 'Cloud', value: 'ON'),
        ),
      ],
    );
  }

  Widget _accountPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sideCardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Comptes Lies',
            style: TextStyle(
              color: Color(0xFFE8EFFD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _AccountAmountChip(
                icon: Icons.credit_card,
                label: 'Visa',
                amount: '\$ 1 920',
                color: Color(0xFF2E7CFF),
              ),
              _AccountAmountChip(
                icon: Icons.phone_android,
                label: 'Mobile Money',
                amount: '\$ 1 160',
                color: Color(0xFFE63B4A),
              ),
              _AccountAmountChip(
                icon: Icons.account_balance,
                label: 'Bank',
                amount: '\$ 780',
                color: Color(0xFF8D5CFF),
              ),
              _AccountAmountChip(
                icon: Icons.wallet,
                label: 'Cash',
                amount: '\$ 420',
                color: Color(0xFF61CC98),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Ajoute tes comptes et centralise toutes les depenses.',
            style: TextStyle(color: Color(0xFFA4B3CF)),
          ),
        ],
      ),
    );
  }

  Widget _statsPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _sideCardStyle(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Apercu Statistiques',
            style: TextStyle(
              color: Color(0xFFE8EFFD),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          _MiniBars(),
          SizedBox(height: 10),
          _MiniDonut(),
        ],
      ),
    );
  }

  BoxDecoration _sideCardStyle() {
    return BoxDecoration(
      color: const Color(0xFF141F35).withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFF2C3D59)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 22,
          offset: const Offset(0, 11),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF17253E),
        border: Border.all(color: const Color(0xFF2C3D5E)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE8F0FF),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA8B8D5),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAmountChip extends StatelessWidget {
  const _AccountAmountChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1B2945),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDCE7FB),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFFF0F6FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars();

  @override
  Widget build(BuildContext context) {
    const List<double> values = <double>[18, 42, 30, 56, 40, 66, 48];
    return SizedBox(
      height: 74,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: values
            .map(
              (double h) => Container(
                width: 16,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      Color(0xFF4A84FF),
                      Color(0xFF8D5CFF),
                      Color(0xFFE63B4A),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MiniDonut extends StatelessWidget {
  const _MiniDonut();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox(
            height: 116,
            width: 116,
            child: CircularProgressIndicator(
              value: 0.72,
              strokeWidth: 12,
              backgroundColor: const Color(0xFF2B3C5D),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4A84FF),
              ),
            ),
          ),
          const Text(
            '72%',
            style: TextStyle(
              color: Color(0xFFE3ECFD),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
