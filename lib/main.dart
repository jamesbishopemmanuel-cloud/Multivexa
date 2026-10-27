import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const gateway = String.fromEnvironment('MULTIVEXA_API_URL', defaultValue: 'http://10.0.2.2:8080');
const sbUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://vihbsfrwnslnmheowkhy.supabase.co',
);
const sbKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpaGJzZnJ3bnNsbm1oZW93a3kiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc4ODAwMzIzOSwiZXhwIjoyMTAzNTc5MjM5fQ.eHAaAj7d7bhpFuBFinwxa80fW-QrjOpNwShSzSadhdA',
);
const ink = Color(0xFF0A0D18), panel = Color(0xFF151A2B), violet = Color(0xFF8B5CF6), cyan = Color(0xFF38BDF8);
bool get sbConfigured => sbUrl.startsWith('https://') && sbKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (sbConfigured) await Supabase.initialize(url: sbUrl, publishableKey: sbKey);
  runApp(const MultivexaApp());
}

class MultivexaApp extends StatelessWidget {
  const MultivexaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Multivexa AI', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: ink,
      colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.dark, surface: panel),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    home: !sbConfigured ? const SetupScreen() : StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (_, __) => Supabase.instance.client.auth.currentUser == null ? const AuthScreen() : const StudioScreen(),
    ),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Padding(
    padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off, size: 56, color: cyan), SizedBox(height: 16),
      Text('Connect Supabase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      SizedBox(height: 10),
      Text('Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY as GitHub Actions variables, then rebuild. Use only the publishable/anon key in the app, never a secret or service-role key.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
    ]),
  )));
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController(), password = TextEditingController();
  bool registering = false, busy = false;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email and a password of at least 6 characters.'))); return;
    }
    setState(() => busy = true);
    try {
      if (registering) {
        final result = await Supabase.instance.client.auth.signUp(email: email.text.trim(), password: password.text);
        if (mounted && result.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Confirm your email, then sign in.')));
          setState(() => registering = false);
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 76, width: 76, alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [violet, cyan])),
        child: const Icon(Icons.auto_awesome, size: 40)),
      const SizedBox(height: 28),
      const Text('MULTIVEXA AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Text(registering ? 'Create your creative space.' : 'Your ideas. Brought to life.', style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 30),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email address')),
      const SizedBox(height: 14),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), labelText: 'Password (6+ characters)')),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : submit, style: FilledButton.styleFrom(backgroundColor: violet, minimumSize: const Size.fromHeight(52)), child: Text(busy ? 'Please wait…' : registering ? 'Create account' : 'Sign in')),
      TextButton(onPressed: busy ? null : () => setState(() => registering = !registering), child: Text(registering ? 'Already have an account? Sign in' : 'New to Multivexa? Create account')),
      const SizedBox(height: 12),
      const Text('Authentication powered by Supabase.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
    ]))))));
}

