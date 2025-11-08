// chaturChatbot.dart - AI Chatbot for Government Schemes with Multilingual Support & Chat History
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

class ChaturChatbot extends StatefulWidget {
  final bool isDarkMode;
  final double textSizeMultiplier;
  final String selectedLanguage;

  const ChaturChatbot({
    Key? key,
    this.isDarkMode = false,
    this.textSizeMultiplier = 1.0,
    this.selectedLanguage = 'English',
  }) : super(key: key);

  @override
  _ChaturChatbotState createState() => _ChaturChatbotState();
}

class _ChaturChatbotState extends State<ChaturChatbot>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // User preferences
  String _selectedLanguage = 'English';
  double _textSizeMultiplier = 1.0;

  static const String API_URL = 'https://navarasa-chatur-model-api.hf.space/chat';
  static const String CHAT_HISTORY_KEY = 'chatur_chat_history';
  static const int MAX_STORED_MESSAGES = 100; // Limit storage size

  // Multilingual UI translations
  final Map<String, Map<String, dynamic>> _translations = {
    'English': {
      'title': 'Chatur AI',
      'subtitle': 'Government Schemes Assistant',
      'placeholder': 'Ask about schemes...',
      'listening': 'Listening...',
      'thinking': 'Chatur is thinking...',
      'welcome': "Namaste! 🙏 I'm Chatur, your AI assistant for government schemes. Ask me anything about schemes, eligibility, or benefits!",
      'suggestions': [
        "Schemes for women",
        "Agriculture schemes",
        "Education benefits",
        "How to apply?",
        "Eligibility criteria",
      ],
      'quickSuggestions': 'Quick suggestions:',
      'errorMessage': 'Sorry, I\'m having trouble connecting. Please check your internet and try again.',
      'emptyStateTitle': 'Ask me anything about\ngovernment schemes!',
    },
    'Kannada': {
      'title': 'ಚತುರ AI',
      'subtitle': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳ ಸಹಾಯಕ',
      'placeholder': 'ಯೋಜನೆಗಳ ಬಗ್ಗೆ ಕೇಳಿ...',
      'listening': 'ಕೇಳುತ್ತಿದೆ...',
      'thinking': 'ಚತುರ ಯೋಚಿಸುತ್ತಿದೆ...',
      'welcome': "ನಮಸ್ಕಾರ! 🙏 ನಾನು ಚತುರ, ನಿಮ್ಮ ಸರ್ಕಾರಿ ಯೋಜನೆಗಳ AI ಸಹಾಯಕ. ಯೋಜನೆಗಳು, ಅರ್ಹತೆ ಅಥವಾ ಪ್ರಯೋಜನಗಳ ಬಗ್ಗೆ ಏನು ಬೇಕಾದರೂ ಕೇಳಿ!",
      'suggestions': [
        "ಮಹಿಳೆಯರಿಗಾಗಿ ಯೋಜನೆಗಳು",
        "ಕೃಷಿ ಯೋಜನೆಗಳು",
        "ಶಿಕ್ಷಣ ಪ್ರಯೋಜನಗಳು",
        "ಹೇಗೆ ಅರ್ಜಿ ಸಲ್ಲಿಸುವುದು?",
        "ಅರ್ಹತೆ ಮಾನದಂಡಗಳು",
      ],
      'quickSuggestions': 'ತ್ವರಿತ ಸಲಹೆಗಳು:',
      'errorMessage': 'ಕ್ಷಮಿಸಿ, ನಾನು ಸಂಪರ್ಕಿಸಲು ತೊಂದರೆ ಅನುಭವಿಸುತ್ತಿದ್ದೇನೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      'emptyStateTitle': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳ ಬಗ್ಗೆ\nಏನು ಬೇಕಾದರೂ ಕೇಳಿ!',
    },
    'Hindi': {
      'title': 'चतुर AI',
      'subtitle': 'सरकारी योजनाओं का सहायक',
      'placeholder': 'योजनाओं के बारे में पूछें...',
      'listening': 'सुन रहा है...',
      'thinking': 'चतुर सोच रहा है...',
      'welcome': "नमस्ते! 🙏 मैं चतुर हूं, आपका सरकारी योजनाओं का AI सहायक। योजनाओं, पात्रता या लाभों के बारे में कुछ भी पूछें!",
      'suggestions': [
        "महिलाओं के लिए योजनाएं",
        "कृषि योजनाएं",
        "शिक्षा लाभ",
        "आवेदन कैसे करें?",
        "पात्रता मानदंड",
      ],
      'quickSuggestions': 'त्वरित सुझाव:',
      'errorMessage': 'क्षमा करें, मुझे कनेक्ट करने में परेशानी हो रही है। कृपया अपना इंटरनेट जांचें और पुनः प्रयास करें।',
      'emptyStateTitle': 'सरकारी योजनाओं के बारे में\nकुछ भी पूछें!',
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _textSizeMultiplier = widget.textSizeMultiplier;
    _initializeSpeech();
    _initializeTts();
    _initializeAnimation();
    _loadChatHistory(); // Load previous chat on startup
  }

  // ============ CHAT HISTORY MANAGEMENT ============
  
  /// Load chat history from local storage
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson = prefs.getString(CHAT_HISTORY_KEY);
      
      if (chatHistoryJson != null && chatHistoryJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(chatHistoryJson);
        final loadedMessages = decoded
            .map((item) => ChatMessage.fromJson(item))
            .toList();
        
        setState(() {
          _messages.addAll(loadedMessages);
        });
        
        print('Loaded ${loadedMessages.length} messages from history');
        _scrollToBottom();
      } else {
        // No history, show welcome message
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      _addWelcomeMessage();
    }
  }
  
  /// Save chat history to local storage
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only the last MAX_STORED_MESSAGES to prevent storage bloat
      final messagesToStore = _messages.length > MAX_STORED_MESSAGES
          ? _messages.sublist(_messages.length - MAX_STORED_MESSAGES)
          : _messages;
      
      final chatHistoryJson = jsonEncode(
        messagesToStore.map((msg) => msg.toJson()).toList()
      );
      
      await prefs.setString(CHAT_HISTORY_KEY, chatHistoryJson);
      print('Saved ${messagesToStore.length} messages to history');
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }
  
  /// Clear all chat history
  Future<void> _clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CHAT_HISTORY_KEY);
      print('Chat history cleared from storage');
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }
  
  /// Export chat history as text
  String _exportChatAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Chatur AI Chat History ===');
    buffer.writeln('Exported: ${DateTime.now().toString()}');
    buffer.writeln('Language: $_selectedLanguage');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    for (var message in _messages) {
      final sender = message.isUser ? 'You' : 'Chatur';
      final time = _formatTime(message.timestamp);
      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.text);
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _updateTtsLanguage();
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _updateTtsLanguage() async {
    String ttsLanguage = 'en-IN';
    if (_selectedLanguage == 'Kannada') {
      ttsLanguage = 'kn-IN';
    } else if (_selectedLanguage == 'Hindi') {
      ttsLanguage = 'hi-IN';
    }
    await _flutterTts.setLanguage(ttsLanguage);
  }

  String _t(String key) {
    return _translations[_selectedLanguage]?[key]?.toString() ?? key;
  }

  List<String> _getSuggestions() {
    return List<String>.from(_translations[_selectedLanguage]?['suggestions'] ?? []);
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        text: _t('welcome'),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bgColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
            final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chat Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Language Selection
                  Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildLanguageChip('English', 'English', setModalState),
                      _buildLanguageChip('ಕನ್ನಡ', 'Kannada', setModalState),
                      _buildLanguageChip('हिंदी', 'Hindi', setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Text Size Selection
                  Text(
                    'Text Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTextSizeButton('Small', 0.85, setModalState),
                      _buildTextSizeButton('Medium', 1.0, setModalState),
                      _buildTextSizeButton('Large', 1.15, setModalState),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageChip(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedLanguage = value;
        });
        setModalState(() {});
        await _updateTtsLanguage();
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to $value'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF667eea),
          ),
        );
        
        // Clear and add new welcome message in selected language
        setState(() {
          _messages.clear();
          _addWelcomeMessage();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextSizeButton(String label, double multiplier, StateSetter setModalState) {
    final isSelected = _textSizeMultiplier == multiplier;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _textSizeMultiplier = multiplier;
          });
          setModalState(() {});
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        
        // Set locale based on selected language
        String locale = 'en_IN';
        if (_selectedLanguage == 'Kannada') {
          locale = 'kn_IN';
        } else if (_selectedLanguage == 'Hindi') {
          locale = 'hi_IN';
        }
        
        _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              setState(() {
                _messageController.text = result.recognizedWords;
                _isListening = false;
              });
            }
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          localeId: locale,
        );
      }
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
    });

    // Save after adding user message
    await _saveChatHistory();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': text.trim()}),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final botResponse = data['response'] ?? data['answer'] ?? 
            _t('errorMessage');

        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        
        // Save after adding bot message
        await _saveChatHistory();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Chat API Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: _t('errorMessage'),
          isUser: false,
          isError: true,
          timestamp: DateTime.now(),
        ));
      });
      await _saveChatHistory();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
        final bgColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
        
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                'Clear Chat History?',
                style: TextStyle(color: textColor, fontSize: 18 * _textSizeMultiplier),
              ),
            ],
          ),
          content: Text(
            'This will permanently delete all your chat messages. This action cannot be undone.',
            style: TextStyle(color: textColor, fontSize: 15 * _textSizeMultiplier),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(fontSize: 15 * _textSizeMultiplier)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearChatHistory();
                setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Chat history cleared'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Clear All', style: TextStyle(fontSize: 15 * _textSizeMultiplier)),
            ),
          ],
        );
      },
    );
  }
  
  void _showChatHistoryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final bgColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
        final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
        
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Chat History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 20),
              
              // Total messages count
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea).withOpacity(0.1), Color(0xFF764ba2).withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Color(0xFF667eea)),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Messages',
                          style: TextStyle(
                            fontSize: 14 * _textSizeMultiplier,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${_messages.length} messages',
                          style: TextStyle(
                            fontSize: 18 * _textSizeMultiplier,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Export chat button
              ListTile(
                leading: Icon(Icons.download_outlined, color: Colors.blue),
                title: Text(
                  'Export Chat History',
                  style: TextStyle(color: textColor, fontSize: 16 * _textSizeMultiplier),
                ),
                subtitle: Text(
                  'Save as text file',
                  style: TextStyle(fontSize: 13 * _textSizeMultiplier),
                ),
                onTap: () {
                  Navigator.pop(context);
                  final exportedText = _exportChatAsText();
                  Clipboard.setData(ClipboardData(text: exportedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat history copied to clipboard!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              
              // Clear chat button
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Clear Chat History',
                  style: TextStyle(color: Colors.red, fontSize: 16 * _textSizeMultiplier),
                ),
                subtitle: Text(
                  'Delete all messages',
                  style: TextStyle(fontSize: 13 * _textSizeMultiplier),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _clearChat();
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? Color(0xFF0A0E27) : Color(0xFFF5F7FA);
    final cardColor = isDark ? Color(0xFF1A1F3A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Color(0xFF0A0E27), Color(0xFF1A1F3A)]
                : [Color(0xFFF5F7FA), Color(0xFFE8EAF6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(cardColor, textColor),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(textColor)
                    : _buildMessageList(cardColor, textColor),
              ),
              if (_messages.length <= 1 && !_isLoading)
                _buildQuickSuggestions(cardColor, textColor),
              _buildInputArea(cardColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color cardColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF764ba2), size: 28),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * _textSizeMultiplier,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _t('subtitle'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12 * _textSizeMultiplier,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: _showChatHistoryMenu,
            tooltip: 'Chat History',
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showSettingsMenu,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _t('emptyStateTitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18 * _textSizeMultiplier,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(Color cardColor, Color textColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingIndicator(cardColor);
        }
        return _buildMessageBubble(_messages[index], cardColor, textColor);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Color cardColor, Color textColor) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)])
                    : null,
                color: message.isUser ? null : (message.isError ? Colors.red.shade50 : cardColor),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                border: message.isError
                    ? Border.all(color: Colors.red.shade200, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : (message.isError ? Colors.red.shade900 : textColor),
                      fontSize: 15 * _textSizeMultiplier,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser ? Colors.white.withOpacity(0.7) : Colors.grey,
                          fontSize: 11 * _textSizeMultiplier,
                        ),
                      ),
                      if (!message.isUser && !message.isError) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _speak(message.text),
                          child: Icon(
                            _isSpeaking ? Icons.volume_off : Icons.volume_up,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color cardColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF764ba2)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              _t('thinking'),
              style: TextStyle(
                fontSize: 14 * _textSizeMultiplier,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions(Color cardColor, Color textColor) {
    final suggestions = _getSuggestions();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('quickSuggestions'),
            style: TextStyle(
              fontSize: 12 * _textSizeMultiplier,
              color: textColor.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () => _sendMessage(suggestion),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea).withOpacity(0.1), Color(0xFF764ba2).withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF667eea).withOpacity(0.3)),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 13 * _textSizeMultiplier,
                      color: Color(0xFF764ba2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color cardColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isListening
                    ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])
                    : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300]),
                shape: BoxShape.circle,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: _isListening ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading && !_isListening,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15 * _textSizeMultiplier,
                ),
                decoration: InputDecoration(
                  hintText: _isListening ? _t('listening') : _t('placeholder'),
                  hintStyle: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 15 * _textSizeMultiplier,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _messageController.text.trim().isEmpty || _isLoading
                ? null
                : () => _sendMessage(_messageController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _messageController.text.trim().isEmpty || _isLoading
                    ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                    : LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                shape: BoxShape.circle,
                boxShadow: _messageController.text.trim().isEmpty || _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    required this.timestamp,
  });
  
  // Convert ChatMessage to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'isError': isError,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  // Create ChatMessage from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      isError: json['isError'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}