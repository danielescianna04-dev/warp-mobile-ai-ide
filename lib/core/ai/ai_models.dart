enum AIModel {
  openAIGpt35('gpt-3.5-turbo-0125', 'GPT-3.5 Turbo', 'OpenAI'),
  openAIGpt4('gpt-4o', 'GPT-4o', 'OpenAI'),
  openAIGpt4Vision('gpt-4o-vision', 'GPT-4o Vision', 'OpenAI'),
  openAIGpt5('gpt-5-chat-latest', 'GPT-5 Chat Latest', 'OpenAI'),
  claudeSonnet('claude-3-sonnet-20240229', 'Claude 3 Sonnet', 'Anthropic'),
  claudeOpus('claude-3-opus-20240229', 'Claude 3 Opus', 'Anthropic'),
  claudeSonnet4('claude-4-sonnet', 'Claude 4 Sonnet', 'Anthropic'),
  claudeHaiku('claude-3-haiku-20240307', 'Claude 3 Haiku', 'Anthropic'),
  geminiPro('gemini-pro', 'Gemini Pro', 'Google'),
  geminiProVision('gemini-pro-vision', 'Gemini Pro Vision', 'Google'),
  mistralSmall('mistral-small', 'Mistral Small', 'Mistral'),
  mistralMedium('mistral-medium', 'Mistral Medium', 'Mistral'),
  local('local', 'On-Device', 'Local');

  final String id;
  final String displayName;
  final String provider;

  const AIModel(this.id, this.displayName, this.provider);

  static List<AIModel> get openAIModels => [
    openAIGpt35, 
    openAIGpt4, 
    openAIGpt4Vision,
    openAIGpt5
  ];

  static List<AIModel> get claudeModels => [
    claudeSonnet, 
    claudeOpus, 
    claudeSonnet4, 
    claudeHaiku
  ];

  static List<AIModel> get geminiModels => [
    geminiPro, 
    geminiProVision
  ];

  static List<AIModel> get mistralModels => [
    mistralSmall, 
    mistralMedium
  ];

  static List<AIModel> get allModels => [
    ...openAIModels,
    ...claudeModels,
    ...geminiModels,
    ...mistralModels,
    local
  ];

  static AIModel fromId(String id) {
    return allModels.firstWhere(
      (model) => model.id == id,
      orElse: () => claudeSonnet4, // Default to Claude 4 Sonnet
    );
  }

  bool get supportsImages => [
    openAIGpt4Vision, 
    openAIGpt5,
    claudeSonnet, 
    claudeOpus, 
    claudeSonnet4, 
    geminiProVision
  ].contains(this);

  bool get supportsAudio => [
    openAIGpt4, 
    openAIGpt4Vision,
    openAIGpt5, 
    claudeSonnet, 
    claudeOpus, 
    claudeSonnet4
  ].contains(this);

  bool get supportsCode => [
    openAIGpt4, 
    openAIGpt4Vision,
    openAIGpt5, 
    claudeSonnet, 
    claudeOpus, 
    claudeSonnet4, 
    geminiPro, 
    geminiProVision,
    mistralMedium
  ].contains(this);
}