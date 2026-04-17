// ignore_for_file: non_constant_identifier_names, use_null_aware_elements

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;

import 'classes.dart';

class AiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final Object? cause;

  const AiException(this.message, {this.statusCode, this.data, this.cause});

  @override
  String toString() {
    final buffer = StringBuffer('AiException: $message');
    if (statusCode != null) {
      buffer.write(' (statusCode: $statusCode)');
    }
    if (data != null) {
      buffer.write(' data: $data');
    }
    if (cause != null) {
      buffer.write(' cause: $cause');
    }
    return buffer.toString();
  }
}

class AiClient {
  static const String defaultBaseUrl =
      'https://generativelanguage.googleapis.com';

  final String key;
  final dio.Dio client;
  final String apiVersion;
  final String baseUrl;

  AiClient(
    this.key, {
    dio.Dio? client,
    this.apiVersion = 'v1beta',
    this.baseUrl = defaultBaseUrl,
  }) : client = client ?? dio.Dio();

  String _endpoint(String model, String action, {Map<String, dynamic>? query}) {
    final uri = Uri.parse('$baseUrl/$apiVersion/models/$model:$action').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
    return uri.toString();
  }

  JsonMap _buildRequestBody({
    String? prompt,
    List<JsonMap>? contents,
    String? systemInstruction,
    JsonMap? systemInstructionMap,
    Map<String, dynamic>? generationConfig,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    List<JsonMap>? safetySettings,
    List<String>? labels,
  }) {
    final resolvedContents =
        contents ??
        (prompt != null
            ? [
                userContent([textPart(prompt)]),
              ]
            : null);

    if (resolvedContents == null || resolvedContents.isEmpty) {
      throw const AiException('Either prompt or contents must be provided.');
    }

    return {
      if (systemInstructionMap case final value?)
        'systemInstruction': value
      else if (systemInstruction case final value?)
        'systemInstruction': systemInstructionFromText(value),
      'contents': resolvedContents,
      if (generationConfig != null) ...generationConfig,
      if (tools case final value?) 'tools': value,
      if (toolConfig case final value?) 'toolConfig': value,
      if (safetySettings case final value?) 'safetySettings': value,
      if (labels case final value?) 'labels': value,
    };
  }

  dio.Options _jsonOptions({dio.ResponseType? responseType}) {
    return dio.Options(
      responseType: responseType,
      headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'},
    );
  }

  Never _throwApiError(Object error) {
    if (error is dio.DioException) {
      final response = error.response;
      throw AiException(
        response?.data is JsonMap && response?.data['error'] is JsonMap
            ? (response!.data['error']['message']?.toString() ??
                  error.message ??
                  'Gemini API request failed.')
            : (error.message ?? 'Gemini API request failed.'),
        statusCode: response?.statusCode,
        data: response?.data,
        cause: error,
      );
    }
    throw AiException('Unexpected Gemini client error.', cause: error);
  }

  Future<AiClass> generateContent(
    String model, {
    String? prompt,
    List<JsonMap>? contents,
    String? systemInstruction,
    JsonMap? systemInstructionMap,
    Map<String, dynamic>? generationConfig,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    List<JsonMap>? safetySettings,
    List<String>? labels,
  }) async {
    try {
      final response = await client.post(
        _endpoint(model, 'generateContent'),
        options: _jsonOptions(),
        data: _buildRequestBody(
          prompt: prompt,
          contents: contents,
          systemInstruction: systemInstruction,
          systemInstructionMap: systemInstructionMap,
          generationConfig: generationConfig,
          tools: tools,
          toolConfig: toolConfig,
          safetySettings: safetySettings,
          labels: labels,
        ),
      );

      if (response.data is! JsonMap) {
        throw AiException(
          'Gemini API returned a non-JSON object response.',
          statusCode: response.statusCode,
          data: response.data,
        );
      }

      return AiClass(response.data as JsonMap);
    } catch (error) {
      _throwApiError(error);
    }
  }

