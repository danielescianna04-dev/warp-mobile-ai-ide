enum AIModel {
  claudeSonnet35('claude-3.5', 'Claude 3.5 Sonnet', 'Anthropic');

  final String id;
  final String displayName;
  final String provider;

  const AIModel(this.id, this.displayName, this.provider);

  static List<AIModel> get allModels => [claudeSonnet35];

  static AIModel fromId(String id) {
    return allModels.firstWhere(
      (model) => model.id == id,
      orElse: () => claudeSonnet35,
    );
  }

  bool get supportsImages => true;
  bool get supportsAudio => true;
  bool get supportsCode => true;
}