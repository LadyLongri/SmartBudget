import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'budget_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const String routeName = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _busy = false;
  bool _registerMode = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _authEmailPassword() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_registerMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const BudgetDashboardScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Erreur inattendue: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final GoogleAuthProvider provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'})
        ..addScope('email')
        ..addScope('profile');

      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const BudgetDashboardScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Connexion Google echouee: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'user-disabled':
        return 'Ce compte est desactive';
      case 'user-not-found':
        return 'Aucun compte trouve avec cet email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Mot de passe ou email incorrect';
      case 'email-already-in-use':
        return 'Cet email est deja utilise';
      case 'weak-password':
        return 'Mot de passe trop faible (min 6 caracteres)';
      default:
        return error.message ?? "Erreur d'authentification";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF0C1730),
                  Color(0xFF162544),
                  Color(0xFF121E39),
                ],
              ),
            ),
          ),
          Positioned(left: -70, top: -30, child: _orb(const Color(0xFF4A84FF))),
          Positioned(
            right: -80,
            bottom: -40,
            child: _orb(const Color(0xFF8D5CFF)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111D33).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF2B3C5A)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Color(0xFFDDE8FF),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _registerMode ? 'Inscription' : 'Connexion',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE6EEFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF1A2A47),
                              border: Border.all(
                                color: const Color(0xFF31456A),
                              ),
                            ),
                            child: Text(
                              _registerMode
                                  ? 'Cree ton compte SB et active la sauvegarde cloud.'
                                  : 'Connecte-toi pour recuperer tes donnees partout.',
                              style: const TextStyle(
                                color: Color(0xFFBFD0F1),
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _registerMode = false,
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: !_registerMode
                                        ? const Color(0xFF2D73E8)
                                        : const Color(0xFF1A2A47),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Connexion'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _registerMode = true,
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _registerMode
                                        ? const Color(0xFF2D73E8)
                                        : const Color(0xFF1A2A47),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Inscription'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Color(0xFFE8F0FF)),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Color(0xFFAEC2E8)),
                              prefixIcon: Icon(
                                Icons.alternate_email_rounded,
                                color: Color(0xFFAEC2E8),
                              ),
                            ),
                            validator: (String? value) {
                              final String v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Email requis';
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            style: const TextStyle(color: Color(0xFFE8F0FF)),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              labelStyle: const TextStyle(
                                color: Color(0xFFAEC2E8),
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFFAEC2E8),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFAEC2E8),
                                ),
                              ),
                            ),
                            validator: (String? value) {
                              final String v = value ?? '';
                              if (v.isEmpty) return 'Mot de passe requis';
                              if (_registerMode && v.length < 6) {
                                return 'Minimum 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _authEmailPassword,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2D73E8),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _busy
                                    ? 'Veuillez patienter...'
                                    : (_registerMode
                                          ? "S'inscrire"
                                          : 'Se connecter'),
                              ),
                            ),
                          ),
                          if (_error != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFF8B8B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Divider(
                                  color: const Color(
                                    0xFF5E739A,
                                  ).withValues(alpha: 0.55),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'ou',
                                  style: TextStyle(color: Color(0xFFAFC2E6)),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: const Color(
                                    0xFF5E739A,
                                  ).withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _loginGoogle,
                              icon: const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 30,
                                color: Color(0xFFD8E4FD),
                              ),
                              label: Text(
                                _registerMode
                                    ? "S'inscrire avec Google"
                                    : 'Continuer avec Google',
                                style: const TextStyle(
                                  color: Color(0xFFD8E4FD),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF425A84),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () => _registerMode = !_registerMode,
                                    ),
                              child: Text(
                                _registerMode
                                    ? 'Tu as deja un compte ? Se connecter'
                                    : 'Pas de compte ? Inscription',
                                style: const TextStyle(
                                  color: Color(0xFFB3C5E8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color color) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 80),
        ],
      ),
    );
  }
}