  Future<String> generateText(
    String model, {
    required String prompt,
    String? systemInstruction,
    JsonMap? systemInstructionMap,
    Map<String, dynamic>? generationConfig,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    List<JsonMap>? safetySettings,
    List<String>? labels,
  }) async {
    final response = await generateContent(
      model,
      prompt: prompt,
      systemInstruction: systemInstruction,
      systemInstructionMap: systemInstructionMap,
      generationConfig: generationConfig,
      tools: tools,
      toolConfig: toolConfig,
      safetySettings: safetySettings,
      labels: labels,
    );
    return response.text;
  }

  Future<dynamic> generateJson(
    String model, {
    required String prompt,
    String? systemInstruction,
    JsonMap? systemInstructionMap,
    JsonMap? schema,
    Map<String, dynamic>? generationConfig,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    List<JsonMap>? safetySettings,
    List<String>? labels,
  }) async {
    final mergedGenerationConfig = {
      ...responseJsonConfig(schema: schema),
      if (generationConfig != null) ...generationConfig,
    };

    final response = await generateContent(
      model,
      prompt: prompt,
      systemInstruction: systemInstruction,
      systemInstructionMap: systemInstructionMap,
      generationConfig: mergedGenerationConfig,
      tools: tools,
      toolConfig: toolConfig,
      safetySettings: safetySettings,
      labels: labels,
    );

    final decoded = response.json;
    if (decoded == null) {
      throw AiException('Model did not return valid JSON.', data: response.raw);
    }
    return decoded;
  }

