import 'package:shared_preferences/shared_preferences.dart';

/// Resultado do modal inicial de código da empresa.
enum CompanyCodeEntryChoice {
  exploreOnly,
  savedCode,
  openEnrollment,
}

/// Código da empresa salvo localmente antes/durante o cadastro (não substitui validação na API).
class PendingCompanyCodeStore {
  static const _keyPendingCode = 'pending_company_code_v1';
  static const _keyEntryPromptDone = 'company_code_entry_prompt_done_v1';

  Future<String?> loadPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingCode);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  Future<void> savePendingCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingCode, trimmed);
  }

  Future<void> clearPendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingCode);
  }

  /// Usuário já viu o modal inicial (salvou código ou escolheu explorar só o guia).
  Future<bool> isEntryPromptCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEntryPromptDone) ?? false;
  }

  Future<void> markEntryPromptCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEntryPromptDone, true);
  }

  Future<void> clearEntryPromptCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEntryPromptDone);
  }
}