class Creation {
  Creation(this.type, this.prompt, this.createdAt, this.taskId, this.status, {this.progress = 1});
  final String type, prompt, taskId, status;
  final DateTime createdAt;
  final int progress;
}
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}
class _StudioScreenState extends State<StudioScreen> with WidgetsBindingObserver {
  final prompt = TextEditingController();
  final history = <Creation>[];
  int tab = 0, mode = 0, credits = 50;
  bool busy = false, loading = true;
  String imageStyle = 'Photorealistic', imageRatio = 'auto', imageResolution = '1K';
  String imageModel = 'gpt-image-2-text-to-image';
  String imageMode = 'Text to image';
  String? imageInputPath, imageInputName, imageInputSignedUrl;
  String videoModel = 'kling-3.0/video', videoStyle = 'Cinematic', videoRatio = '16:9', videoDuration = '5', videoQuality = '720p';
  String videoMode = 'Text to video';
  String? videoInputPath, videoInputName, videoInputSignedUrl;
  String musicModel = 'V6', musicVoiceMode = 'AI Voice', musicTitle = 'My New Track', musicStyle = 'Afrobeats';
  String? voiceFilePath, voiceFileName, voicePublicUrl;
  bool recordingVoice = false;
  final AudioRecorder audioRecorder = AudioRecorder();
  static const imageStyles = [
    'Photorealistic', 'Cinematic', 'Anime', '3D Render', 'Digital Art',
    'Watercolor', 'Oil Painting', 'Pencil Sketch', 'Comic Book', 'Fantasy',
    'Cyberpunk', 'Minimalist', 'Vector Art', 'Product Photography',
    'Portrait Photography', 'Architecture', 'Vintage Film', 'Pixel Art',
    'Low Poly', 'Paper Cutout', 'Claymation', 'Isometric', 'Surrealism',
    'Concept Art', 'Children’s Book Illustration'
  ];
  List<String> get availableImageRatios => imageModel == 'gpt-image-2-5-flare-text-to-image'
      ? ['3:2']
      : ['auto', '1:1', '9:16', '16:9', '4:3', '3:4'];
  static const imageModels = <String, String>{
    'GPT Image 2': 'gpt-image-2-text-to-image',
    'GPT Image 2.5 Flare': 'gpt-image-2-5-flare-text-to-image',
    'Google Nano Banana 2': 'nano-banana-2',
    'Google Nano Banana 2.1': 'nano-banana-2-1',
  };
  static const videoModels = <String, String>{
    'Kling 3.0': 'kling-3.0/video',
    'Seedance 2.5': 'bytedance/seedance-2-5',
    'Runway': 'runway',
    'Kling 2.6': 'kling-2.6/text-to-video',
  };
  static const videoStyles = [
    'Cinematic', 'Photorealistic', 'Anime', '3D Animation', 'Cartoon',
    'Fantasy', 'Sci-Fi', 'Cyberpunk', 'Documentary', 'Music Video',
    'Commercial', 'Product Showcase', 'Nature', 'Travel Film', 'Horror Atmosphere',
    'Vintage Film', 'Stop Motion', 'Claymation', 'Pixel Art', 'Surreal',
    'Slow Motion', 'Action', 'Dreamlike', 'Minimalist', 'Fashion Film',
    'Architectural Visualization', 'Watercolor Animation', 'Comic Book'
  ];
  static const videoRatios = ['16:9', '9:16', '1:1'];
  static const musicModels = <String, String>{
    'Suno V6': 'V6', 'Suno V6 Mini': 'V6_MINI', 'Suno V6 Wild': 'V6_WILD',
  };
  static const musicStyles = [
    'Afrobeats', 'Afro-pop', 'Amapiano', 'R&B', 'Pop', 'Hip-hop', 'Rap',
    'Gospel', 'Highlife', 'Reggae', 'Dancehall', 'EDM', 'House', 'Jazz',
    'Soul', 'Rock', 'Country', 'Classical', 'Cinematic', 'Lo-fi',
    'Acoustic', 'Orchestral', 'Ambient', 'Drill', 'Afro-fusion', 'Funk',
  ];
  List<String> get imageResolutions => imageRatio == 'auto'
      ? ['1K']
      : imageRatio == '1:1' ? ['1K', '2K'] : ['1K', '2K', '4K'];
  String? _pendingPaymentRef;
  bool paymentBusy = false;
  Timer? _statusTimer;
  Timer? _progressTimer;
  static const types = ['Image', 'Video', 'Music'];
  static const icons = [Icons.image_outlined, Icons.movie_creation_outlined, Icons.music_note_outlined];
  SupabaseClient get db => Supabase.instance.client;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadHistory();
    loadWalletBalance();
    // KIE continues running on the server if the app is backgrounded or closed.
    // Refresh task states while the app is open and again whenever history loads.
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) => refreshTaskStatuses());
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) => updateEstimatedProgress());
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadHistory();
      refreshTaskStatuses();
    }
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _statusTimer?.cancel(); _progressTimer?.cancel(); prompt.dispose(); audioRecorder.dispose(); super.dispose(); }

  Future<void> loadWalletBalance() async {
    final token = db.auth.currentSession?.accessToken;
    if (token == null) return;
    try {
      final base = gateway.replaceFirst(RegExp(r'/+$'), '');
      final response = await http.get(Uri.parse('$base/api/wallet/balance'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final purchased = (data['credits'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => credits = 50 + purchased);
    } catch (_) { /* Keep the app usable if the wallet endpoint is temporarily offline. */ }
  }

  Future<void> startTopUp(String pack) async {
    final user = db.auth.currentUser;
    final token = user == null ? null : db.auth.currentSession?.accessToken;
    if (token == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in before purchasing credits.'))); return; }
    setState(() => paymentBusy = true);
    try {
      final base = gateway.replaceFirst(RegExp(r'/+$'), '');
      final response = await http.post(Uri.parse('$base/api/payments/checkout'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'pack': pack})).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error']?.toString() ?? 'Could not start checkout.');
      final url = Uri.tryParse(data['checkoutUrl']?.toString() ?? '');
      if (url == null || !url.isScheme('https')) throw Exception('Flutterwave returned an invalid checkout URL.');
      _pendingPaymentRef = data['txRef']?.toString();
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception('Could not open Flutterwave checkout.');
      if (mounted) await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Complete your payment'),
        content: const Text('Finish payment in Flutterwave, return to Multivexa, then tap Verify payment to add your credits.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Later')), FilledButton(onPressed: () { Navigator.pop(dialogContext); verifyTopUp(); }, child: const Text('Verify payment'))],
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Flutterwave checkout failed: $e')));
    } finally { if (mounted) setState(() => paymentBusy = false); }
  }

  Future<void> verifyTopUp() async {
    final txRef = _pendingPaymentRef;
    final token = db.auth.currentSession?.accessToken;
    if (txRef == null || token == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start a credit purchase first.'))); return; }
    setState(() => paymentBusy = true);
    try {
      final base = gateway.replaceFirst(RegExp(r'/+$'), '');
      final response = await http.post(Uri.parse('$base/api/payments/verify'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'txRef': txRef})).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception(data['error']?.toString() ?? 'Payment is not verified yet.');
      final added = (data['credits'] as num?)?.toInt() ?? 0;
      if (added <= 0) throw Exception('Verified payment did not include credits.');
      if (!mounted) return;
      final balance = (data['balance'] as num?)?.toInt();
      setState(() { credits = 50 + (balance ?? added); _pendingPaymentRef = null; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verified. $added credits added.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verification: $e')));
    } finally { if (mounted) setState(() => paymentBusy = false); }
  }

  Future<void> showTopUpOptions() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: panel, builder: (sheetContext) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Buy AI credits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      const Text('Secure checkout powered by Flutterwave. Prices are in Nigerian naira.', style: TextStyle(color: Colors.white70)), const SizedBox(height: 16),
      _packButton(sheetContext, 'starter', 'Starter', '₦1,500', '100 credits'),
      _packButton(sheetContext, 'creator', 'Creator', '₦5,000', '300 credits'),
      _packButton(sheetContext, 'studio', 'Studio', '₦10,000', '800 credits'),
      _packButton(sheetContext, 'mega', 'Mega', '₦13,600', '1,000 credits'),
      if (_pendingPaymentRef != null) OutlinedButton.icon(onPressed: paymentBusy ? null : () { Navigator.pop(sheetContext); verifyTopUp(); }, icon: const Icon(Icons.verified_outlined), label: const Text('Verify previous payment')),
    ]))));
  }

  Widget _packButton(BuildContext sheetContext, String pack, String title, String price, String detail) => Padding(padding: const EdgeInsets.only(bottom: 10), child: FilledButton.tonal(onPressed: paymentBusy ? null : () { Navigator.pop(sheetContext); startTopUp(pack); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(detail)])), Text(price, style: const TextStyle(fontWeight: FontWeight.w800))]))));


  void updateEstimatedProgress() {
    if (!mounted || history.isEmpty) return;
    var changed = false;
    final updated = history.map((item) {
      if (item.status == 'Completed') return Creation(item.type, item.prompt, item.createdAt, item.taskId, item.status, progress: 100);
      if (item.status == 'Failed') return item;
      final estimate = (1 + DateTime.now().difference(item.createdAt).inSeconds * 0.45).round().clamp(1, 95);
      if (estimate != item.progress) changed = true;
      return Creation(item.type, item.prompt, item.createdAt, item.taskId, item.status, progress: estimate);
    }).toList();
    if (changed) setState(() { history..clear()..addAll(updated); });
  }

  Future<void> chooseImageInput() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: false);
    if (result == null || result.files.single.path == null || !mounted) return;
    setState(() {
      imageInputPath = result.files.single.path;
      imageInputName = result.files.single.name;
      imageInputSignedUrl = null;
    });
  }

  Future<String> uploadImageInput() async {
    if (imageInputSignedUrl != null) return imageInputSignedUrl!;
    final path = imageInputPath;
    if (path == null) throw Exception('Choose an image before using image-to-image.');
    final user = db.auth.currentUser;
    if (user == null) throw Exception('Sign in before uploading an image.');
    final file = File(path);
    final ext = path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'png' : ext}';
    await db.storage.from('image-inputs').upload(storagePath, file, fileOptions: const FileOptions(upsert: false));
    final signed = await db.storage.from('image-inputs').createSignedUrl(storagePath, 3600);
    if (mounted) setState(() => imageInputSignedUrl = signed);
    return signed;
  }

  Future<void> chooseVideoInput() async {
    final result = await FilePicker.platform.pickFiles(type: videoMode == 'Image to video' ? FileType.image : FileType.video, withData: false);
    if (result == null || result.files.single.path == null || !mounted) return;
    setState(() { videoInputPath = result.files.single.path; videoInputName = result.files.single.name; videoInputSignedUrl = null; });
  }

  Future<String> uploadVideoInput() async {
    if (videoInputSignedUrl != null) return videoInputSignedUrl!;
    final path = videoInputPath;
    if (path == null) throw Exception('Choose a source file first.');
    final user = db.auth.currentUser;
    if (user == null) throw Exception('Sign in before uploading a source file.');
    final ext = path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? (videoMode == 'Image to video' ? 'png' : 'mp4') : ext}';
    await db.storage.from('video-inputs').upload(storagePath, File(path), fileOptions: const FileOptions(upsert: false));
    final signed = await db.storage.from('video-inputs').createSignedUrl(storagePath, 3600);
    if (mounted) setState(() => videoInputSignedUrl = signed);
    return signed;
  }

  Future<void> chooseVoiceFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['wav', 'mp3', 'm4a', 'aac', 'ogg', 'flac'], withData: false);
    if (result == null || result.files.single.path == null || !mounted) return;
    setState(() { voiceFilePath = result.files.single.path; voiceFileName = result.files.single.name; voicePublicUrl = null; });
  }

  Future<void> toggleVoiceRecording() async {
    try {
      if (recordingVoice) {
        final path = await audioRecorder.stop();
        if (!mounted) return;
        setState(() { recordingVoice = false; voiceFilePath = path; voiceFileName = path == null ? null : 'Recorded voice.m4a'; voicePublicUrl = null; });
        return;
      }
      if (!await audioRecorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required to record voice.')));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/multivexa_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() { recordingVoice = true; voiceFilePath = null; voiceFileName = null; voicePublicUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice recording failed: $e')));
    }
  }

  Future<String> uploadVoiceReference() async {
    if (voicePublicUrl != null) return voicePublicUrl!;
    final path = voiceFilePath;
    if (path == null) throw Exception('Record or select an audio file first.');
    final user = db.auth.currentUser;
    if (user == null) throw Exception('Sign in before uploading voice audio.');
    final file = File(path);
    final ext = path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'm4a' : ext}';
    await db.storage.from('music-inputs').upload(storagePath, file, fileOptions: const FileOptions(upsert: false));
    final signed = await db.storage.from('music-inputs').createSignedUrl(storagePath, 3600);
    final url = signed;
    if (mounted) setState(() => voicePublicUrl = url);
    return url;
  }
  Future<void> loadHistory() async {
    try {
      final rows = await db.from('creations').select().order('created_at', ascending: false).limit(100);
      final items = (rows as List).map((r) { final created = DateTime.parse(r['created_at'] as String); final status = r['status'] as String; final elapsed = DateTime.now().difference(created).inSeconds; final progress = status == 'Completed' ? 100 : status == 'Failed' ? 0 : (1 + elapsed * 0.45).round().clamp(1, 95); return Creation(r['type'] as String, r['prompt'] as String, created, r['task_id'] as String, status, progress: progress); }).toList();
      if (mounted) setState(() { history..clear()..addAll(items); loading = false; });
      refreshTaskStatuses();
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load history. Run supabase/schema.sql in Supabase SQL Editor. Details: $e')));
    }
  }
  Future<void> refreshTaskStatuses() async {
    if (!mounted || history.isEmpty) return;
    final pending = history.where((item) =>
      item.status == 'Submitted to KIE' ||
      item.status == 'Processing' ||
      item.status == 'Queued').toList();
    for (final item in pending) {
      try {
        final base = gateway.replaceFirst(RegExp(r'/+$'), '');
        final response = await http.get(Uri.parse(
          '$base/api/tasks/${Uri.encodeComponent(item.taskId)}',
        )).timeout(const Duration(seconds: 12));
        if (response.statusCode < 200 || response.statusCode >= 300) continue;
        final payload = jsonDecode(response.body);
        if (payload is! Map<String, dynamic>) continue;
        final data = payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : payload;
        final rawState = (data['state'] ?? data['status'] ?? data['taskStatus'] ?? '')
            .toString().toLowerCase();
        String? nextStatus;
        if (['success', 'succeed', 'completed', 'complete'].contains(rawState)) {
          nextStatus = 'Completed';
        } else if (['fail', 'failed', 'error'].contains(rawState)) {
          nextStatus = 'Failed';
        } else if (['waiting', 'queued', 'submitted', 'processing', 'running', 'pending'].contains(rawState)) {
          nextStatus = rawState == 'waiting' || rawState == 'queued' ? 'Queued' : 'Processing';
        }
        if (nextStatus != null && mounted) {
          final index = history.indexWhere((entry) => entry.taskId == item.taskId);
          if (index >= 0 && history[index].status != nextStatus) {
            await db.from('creations').update({'status': nextStatus}).eq('task_id', item.taskId);
            if (!mounted) return;
            setState(() {
              history[index] = Creation(item.type, item.prompt, item.createdAt, item.taskId, nextStatus!);
            });
          }
        }
      } catch (_) {
        // Keep saved history intact if the network is temporarily unavailable.
      }
    }
  }
  Future<void> generate() async {
    final text = prompt.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe what you want to create first.')),
      );
      return;
    }
    if (mode == 1 && videoMode != 'Text to video' && videoInputPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Choose a source ${videoMode == 'Image to video' ? 'image' : 'video'} first.')));
      return;
    }
    if (mode == 0 && imageMode == 'Image to image') {
      if (imageInputPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a source image for image-to-image.')));
        return;
      }
      if (imageModel == 'gpt-image-2-5-flare-text-to-image') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPT Image 2.5 Flare currently supports text-to-image here. Choose GPT Image 2 or Nano Banana for image editing.')));
        return;
      }
    }
    if (credits < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of demo credits.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final effectivePrompt = mode == 0
          ? 'Style: $imageStyle. Create the following image in this style: $text'
          : mode == 1
              ? 'Visual style: $videoStyle. Create this video with the requested style and motion: $text'
              : text;
      final requestBody = <String, dynamic>{
        'type': types[mode].toLowerCase(),
        'prompt': effectivePrompt,
        if (mode == 0) ...{
          'model': imageMode == 'Image to image' && imageModel == 'gpt-image-2-text-to-image'
              ? 'gpt-image-2-image-to-image' : imageModel,
          'input': {
            'aspect_ratio': imageRatio,
            'resolution': imageResolution,
            if (imageModel == 'nano-banana-2' || imageModel == 'nano-banana-2-1') 'output_format': 'png',
            if (imageMode == 'Image to image' && imageModel == 'gpt-image-2-text-to-image')
              'input_urls': [await uploadImageInput()],
            if (imageMode == 'Image to image' && (imageModel == 'nano-banana-2' || imageModel == 'nano-banana-2-1'))
              'image_input': [await uploadImageInput()],
          },
        },
        if (mode == 1) ...{
          'model': videoModel,
          'input': {
            'aspect_ratio': videoRatio,
            if (videoMode == 'Image to video') 'image_urls': [await uploadVideoInput()],
            if (videoMode == 'Video to video') 'video_urls': [await uploadVideoInput()],
            if (videoModel == 'kling-3.0/video') ...{
              'duration': videoDuration,
              'mode': videoQuality == '4K' ? '4K' : videoQuality == '1080p' ? 'pro' : 'std',
              'sound': true,
              'multi_shots': false,
            } else if (videoModel == 'bytedance/seedance-2-5') ...{
              'duration': int.parse(videoDuration),
              'resolution': videoQuality,
              'generate_audio': true,
            } else if (videoModel == 'runway') ...{
              'duration': int.parse(videoDuration),
              'quality': videoQuality == '1080p' ? '1080p' : '720p',
              'watermark': '',
            } else ...{
              'duration': int.parse(videoDuration),
              'resolution': videoQuality,
            },
          },
        },
        if (mode == 2) ...{
          'model': 'ai-music-api/generate',
          'input': {
            'model': musicModel,
            'custom_mode': musicVoiceMode == 'AI Voice',
            'instrumental': false,
            'title': musicTitle.trim().isEmpty ? 'Multivexa Track' : musicTitle.trim().substring(0, musicTitle.trim().length > 80 ? 80 : musicTitle.trim().length),
            'style': musicStyle,
            if (musicVoiceMode == 'AI Voice') 'lyrics': text,
            if (musicVoiceMode == 'Record Voice' || musicVoiceMode == 'Upload Voice') ...{
              'prompt': text,
              'custom_mode': false,
              'audio_urls': [await uploadVoiceReference()],
            },
          },
        },
      };
      final base = gateway.replaceFirst(RegExp(r'/+, '');
      final response = await http.post(
        Uri.parse('$base/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error']?.toString() ?? 'KIE request failed (${response.statusCode})');
      }
      final taskId = data['taskId']?.toString() ?? '';
      if (taskId.isEmpty) throw Exception('KIE did not return a task ID.');
      final item = Creation(types[mode], text, DateTime.now(), taskId, 'Submitted to KIE');
      await db.from('creations').insert({
        'user_id': db.auth.currentUser!.id,
        'type': item.type,
        'prompt': item.prompt,
        'task_id': item.taskId,
        'status': item.status,
      });
      if (!mounted) return;
      setState(() {
        credits--;
        history.insert(0, item);
        tab = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KIE accepted your generation task.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation or history save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Multivexa AI', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: ink,
      actions: [Center(child: Text('$credits credits')), IconButton(tooltip: 'Buy credits with Flutterwave', onPressed: paymentBusy ? null : showTopUpOptions, icon: const Icon(Icons.account_balance_wallet_outlined)), IconButton(tooltip: 'Sign out', onPressed: () => db.auth.signOut(), icon: const Icon(Icons.logout))]),
    body: SafeArea(child: tab == 0 ? createView() : historyView()),
    bottomNavigationBar: NavigationBar(backgroundColor: panel, selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v),
      destinations: const [NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Create'), NavigationDestination(icon: Icon(Icons.history), label: 'History')]),
  );
  Widget createView() => ListView(padding: const EdgeInsets.all(20), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF30205B), Color(0xFF122D49)])),
      child: const Text('MAKE SOMETHING\nUNFORGETTABLE', style: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w900))),
    const SizedBox(height: 24), const Text('Choose a creation type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    Row(
      children: List.generate(types.length, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
          child: InkWell(
            onTap: () => setState(() => mode = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: mode == i ? violet.withValues(alpha: .22) : panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: mode == i ? violet : Colors.white10),
              ),
              child: Column(children: [
                Icon(icons[i], color: cyan, size: 28),
                const SizedBox(height: 8),
                Text(types[i]),
              ]),
            ),
          ),
        ),
      )),
    ),
    const SizedBox(height: 24), Text('Describe your ${types[mode].toLowerCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
    if (mode == 0) ...[
      const Text('Generation mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: imageMode,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.layers_outlined), labelText: 'Text-to-image or image-to-image'),
        items: const [
          DropdownMenuItem(value: 'Text to image', child: Text('Text to image — create from a prompt')),
          DropdownMenuItem(value: 'Image to image', child: Text('Image to image — edit a source image')),
        ],
        onChanged: busy ? null : (value) { if (value != null) setState(() { imageMode = value; imageInputSignedUrl = null; }); },
      ),
      if (imageMode == 'Image to image') ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : chooseImageInput,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(imageInputName == null ? 'Choose source image' : 'Change image: $imageInputName', overflow: TextOverflow.ellipsis),
        ),
        if (imageInputPath != null) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imageInputPath!), height: 150, fit: BoxFit.contain)),
        ],
        const Padding(padding: EdgeInsets.only(top: 8), child: Text('Upload a JPG, PNG or WebP image, then describe how you want it changed. The source is stored privately in your Supabase image-inputs bucket.', style: TextStyle(color: Colors.white54, fontSize: 12))),
      ],
      const SizedBox(height: 14),
      const Text('Image model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: imageModel,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.auto_awesome), labelText: 'Choose image model'),
        items: imageModels.entries.map((entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() { imageModel = value; imageRatio = value == 'gpt-image-2-5-flare-text-to-image' ? '3:2' : 'auto'; imageResolution = '1K'; }); },
      ),
      const SizedBox(height: 12),
      const Text('Image style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: imageStyle,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.palette_outlined), labelText: 'Choose a visual style'),
        items: imageStyles.map((style) => DropdownMenuItem(value: style, child: Text(style))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => imageStyle = value); },
      ),
      const SizedBox(height: 12),
      const Text('Aspect ratio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: imageRatio,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.aspect_ratio), labelText: 'Image dimensions'),
        items: availableImageRatios.map((ratio) => DropdownMenuItem(
          value: ratio,
          child: Text(ratio == 'auto' ? 'Auto' : ratio),
        )).toList(),
        onChanged: busy ? null : (value) {
          if (value != null) setState(() {
            imageRatio = value;
            if (!imageResolutions.contains(imageResolution)) imageResolution = '1K';
          });
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: imageResolution,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.high_quality_outlined), labelText: 'Resolution'),
        items: imageResolutions.map((resolution) => DropdownMenuItem(
          value: resolution,
          child: Text(resolution),
        )).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => imageResolution = value); },
      ),
      const SizedBox(height: 16),
    ],
    if (mode == 1) ...[
      const Text('Generation mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: videoMode,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.video_settings_outlined), labelText: 'Text, image or video input'),
        items: const [
          DropdownMenuItem(value: 'Text to video', child: Text('Text to video')),
          DropdownMenuItem(value: 'Image to video', child: Text('Image to video — animate a still image')),
          DropdownMenuItem(value: 'Video to video', child: Text('Video to video — transform a source clip')),
        ],
        onChanged: busy ? null : (value) { if (value != null) setState(() { videoMode = value; videoInputPath = null; videoInputName = null; videoInputSignedUrl = null; }); },
      ),
      if (videoMode != 'Text to video') ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : chooseVideoInput,
          icon: Icon(videoMode == 'Image to video' ? Icons.add_photo_alternate_outlined : Icons.video_file_outlined),
          label: Text(videoInputName == null ? (videoMode == 'Image to video' ? 'Choose source image' : 'Choose source video') : 'Change source: $videoInputName', overflow: TextOverflow.ellipsis),
        ),
        if (videoMode == 'Image to video' && videoInputPath != null) ...[
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(videoInputPath!), height: 150, fit: BoxFit.contain)),
        ],
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(videoMode == 'Image to video' ? 'Choose a still image and describe the motion you want.' : 'Choose a source clip and describe how you want it transformed. Provider support varies by selected model.', style: const TextStyle(color: Colors.white54, fontSize: 12))),
      ],
      const SizedBox(height: 14),
      const Text('Video model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: videoModel,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.movie_filter_outlined), labelText: 'Choose video model'),
        items: videoModels.entries.map((entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() { videoModel = value; videoRatio = '16:9'; videoDuration = '5'; videoQuality = '720p'; }); },
      ),
      const SizedBox(height: 12),
      const Text('Video style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: videoStyle,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.palette_outlined), labelText: 'Visual style'),
        items: videoStyles.map((style) => DropdownMenuItem(value: style, child: Text(style))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => videoStyle = value); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: videoRatio,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.aspect_ratio), labelText: 'Aspect ratio'),
        items: videoRatios.map((ratio) => DropdownMenuItem(value: ratio, child: Text(ratio))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => videoRatio = value); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: videoDuration,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.timer_outlined), labelText: 'Duration'),
        items: (videoModel == 'bytedance/seedance-2-5' ? ['5', '10', '15'] : videoModel == 'kling-3.0/video' ? ['5', '10', '15'] : ['5', '10']).map((duration) => DropdownMenuItem(value: duration, child: Text('$duration seconds'))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => videoDuration = value); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: videoQuality,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.high_quality_outlined), labelText: 'Resolution / quality'),
        items: (videoModel == 'kling-3.0/video' ? ['720p', '1080p', '4K'] : videoModel == 'runway' ? ['720p', '1080p'] : ['720p', '1080p']).map((quality) => DropdownMenuItem(value: quality, child: Text(quality))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => videoQuality = value); },
      ),
      const SizedBox(height: 16),
    ],
    if (mode == 2) ...[
      const Text('Music model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: musicModel,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.graphic_eq), labelText: 'Choose music model'),
        items: musicModels.entries.map((entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => musicModel = value); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: musicStyle,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.music_note), labelText: 'Music style'),
        items: musicStyles.map((style) => DropdownMenuItem(value: style, child: Text(style))).toList(),
        onChanged: busy ? null : (value) { if (value != null) setState(() => musicStyle = value); },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: musicVoiceMode,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.record_voice_over), labelText: 'Voice source'),
        items: const [
          DropdownMenuItem(value: 'AI Voice', child: Text('AI voice')),
          DropdownMenuItem(value: 'Record Voice', child: Text('Record my voice')),
          DropdownMenuItem(value: 'Upload Voice', child: Text('Upload audio')),
        ],
        onChanged: busy ? null : (value) { if (value != null) setState(() { musicVoiceMode = value; voicePublicUrl = null; }); },
      ),
      const SizedBox(height: 12),
      TextField(
        onChanged: (value) => musicTitle = value,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.title), labelText: 'Track title (optional)', hintText: 'My New Track'),
      ),
      if (musicVoiceMode != 'AI Voice') ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : toggleVoiceRecording,
            icon: Icon(recordingVoice ? Icons.stop_circle_outlined : Icons.mic_none),
            label: Text(recordingVoice ? 'Stop recording' : 'Record voice'),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: busy ? null : chooseVoiceFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose audio'),
          )),
        ]),
        if (voiceFileName != null) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Selected: $voiceFileName', style: const TextStyle(color: Colors.white70)),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Your audio is uploaded to your Supabase music-inputs bucket and used as a reference for generation.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
      const SizedBox(height: 16),
    ],
    TextField(controller: prompt, minLines: 4, maxLines: 7, decoration: InputDecoration(hintText: mode == 0 ? (imageMode == 'Image to image' ? 'Describe the edits: change the background, add warm cinematic lighting...' : 'A cinematic futuristic city at sunset...') : mode == 1 ? 'A smooth camera move through a glowing city...' : 'An uplifting Afrobeats instrumental with warm guitar...', alignLabelWithHint: true)),
    const SizedBox(height: 16), FilledButton.icon(onPressed: busy ? null : generate, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(busy ? 'Sending to KIE…' : 'Generate · 1 credit'), style: FilledButton.styleFrom(backgroundColor: violet, minimumSize: const Size.fromHeight(54))),
    const SizedBox(height: 14), const Text('Supabase saves account history. Credits remain demo-only and must be enforced on the server before production.', style: TextStyle(color: Colors.white54, fontSize: 12)),
  ]);
  Widget historyView() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (history.isEmpty) return const Center(child: Text('Your saved creations will appear here.'));
    return ListView.separated(padding: const EdgeInsets.all(20), itemCount: history.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) { final item = history[i]; final icon = item.type == 'Image' ? icons[0] : item.type == 'Video' ? icons[1] : icons[2];
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [Icon(icon, color: cyan, size: 32), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item.type} prompt', style: const TextStyle(fontWeight: FontWeight.w800)), Text(item.prompt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
            Text('${item.status} · ${item.createdAt.toLocal()}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ]))]));
      });
  }
}
