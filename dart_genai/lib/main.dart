// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:dart_genai/classes.dart';

class AiClient {
  final String key;
  final dio.Dio client;
  AiClient(this.key, {dio.Dio? client}) : client = client ?? dio.Dio();

  Future<dynamic> generate_content(
    String model,
    String prompt, {
    String? systeminstruction,
    Map<String,dynamic>? generate_config,
    Map<String,dynamic>? tool
  }) async {
    var response = await client.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      options: dio.Options(headers:{'x-goog-api-key': key, 'Content-Type': 'application/json'}),
      data:{
        if (systeminstruction != null) "system_instruction": {
          "parts": [
            {"text": systeminstruction},
          ],
        },
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
        if(generate_config != null) ...generate_config,
        if(tool != null) ...tool,
      },
    );
    if (response.statusCode == 200) {
      final aiResponse = AiClass(response.data);
      return aiResponse;
    } else {
      return response.statusCode.toString();
    }
  }

  Stream<AiClass> generate_stream_content(
    String model,
    String prompt, {
    String? systeminstruction,
    Map<String, dynamic>? generate_config,
    Map<String, dynamic>? tool,
  }) async* {
    var response = await client.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse',
      options: dio.Options(
        responseType: dio.ResponseType.stream,
        headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'}
      ),
      data: {
        if (systeminstruction != null)
          "system_instruction": {
            "parts": [{"text": systeminstruction}]
          },
        "contents": [
          {
            "parts": [{"text": prompt}]
          }
        ],
        if (generate_config != null) ...generate_config,
        if (tool != null) ...tool,
      },
    );

    final stream = response.data.stream.cast<List<int>>().transform(utf8.decoder);

    await for (var data in stream) {
      int start = data.indexOf('{');
      int end = data.lastIndexOf('}');

      if (start != -1 && end != -1 && start < end) {
        try {
          final jsonString = data.substring(start, end + 1);
          yield AiClass(jsonDecode(jsonString));
        } catch (_) {
          continue;
        }
      }
    }
  }

  void close() {
    client.close();
  }
}

class AiChatClient {
  final String key;
  final String model;
  final dio.Dio client;
  final String? systeminstruction;
  final Map<String,dynamic>? generate_config;
  final Map<String,dynamic>? tool;

  AiChatClient(this.key, this.model, {dio.Dio? client, this.systeminstruction, this.generate_config, this.tool}) : client = client ?? dio.Dio();
  final List<Map<String, dynamic>> history = [];

  Future<dynamic> send_message(String prompt) async {
    history.add({
        "role": "user",
        "parts": [
          {
            "text": prompt
          }
        ]
      });
    var response = await client.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      options: dio.Options(headers:{'x-goog-api-key': key, 'Content-Type': 'application/json'}),
      data:{
        if (systeminstruction != null) "system_instruction": {
          "parts": [
            {"text": systeminstruction},
          ],
        },
        "contents": history,
        if(tool != null) ...tool!,
        if(generate_config != null) ...generate_config!,
      },
    );
    if (response.statusCode == 200) {
      final aiResponse = AiClass(response.data);
      history.add({
        "role": "model",
        "parts": [
          {
            "text": aiResponse.content
          }
        ]
      });
      return aiResponse;
    } else {
      history.removeLast();
    }
  }

  Stream<dynamic> stream_send_message(String prompt) async* {
  history.add({
    "role": "user",
    "parts": [{"text": prompt}]
  });

  try {
    var response = await client.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse',
      options: dio.Options(
        responseType: dio.ResponseType.stream, 
        headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'}
      ),
      data: {
        if (systeminstruction != null) "system_instruction": {"parts": [{"text": systeminstruction}]},
        "contents": history,
        if (tool != null) ...tool!,
        if (generate_config != null) ...generate_config!,
      },
    );

    final stream = response.data.stream.cast<List<int>>().transform(utf8.decoder);
    String response_history = "";

    await for (var data in stream) {
      int start = data.indexOf('{');
      int end = data.lastIndexOf('}');

      if (start != -1 && end != -1 && start < end) {
        String jsonString = data.substring(start, end + 1);
        
        try {
          final aiResponse = AiClass(jsonDecode(jsonString));
          response_history += aiResponse.content;
          yield aiResponse;
        } catch (_) {
          continue;
        }
      }
    }

    history.add({
      "role": "model",
      "parts": [{"text": response_history}]
    });
  } catch (e) {
    if (history.isNotEmpty) history.removeLast();
    rethrow;
  }
}

  void close() {
    client.close();
  }
}

