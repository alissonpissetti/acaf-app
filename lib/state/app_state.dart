import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/associates_repository.dart';
import '../data/connect_plans.dart';
import '../models/company_enrollment.dart';
import '../models/connect_product_plan.dart';
import '../models/daily_pass_offer.dart';
import '../models/gym.dart';
import '../services/check_in_location.dart';
import '../services/acaf_api.dart';
import '../models/primary_gym.dart';
import '../models/user_account.dart';
import 'app_state_persistence.dart';

class AppState extends ChangeNotifier {
  AppState({
    AppStatePersistence? persistence,
    AssociatesRepository? associatesRepository,
  })  : _persistence = persistence ?? AppStatePersistence(),
        _associates = associatesRepository;

  final AppStatePersistence _persistence;
  final AssociatesRepository? _associates;

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
    await _syncSessionFromApi();
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
    final result = await AcafApi().validateEnrollmentCode(code);
    if (!result.ok) {
      return result.errorMessage ??
          'Código inválido ou expirado. Verifique com o RH da sua empresa.';
    }
    _companyEnrollment = CompanyEnrollment(
      companyName: result.companyName ?? 'Empresa',
      code: result.code ?? code.trim(),
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

  /// Confirma assinatura Connect após checkout e registra na API.
  Future<void> activateConnectPlan({
    required String planId,
    required String cardBrand,
    required String cardLastFour,
    String? holderName,
    String? expiryLabel,
  }) async {
    final plan = connectPlanById(planId);
    if (plan == null) return;

    final now = DateTime.now();
    final holder = holderName?.trim().isNotEmpty == true ? holderName!.trim() : 'Titular';
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
      holderName: holder,
      expiryLabel: expiryLabel ?? '—',
      makeDefault: true,
      persist: false,
    );

    await AcafApi().registerConnectSubscription(
      holderName: _defaultHolderName(),
      connectPlanId: planId,
      companyName: _companyEnrollment?.companyName,
    );
    await _syncSessionFromApi();
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

  /// Define a academia principal via API. Retorna mensagem de erro ou null se OK.
  Future<String?> trySetPrimaryGym({required String gymId, required String gymName}) async {
    final block = primaryGymChangeBlockReason(gymId: gymId);
    if (block != null) return block;

    final result = await AcafApi().setConnectPrimaryGym(
      holderName: _defaultHolderName(),
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
    final holder = _sessionHolderName();
    if (holder.trim().isEmpty) return;

    final profile = await AcafApi().fetchConnectMember(holder);
    if (profile != null && profile.active) {
      final plan = connectPlanById(profile.connectPlanId);
      final previous = _activeConnectSubscription;
      _activeConnectSubscription = ActiveConnectSubscription(
        planId: profile.connectPlanId,
        planName: plan?.name ?? profile.connectPlanId,
        pricePerMonth: plan?.pricePerMonth ?? previous?.pricePerMonth ?? 0,
        since: DateTime.tryParse(profile.since) ?? previous?.since ?? DateTime.now(),
        cardBrand: previous?.cardBrand ?? 'Cartão',
        cardLastFour: previous?.cardLastFour ?? '0000',
      );
      _selectedConnectPlanId = profile.connectPlanId;
      _applyConnectMemberProfile(profile);
      _rebuildConnectBillingEntries();
    } else if (_activeConnectSubscription != null) {
      _rebuildConnectBillingEntries();
    }

    await _syncWalletFromApi(holder);
  }

  /// Mensalidades do plano Connect (valor do colaborador), últimos 3 meses.
  void _rebuildConnectBillingEntries() {
    final sub = _activeConnectSubscription;
    if (sub == null) return;

    _billingEntries.removeWhere(
      (e) =>
          e.kind == BillingEntryKind.connectSubscription ||
          (e.kind == BillingEntryKind.gymSubscription && e.description.contains(sub.planName)),
    );

    final since = sub.since;
    final billingDay = since.day;
    final billingTime = DateTime(since.year, since.month, since.day, since.hour, since.minute);
    final now = DateTime.now();

    for (var monthsBack = 0; monthsBack < 3; monthsBack++) {
      final anchor = DateTime(now.year, now.month - monthsBack, 1);
      final day = billingDay.clamp(1, _daysInMonth(anchor.year, anchor.month));
      final occurredAt = DateTime(
        anchor.year,
        anchor.month,
        day,
        billingTime.hour,
        billingTime.minute,
      );
      if (occurredAt.isBefore(billingTime)) continue;

      _billingEntries.add(
        BillingEntry(
          id: 'bill-connect-${anchor.year}-${anchor.month.toString().padLeft(2, '0')}',
          occurredAt: occurredAt,
          description: 'Mensalidade ${sub.planName}',
          amount: sub.pricePerMonth,
          kind: BillingEntryKind.connectSubscription,
          status: BillingEntryStatus.paid,
          cardLastFour: sub.cardLastFour,
        ),
      );
    }

    _billingEntries.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  Future<void> _syncWalletFromApi(String holderName) async {
    final associates = _associates;
    if (associates == null) return;

    final passes = await AcafApi().fetchActiveDailyPasses(holderName);
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

  String _defaultHolderName() {
    for (final card in _savedCards) {
      if (card.isDefault && card.holderName.trim().isNotEmpty) {
        return card.holderName.trim();
      }
    }
    if (_savedCards.isNotEmpty && _savedCards.first.holderName.trim().isNotEmpty) {
      return _savedCards.first.holderName.trim();
    }
    return 'Associado ACAF Connect';
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

      final result = await AcafApi().requestGeoCheckIn(
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

    final code = 'ACAF-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}-${gym.id.toUpperCase()}';
    final validUntil = DateTime(now.year, now.month, now.day, 23, 59);
    final holderName = _dailyPassHolderName();
    final issued = await AcafApi().issueDailyPassCode(
      code: code,
      unitId: gym.id,
      holderName: holderName,
      validUntil: validUntil,
      offerId: offer.id,
      occurrenceDate: occurrenceDate,
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
    if (enrollment?.companyName != null && enrollment!.companyName.trim().isNotEmpty) {
      return enrollment.companyName.trim();
    }
    return 'Visitante app';
  }
}
