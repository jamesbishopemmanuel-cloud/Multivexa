import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kieGatewayUrl = String.fromEnvironment('MULTIVEXA_API_URL', defaultValue: 'http://10.0.2.2:8080');

void main() {
  runApp(const MultivexaApp());
}

const Color ink = Color(0xFF0A0D18);
const Color panel = Color(0xFF151A2B);
const Color violet = Color(0xFF8B5CF6);
const Color cyan = Color(0xFF38BDF8);

class MultivexaApp extends StatelessWidget {
  const MultivexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multivexa AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          brightness: Brightness.dark,
          surface: panel,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue() {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password to continue.')),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StudioScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 76,
                    width: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(colors: [violet, cyan]),
                    ),
                    child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'MULTIVEXA AI',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _register ? 'Create your creative space.' : 'Your ideas. Brought to life.',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      labelText: 'Email address',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: violet,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Already have an account? Sign in'
                        : 'New to Multivexa? Create account'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Prototype sign-in screen. Connect an authentication provider before using real accounts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Creation {
  Creation({required this.type, required this.prompt, required this.createdAt});

  final String type;
  final String prompt;
  final DateTime createdAt;
  final String taskId;
  final String status;
}

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  int _tab = 0;
  int _mode = 0;
  int _credits = 50;
  final _prompt = TextEditingController();
  final List<Creation> _history = [];

  static const _types = ['Image', 'Video', 'Music'];
  static const _icons = [Icons.image_outlined, Icons.movie_creation_outlined, Icons.music_note_outlined];

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  bool _generating = false;

  Future<void> _generate() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe what you want to create first.')),
      );
      return;
    }
    if (_credits < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are out of demo credits.')),
      );
      return;
    }
    setState(() => _generating = true);
    try {
      final response = await http.post(
        Uri.parse('${kieGatewayUrl.replaceFirst(RegExp(r'/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multivexa AI', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: ink,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: cyan, size: 18),
                    const SizedBox(width: 5),
                    Text('$_credits credits', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _tab == 0 ? _buildCreate() : _buildHistory(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  Widget _buildCreate() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF30205B), Color(0xFF122D49)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAKE SOMETHING
UNFORGETTABLE', style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('Create visuals, motion and sound from your imagination.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Choose a creation type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_types.length, (index) {
            final selected = _mode == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == _types.length - 1 ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _mode = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? violet.withValues(alpha: 0.22) : panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? violet : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Icon(_icons[index], color: selected ? cyan : Colors.white70, size: 28),
                        const SizedBox(height: 8),
                        Text(_types[index], style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          _mode == 0 ? 'Describe your image' : _mode == 1 ? 'Describe your video' : 'Describe your music',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _prompt,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: _mode == 0
                ? 'A cinematic futuristic city at sunset...'
                : _mode == 1
                    ? 'A smooth camera move through a glowing city...'
                    : 'An uplifting Afrobeats instrumental with warm guitar...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
          label: Text(_generating ? 'Sending to KIE…' : 'Generate · 1 credit'),
          style: FilledButton.styleFrom(
            backgroundColor: violet,
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Powered by KIE. Configure your server URL and KIE API key on the backend before generating. Credits and history are currently stored only for this app session.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 56, color: cyan),
              const SizedBox(height: 16),
              const Text('Your creations will appear here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Create a prompt to add an item to this demo history.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => setState(() => _tab = 0),
                child: const Text('Start creating'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _history[index];
        final icon = item.type == 'Image'
            ? Icons.image_outlined
            : item.type == 'Video'
                ? Icons.movie_creation_outlined
                : Icons.music_note_outlined;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(color: violet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.type} prompt', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(item.prompt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('${item.status} · Task ${item.taskId} · ${item.createdAt.toLocal()}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
), '')}/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': _types[_mode].toLowerCase(), 'prompt': prompt}),
      ).timeout(const Duration(seconds: 45));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error']?.toString() ?? 'KIE request failed (${response.statusCode})');
      }
      final taskId = data['taskId']?.toString() ?? '';
      if (taskId.isEmpty) throw Exception('KIE did not return a task ID.');
      if (!mounted) return;
      setState(() {
        _credits--;
        _history.insert(0, Creation(type: _types[_mode], prompt: prompt, createdAt: DateTime.now(), taskId: taskId, status: 'Submitted to KIE'));
        _tab = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KIE accepted your ${_types[_mode].toLowerCase()} task: $taskId')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: $error')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multivexa AI', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: ink,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: cyan, size: 18),
                    const SizedBox(width: 5),
                    Text('$_credits credits', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _tab == 0 ? _buildCreate() : _buildHistory(),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Create'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }

  Widget _buildCreate() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF30205B), Color(0xFF122D49)],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MAKE SOMETHING
UNFORGETTABLE', style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text('Create visuals, motion and sound from your imagination.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Choose a creation type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_types.length, (index) {
            final selected = _mode == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == _types.length - 1 ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _mode = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? violet.withValues(alpha: 0.22) : panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? violet : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Icon(_icons[index], color: selected ? cyan : Colors.white70, size: 28),
                        const SizedBox(height: 8),
                        Text(_types[index], style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          _mode == 0 ? 'Describe your image' : _mode == 1 ? 'Describe your video' : 'Describe your music',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _prompt,
          minLines: 4,
          maxLines: 7,
          decoration: InputDecoration(
            hintText: _mode == 0
                ? 'A cinematic futuristic city at sunset...'
                : _mode == 1
                    ? 'A smooth camera move through a glowing city...'
                    : 'An uplifting Afrobeats instrumental with warm guitar...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate · 1 demo credit'),
          style: FilledButton.styleFrom(
            backgroundColor: violet,
            minimumSize: const Size.fromHeight(54),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Build status: interface prototype. Real image, video and music generation requires API integration; account security and synced history require backend setup.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.collections_bookmark_outlined, size: 56, color: cyan),
              const SizedBox(height: 16),
              const Text('Your creations will appear here', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Create a prompt to add an item to this demo history.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => setState(() => _tab = 0),
                child: const Text('Start creating'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _history[index];
        final icon = item.type == 'Image'
            ? Icons.image_outlined
            : item.type == 'Video'
                ? Icons.movie_creation_outlined
                : Icons.music_note_outlined;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(color: violet.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.type} prompt', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(item.prompt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('Demo entry · ${item.createdAt.toLocal()}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
