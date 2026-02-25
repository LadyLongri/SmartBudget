import 'package:flutter/material.dart';

class FrontendHomeScreen extends StatefulWidget {
  const FrontendHomeScreen({super.key});
  static const String routeName = '/frontend-home';

  @override
  State<FrontendHomeScreen> createState() => _FrontendHomeScreenState();
}

class _FrontendHomeScreenState extends State<FrontendHomeScreen> {
  int _index = 0;
  int _selectedDay = 24;
  bool _monthly = false;
  double _balance = 0;
  double _income = 0;
  double _expense = 0;
  final Map<String, double> _cat = <String, double>{
    'Restaurant': 0,
    'Electricity': 0,
    'Education': 0,
    'Others': 0,
  };
  final List<_Tx> _tx = <_Tx>[];

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      _transactionsTab(),
      _calendarTab(),
      _statTab(),
      _walletTab(),
    ];

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const _Bg(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: tabs[_index],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transaction',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            label: 'Statistic',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }

  Widget _transactionsTab() {
    final String topName = _topCategoryName();
    final double topAmount = _cat[topName] ?? 0;
    final double progress = _expense == 0
        ? 0
        : (topAmount / _expense).clamp(0, 1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome back!',
                  style: TextStyle(color: Color(0xFF60739A)),
                ),
                SizedBox(height: 4),
                Text(
                  'SmartBudget',
                  style: TextStyle(
                    color: Color(0xFF15234A),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: _addTxSheet,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Balance', style: TextStyle(color: Color(0xFF526991))),
              Text(
                _money(_balance),
                style: const TextStyle(
                  color: Color(0xFF2859BA),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  _pill('Expense', _money(_expense), const Color(0xFFFF5A4A)),
                  const SizedBox(width: 10),
                  _pill('Income', _money(_income), const Color(0xFF4A84FF)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Expense Structure',
                style: TextStyle(
                  color: Color(0xFF2D58B5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'USD ${_expense.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF182A52),
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 82,
                    height: 82,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFD9E6FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _cat.entries
                          .map(
                            (MapEntry<String, double> e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${e.key}: ${_moneyShort(e.value)}',
                                style: const TextStyle(
                                  color: Color(0xFF546A94),
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          _tx.isEmpty
              ? Column(
                  children: <Widget>[
                    const Text(
                      'No transaction yet',
                      style: TextStyle(
                        color: Color(0xFF4A6290),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addTxSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add transaction'),
                    ),
                  ],
                )
              : Column(
                  children: List<Widget>.generate(_tx.length, (int i) {
                    final _Tx t = _tx[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF2F6FF),
                        child: Icon(
                          t.icon,
                          color: const Color(0xFF3F65B2),
                          size: 20,
                        ),
                      ),
                      title: Text(t.title),
                      subtitle: Text(t.category),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${t.expense ? '-' : '+'}${_money(t.amount)}',
                            style: TextStyle(
                              color: t.expense
                                  ? const Color(0xFFE24545)
                                  : const Color(0xFF2C8A57),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeTx(i),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _calendarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Calendar',
          style: TextStyle(
            color: Color(0xFF142854),
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(28, (int i) {
              final int day = i + 1;
              final bool active = day == _selectedDay;
              return InkWell(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF4E85EA)
                        : const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF4A6190),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Selected day quick action',
                  style: TextStyle(
                    color: Color(0xFF203A72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                onPressed: _quickExpense,
                child: Text('Add -\$10 (day $_selectedDay)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTab() {
    final List<double> values = _buildBars();
    final double max = values.fold<double>(
      0,
      (double a, double b) => a > b ? a : b,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Statistic',
              style: TextStyle(
                color: Color(0xFF142854),
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text('Week')),
                ButtonSegment<bool>(value: true, label: Text('Month')),
              ],
              selected: <bool>{_monthly},
              onSelectionChanged: (Set<bool> s) =>
                  setState(() => _monthly = s.first),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(values.length, (int i) {
                final double h = max <= 0 ? 26 : 26 + (values[i] / max) * 140;
                final Color c = i % 3 == 0
                    ? const Color(0xFF4A84FF)
                    : i % 3 == 1
                    ? const Color(0xFF8C5EFF)
                    : const Color(0xFFFF5A4A);
                return Container(
                  width: 24,
                  height: h,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _card(
          Text(
            'Top category: ${_topCategoryName()} (${(_topCategoryPercent() * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(
              color: Color(0xFF203A72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _walletTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const Text(
          'Wallet',
          style: TextStyle(
            color: Color(0xFF142854),
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: <Color>[
                Color(0xFF4A84FF),
                Color(0xFF8B5DFF),
                Color(0xFFFF5A4A),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'SMARTBUDGET CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '**** **** **** 0000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _money(_balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _walletIncome(50),
                icon: const Icon(Icons.add),
                label: const Text('Add \$50'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _walletExpense(20),
                icon: const Icon(Icons.remove),
                label: const Text('Spend \$20'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _resetAll,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset data'),
        ),
      ],
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFC8D9FF)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          blurRadius: 22,
          offset: const Offset(0, 12),
          color: const Color(0xFF6A8FD8).withValues(alpha: 0.16),
        ),
      ],
    ),
    child: child,
  );

  Widget _pill(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  Future<void> _addTxSheet() async {
    final _TxDraft? draft = await showModalBottomSheet<_TxDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TxSheet(day: _selectedDay),
    );
    if (draft == null) return;
    setState(() {
      final _Tx item = _Tx(
        title: draft.title.isEmpty
            ? (draft.expense ? 'Expense' : 'Income')
            : draft.title,
        category: draft.category,
        amount: draft.amount,
        expense: draft.expense,
        icon: _iconFor(draft.category),
      );
      _tx.insert(0, item);
      if (draft.expense) {
        _expense += draft.amount;
        _balance -= draft.amount;
        _cat[draft.category] = (_cat[draft.category] ?? 0) + draft.amount;
      } else {
        _income += draft.amount;
        _balance += draft.amount;
      }
    });
    _snack('Transaction ajoutee');
  }

  void _removeTx(int i) {
    final _Tx t = _tx.removeAt(i);
    setState(() {
      if (t.expense) {
        _expense = (_expense - t.amount).clamp(0, double.infinity);
        _balance += t.amount;
        _cat[t.category] = ((_cat[t.category] ?? 0) - t.amount).clamp(
          0,
          double.infinity,
        );
      } else {
        _income = (_income - t.amount).clamp(0, double.infinity);
        _balance -= t.amount;
      }
    });
    _snack('Transaction supprimee');
  }

  void _quickExpense() {
    setState(() {
      _expense += 10;
      _balance -= 10;
      _cat['Others'] = (_cat['Others'] ?? 0) + 10;
      _tx.insert(
        0,
        const _Tx(
          title: 'Quick expense',
          category: 'Others',
          amount: 10,
          expense: true,
          icon: Icons.flash_on_rounded,
        ),
      );
    });
    _snack('Depense rapide ajoutee');
  }

  void _walletIncome(double value) {
    setState(() {
      _income += value;
      _balance += value;
      _tx.insert(
        0,
        _Tx(
          title: 'Wallet top-up',
          category: 'Others',
          amount: value,
          expense: false,
          icon: Icons.savings_outlined,
        ),
      );
    });
    _snack('Fond ajoute');
  }

  void _walletExpense(double value) {
    setState(() {
      _expense += value;
      _balance -= value;
      _cat['Others'] = (_cat['Others'] ?? 0) + value;
      _tx.insert(
        0,
        _Tx(
          title: 'Wallet spend',
          category: 'Others',
          amount: value,
          expense: true,
          icon: Icons.remove_circle_outline,
        ),
      );
    });
    _snack('Depense wallet ajoutee');
  }

  void _resetAll() {
    setState(() {
      _balance = 0;
      _income = 0;
      _expense = 0;
      _tx.clear();
      _cat.updateAll((String key, double value) => 0);
    });
    _snack('Data reset');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<double> _buildBars() {
    final int len = _monthly ? 6 : 7;
    final List<double> bars = List<double>.filled(len, 0);
    for (int i = 0; i < _tx.length; i++) {
      final _Tx t = _tx[i];
      if (!t.expense) continue;
      final int idx = _monthly ? i % 6 : i % 7;
      bars[idx] += t.amount;
    }
    return bars;
  }

  String _topCategoryName() {
    String best = 'No category';
    double max = 0;
    for (final MapEntry<String, double> e in _cat.entries) {
      if (e.value > max) {
        max = e.value;
        best = e.key;
      }
    }
    return best;
  }

  double _topCategoryPercent() {
    if (_expense <= 0) return 0;
    double max = 0;
    for (final double value in _cat.values) {
      if (value > max) max = value;
    }
    return (max / _expense).clamp(0, 1);
  }

  IconData _iconFor(String cat) {
    switch (cat) {
      case 'Restaurant':
        return Icons.local_cafe_outlined;
      case 'Electricity':
        return Icons.bolt_outlined;
      case 'Education':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _Bg extends StatelessWidget {
  const _Bg();

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
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -80,
            top: -70,
            child: _orb(const Color(0xFF4A84FF).withValues(alpha: 0.16), 200),
          ),
          Positioned(
            right: -100,
            top: 20,
            child: _orb(const Color(0xFFFF4A4A).withValues(alpha: 0.14), 180),
          ),
          Positioned(
            right: -120,
            bottom: -110,
            child: _orb(const Color(0xFF9B58FF).withValues(alpha: 0.16), 240),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: color,
          blurRadius: size * 0.35,
          spreadRadius: size * 0.04,
        ),
      ],
    ),
  );
}

class _Tx {
  const _Tx({
    required this.title,
    required this.category,
    required this.amount,
    required this.expense,
    required this.icon,
  });
  final String title;
  final String category;
  final double amount;
  final bool expense;
  final IconData icon;
}

class _TxDraft {
  const _TxDraft({
    required this.title,
    required this.category,
    required this.amount,
    required this.expense,
  });
  final String title;
  final String category;
  final double amount;
  final bool expense;
}

class _TxSheet extends StatefulWidget {
  const _TxSheet({required this.day});
  final int day;

  @override
  State<_TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<_TxSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  bool _expense = true;
  String _cat = 'Others';

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFCFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _cat,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'Restaurant',
                  child: Text('Restaurant'),
                ),
                DropdownMenuItem<String>(
                  value: 'Electricity',
                  child: Text('Electricity'),
                ),
                DropdownMenuItem<String>(
                  value: 'Education',
                  child: Text('Education'),
                ),
                DropdownMenuItem<String>(
                  value: 'Others',
                  child: Text('Others'),
                ),
              ],
              onChanged: (String? v) => setState(() => _cat = v ?? 'Others'),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: _expense,
                  onSelected: (_) => setState(() => _expense = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: !_expense,
                  onSelected: (_) => setState(() => _expense = false),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final double amount =
                      double.tryParse(_amount.text.trim()) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(
                    context,
                    _TxDraft(
                      title: _title.text.trim(),
                      category: _cat,
                      amount: amount,
                      expense: _expense,
                    ),
                  );
                },
                child: Text('Save day ${widget.day}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double v) => '\$ ${v.toStringAsFixed(2)}';
String _moneyShort(double v) => '\$${v.toStringAsFixed(0)}';
