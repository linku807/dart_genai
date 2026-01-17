import 'package:dart_genai/classes.dart';
import 'package:dart_genai/main.dart';
import 'dart:io';

AiChatClient chatClient = AiChatClient("your key","gemini-2.5-flash-lite",systeminstruction: "sya simply",generate_config: generateconfig(thinkingConfig: thinkingconfig(includeThoughts: false)),tool: aiTool({"google_search": {}}));
void main() async{
  // ignore: prefer_typing_uninitialized_variables
    chatClient.stream_send_message("").listen((event){
      stdout.write(event.content);
  });
}