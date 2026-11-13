import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/associates_repository.dart';
import '../data/connect_plans.dart';
import '../models/company_enrollment.dart';
import '../models/connect_product_plan.dart';
import '../models/daily_pass_offer.dart';
import '../models/gym.dart';
import '../services/check_in_location.dart';
import '../services/connect_api.dart';
import '../utils/payment_input_formatters.dart';
import '../models/primary_gym.dart';
import '../models/user_account.dart';
import '../services/biometric_session_store.dart';
import '../services/pending_company_code_store.dart';
import 'app_state_persistence.dart';

class AppState extends ChangeNotifier {
  AppState({
    AppStatePersistence? persistence,
    AssociatesRepository? associatesRepository,
    BiometricSessionStore? biometricSessionStore,
    PendingCompanyCodeStore? pendingCompanyCodeStore,
  })  : _persistence = persistence ?? AppStatePersistence(),
        _associates = associatesRepository,
        _biometricSessionStore = biometricSessionStore ?? BiometricSessionStore(),
        _injectedPendingCompanyCodeStore = pendingCompanyCodeStore;

  final AppStatePersistence _persistence;
  final AssociatesRepository? _associates;
  final BiometricSessionStore _biometricSessionStore;
  final PendingCompanyCodeStore? _injectedPendingCompanyCodeStore;
  PendingCompanyCodeStore? _lazyPendingCompanyCodeStore;

  /// Sempre não-nulo; lazy init evita crash em hot reload após adicionar o store.
  PendingCompanyCodeStore get _pendingCompanyCodeStore =>
      _injectedPendingCompanyCodeStore ??
      (_lazyPendingCompanyCodeStore ??= PendingCompanyCodeStore());

  final List<WalletItem> _wallet = [];
  final List<SavedPaymentCard> _savedCards = [];
  final List<BillingEntry> _billingEntries = [];
  int homeTabIndex = 0;

  String? _selectedConnectPlanId;
  ActiveConnectSubscription? _activeConnectSubscription;
  ActiveGymSubscription? _activeGymSubscription;
  PrimaryGymChoice? _primaryGym;
  CompanyEnrollment? _companyEnrollment;

  String? _pendingCompanyCode;
  bool _companyCodeEntryPromptDone = false;

  bool _persistReady = false;
  bool _guestPrefsLoaded = false;

  List<WalletItem> get wallet => List.unmodifiable(_wallet);

  List<SavedPaymentCard> get savedCards => List.unmodifiable(_savedCards);

  List<BillingEntry> get billingEntries => List.unmodifiable(_billingEntries);

  String? get selectedConnectPlanId => _selectedConnectPlanId;

  ActiveConnectSubscription? get activeConnectSubscription => _activeConnectSubscription;

  ActiveGymSubscription? get activeGymSubscription => _activeGymSubscription;

  PrimaryGymChoice? get primaryGym => _primaryGym;

  bool get hasPrimaryGym => _primaryGym != null;

  String? get primaryGymId => _primaryGym?.gymId;

  String? get primaryGymName => _primaryGym?.gymName ?? _activeGymSubscription?.gymName;

  bool get isEmployeeIdentified => _companyEnrollment != null;

  CompanyEnrollment? get companyEnrollment => _companyEnrollment;

  String? get pendingCompanyCode => _pendingCompanyCode;

  /// Sem cadastro corporativo concluído e sem sessão de membro (carteira/plano local).
  bool get isGuestGuideMode => !isEmployeeIdentified && !hasEstablishedSession;

  /// Modal na abertura quando não há sessão e o usuário ainda não concluiu o fluxo inicial.
  bool get shouldShowCompanyCodeEntry {
    if (!_guestPrefsLoaded) return false;
    if (hasEstablishedSession || isEmployeeIdentified) return false;
    return !_companyCodeEntryPromptDone;
  }

  /// Sessão local com vínculo, plano, carteira ou cartões (base para desbloqueio biométrico).
  bool get hasEstablishedSession =>
      _companyEnrollment != null ||
      _activeConnectSubscription != null ||
      _activeGymSubscription != null ||
      _wallet.isNotEmpty ||
      _savedCards.isNotEmpty;

  /// Plano Movly com cartão cadastrado, assinatura em unidade ou equivalente.
  bool get hasActiveMembership =>
      _activeConnectSubscription != null ||
      _activeGymSubscription != null;

