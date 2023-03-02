import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Secret.dart';

void main() => runApp(MyApp());
// message container for json response
class Message {
  final String role;
  final String content;
  final DateTime timestamp;

  Message({required this.role, required this.content, required this.timestamp});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['choices'][0]['message']['role'],
      content: json['choices'][0]['message']['content'],
      timestamp: DateTime.now(),
    );
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('GPTchatBot'),
        ),
        body: ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final String ApiKey = "";

  // fetch apikey from secrets at startup
  @override
  void initState() {
    super.initState();
    getSecretApikey();
  }

  Future<String> getSecretApikey() async {
    Secret secret = await SecretLoader(secretPath: "secrets.json").load();
    return secret.apiKey;
  }

  Future<Message> _getResponse(String message) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${ApiKey.isEmpty ? await getSecretApikey() : ApiKey}',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [          {'role': 'user', 'content': message},        ],
      }),
    );
    final jsonResponse = json.decode(response.body);
    //final result = jsonResponse['choices'][0]['message']['content'];
    print(getSecretApikey);
    return Message.fromJson(jsonResponse);
  }

  void _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _messages.insert(0, Message(role: 'user', content: text, timestamp: DateTime.now()));
    });
    final response = await _getResponse(text);
    setState(() {
      _messages.insert(0, response);
    });
  }

  Widget _buildTextComposer() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration:
              InputDecoration.collapsed(hintText: 'Send a message'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Flexible(
      child: ListView.builder(
        padding: EdgeInsets.all(8.0),
        reverse: true,
        itemCount: _messages.length,
        itemBuilder: (_, int index) => _buildMessageItem(_messages[index]),
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    // return a listTile that contain the message, role, timestamp and round icon related to the role
    // the message content is wrapped in a container with a background color that is related to the role
    // the timestamp is shown below the message, with only the time, wrap inside the message container
    return ListTile(
      title: Container(
        decoration: BoxDecoration(
          color: message.role == 'user' ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content.trim(),
              style: TextStyle(
                fontSize: 16.0,
                //color: message.role == 'user' ? Colors.blue : Colors.green,
              ),
            ),
            SizedBox(height: 5.0),
            Text(
              message.timestamp.toString().substring(11, 16),
              style: TextStyle(
                fontSize: 12.0,
                color: message.role == 'user' ? Colors.blue : Colors.green,
              ),
            ),
          ],
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: message.role == 'user' ? Colors.blue : Colors.green,
        child: Icon(
          message.role == 'user' ? Icons.person : Icons.smart_toy_outlined,
          color: Colors.white,
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMessageList(),
        Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: _buildTextComposer(),
        ),
      ],
    );
  }
}
