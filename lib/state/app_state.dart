import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/connect_plans.dart';
import '../data/mock_enrollment_codes.dart';
import '../models/connect_product_plan.dart';
import '../models/gym.dart';
import '../services/gym_portal_api.dart';
import '../models/primary_gym.dart';
import '../models/user_account.dart';
import 'app_state_persistence.dart';

class AppState extends ChangeNotifier {
  AppState({AppStatePersistence? persistence})
      : _persistence = persistence ?? AppStatePersistence();

  final AppStatePersistence _persistence;

  final List<WalletItem> _wallet = [];
  final List<SavedPaymentCard> _savedCards = [];
  final List<BillingEntry> _billingEntries = [];
  int homeTabIndex = 0;

  String? _selectedConnectPlanId;
  ActiveConnectSubscription? _activeConnectSubscription;
  ActiveGymSubscription? _activeGymSubscription;
  PrimaryGymChoice? _primaryGym;
  CompanyEnrollment? _companyEnrollment;

  bool _persistReady = false;

  bool get persistencePlatformAvailable => _persistence.platformAvailable;

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

  /// Plano Connect com cartão cadastrado, assinatura em unidade ou equivalente.
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
    _persistReady = true;
    notifyListeners();
  }

  /// Apaga vínculos, carteira, cartões e extrato — útil para recomeçar a demo.
  Future<void> resetDemoData() async {
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

  /// Valida código de adesão da empresa. Retorna mensagem de erro ou null se OK.
  String? redeemEnrollmentCode(String code, {String? collaboratorName}) {
    final invite = findEnrollmentInvite(code);
    if (invite == null) {
      return 'Código inválido ou expirado. Verifique com o RH da sua empresa.';
    }
    _companyEnrollment = CompanyEnrollment(
      companyName: invite.companyName,
      code: invite.code,
      collaboratorLabel: collaboratorName?.trim().isEmpty ?? true ? null : collaboratorName!.trim(),
    );
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

  /// Confirma assinatura Connect após checkout (mock — tokenização real virá da API).
  void activateConnectPlan({
    required String planId,
    required String cardBrand,
    required String cardLastFour,
    String? holderName,
    String? expiryLabel,
  }) {
    final plan = connectPlanById(planId);
    if (plan == null) return;

    final now = DateTime.now();
    _selectedConnectPlanId = planId;
    _activeConnectSubscription = ActiveConnectSubscription(
      planId: plan.id,
      planName: plan.name,
      pricePerMonth: plan.pricePerMonth,
      since: now,
      cardBrand: cardBrand,
      cardLastFour: cardLastFour,
    );

    registerPaymentCard(
      brand: cardBrand,
      lastFour: cardLastFour,
      holderName: holderName ?? 'Titular',
      expiryLabel: expiryLabel ?? '—',
      makeDefault: true,
      persist: false,
    );

    _billingEntries.insert(
      0,
      BillingEntry(
        id: 'bill-${now.millisecondsSinceEpoch}',
        occurredAt: now,
        description: 'Assinatura ${plan.name}',
        amount: plan.pricePerMonth,
        kind: BillingEntryKind.connectSubscription,
        status: BillingEntryStatus.paid,
        cardLastFour: cardLastFour,
      ),
    );

    _emit();
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
      return 'Ative um plano ACAF Connect em Minha conta antes de escolher sua academia principal.';
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

  /// Define a academia principal. Retorna mensagem de erro ou null se OK.
  String? trySetPrimaryGym({required String gymId, required String gymName}) {
    final block = primaryGymChangeBlockReason(gymId: gymId);
    if (block != null) return block;

    final now = DateTime.now();
    _primaryGym = PrimaryGymChoice(
      gymId: gymId,
      gymName: gymName,
      chosenAt: now,
    );
    _emit();
    return null;
  }

  /// Registra check-in na academia principal (conta para regra de permanência).
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

  void addDailyPass({
    required Gym gym,
    required String paymentLabel,
    String? cardLastFour,
  }) {
    final now = DateTime.now();
    final existing = activeDailyPassForGym(gym.id);
    if (existing != null) {
      _wallet.remove(existing);
      _wallet.insert(0, existing);
      _appendBilling(
        description: 'Diária · ${gym.name} · $paymentLabel',
        amount: gym.dailyPassPrice,
        kind: BillingEntryKind.dailyPass,
        cardLastFour: cardLastFour,
      );
      _emit();
      return;
    }

    final code = 'ACAF-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-${gym.id.toUpperCase()}';
    final validUntil = DateTime(now.year, now.month, now.day, 23, 59);
    GymPortalApi().issueDailyPassCode(
      code: code,
      unitId: gym.id,
      holderName: 'Associado app',
      validUntil: validUntil,
    );
    _wallet.insert(
      0,
      WalletItem(
        id: 'daily-${now.millisecondsSinceEpoch}',
        gym: gym,
        type: PurchaseType.dailyPass,
        title: 'Diária',
        purchasedAt: now,
        validUntil: validUntil,
        checkInCode: code,
      ),
    );
    _appendBilling(
      description: 'Diária · ${gym.name} · $paymentLabel',
      amount: gym.dailyPassPrice,
      kind: BillingEntryKind.dailyPass,
      cardLastFour: cardLastFour,
    );
    _emit();
  }
}