  bool get hasConnectPlanPendingCheckout =>
      _selectedConnectPlanId != null &&
      _companyEnrollment != null &&
      _activeConnectSubscription == null;

  bool get canUseMemberCheckIn =>
      _activeConnectSubscription != null && _primaryGym != null;

  List<WalletItem> get activeDailyPasses =>
      _wallet.where((w) => w.type == PurchaseType.dailyPass && w.isActiveDailyPass).toList();

  WalletItem? walletItemById(String id) {
    for (final item in _wallet) {
      if (item.id == id) return item;
    }
    return null;
  }

  WalletItem? activeDailyPassForGym(String gymId) {
    for (final item in _wallet) {
      if (item.type == PurchaseType.dailyPass &&
          item.gym.id == gymId &&
          item.isActiveDailyPass) {
        return item;
      }
    }
    return null;
  }

  Future<void> loadPersistedState() async {
    final snapshot = await _persistence.load();
    if (snapshot != null) {
      _applySnapshot(snapshot);
    }
    await loadGuestEntryPreferences();
    _persistReady = true;
    await _syncSessionFromApi();
    notifyListeners();
  }

  Future<void> loadGuestEntryPreferences() async {
    _pendingCompanyCode = await _pendingCompanyCodeStore.loadPendingCode();
    _companyCodeEntryPromptDone = await _pendingCompanyCodeStore.isEntryPromptCompleted();
    _guestPrefsLoaded = true;
  }

