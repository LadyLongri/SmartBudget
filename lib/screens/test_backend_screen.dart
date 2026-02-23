import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/api_client.dart';

class TestBackendScreen extends StatefulWidget {
  const TestBackendScreen({super.key});

  @override
  State<TestBackendScreen> createState() => _TestBackendScreenState();
}

class _TestBackendScreenState extends State<TestBackendScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final TabController _tabController;

  bool _busy = false;
  bool _categoriesLoading = false;
  bool _transactionsLoading = false;

  List<CategoryModel> _categories = <CategoryModel>[];
  List<TransactionModel> _transactions = <TransactionModel>[];

  String _healthInfo = '';
  String _meInfo = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    if (_isLoggedIn) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get _isLoggedIn => _currentUser != null;

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final String y = '${date.year}'.padLeft(4, '0');
    final String m = '${date.month}'.padLeft(2, '0');
    final String d = '${date.day}'.padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _categoryNameById(String? id) {
    if (id == null || id.isEmpty) return 'Aucune';
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return id;
  }

  Future<void> _refreshData() async {
    if (!_isLoggedIn) {
      if (mounted) {
        setState(() {
          _categories = <CategoryModel>[];
          _transactions = <TransactionModel>[];
        });
      }
      return;
    }
    await Future.wait(<Future<void>>[_loadCategories(), _loadTransactions()]);
  }

  Future<void> _loadCategories() async {
    if (!_isLoggedIn) return;
    if (mounted) setState(() => _categoriesLoading = true);

    try {
      final List<CategoryModel> items = await ApiClient.getCategories();
      if (!mounted) return;
      setState(() => _categories = items);
    } catch (error) {
      _show('Erreur categories: $error');
    } finally {
      if (mounted) {
        setState(() => _categoriesLoading = false);
      }
    }
  }

  Future<void> _loadTransactions() async {
    if (!_isLoggedIn) return;
    if (mounted) setState(() => _transactionsLoading = true);

    try {
      final List<TransactionModel> items = await ApiClient.getTransactions();
      if (!mounted) return;
      setState(() => _transactions = items);
    } catch (error) {
      _show('Erreur transactions: $error');
    } finally {
      if (mounted) {
        setState(() => _transactionsLoading = false);
      }
    }
  }

  Future<void> _login() async {
    await _runBusy(() async {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        _show('Email et mot de passe obligatoires.');
        return;
      }

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _show('Connexion reussie.');
        await _refreshData();
      } catch (error) {
        _show('Echec login: $error');
      }
    });
  }

  Future<void> _register() async {
    await _runBusy(() async {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        _show('Email et mot de passe obligatoires.');
        return;
      }

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _show('Compte cree et connecte.');
        await _refreshData();
      } catch (error) {
        _show('Echec inscription: $error');
      }
    });
  }

  Future<void> _logout() async {
    await _runBusy(() async {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _categories = <CategoryModel>[];
        _transactions = <TransactionModel>[];
        _meInfo = '';
      });
      _show('Deconnexion terminee.');
    });
  }

  Future<void> _testHealth() async {
    await _runBusy(() async {
      try {
        final response = await ApiClient.health();
        if (!mounted) return;
        setState(() => _healthInfo = '${response.statusCode} ${response.body}');
      } catch (error) {
        if (!mounted) return;
        setState(() => _healthInfo = 'Erreur: $error');
      }
    });
  }

  Future<void> _testMe() async {
    await _runBusy(() async {
      if (!_isLoggedIn) {
        _show('Connecte-toi avant /me.');
        return;
      }
      try {
        final Map<String, dynamic> me = await ApiClient.getMe();
        if (!mounted) return;
        setState(() => _meInfo = me.toString());
      } catch (error) {
        if (!mounted) return;
        setState(() => _meInfo = 'Erreur: $error');
      }
    });
  }

  Future<void> _upsertCategory([CategoryModel? current]) async {
    final _CategoryFormData? formData = await _showCategoryDialog(current);
    if (!mounted || formData == null) return;

    await _runBusy(() async {
      try {
        if (current == null) {
          await ApiClient.createCategory(
            name: formData.name,
            icon: formData.icon,
            color: formData.color,
          );
          _show('Categorie creee.');
        } else {
          await ApiClient.updateCategory(
            id: current.id,
            name: formData.name,
            icon: formData.icon,
            color: formData.color,
          );
          _show('Categorie modifiee.');
        }
        await Future.wait(<Future<void>>[
          _loadCategories(),
          _loadTransactions(),
        ]);
      } catch (error) {
        _show('Erreur categorie: $error');
      }
    });
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer categorie'),
          content: Text('Confirmer la suppression de "${category.name}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _runBusy(() async {
      try {
        await ApiClient.deleteCategory(category.id);
        _show('Categorie supprimee.');
        await Future.wait(<Future<void>>[
          _loadCategories(),
          _loadTransactions(),
        ]);
      } catch (error) {
        _show('Erreur suppression categorie: $error');
      }
    });
  }

  Future<void> _upsertTransaction([TransactionModel? current]) async {
    final _TransactionFormData? formData = await _showTransactionDialog(
      current,
    );
    if (!mounted || formData == null) return;

    await _runBusy(() async {
      try {
        if (current == null) {
          await ApiClient.createTransaction(
            type: formData.type,
            amount: formData.amount,
            currency: formData.currency,
            categoryId: formData.categoryId,
            note: formData.note,
            date: formData.date,
          );
          _show('Transaction creee.');
        } else {
          await ApiClient.updateTransaction(
            id: current.id,
            type: formData.type,
            amount: formData.amount,
            currency: formData.currency,
            categoryId: formData.categoryId,
            note: formData.note,
            date: formData.date,
          );
          _show('Transaction modifiee.');
        }
        await _loadTransactions();
      } catch (error) {
        _show('Erreur transaction: $error');
      }
    });
  }

  Future<void> _deleteTransaction(TransactionModel item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer transaction'),
          content: Text(
            'Supprimer ${item.type} ${item.amount.toStringAsFixed(2)} ${item.currency} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _runBusy(() async {
      try {
        await ApiClient.deleteTransaction(item.id);
        _show('Transaction supprimee.');
        await _loadTransactions();
      } catch (error) {
        _show('Erreur suppression transaction: $error');
      }
    });
  }

  Future<_CategoryFormData?> _showCategoryDialog([CategoryModel? current]) {
    final TextEditingController nameController = TextEditingController(
      text: current?.name ?? '',
    );
    final TextEditingController iconController = TextEditingController(
      text: current?.icon ?? '',
    );
    final TextEditingController colorController = TextEditingController(
      text: current?.color ?? '',
    );

    return showDialog<_CategoryFormData>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            current == null ? 'Nouvelle categorie' : 'Modifier categorie',
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon (optionnel)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'Couleur (optionnel)',
                    hintText: '#22A45D',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final String name = nameController.text.trim();
                if (name.length < 2) {
                  return;
                }
                Navigator.pop(
                  context,
                  _CategoryFormData(
                    name: name,
                    icon: iconController.text.trim(),
                    color: colorController.text.trim(),
                  ),
                );
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      iconController.dispose();
      colorController.dispose();
    });
  }

  Future<_TransactionFormData?> _showTransactionDialog([
    TransactionModel? current,
  ]) {
    final TextEditingController amountController = TextEditingController(
      text: current == null ? '' : current.amount.toStringAsFixed(2),
    );
    final TextEditingController noteController = TextEditingController(
      text: current?.note ?? '',
    );

    String selectedType = current?.type ?? 'expense';
    String selectedCurrency = current?.currency ?? 'USD';
    String? selectedCategoryId = current?.categoryId;
    DateTime selectedDate = current?.date ?? DateTime.now();

    return showDialog<_TransactionFormData>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                return AlertDialog(
                  title: Text(
                    current == null
                        ? 'Nouvelle transaction'
                        : 'Modifier transaction',
                  ),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          items: const [
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text('expense'),
                            ),
                            DropdownMenuItem(
                              value: 'income',
                              child: Text('income'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) return;
                            setModalState(() => selectedType = value);
                          },
                          decoration: const InputDecoration(labelText: 'Type'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Montant',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCurrency,
                          items: const [
                            DropdownMenuItem(value: 'USD', child: Text('USD')),
                            DropdownMenuItem(value: 'CDF', child: Text('CDF')),
                          ],
                          onChanged: (String? value) {
                            if (value == null) return;
                            setModalState(() => selectedCurrency = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Devise',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: selectedCategoryId,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Aucune categorie'),
                            ),
                            ..._categories.map(
                              (CategoryModel c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            setModalState(() => selectedCategoryId = value);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Categorie',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: noteController,
                          decoration: const InputDecoration(labelText: 'Note'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Date: ${_formatDate(selectedDate)}'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) return;
                                setModalState(() => selectedDate = picked);
                              },
                              child: const Text('Choisir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final double? amount = double.tryParse(
                          amountController.text.trim().replaceAll(',', '.'),
                        );
                        if (amount == null || amount <= 0) {
                          return;
                        }
                        Navigator.pop(
                          context,
                          _TransactionFormData(
                            type: selectedType,
                            amount: amount,
                            currency: selectedCurrency,
                            categoryId: selectedCategoryId,
                            note: noteController.text.trim(),
                            date: selectedDate,
                          ),
                        );
                      },
                      child: const Text('Valider'),
                    ),
                  ],
                );
              },
        );
      },
    ).whenComplete(() {
      amountController.dispose();
      noteController.dispose();
    });
  }

  Widget _buildAuthCard() {
    final User? user = _currentUser;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _login,
                  child: const Text('Login'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _register,
                  child: const Text('Register'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _testHealth,
                  child: const Text('Tester /health'),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _testMe,
                  child: const Text('Tester /me'),
                ),
                if (user != null)
                  ElevatedButton(
                    onPressed: _busy ? null : _logout,
                    child: const Text('Logout'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (user != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Connecte: ${user.email ?? user.uid}'),
              ),
            if (_healthInfo.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Health: $_healthInfo'),
              ),
            if (_meInfo.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Me: $_meInfo'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return const Center(child: Text('Aucune transaction.'));
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _transactions.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final TransactionModel item = _transactions[index];
          final String sign = item.type == 'income' ? '+' : '-';
          final String colorLabel = item.type == 'income'
              ? 'income'
              : 'expense';
          return Card(
            child: ListTile(
              title: Text(
                '$sign${item.amount.toStringAsFixed(2)} ${item.currency} ($colorLabel)',
              ),
              subtitle: Text(
                '${_formatDate(item.date)} | Categorie: ${_categoryNameById(item.categoryId)} | ${item.note}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _busy ? null : () => _upsertTransaction(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _busy ? null : () => _deleteTransaction(item),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesTab() {
    if (_categoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(child: Text('Aucune categorie.'));
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _categories.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final CategoryModel category = _categories[index];
          return Card(
            child: ListTile(
              title: Text(category.name),
              subtitle: Text(
                'icon: ${category.icon ?? '-'} | color: ${category.color ?? '-'}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _busy ? null : () => _upsertCategory(category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _busy ? null : () => _deleteCategory(category),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool loggedIn = _isLoggedIn;
    final bool onTransactionsTab = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartBudget CRUD'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _testHealth,
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Health',
          ),
          if (loggedIn)
            IconButton(
              onPressed: _busy ? null : _refreshData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      floatingActionButton: loggedIn
          ? FloatingActionButton.extended(
              onPressed: _busy
                  ? null
                  : () {
                      if (onTransactionsTab) {
                        _upsertTransaction();
                      } else {
                        _upsertCategory();
                      }
                    },
              label: Text(
                onTransactionsTab ? 'Ajouter transaction' : 'Ajouter categorie',
              ),
              icon: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _buildAuthCard(),
          if (!loggedIn)
            const Expanded(
              child: Center(
                child: Text('Connecte-toi pour utiliser le CRUD complet.'),
              ),
            )
          else ...[
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Categories'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTransactionsTab(), _buildCategoriesTab()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFormData {
  final String name;
  final String? icon;
  final String? color;

  const _CategoryFormData({required this.name, this.icon, this.color});
}

class _TransactionFormData {
  final String type;
  final double amount;
  final String currency;
  final String? categoryId;
  final String note;
  final DateTime date;

  const _TransactionFormData({
    required this.type,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.note,
    required this.date,
  });
}