  Stream<AiClass> streamGenerateContent(
    String model, {
    String? prompt,
    List<JsonMap>? contents,
    String? systemInstruction,
    JsonMap? systemInstructionMap,
    Map<String, dynamic>? generationConfig,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    List<JsonMap>? safetySettings,
    List<String>? labels,
  }) async* {
    dio.Response<dynamic> response;
    try {
      response = await client.post(
        _endpoint(model, 'streamGenerateContent', query: {'alt': 'sse'}),
        options: _jsonOptions(responseType: dio.ResponseType.stream),
        data: _buildRequestBody(
          prompt: prompt,
          contents: contents,
          systemInstruction: systemInstruction,
          systemInstructionMap: systemInstructionMap,
          generationConfig: generationConfig,
          tools: tools,
          toolConfig: toolConfig,
          safetySettings: safetySettings,
          labels: labels,
        ),
      );
    } catch (error) {
      _throwApiError(error);
    }

    final stream = response.data.stream as Stream<List<int>>;
    final lines = stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final dataBuffer = StringBuffer();

    await for (final line in lines) {
      if (line.startsWith('data:')) {
        final payload = line.substring(5).trim();
        if (payload == '[DONE]') {
          break;
        }
        dataBuffer.writeln(payload);
        continue;
      }

      if (line.trim().isEmpty && dataBuffer.isNotEmpty) {
        final payload = dataBuffer.toString().trim();
        dataBuffer.clear();

        try {
          final decoded = jsonDecode(payload);
          if (decoded is JsonMap) {
            yield AiClass(decoded);
          } else if (decoded is List) {
            for (final item in decoded) {
              if (item is JsonMap) {
                yield AiClass(item);
              }
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    if (dataBuffer.isNotEmpty) {
      final payload = dataBuffer.toString().trim();
      try {
        final decoded = jsonDecode(payload);
        if (decoded is JsonMap) {
          yield AiClass(decoded);
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is JsonMap) {
              yield AiClass(item);
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<AiClass> generate_content(
    String model,
    String prompt, {
    String? systeminstruction,
    Map<String, dynamic>? generate_config,
    Map<String, dynamic>? tool,
  }) {
    return generateContent(
      model,
      prompt: prompt,
      systemInstruction: systeminstruction,
      generationConfig: generate_config,
      tools: _extractTools(tool),
      toolConfig: _extractToolConfig(tool),
    );
  }

  Stream<AiClass> generate_stream_content(
    String model,
    String prompt, {
    String? systeminstruction,
    Map<String, dynamic>? generate_config,
    Map<String, dynamic>? tool,
  }) {
    return streamGenerateContent(
      model,
      prompt: prompt,
      systemInstruction: systeminstruction,
      generationConfig: generate_config,
      tools: _extractTools(tool),
      toolConfig: _extractToolConfig(tool),
    );
  }

  List<JsonMap>? _extractTools(Map<String, dynamic>? tool) {
    final value = tool?['tools'];
    if (value is List) {
      return value.whereType<JsonMap>().toList(growable: false);
    }
    return null;
  }

  JsonMap? _extractToolConfig(Map<String, dynamic>? tool) {
    final value = tool?['toolConfig'];
    return value is JsonMap ? value : null;
  }

  void close() {
    client.close();
  }
}

class AiChatClient {
  final String key;
  final String model;
  final dio.Dio client;
  final String? legacySysteminstruction;
  final String? systemInstruction;
  final JsonMap? systemInstructionMap;
  final Map<String, dynamic>? generationConfig;
  final List<JsonMap>? tools;
  final JsonMap? toolConfig;
  final List<JsonMap>? safetySettings;
  final List<String>? labels;
  final String apiVersion;
  final String baseUrl;

  AiChatClient(
    this.key,
    this.model, {
    dio.Dio? client,
    String? systeminstruction,
    this.systemInstruction,
    this.systemInstructionMap,
    Map<String, dynamic>? generate_config,
    this.generationConfig,
    Map<String, dynamic>? tool,
    List<JsonMap>? tools,
    JsonMap? toolConfig,
    this.safetySettings,
    this.labels,
    this.apiVersion = 'v1beta',
    this.baseUrl = AiClient.defaultBaseUrl,
  }) : legacySysteminstruction = systeminstruction,
       client = client ?? dio.Dio(),
       tools = tools ?? _toolsFromLegacy(tool),
       toolConfig = toolConfig ?? _toolConfigFromLegacy(tool),
       assert(
         systeminstruction == null || systemInstruction == null,
         'Use either systeminstruction or systemInstruction, not both.',
       );

  final List<JsonMap> history = [];

  String? get _resolvedSystemInstruction =>
      systemInstruction ?? legacySysteminstruction;

  AiClient get _delegate =>
      AiClient(key, client: client, apiVersion: apiVersion, baseUrl: baseUrl);

  List<JsonMap> get messages => List.unmodifiable(history);

  void addContent(JsonMap content) {
    history.add(content);
  }

  void addUserText(String text) {
    history.add(userContent([textPart(text)]));
  }

  void addModelText(String text) {
    history.add(modelContent([textPart(text)]));
  }

  void addToolResponse({required String name, required JsonMap response}) {
    history.add(
      toolContent([functionResponsePart(name: name, response: response)]),
    );
  }

  void clearHistory() {
    history.clear();
  }

  Future<AiClass> sendMessage(
    String prompt, {
    List<JsonMap>? extraParts,
  }) async {
    final userParts = <JsonMap>[textPart(prompt), ...?extraParts];
    history.add(userContent(userParts));

    try {
      final response = await _delegate.generateContent(
        model,
        contents: List<JsonMap>.from(history),
        systemInstruction: _resolvedSystemInstruction,
        systemInstructionMap: systemInstructionMap,
        generationConfig: generationConfig,
        tools: tools,
        toolConfig: toolConfig,
        safetySettings: safetySettings,
        labels: labels,
      );

      final content = response.contentMap;
      if (content != null) {
        history.add(Map<String, dynamic>.from(content));
      } else if (response.text.isNotEmpty) {
        history.add(modelContent([textPart(response.text)]));
      }

      return response;
    } catch (error) {
      if (history.isNotEmpty) {
        history.removeLast();
      }
      rethrow;
    }
  }

  Future<AiClass> sendMessageWithParts(List<JsonMap> parts) async {
    history.add(userContent(parts));

    try {
      final response = await _delegate.generateContent(
        model,
        contents: List<JsonMap>.from(history),
        systemInstruction: _resolvedSystemInstruction,
        systemInstructionMap: systemInstructionMap,
        generationConfig: generationConfig,
        tools: tools,
        toolConfig: toolConfig,
        safetySettings: safetySettings,
        labels: labels,
      );

      final content = response.contentMap;
      if (content != null) {
        history.add(Map<String, dynamic>.from(content));
      } else if (response.text.isNotEmpty) {
        history.add(modelContent([textPart(response.text)]));
      }

      return response;
    } catch (error) {
      if (history.isNotEmpty) {
        history.removeLast();
      }
      rethrow;
    }
  }

  Future<AiClass> sendFunctionResponse({
    required String name,
    required JsonMap response,
  }) {
    history.add(
      toolContent([functionResponsePart(name: name, response: response)]),
    );
    return _delegate
        .generateContent(
          model,
          contents: List<JsonMap>.from(history),
          systemInstruction: _resolvedSystemInstruction,
          systemInstructionMap: systemInstructionMap,
          generationConfig: generationConfig,
          tools: tools,
          toolConfig: toolConfig,
          safetySettings: safetySettings,
          labels: labels,
        )
        .then((result) {
          final content = result.contentMap;
          if (content != null) {
            history.add(Map<String, dynamic>.from(content));
          } else if (result.text.isNotEmpty) {
            history.add(modelContent([textPart(result.text)]));
          }
          return result;
        })
        .catchError((error) {
          if (history.isNotEmpty) {
            history.removeLast();
          }
          throw error;
        });
  }

  Stream<AiClass> streamSendMessage(
    String prompt, {
    List<JsonMap>? extraParts,
  }) async* {
    final userParts = <JsonMap>[textPart(prompt), ...?extraParts];
    history.add(userContent(userParts));

    final collectedParts = <JsonMap>[];
    final textBuffer = StringBuffer();

    try {
      await for (final chunk in _delegate.streamGenerateContent(
        model,
        contents: List<JsonMap>.from(history),
        systemInstruction: _resolvedSystemInstruction,
        systemInstructionMap: systemInstructionMap,
        generationConfig: generationConfig,
        tools: tools,
        toolConfig: toolConfig,
        safetySettings: safetySettings,
        labels: labels,
      )) {
        for (final part in chunk.parts.whereType<JsonMap>()) {
          collectedParts.add(Map<String, dynamic>.from(part));
          final text = part['text'];
          if (text is String) {
            textBuffer.write(text);
          }
        }
        yield chunk;
      }

      if (collectedParts.isNotEmpty) {
        history.add(modelContent(collectedParts));
      } else if (textBuffer.isNotEmpty) {
        history.add(modelContent([textPart(textBuffer.toString())]));
      }
    } catch (error) {
      if (history.isNotEmpty) {
        history.removeLast();
      }
      rethrow;
    }
  }

  Future<dynamic> send_message(String prompt) => sendMessage(prompt);

  Stream<dynamic> stream_send_message(String prompt) =>
      streamSendMessage(prompt);

  static List<JsonMap>? _toolsFromLegacy(Map<String, dynamic>? legacyTool) {
    final value = legacyTool?['tools'];
    if (value is List) {
      return value.whereType<JsonMap>().toList(growable: false);
    }
    return null;
  }

  static JsonMap? _toolConfigFromLegacy(Map<String, dynamic>? legacyTool) {
    final value = legacyTool?['toolConfig'];
    return value is JsonMap ? value : null;
  }

  void close() {
    client.close();
  }
}
