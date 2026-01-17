// ignore_for_file: constant_identifier_names

class AiClass {
  final Map<String, dynamic> map;

  AiClass(this.map);
  String get content {try{return map['candidates'][0]['content']['parts'][0]['text'];}catch(e){return"응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e";}}
  String get responseid {try{return map['responseId'];}catch(e){return"응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e";}}
  String get model {try{return  map['modelVersion'];}catch(e){return"응답을 읽어들이는 도중 에러가 발생했습니다 에러:$e";}}

}

Map<String, dynamic> generateconfig({
  String? stopsequence,
  String? responsemodalities,
  int? candidatecount,
  int? maxoutputtokens,
  double? temperature,
  double? topp,
  double? topk,
  int? seed,
  Map<String,dynamic>? thinkingConfig,
}) {
  return {"generationConfig":{
    "stopSequences": stopsequence,
    "responseModalities": responsemodalities,
    "candidateCount": candidatecount,
    "maxOutputTokens": maxoutputtokens,
    "temperature": temperature,
    "topP": topp,
    "topK": topk,
    "seed": seed,
    if(thinkingConfig != null) "thinkingConfig": thinkingConfig,
  }
};
}

Map<String, dynamic> thinkingconfig(
  {int? thinkingbudget,bool? includeThoughts,
  Thinkinglevel? thinkinglevel}
) {
  return {
    if (includeThoughts != null) "includeThoughts": includeThoughts,
    if (thinkingbudget != null) "thinkingBudget": thinkingbudget,
    if (thinkinglevel != null) "thinkingLevel": thinkinglevel.name,
  };
}

enum Thinkinglevel { THINKING_LEVEL_UNSPECIFIED, LOW, HIGH }

Map<String,dynamic> aiTool(dynamic tool) {
  return {"tools": [
      tool
     ]
   };
}