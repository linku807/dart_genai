// ignore_for_file: constant_identifier_names, use_null_aware_elements

import 'dart:convert';

typedef JsonMap = Map<String, dynamic>;

class AiClass {
  final JsonMap map;

  AiClass(this.map);

  JsonMap get raw => map;

  List<dynamic> get candidates =>
      (map['candidates'] as List?)?.cast<dynamic>() ?? const [];

  JsonMap? get firstCandidate =>
      candidates.isNotEmpty && candidates.first is JsonMap
      ? candidates.first as JsonMap
      : null;

  JsonMap? get contentMap {
    final candidate = firstCandidate;
    final content = candidate?['content'];
    return content is JsonMap ? content : null;
  }

  List<dynamic> get parts =>
      (contentMap?['parts'] as List?)?.cast<dynamic>() ?? const [];

  List<String> get textParts {
    return parts
        .whereType<JsonMap>()
        .map((part) => part['text'])
        .whereType<String>()
        .toList(growable: false);
  }

  String get text => textParts.join();

  String get content {
    final value = text;
    if (value.isNotEmpty) {
      return value;
    }
    try {
      return map['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (e) {
      return '응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e';
    }
  }

  String get responseid {
    final id = responseId;
    if (id != null) {
      return id;
    }
    try {
      return map['responseId'] as String;
    } catch (e) {
      return '응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e';
    }
  }

  String get model {
    final value = modelVersion;
    if (value != null) {
      return value;
    }
    try {
      return map['modelVersion'] as String;
    } catch (e) {
      return '응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e';
    }
  }

  String? get responseId => map['responseId'] as String?;

  String? get modelVersion => map['modelVersion'] as String?;

  String? get finishReason => firstCandidate?['finishReason'] as String?;

  JsonMap? get usageMetadata {
    final value = map['usageMetadata'];
    return value is JsonMap ? value : null;
  }

  JsonMap? get promptFeedback {
    final value = map['promptFeedback'];
    return value is JsonMap ? value : null;
  }

  List<JsonMap> get functionCalls {
    return parts
        .whereType<JsonMap>()
        .map((part) => part['functionCall'])
        .whereType<JsonMap>()
        .toList(growable: false);
  }

  bool get hasFunctionCall => functionCalls.isNotEmpty;

  JsonMap? get firstFunctionCall =>
      functionCalls.isNotEmpty ? functionCalls.first : null;

  List<JsonMap> get functionResponses {
    return parts
        .whereType<JsonMap>()
        .map((part) => part['functionResponse'])
        .whereType<JsonMap>()
        .toList(growable: false);
  }

  dynamic get json {
    final object = jsonObject;
    if (object != null) {
      return object;
    }

    final array = jsonArray;
    if (array != null) {
      return array;
    }

    return null;
  }

  JsonMap? get jsonObject {
    final source = text.trim();
    if (source.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(source);
      return decoded is JsonMap ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? get jsonArray {
    final source = text.trim();
    if (source.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(source);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => text.isNotEmpty ? text : map.toString();
}

Map<String, dynamic> generateconfig({
  List<String>? stopsequences,
  String? responsemodalities,
  int? candidatecount,
  int? maxoutputtokens,
  double? temperature,
  double? topp,
  int? topk,
  int? seed,
  Map<String, dynamic>? thinkingConfig,
  String? responseMimeType,
  JsonMap? responseSchema,
  List<JsonMap>? safetySettings,
  int? presencePenalty,
  int? frequencyPenalty,
}) {
  return generationConfig(
    stopSequences: stopsequences,
    responseModalities: responsemodalities == null
        ? null
        : [responsemodalities],
    candidateCount: candidatecount,
    maxOutputTokens: maxoutputtokens,
    temperature: temperature,
    topP: topp,
    topK: topk,
    seed: seed,
    thinkingConfig: thinkingConfig,
    responseMimeType: responseMimeType,
    responseSchema: responseSchema,
    safetySettings: safetySettings,
    presencePenalty: presencePenalty?.toDouble(),
    frequencyPenalty: frequencyPenalty?.toDouble(),
  );
}

Map<String, dynamic> generationConfig({
  List<String>? stopSequences,
  List<String>? responseModalities,
  int? candidateCount,
  int? maxOutputTokens,
  double? temperature,
  double? topP,
  int? topK,
  int? seed,
  Map<String, dynamic>? thinkingConfig,
  String? responseMimeType,
  JsonMap? responseSchema,
  List<JsonMap>? safetySettings,
  double? presencePenalty,
  double? frequencyPenalty,
}) {
  return {
    'generationConfig': {
      'stopSequences': stopSequences,
      'responseModalities': responseModalities,
      'candidateCount': candidateCount,
      'maxOutputTokens': maxOutputTokens,
      'temperature': temperature,
      'topP': topP,
      'topK': topK,
      'seed': seed,
      'thinkingConfig': thinkingConfig,
      'responseMimeType': responseMimeType,
      'responseSchema': responseSchema,
      'presencePenalty': presencePenalty,
      'frequencyPenalty': frequencyPenalty,
    }..removeWhere((key, value) => value == null),
    if (safetySettings case final value?) 'safetySettings': value,
  };
}

Map<String, dynamic> responseJsonConfig({
  JsonMap? schema,
  int? candidateCount,
  int? maxOutputTokens,
  double? temperature,
  double? topP,
  int? topK,
  int? seed,
  Map<String, dynamic>? thinkingConfig,
}) {
  return generationConfig(
    candidateCount: candidateCount,
    maxOutputTokens: maxOutputTokens,
    temperature: temperature,
    topP: topP,
    topK: topK,
    seed: seed,
    thinkingConfig: thinkingConfig,
    responseMimeType: 'application/json',
    responseSchema: schema,
  );
}

Map<String, dynamic> thinkingconfig({
  int? thinkingbudget,
  bool? includeThoughts,
  Thinkinglevel? thinkinglevel,
}) {
  return thinkingConfig(
    thinkingBudget: thinkingbudget,
    includeThoughts: includeThoughts,
    thinkingLevel: thinkinglevel,
  );
}

Map<String, dynamic> thinkingConfig({
  int? thinkingBudget,
  bool? includeThoughts,
  Thinkinglevel? thinkingLevel,
}) {
  return {
    if (includeThoughts case final value?) 'includeThoughts': value,
    if (thinkingBudget case final value?) 'thinkingBudget': value,
    if (thinkingLevel case final value?) 'thinkingLevel': value.name,
  };
}

enum Thinkinglevel { THINKING_LEVEL_UNSPECIFIED, LOW, HIGH }

Map<String, dynamic> aiTool(dynamic tool) {
  return tools(tool is List ? tool.cast<JsonMap>() : [tool as JsonMap]);
}

Map<String, dynamic> tools(List<JsonMap> toolList, {JsonMap? toolConfig}) {
  return {
    'tools': toolList,
    if (toolConfig case final value?) 'toolConfig': value,
  };
}

JsonMap tool(List<JsonMap> functionDeclarations) {
  return {'functionDeclarations': functionDeclarations};
}

JsonMap toolconfig({
  FunctionCallingMode? mode,
  List<String>? allowedFunctionNames,
}) {
  return toolConfig(mode: mode, allowedFunctionNames: allowedFunctionNames);
}

JsonMap toolConfig({
  FunctionCallingMode? mode,
  List<String>? allowedFunctionNames,
}) {
  return {
    'functionCallingConfig': {
      if (mode case final value?) 'mode': value.name,
      if (allowedFunctionNames case final value?) 'allowedFunctionNames': value,
    },
  };
}

enum FunctionCallingMode { AUTO, ANY, NONE }

JsonMap functionDeclaration({
  required String name,
  String? description,
  JsonMap? parameters,
}) {
  return {
    'name': name,
    if (description case final value?) 'description': value,
    if (parameters case final value?) 'parameters': value,
  };
}

JsonMap textPart(String text) => {'text': text};

JsonMap inlineDataPart({required String mimeType, required String data}) {
  return {
    'inlineData': {'mimeType': mimeType, 'data': data},
  };
}

JsonMap fileDataPart({required String mimeType, required String fileUri}) {
  return {
    'fileData': {'mimeType': mimeType, 'fileUri': fileUri},
  };
}

JsonMap functionResponsePart({
  required String name,
  required JsonMap response,
}) {
  return {
    'functionResponse': {'name': name, 'response': response},
  };
}

JsonMap functionCallPart({required String name, JsonMap? args}) {
  return {
    'functionCall': {'name': name, if (args case final value?) 'args': value},
  };
}

JsonMap userContent(List<JsonMap> parts) => {'role': 'user', 'parts': parts};

JsonMap modelContent(List<JsonMap> parts) => {'role': 'model', 'parts': parts};

JsonMap toolContent(List<JsonMap> parts) => {'role': 'tool', 'parts': parts};

JsonMap systemInstructionFromText(String text) => {
  'parts': [textPart(text)],
};

JsonMap safetySetting({required String category, required String threshold}) {
  return {'category': category, 'threshold': threshold};
}
