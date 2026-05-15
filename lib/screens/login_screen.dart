import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/prefs_service.dart';
import '../utils/platform_utils.dart';
import 'contacts_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _ipController = TextEditingController(
    text: getServerIp(), // funciona en web Y en Android
  );
  bool _loading = false;
  bool _checkingAutoLogin = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  /// Intenta auto-login si hay credenciales guardadas.
  /// Si encuentra, conecta y va directo a ContactsScreen.
  Future<void> _tryAutoLogin() async {
    final saved = await PrefsService.loadLogin();
    if (!mounted) return;

    if (saved == null) {
      setState(() => _checkingAutoLogin = false);
      return;
    }

    // Prellenar campos por si falla la conexion
    _ipController.text = saved.ip;
    _nameController.text = saved.name;

    // Conectar automaticamente y navegar
    ChatService().connect(saved.ip, saved.name);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ContactsScreen()),
    );
  }

  Future<void> _connect() async {
    final name = _nameController.text.trim();
    final ip = _ipController.text.trim();

    if (name.isEmpty || ip.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      ChatService().connect(ip, name);
      // Guardamos para proximas aperturas
      await PrefsService.saveLogin(ip, name);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ContactsScreen()),
      );
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar al servidor';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras chequeamos si hay login guardado mostramos splash
    if (_checkingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFF075E54),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/splash.png', width: 140, height: 140),
              const SizedBox(height: 20),
              const Text(
                'Chat Cifrado',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/splash.png', width: 100, height: 100),
                const SizedBox(height: 16),
                const Text(
                  'Chat Cifrado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tus mensajes viajan cifrados',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                _buildField(_nameController, 'Tu nombre', Icons.person),
                const SizedBox(height: 16),
                _buildField(_ipController, 'IP del servidor', Icons.wifi),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'CONECTAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }
}
