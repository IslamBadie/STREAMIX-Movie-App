import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../chatbot/chatbot_service.dart';
import '../services/chat_firebase_service.dart';
import '../models/movie_model.dart';
import '../config/api_config.dart';
import '../services/localization_service.dart';
import '../movie_details_screen.dart';
import '../models/movie.dart' as app_movie;

class ChatBotView extends StatefulWidget {
  const ChatBotView({super.key});

  @override
  State<ChatBotView> createState() => _ChatBotViewState();
}

class _ChatBotViewState extends State<ChatBotView> {
  final ChatBotService _botService = ChatBotService();
  final ChatFirebaseService _firebaseService = ChatFirebaseService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;

  final List<_ChatMessage> _messages = [];
  String? _conversationId;
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _lastAuthUID;

  @override
  void initState() {
    super.initState();
    _botService.loadData();
    _initializeSpeech();
    _initializeChat();
    _monitorAuthState();

    // Monitor changes in the TextField
    _controller.addListener(() {
      setState(() {});
    });
  }

  /// Monitor Firebase Auth state changes to reload chat when user logs in/out
  void _monitorAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        if (user != null && _lastAuthUID != user.uid) {
          // User logged in or switched account
          _lastAuthUID = user.uid;
          _initializeChat();
        } else if (user == null && _lastAuthUID != null) {
          // User logged out
          _lastAuthUID = null;
          _clearChat();
          _initializeChat();
        }
      }
    });
  }

  /// Clear chat messages
  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  /// Initialize speech recognition service
  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    setState(() {});
  }

  /// Initialize chat and load previous conversation if present
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      _conversationId = await _firebaseService.getLastConversation();

      if (_conversationId != null) {
        final messages =
            await _firebaseService.getConversationMessages(_conversationId!);

        setState(() {
          _messages.clear();
          for (var msgData in messages) {
            final text = msgData['message'] ?? '';
            final isUser = msgData['isUser'] ?? false;

            // كشف الرسالة الترحيبية القديمة وإضافة translationKey لها
            String? translationKey;
            if (!isUser &&
                text.contains('Welcome') &&
                text.contains('action movie')) {
              translationKey = 'welcome_chatbot';
            } else if (!isUser &&
                text.contains('أهلاً') &&
                text.contains('أكشن')) {
              translationKey = 'welcome_chatbot';
            }

            _messages.add(_ChatMessage(
              text: text,
              isUser: isUser,
              translationKey: translationKey,
            ));
          }
        });
      } else {
        _conversationId = await _firebaseService.createConversation();
        _addBotMessage(
          LocalizationService().t('welcome_chatbot'),
          saveToFirebase: true,
          translationKey: 'welcome_chatbot',
        );
      }
    } catch (e) {
      // Silently fail - conversation creation errors are handled gracefully
      _conversationId = null;
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _addUserMessage(String text, {bool saveToFirebase = true}) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });

    if (saveToFirebase && _conversationId != null) {
      _firebaseService.saveMessage(
        message: text,
        isUser: true,
        conversationId: _conversationId!,
      );
    }

    _scrollToBottom();
  }

  void _addBotMessage(String text,
      {bool saveToFirebase = true,
      List<Movie>? recommendations,
      String? translationKey}) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: false,
        recommendations: recommendations,
        translationKey: translationKey,
      ));
    });

    if (saveToFirebase && _conversationId != null) {
      _firebaseService.saveMessage(
        message: text,
        isUser: false,
        conversationId: _conversationId!,
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addUserMessage(text);

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    // Get reply with automatic poster enrichment
    final reply = await _botService.reply(text);
    final recommendations = _botService.lastRecommendations.isNotEmpty
        ? _botService.lastRecommendations
        : null;

    _addBotMessage(reply, recommendations: recommendations);

    setState(() => _isLoading = false);
  }

  /// Toggle speech recording (start / stop)
  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition service is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isListening) {
      // Stop recording
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Start recording
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
        localeId: 'ar_EG', // Arabic locale (Egypt)
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  /// Start a new conversation
  Future<void> _startNewConversation() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final dialogTitle = isDark ? Colors.white : Colors.black87;
    final dialogContent = isDark ? Colors.white70 : Colors.black54;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          LocalizationService().t('new_conversation'),
          style: TextStyle(color: dialogTitle),
        ),
        content: Text(
          LocalizationService().t('new_conversation'),
          style: TextStyle(color: dialogContent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService().t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocalizationService().t('yes')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
        _isLoading = true;
      });

      try {
        _conversationId = await _firebaseService.createConversation();
        _addBotMessage(
          LocalizationService().t('welcome_chatbot'),
          translationKey: 'welcome_chatbot',
        );
      } catch (e) {
        // Silently fail - conversation creation errors are handled gracefully
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F5);
    final appBarColor =
        isDark ? const Color(0xFF020617) : const Color(0xFFFFFFFF);
    final appBarTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: appBarTextColor,
        title: Text(LocalizationService().t('movie_recommendation_bot')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New Conversation',
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(message: msg);
                    },
                  ),
          ),
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingMicIcon(isDark: isDark),
                  const SizedBox(width: 12),
                  Text(
                    'Listening...',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_isLoading && _messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypingDot(delay: 0),
                    const SizedBox(width: 4),
                    _TypingDot(delay: 200),
                    const SizedBox(width: 4),
                    _TypingDot(delay: 400),
                  ],
                ),
              ),
            ),
          _InputBar(
            controller: _controller,
            onSend: _sendMessage,
            onMicPressed: _toggleListening,
            isListening: _isListening,
            enabled: !_isLoading,
            hasText: _controller.text.isNotEmpty,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.cancel();
    super.dispose();
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<Movie>? recommendations;
  final String? translationKey; // المفتاح للترجمة الديناميكية

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendations,
    this.translationKey,
  });
}

