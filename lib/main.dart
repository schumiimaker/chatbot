import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Офлайн Чат-бот',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'Офлайн Чат-бот'),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    // Обязательно освобождаем ресурсы контроллеров, чтобы избежать утечек памяти
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageWidget(
                    text: message.text,
                    isFromUser: message.isFromUser,
                  );
                },
              ),
            ),
            if (_loading) const CircularProgressIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (String text) {
                        _sendMessage();
                      },
                    ),
                  ),
                  const SizedBox.square(dimension: 8),
                  IconButton(
                    onPressed: _loading ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.isEmpty) return;
    _textController.clear();

    // Добавляем сообщение пользователя и показываем индикатор загрузки в одном вызове setState
    setState(() {
      _messages.add(Message(text, true));
      _loading = true;
    });

    _scrollToBottom();

    // Имитация "размышлений" бота с помощью Future.delayed
    Future.delayed(const Duration(milliseconds: 500), () {
      final botResponse = _getBotResponse(text);

      // Добавляем ответ бота и убираем индикатор загрузки
      setState(() {
        _messages.add(Message(botResponse, false));
        _loading = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // Прокручиваем вниз после того, как кадр будет отрисован
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Бот, основанный на правилах. Использование Map делает код более масштабируемым.
  String _getBotResponse(String userInput) {
    final input = userInput.toLowerCase().trim();

    // Ищем первое ключевое слово, которое совпадет
    for (var entry in _botRules.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Я вас не понял. Попробуйте спросить что-нибудь другое, например "привет" или "как дела?".';
  }
}

class Message {
  final String text;
  final bool isFromUser;
  Message(this.text, this.isFromUser);
}

// Правила для бота вынесены для лучшей читаемости
const Map<String, String> _botRules = {
  'привет': 'Здравствуйте! Чем могу помочь?',
  'как дела': 'У меня все отлично, я ведь программа! А у вас?',
  'погода': 'Я не умею проверять погоду, я всего лишь простой бот.',
  'время работы?': 'Время работы Пн-Вс 08.00-22.00',
};

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const MessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isFromUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: MarkdownBody(data: text, selectable: true),
          ),
        ),
      ],
    );
  }
}