  Future<void> savePendingCompanyCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    _pendingCompanyCode = trimmed;
    await _pendingCompanyCodeStore.savePendingCode(trimmed);
    notifyListeners();
  }

  Future<void> completeCompanyCodeEntry(CompanyCodeEntryChoice? choice) async {
    await _pendingCompanyCodeStore.markEntryPromptCompleted();
    _companyCodeEntryPromptDone = true;
    if (choice == CompanyCodeEntryChoice.exploreOnly) {
      homeTabIndex = 0;
    }
    notifyListeners();
  }

  /// Limpa cache local da sessão (vínculo, plano, carteira, cartões e extrato).
  Future<void> clearLocalSession() async {
    _wallet.clear();
    _savedCards.clear();
    _billingEntries.clear();
    homeTabIndex = 0;
    _selectedConnectPlanId = null;
    _activeConnectSubscription = null;
    _activeGymSubscription = null;
    _primaryGym = null;
    _companyEnrollment = null;
    await _persistence.clear();
    await _biometricSessionStore.clearBoundSession();
    await _pendingCompanyCodeStore.clearPendingCode();
    await _pendingCompanyCodeStore.clearEntryPromptCompleted();
    _pendingCompanyCode = null;
    _companyCodeEntryPromptDone = false;
    notifyListeners();
  }

  AppStateSnapshot _toSnapshot() {
    return AppStateSnapshot(
      homeTabIndex: homeTabIndex,
      selectedConnectPlanId: _selectedConnectPlanId,
      enrollment: _companyEnrollment,
      activeConnect: _activeConnectSubscription,
      activeGymSubscription: _activeGymSubscription,
      primaryGym: _primaryGym,
      wallet: List.of(_wallet),
      savedCards: List.of(_savedCards),
      billingEntries: List.of(_billingEntries),
    );
  }

  void _applySnapshot(AppStateSnapshot snapshot) {
    homeTabIndex = snapshot.homeTabIndex;
    _selectedConnectPlanId = snapshot.selectedConnectPlanId;
    _companyEnrollment = snapshot.enrollment;
    _activeConnectSubscription = snapshot.activeConnect;
    _activeGymSubscription = snapshot.activeGymSubscription;
    _primaryGym = snapshot.primaryGym;
    _wallet
      ..clear()
      ..addAll(snapshot.wallet);
    _savedCards
      ..clear()
      ..addAll(snapshot.savedCards);
    _billingEntries
      ..clear()
      ..addAll(snapshot.billingEntries);
  }

  void _emit() {
    notifyListeners();
    if (!_persistReady) return;
    unawaited(_persistence.save(_toSnapshot()));
  }

  /// Valida código de adesão da empresa via API. Retorna mensagem de erro ou null se OK.
  Future<String?> redeemEnrollmentCode(String code, {String? collaboratorName}) async {
    final result = await ConnectApi().validateEnrollmentCode(code);
    if (!result.ok) {
      return result.errorMessage ??
          'Código inválido ou expirado. Verifique com o RH da sua empresa.';
    }
    _companyEnrollment = CompanyEnrollment(
      companyName: result.companyName ?? 'Empresa',
      code: result.code ?? code.trim(),
      collaboratorLabel: collaboratorName?.trim().isEmpty ?? true ? null : collaboratorName!.trim(),
    );
    await _pendingCompanyCodeStore.clearPendingCode();
    _pendingCompanyCode = null;
    _emit();
    return null;
  }

  void clearEnrollment() {
    _companyEnrollment = null;
    _selectedConnectPlanId = null;
    _activeConnectSubscription = null;
    _savedCards.clear();
    _billingEntries.clear();
    _emit();
  }

  void openPlanTab() {
    if (isGuestGuideMode) {
      homeTabIndex = 0;
      _emit();
      return;
    }
    homeTabIndex = 1;
    _emit();
  }

  void openGuideTab() {
    homeTabIndex = 0;
    _emit();
  }

  @Deprecated('Use openPlanTab')
  void openWalletTab() => openPlanTab();

  void selectConnectPlan(String planId) {
    _selectedConnectPlanId = planId;
    _emit();
  }

  /// Troca de plano com cobrança (upgrade) ou apenas confirmação (downgrade). Retorna erro ou `null`.
  Future<String?> tryChangeConnectPlan(String planId) async {
    final plan = connectPlanById(planId);
    if (plan == null) return 'Plano não encontrado.';

    final current = _activeConnectSubscription;
    if (current == null) {
      return 'Você ainda não tem um plano ativo. Escolha um plano e confirme o pagamento para começar.';
    }

    final profileBefore = await _fetchActiveConnectMemberProfile();
    if (profileBefore == null || !profileBefore.active) {
      if (_activeConnectSubscription != null) {
        _activeConnectSubscription = null;
        _emit();
      }
      return 'Não encontramos um plano ativo nesta conta. '
          'Escolha e confirme um plano abaixo ou fale com o RH se o benefício ainda não foi liberado.';
    }

    final holder = profileBefore.holderName.trim().isNotEmpty
        ? profileBefore.holderName.trim()
        : _holderNameForConnectApi(profileBefore);

    final api = await ConnectApi().changeConnectSubscriptionPlan(
      holderName: holder,
      connectPlanId: planId,
    );
    if (!api.ok) {
      return api.errorMessage ?? 'Não foi possível alterar o plano.';
    }

    final outcome = api.paymentOutcome?.trim().toLowerCase();
    if (outcome == 'pending_payment') {
      await _syncSessionFromApi();
      _emit();
      return 'Pagamento do upgrade ainda em processamento no cartão. '
          'O plano só será alterado após a confirmação — acompanhe em faturamento ou tente novamente em instantes.';
    }
    if (outcome == 'failed') {
      return 'Cobrança do upgrade não foi autorizada. Verifique o cartão cadastrado.';
    }

    final profile = api.profile;
    if (profile == null || !profile.active) {
      return 'Não foi possível confirmar a troca de plano.';
    }
    if (profile.connectPlanId != planId) {
      return 'A troca de plano ainda não foi confirmada no gateway de pagamento.';
    }

    final previous = _activeConnectSubscription;
    _selectedConnectPlanId = planId;
    _activeConnectSubscription = ActiveConnectSubscription(
      planId: plan.id,
      planName: plan.name,
      pricePerMonth: plan.pricePerMonth,
      since: DateTime.tryParse(profile.since) ?? previous?.since ?? DateTime.now(),
      cardBrand: previous?.cardBrand ?? 'Cartão',
      cardLastFour: profile.cardLastFour ?? previous?.cardLastFour ?? '0000',
    );

    if (api.kind == 'upgrade' && (api.upgradeChargeNow ?? 0) > 0) {
      _appendBilling(
        description: 'Upgrade Movly — ${plan.name}',
        amount: api.upgradeChargeNow!,
        kind: BillingEntryKind.connectSubscription,
        cardLastFour: profile.cardLastFour ?? previous?.cardLastFour,
      );
    }

    await _syncSessionFromApi();
    _emit();
    return null;
  }

  /// Cobrança no Asaas e confirma assinatura. Retorna mensagem de erro ou `null` se ok.
  Future<String?> activateConnectPlan({
    required String planId,
    required String cardNumber,
    required String cardHolderName,
    required String expiryLabel,
    required String cvv,
    String? holderCpf,
    String? holderPhone,
  }) async {
    final plan = connectPlanById(planId);
    if (plan == null) return 'Plano não encontrado.';

    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final brand = inferCardBrand(digits);
    final lastFour = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    final expiryDigits = expiryLabel.replaceAll(RegExp(r'\D'), '');
    if (expiryDigits.length != 4) {
      return 'Validade do cartão inválida.';
    }
    final expiryMonth = expiryDigits.substring(0, 2);
    final expiryYear = expiryDigits.substring(2);

    final api = await ConnectApi().checkoutConnectSubscription(
      holderName: _connectSubscriptionHolderName(fallbackCardHolder: cardHolderName),
      connectPlanId: planId,
      cardHolderName: cardHolderName,
      cardNumber: digits,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: cvv,
      companyName: _companyEnrollment?.companyName,
      holderCpf: holderCpf,
      holderPhone: holderPhone,
    );

    if (!api.ok) {
      return api.errorMessage ?? 'Não foi possível cadastrar o cartão.';
    }

    final subscriptionId = api.asaasSubscriptionId?.trim();
    if (subscriptionId == null || subscriptionId.isEmpty) {
      return 'Cobrança não confirmada no gateway. Tente novamente.';
    }

    final profile = api.profile;
    if (profile == null || !profile.active) {
      return 'Não foi possível confirmar a assinatura.';
    }

    final confirmedLastFour = profile.cardLastFour ?? api.cardLastFour ?? lastFour;
    final since = DateTime.tryParse(profile.since) ?? DateTime.now();
    final holder = cardHolderName.trim().isNotEmpty ? cardHolderName.trim() : 'Titular';

    _selectedConnectPlanId = planId;
    _activeConnectSubscription = ActiveConnectSubscription(
      planId: plan.id,
      planName: plan.name,
      pricePerMonth: plan.pricePerMonth,
      since: since,
      cardBrand: brand,
      cardLastFour: confirmedLastFour,
    );

    registerPaymentCard(
      brand: brand,
      lastFour: confirmedLastFour,
      holderName: holder,
      expiryLabel: expiryLabel,
      makeDefault: true,
      persist: false,
    );

    await _syncSessionFromApi();
    final firstPaymentId = api.firstPaymentId?.trim();
    if (firstPaymentId != null && firstPaymentId.isNotEmpty) {
      _upsertConnectBillingRow(
        paymentId: firstPaymentId,
        description: 'Movly — ${plan.name}',
        amount: plan.pricePerMonth,
        status: api.firstPaymentStatus,
        cardLastFour: confirmedLastFour,
      );
    }
    _emit();
    return null;
  }

  void registerPaymentCard({
    required String brand,
    required String lastFour,
    required String holderName,
    required String expiryLabel,
    bool makeDefault = false,
    bool persist = true,
  }) {
    final now = DateTime.now();
    if (makeDefault) {
      for (var i = 0; i < _savedCards.length; i++) {
        final c = _savedCards[i];
        if (c.isDefault) {
          _savedCards[i] = SavedPaymentCard(
            id: c.id,
            brand: c.brand,
            lastFour: c.lastFour,
            holderName: c.holderName,
            expiryLabel: c.expiryLabel,
            addedAt: c.addedAt,
          );
        }
      }
    }

    final existing = _savedCards.indexWhere((c) => c.lastFour == lastFour && c.brand == brand);
    if (existing >= 0) {
      final c = _savedCards[existing];
      _savedCards[existing] = SavedPaymentCard(
        id: c.id,
        brand: c.brand,
        lastFour: c.lastFour,
        holderName: holderName,
        expiryLabel: expiryLabel,
        addedAt: c.addedAt,
        isDefault: makeDefault || c.isDefault,
      );
    } else {
      _savedCards.insert(
        0,
        SavedPaymentCard(
          id: 'card-${now.millisecondsSinceEpoch}',
          brand: brand,
          lastFour: lastFour,
          holderName: holderName,
          expiryLabel: expiryLabel,
          addedAt: now,
          isDefault: makeDefault || _savedCards.isEmpty,
        ),
      );
    }
    if (persist) {
      _emit();
    }
  }

  void setDefaultPaymentCard(String cardId) {
    _savedCards.replaceRange(
      0,
      _savedCards.length,
      _savedCards.map(
        (c) => SavedPaymentCard(
          id: c.id,
          brand: c.brand,
          lastFour: c.lastFour,
          holderName: c.holderName,
          expiryLabel: c.expiryLabel,
          addedAt: c.addedAt,
          isDefault: c.id == cardId,
        ),
      ),
    );
    _emit();
  }

  void removePaymentCard(String cardId) {
    if (_activeConnectSubscription != null) {
      final sub = _activeConnectSubscription!;
      final card = _savedCards.where((c) => c.id == cardId).firstOrNull;
      if (card != null &&
          card.lastFour == sub.cardLastFour &&
          card.brand == sub.cardBrand) {
        return;
      }
    }
    _savedCards.removeWhere((c) => c.id == cardId);
    if (_savedCards.isNotEmpty && !_savedCards.any((c) => c.isDefault)) {
      final first = _savedCards.first;
      _savedCards[0] = SavedPaymentCard(
        id: first.id,
        brand: first.brand,
        lastFour: first.lastFour,
        holderName: first.holderName,
        expiryLabel: first.expiryLabel,
        addedAt: first.addedAt,
        isDefault: true,
      );
    }
    _emit();
  }

  void _appendBilling({
    required String description,
    required double amount,
    required BillingEntryKind kind,
    String? cardLastFour,
  }) {
    final now = DateTime.now();
    _billingEntries.insert(
      0,
      BillingEntry(
        id: 'bill-${now.millisecondsSinceEpoch}',
        occurredAt: now,
        description: description,
        amount: amount,
        kind: kind,
        status: BillingEntryStatus.paid,
        cardLastFour: cardLastFour,
      ),
    );
  }

  void addSubscription({
    required Gym gym,
    required SubscriptionPlan plan,
  }) {
    final now = DateTime.now();
    _activeGymSubscription = ActiveGymSubscription(
      gymId: gym.id,
      gymName: gym.name,
      planId: plan.id,
      planName: plan.name,
      pricePerMonth: plan.pricePerMonth,
      since: now,
    );
    _wallet.insert(
      0,
      WalletItem(
        id: 'sub-${now.millisecondsSinceEpoch}',
        gym: gym,
        type: PurchaseType.subscription,
        title: 'Assinatura ${plan.name}',
        purchasedAt: now,
        planName: plan.name,
        validUntil: DateTime(now.year, now.month + 1, now.day),
      ),
    );
    _appendBilling(
      description: 'Assinatura ${plan.name} · ${gym.name}',
      amount: plan.pricePerMonth,
      kind: BillingEntryKind.gymSubscription,
    );
    _emit();
  }

  /// Motivo pelo qual não dá para trocar/definir principal (null = pode confirmar).
  String? primaryGymChangeBlockReason({required String gymId}) {
    if (_activeConnectSubscription == null) {
      return 'Ative um plano app em Minha conta antes de escolher sua academia principal.';
    }

    final current = _primaryGym;
    if (current != null && current.gymId == gymId) {
      return 'Esta unidade já é sua academia principal.';
    }

    if (current != null && !current.canChangeToAnotherGym) {
      final left = current.remainingCheckInsBeforeChange;
      return 'Faça mais $left check-in${left == 1 ? '' : 's'} na ${current.gymName} '
          'para poder trocar de academia principal.';
    }

    return null;
  }

  /// Define a academia principal via API. Retorna mensagem de erro ou null se OK.
  Future<String?> trySetPrimaryGym({required String gymId, required String gymName}) async {
    final block = primaryGymChangeBlockReason(gymId: gymId);
    if (block != null) return block;

    final connectProfile = await _fetchActiveConnectMemberProfile();
    final holder = connectProfile != null
        ? _holderNameForConnectApi(connectProfile)
        : _connectSubscriptionHolderName();
    final result = await ConnectApi().setConnectPrimaryGym(
      holderName: holder,
      unitId: gymId,
    );
    if (!result.ok) {
      return result.errorMessage ?? 'Não foi possível definir a academia principal.';
    }
    if (result.profile != null) {
      _applyConnectMemberProfile(result.profile!);
    } else {
      _primaryGym = PrimaryGymChoice(
        gymId: gymId,
        gymName: gymName,
        chosenAt: DateTime.now(),
      );
    }
    _emit();
    return null;
  }

  void _applyConnectMemberProfile(ConnectMemberProfile profile) {
    if (!profile.active) return;
    if (profile.primaryUnitId == null || profile.primaryUnitName == null) {
      return;
    }
    _primaryGym = PrimaryGymChoice(
      gymId: profile.primaryUnitId!,
      gymName: profile.primaryUnitName!,
      chosenAt: profile.primaryChosenAt != null
          ? DateTime.tryParse(profile.primaryChosenAt!) ?? DateTime.now()
          : DateTime.now(),
      firstCheckInAt: profile.primaryFirstCheckInAt != null
          ? DateTime.tryParse(profile.primaryFirstCheckInAt!)
          : null,
      checkInsSinceFirst: profile.primaryCheckInsSinceFirst,
    );
  }

  Future<void> _syncSessionFromApi() async {
    final profile = await _fetchActiveConnectMemberProfile();
    final holder = _holderNameForConnectApi(profile);
    if (holder.trim().isEmpty) return;

    if (profile != null && profile.active) {
      final plan = connectPlanById(profile.connectPlanId);
      final previous = _activeConnectSubscription;
      _activeConnectSubscription = ActiveConnectSubscription(
        planId: profile.connectPlanId,
        planName: plan?.name ?? profile.connectPlanId,
        pricePerMonth: plan?.pricePerMonth ?? previous?.pricePerMonth ?? 0,
        since: DateTime.tryParse(profile.since) ?? previous?.since ?? DateTime.now(),
        cardBrand: previous?.cardBrand ?? 'Cartão',
        cardLastFour: profile.cardLastFour ?? previous?.cardLastFour ?? '0000',
      );
      _selectedConnectPlanId = profile.connectPlanId;
      _applyConnectMemberProfile(profile);
    }

    await _syncConnectBillingFromApi(profile: profile);
    await _syncWalletFromApi(holder);
  }

  /// Atualiza apenas o extrato da assinatura (Asaas) — útil ao abrir Minha conta.
  Future<void> refreshConnectBillingStatement() async {
    await _syncConnectBillingFromApi();
    _emit();
  }

  /// Extrato da assinatura a partir do Asaas (remove lançamentos locais fictícios).
  Future<void> _syncConnectBillingFromApi({ConnectMemberProfile? profile}) async {
    profile ??= await _fetchActiveConnectMemberProfile();
    if (profile == null || !profile.active) return;

    final subscriptionId = profile.asaasSubscriptionId?.trim();
    if (subscriptionId == null || subscriptionId.isEmpty) return;

    final holder = _holderNameForConnectApi(profile);
    if (holder.trim().isEmpty) return;

    final rows = await ConnectApi().fetchConnectBillingStatement(holder);
    _billingEntries.removeWhere((e) => e.kind == BillingEntryKind.connectSubscription);

    final sub = _activeConnectSubscription;
    final fallbackLastFour = profile.cardLastFour ?? sub?.cardLastFour;

    for (final row in rows) {
      if (row.id.isEmpty) continue;
      _billingEntries.add(
        BillingEntry(
          id: 'bill-asaas-${row.id}',
          occurredAt: DateTime.tryParse(row.occurredAt) ?? DateTime.now(),
          description: row.description,
          amount: row.amount,
          kind: BillingEntryKind.connectSubscription,
          status: _billingStatusFromApiRow(row.status),
          cardLastFour: row.cardLastFour ?? fallbackLastFour,
        ),
      );
    }

    _billingEntries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<ConnectMemberProfile?> _fetchActiveConnectMemberProfile() async {
    for (final holder in _connectMemberHolderCandidates()) {
      final profile = await ConnectApi().fetchConnectMember(holder);
      if (profile != null && profile.active) {
        return profile;
      }
    }
    return null;
  }

  List<String> _connectMemberHolderCandidates() {
    final seen = <String>{};
    final out = <String>[];

    void add(String? raw) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isEmpty || trimmed == 'Associado') return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
    }

    add(_sessionHolderName());
    add(_defaultHolderName());
    if (_activeConnectSubscription != null) {
      for (final card in _savedCards) {
        add(card.holderName);
      }
    }
    return out;
  }

  String _holderNameForConnectApi(ConnectMemberProfile? profile) {
    final fromProfile = profile?.holderName.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) {
      return fromProfile;
    }
    final candidates = _connectMemberHolderCandidates();
    if (candidates.isNotEmpty) return candidates.first;
    return _sessionHolderName();
  }

  void _upsertConnectBillingRow({
    required String paymentId,
    required String description,
    required double amount,
    required String? status,
    required String? cardLastFour,
  }) {
    final id = 'bill-asaas-$paymentId';
    _billingEntries.removeWhere((e) => e.id == id);
    _billingEntries.insert(
      0,
      BillingEntry(
        id: id,
        occurredAt: DateTime.now(),
        description: description,
        amount: amount,
        kind: BillingEntryKind.connectSubscription,
        status: _billingStatusFromApiRow(status ?? 'pending'),
        cardLastFour: cardLastFour,
      ),
    );
  }

  BillingEntryStatus _billingStatusFromApiRow(String status) {
    switch (ConnectBillingStatementRow.normalizedStatus(status)) {
      case 'paid':
        return BillingEntryStatus.paid;
      case 'failed':
        return BillingEntryStatus.failed;
      default:
        return BillingEntryStatus.pending;
    }
  }

  Future<void> _syncWalletFromApi(String holderName) async {
    final associates = _associates;
    if (associates == null) return;

    final passes = await ConnectApi().fetchActiveDailyPasses(holderName);
    final subscriptions = _wallet.where((w) => w.type == PurchaseType.subscription).toList();
    final dailyItems = <WalletItem>[];

    for (final pass in passes) {
      final gym = associates.gymById(pass.unitId);
      if (gym == null) continue;
      final validUntil = DateTime.tryParse(pass.validUntil);
      final occurrence = pass.occurrenceDate;
      final purchasedAt = occurrence != null
          ? DateTime.tryParse(occurrence) ?? DateTime.now()
          : DateTime.now();
      dailyItems.add(
        WalletItem(
          id: 'daily-api-${pass.code}',
          gym: gym,
          type: PurchaseType.dailyPass,
          title: 'Diária',
          purchasedAt: purchasedAt,
          validUntil: validUntil,
          checkInCode: pass.code,
          pricePaid: pass.pricePaid,
          validWindowStart: pass.validWindowStart,
          validWindowEnd: pass.validWindowEnd,
          allowedModalities: pass.allowedModalities,
        ),
      );
    }

    _wallet
      ..clear()
      ..addAll(dailyItems)
      ..addAll(subscriptions);
  }

  Future<void> refreshConnectProfile() async {
    await _syncSessionFromApi();
    _emit();
  }

  /// Registra check-in na academia principal (conta local; API é fonte de verdade).
  void recordPrimaryGymCheckIn(String gymId) {
    final current = _primaryGym;
    if (current == null || current.gymId != gymId) return;

    final now = DateTime.now();
    if (!current.hasStartedCheckIns) {
      _primaryGym = current.copyWith(firstCheckInAt: now, checkInsSinceFirst: 1);
    } else {
      _primaryGym = current.copyWith(checkInsSinceFirst: current.checkInsSinceFirst + 1);
    }
    _emit();
  }

  String _sessionHolderName() {
    final enrollment = _companyEnrollment;
    if (enrollment?.collaboratorLabel != null &&
        enrollment!.collaboratorLabel!.trim().isNotEmpty) {
      return enrollment.collaboratorLabel!.trim();
    }
    return _defaultHolderName();
  }

  /// Titular usado em cobrança/assinatura (prioriza nome do colaborador corporativo).
  String _connectSubscriptionHolderName({String? fallbackCardHolder}) {
    final enrollment = _companyEnrollment;
    final collaborator = enrollment?.collaboratorLabel?.trim();
    if (collaborator != null && collaborator.isNotEmpty) {
      return collaborator;
    }
    final card = fallbackCardHolder?.trim();
    if (card != null && card.isNotEmpty) {
      return card;
    }
    final fromSession = _sessionHolderName();
    if (fromSession != 'Associado') {
      return fromSession;
    }
    return _dailyPassHolderName();
  }

  String _defaultHolderName() {
    for (final card in _savedCards) {
      if (card.isDefault && card.holderName.trim().isNotEmpty) {
        return card.holderName.trim();
      }
    }
    if (_savedCards.isNotEmpty && _savedCards.first.holderName.trim().isNotEmpty) {
      return _savedCards.first.holderName.trim();
    }
    return 'Associado';
  }

  static String connectCheckInCodeForUnit(String unitId) {
    final token = unitId.toUpperCase().replaceAll('-', '_');
    return 'CHK-$token-${DateTime.now().day}';
  }

  /// Check-in automático via GPS (raio de 1 km) + API do portal parceiro.
  Future<String?> performGeoCheckIn({
    required Gym gym,
    String? checkInCode,
    String? holderName,
  }) async {
    final code = checkInCode ?? connectCheckInCodeForUnit(gym.id);
    final name = holderName?.trim().isNotEmpty == true ? holderName!.trim() : _defaultHolderName();

    try {
      final position = await CheckInLocationService().resolvePosition(
        gymLatitude: gym.latitude,
        gymLongitude: gym.longitude,
      );

      if (gym.latitude != null &&
          gym.longitude != null &&
          CheckInLocationService.distanceKm(
            position.latitude,
            position.longitude,
            gym.latitude!,
            gym.longitude!,
          ) > CheckInLocationService.maxRadiusKm) {
        final km = CheckInLocationService.distanceKm(
          position.latitude,
          position.longitude,
          gym.latitude!,
          gym.longitude!,
        );
        return 'Você está ${km.toStringAsFixed(1).replaceAll('.', ',')} km de ${gym.name}. '
            'O check-in só funciona dentro de ${CheckInLocationService.maxRadiusKm} km da unidade principal.';
      }

      final result = await ConnectApi().requestGeoCheckIn(
        unitId: gym.id,
        code: code,
        holderName: name,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!result.ok) return result.message;

      await _syncSessionFromApi();
      _emit();
      return null;
    } on CheckInLocationException catch (e) {
      return e.message;
    } catch (_) {
      return 'Não foi possível completar o check-in.';
    }
  }

  Future<bool> addDailyPass({
    required Gym gym,
    required DailyPassOffer offer,
    required String paymentLabel,
    String? cardLastFour,
  }) async {
    final now = DateTime.now();
    final occurrenceDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final existing = activeDailyPassForGym(gym.id);
    if (existing != null) {
      _wallet.remove(existing);
      _wallet.insert(0, existing);
      _appendBilling(
        description: 'Diária · ${gym.name} · $paymentLabel',
        amount: offer.price,
        kind: BillingEntryKind.dailyPass,
        cardLastFour: cardLastFour,
      );
      _emit();
      return true;
    }

    final code = 'PASS-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-${gym.id.toUpperCase()}';
    final validUntil = DateTime(now.year, now.month, now.day, 23, 59);
    final holderName = _dailyPassHolderName();
    final issued = await ConnectApi().issueDailyPassCode(
      code: code,
      unitId: gym.id,
      holderName: holderName,
      validUntil: validUntil,
      offerId: offer.id,
      occurrenceDate: occurrenceDate,
      companyName: _companyEnrollment?.companyName,
    );
    if (!issued) return false;
    _wallet.insert(
      0,
      WalletItem(
        id: 'daily-${now.millisecondsSinceEpoch}',
        gym: gym,
        type: PurchaseType.dailyPass,
        title: offer.label,
        purchasedAt: now,
        validUntil: validUntil,
        checkInCode: code,
        pricePaid: offer.price,
        offerId: offer.id,
        validWindowStart: offer.startTime,
        validWindowEnd: offer.endTime,
        allowedModalities: offer.modalities,
      ),
    );
    _appendBilling(
      description: 'Diária · ${gym.name} · $paymentLabel',
      amount: offer.price,
      kind: BillingEntryKind.dailyPass,
      cardLastFour: cardLastFour,
    );
    _emit();
    return true;
  }

  String _dailyPassHolderName() {
    final enrollment = _companyEnrollment;
    if (enrollment?.collaboratorLabel != null &&
        enrollment!.collaboratorLabel!.trim().isNotEmpty) {
      return enrollment.collaboratorLabel!.trim();
    }
    return 'Colaborador';
  }
}