// ===============================
// Chat Bubble
// ===============================
class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final botBgColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB);
    final botTextColor = isDark ? Colors.white : Colors.black87;
    final userBgColor = const Color(0xFF2563EB);
    final userTextColor = Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isUser ? userBgColor : botBgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              // استخدم translationKey إذا كان موجوداً لترجمة الرسالة ديناميكياً
              message.translationKey != null
                  ? LocalizationService().t(message.translationKey!)
                  : message.text,
              style: TextStyle(
                color: isUser ? userTextColor : botTextColor,
                height: 1.4,
              ),
            ),
          ),
          // Show movie recommendations if available
          if (!isUser &&
              message.recommendations != null &&
              message.recommendations!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.recommendations!.length,
                  itemBuilder: (context, index) {
                    final movie = message.recommendations![index];
                    return _MovieRecommendationCard(movie: movie);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===============================
// Movie Recommendation Card
// ===============================
class _MovieRecommendationCard extends StatefulWidget {
  final Movie movie;

  const _MovieRecommendationCard({required this.movie});

  @override
  State<_MovieRecommendationCard> createState() =>
      _MovieRecommendationCardState();
}

class _MovieRecommendationCardState extends State<_MovieRecommendationCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);

    return GestureDetector(
      onTap: () {
        // Navigate to movie details screen when poster is tapped
        _navigateToMovieDetails(context);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie Poster
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: widget.movie.posterUrl.isNotEmpty
                    ? Image.network(
                        widget.movie.posterUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.white38),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(Icons.movie,
                              color: Colors.white38, size: 40),
                        ),
                      ),
              ),
            ),
            // Movie Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.movie.rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFF6E105), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              widget.movie.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      if (widget.movie.year > 0 || widget.movie.runtime > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${widget.movie.year > 0 ? widget.movie.year : '?'} • ${widget.movie.runtime > 0 ? '${widget.movie.runtime}m' : '?'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (widget.movie.genres.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.movie.genres.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to the movie details screen
  void _navigateToMovieDetails(BuildContext context) {
    // Import the movie details screen
    // For now, we'll create a simple dialog showing movie details
    // Try to fetch full movie details from API and navigate to MovieDetailsScreen
    _fetchAndNavigateAsync(context);
  }

  Future<void> _fetchAndNavigateAsync(BuildContext context) async {
    final ctx = context; // Save context before async operation

    // Get theme BEFORE async operation to avoid cross-async-gap context issue
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBgColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
    final dialogTextColor = isDark ? Colors.white : Colors.black87;

    try {
      final apiKey = ApiConfig.effectiveTmdbApiKey;
      if (apiKey.isEmpty) {
        throw Exception('TMDB API key not configured');
      }
      final resp = await http.get(Uri.parse(
          '${ApiConfig.tmdbBaseUrl}/movie/${widget.movie.id}?api_key=$apiKey&append_to_response=videos,credits'));
      if (resp.statusCode == 200) {
        if (!mounted) return;
        final data = json.decode(resp.body);
        final detailed =
            app_movie.Movie.fromTmdbDetails(data as Map<String, dynamic>);
        if (!mounted) return;
        Navigator.push(
          // ignore: use_build_context_synchronously
          ctx,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: detailed),
          ),
        );
        return;
      }
    } catch (e) {
      // Silently fail - show fallback dialog instead
    }

    if (!mounted) return;

    showDialog(
      // ignore: use_build_context_synchronously
      context: ctx,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          widget.movie.title,
          style: TextStyle(color: dialogTextColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.movie.posterUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.movie.posterUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (widget.movie.rating > 0)
              Text(
                '⭐ Rating: ${widget.movie.rating.toStringAsFixed(1)}',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            if (widget.movie.year > 0)
              Text(
                '📅 Year: ${widget.movie.year}',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            if (widget.movie.runtime > 0)
              Text(
                '⏱️ Duration: ${widget.movie.runtime} minutes',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            if (widget.movie.genres.isNotEmpty)
              Text(
                '🎬 Genres: ${widget.movie.genres.join(', ')}',
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LocalizationService().t('close'),
              style: const TextStyle(color: Color.fromARGB(255, 156, 121, 5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ctx = context;
              Navigator.pop(ctx);
              // Try again to navigate to details (best-effort)
              try {
                final apiKey = ApiConfig.effectiveTmdbApiKey;
                if (apiKey.isEmpty) {
                  throw Exception('TMDB API key not configured');
                }
                final resp = await http.get(Uri.parse(
                    '${ApiConfig.tmdbBaseUrl}/movie/${widget.movie.id}?api_key=$apiKey&append_to_response=videos,credits'));
                if (resp.statusCode == 200) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  final data = json.decode(resp.body);
                  final detailed = app_movie.Movie.fromTmdbDetails(
                      data as Map<String, dynamic>);
                  Navigator.push(
                    // ignore: use_build_context_synchronously
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(movie: detailed),
                    ),
                  );
                }
              } catch (e) {
                // Navigation error - fallback already handled
              }
            },
            child: Text(
              LocalizationService().t('see_more'),
              style: const TextStyle(color: Color.fromARGB(255, 156, 121, 5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// Input Bar
// ===============================
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final bool isListening;
  final bool enabled;
  final bool hasText;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onMicPressed,
    required this.isListening,
    required this.hasText,
    this.enabled = true,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final inputBgColor =
        isDark ? const Color(0xFF020617) : const Color(0xFFF5F5F5);
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final textFieldBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: inputBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled && !isListening,
              style: TextStyle(color: inputTextColor),
              decoration: InputDecoration(
                hintText: LocalizationService().t('type_or_press_mic'),
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
                filled: true,
                fillColor: textFieldBgColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              onSubmitted: enabled && hasText ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: enabled ? (hasText ? onSend : onMicPressed) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled
                    ? (isListening ? Colors.red : const Color(0xFF2563EB))
                    : const Color(0xFF1E293B),
                shape: BoxShape.circle,
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                hasText ? Icons.send : (isListening ? Icons.stop : Icons.mic),
                color: enabled ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// Typing Indicator Dot
// ===============================
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ===============================
// Pulsing Mic Icon
// ===============================
class _PulsingMicIcon extends StatefulWidget {
  final bool isDark;

  const _PulsingMicIcon({this.isDark = true});

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: const Icon(
        Icons.mic,
        color: Colors.red,
        size: 32,
      ),
    );
  }
}
