import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/associates_repository.dart';
import '../models/connect_product_plan.dart';
import '../models/gym.dart';
import '../models/primary_gym.dart';
import '../models/user_account.dart';
import '../models/company_enrollment.dart';

/// Cache local leve da sessão do associado (preferências de UI e dados ainda sem endpoint dedicado).
/// Plano Connect, academia principal e diárias ativas são sincronizados com a API ao abrir o app.
class AppStatePersistence {
  AppStatePersistence({AssociatesRepository? repository})
      : _repository = repository;

  static const storageKey = 'connect_session_v1';
  static const legacyStorageKey = 'connect_mock_state_v1';

  final AssociatesRepository? _repository;

  bool _platformAvailable = true;

  String? _sessionFallbackJson;

  Future<SharedPreferences?> _prefs() async {
    if (!_platformAvailable) return null;
    try {
      return await SharedPreferences.getInstance();
    } on PlatformException catch (e, st) {
      _platformAvailable = false;
      debugPrint('Connect: SharedPreferences indisponível (${e.message}). '
          'Use flutter run (rebuild completo). Cache só nesta sessão.');
      debugPrint('$st');
      return null;
    } catch (e, st) {
      _platformAvailable = false;
      debugPrint('Connect: erro ao abrir SharedPreferences: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<AppStateSnapshot?> load() async {
    try {
      final prefs = await _prefs();
      final raw = prefs?.getString(storageKey) ??
          prefs?.getString(legacyStorageKey) ??
          _sessionFallbackJson;
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (_repository == null) return null;
      return AppStateSnapshot.fromJson(map, _repository!);
    } catch (e, st) {
      debugPrint('Connect: falha ao carregar sessão local: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<void> save(AppStateSnapshot snapshot) async {
    try {
      final encoded = jsonEncode(snapshot.toJson());
      _sessionFallbackJson = encoded;
      final prefs = await _prefs();
      if (prefs != null) {
        await prefs.setString(storageKey, encoded);
        await prefs.remove(legacyStorageKey);
      }
    } catch (e, st) {
      debugPrint('Connect: falha ao salvar sessão local: $e');
      debugPrint('$st');
    }
  }

  Future<void> clear() async {
    _sessionFallbackJson = null;
    try {
      final prefs = await _prefs();
      if (prefs != null) {
        await prefs.remove(storageKey);
        await prefs.remove(legacyStorageKey);
      }
    } catch (e, st) {
      debugPrint('Connect: falha ao limpar sessão local: $e');
      debugPrint('$st');
    }
  }
}

class AppStateSnapshot {
  AppStateSnapshot({
    required this.homeTabIndex,
    this.selectedConnectPlanId,
    this.enrollment,
    this.activeConnect,
    this.activeGymSubscription,
    this.primaryGym,
    this.wallet = const [],
    this.savedCards = const [],
    this.billingEntries = const [],
  });

  final int homeTabIndex;
  final String? selectedConnectPlanId;
  final CompanyEnrollment? enrollment;
  final ActiveConnectSubscription? activeConnect;
  final ActiveGymSubscription? activeGymSubscription;
  final PrimaryGymChoice? primaryGym;
  final List<WalletItem> wallet;
  final List<SavedPaymentCard> savedCards;
  final List<BillingEntry> billingEntries;

  Map<String, dynamic> toJson() => {
        'v': 1,
        'homeTabIndex': homeTabIndex,
        'selectedConnectPlanId': selectedConnectPlanId,
        'enrollment': enrollment == null
            ? null
            : {
                'companyName': enrollment!.companyName,
                'code': enrollment!.code,
                'collaboratorLabel': enrollment!.collaboratorLabel,
              },
        'activeConnect': activeConnect == null
            ? null
            : {
                'planId': activeConnect!.planId,
                'planName': activeConnect!.planName,
                'pricePerMonth': activeConnect!.pricePerMonth,
                'since': activeConnect!.since.toIso8601String(),
                'cardBrand': activeConnect!.cardBrand,
                'cardLastFour': activeConnect!.cardLastFour,
              },
        'activeGymSubscription': activeGymSubscription == null
            ? null
            : {
                'gymId': activeGymSubscription!.gymId,
                'gymName': activeGymSubscription!.gymName,
                'planId': activeGymSubscription!.planId,
                'planName': activeGymSubscription!.planName,
                'pricePerMonth': activeGymSubscription!.pricePerMonth,
                'since': activeGymSubscription!.since.toIso8601String(),
              },
        'primaryGym': primaryGym == null
            ? null
            : {
                'gymId': primaryGym!.gymId,
                'gymName': primaryGym!.gymName,
                'chosenAt': primaryGym!.chosenAt.toIso8601String(),
                'firstCheckInAt': primaryGym!.firstCheckInAt?.toIso8601String(),
                'checkInsSinceFirst': primaryGym!.checkInsSinceFirst,
              },
        'wallet': wallet
            .map(
              (w) => {
                'id': w.id,
                'gymId': w.gym.id,
                'type': w.type.name,
                'title': w.title,
                'purchasedAt': w.purchasedAt.toIso8601String(),
                'planName': w.planName,
                'validUntil': w.validUntil?.toIso8601String(),
                'checkInCode': w.checkInCode,
              },
            )
            .toList(),
        'savedCards': savedCards
            .map(
              (c) => {
                'id': c.id,
                'brand': c.brand,
                'lastFour': c.lastFour,
                'holderName': c.holderName,
                'expiryLabel': c.expiryLabel,
                'addedAt': c.addedAt.toIso8601String(),
                'isDefault': c.isDefault,
              },
            )
            .toList(),
        'billingEntries': billingEntries
            .map(
              (b) => {
                'id': b.id,
                'occurredAt': b.occurredAt.toIso8601String(),
                'description': b.description,
                'amount': b.amount,
                'kind': b.kind.name,
                'status': b.status.name,
                'cardLastFour': b.cardLastFour,
              },
            )
            .toList(),
      };

  static AppStateSnapshot? fromJson(Map<String, dynamic> json, AssociatesRepository repository) {
    if (json['v'] != 1) return null;

    CompanyEnrollment? enrollment;
    final e = json['enrollment'];
    if (e is Map<String, dynamic>) {
      enrollment = CompanyEnrollment(
        companyName: e['companyName'] as String,
        code: e['code'] as String,
        collaboratorLabel: e['collaboratorLabel'] as String?,
      );
    }

    ActiveConnectSubscription? activeConnect;
    final ac = json['activeConnect'];
    if (ac is Map<String, dynamic>) {
      activeConnect = ActiveConnectSubscription(
        planId: ac['planId'] as String,
        planName: ac['planName'] as String,
        pricePerMonth: (ac['pricePerMonth'] as num).toDouble(),
        since: DateTime.parse(ac['since'] as String),
        cardBrand: ac['cardBrand'] as String,
        cardLastFour: ac['cardLastFour'] as String,
      );
    }

    ActiveGymSubscription? activeGymSubscription;
    final ag = json['activeGymSubscription'];
    if (ag is Map<String, dynamic>) {
      activeGymSubscription = ActiveGymSubscription(
        gymId: ag['gymId'] as String,
        gymName: ag['gymName'] as String,
        planId: ag['planId'] as String,
        planName: ag['planName'] as String,
        pricePerMonth: (ag['pricePerMonth'] as num).toDouble(),
        since: DateTime.parse(ag['since'] as String),
      );
    }

    PrimaryGymChoice? primaryGym;
    final pg = json['primaryGym'];
    if (pg is Map<String, dynamic>) {
      primaryGym = PrimaryGymChoice(
        gymId: pg['gymId'] as String,
        gymName: pg['gymName'] as String,
        chosenAt: DateTime.parse(pg['chosenAt'] as String),
        firstCheckInAt: pg['firstCheckInAt'] != null
            ? DateTime.parse(pg['firstCheckInAt'] as String)
            : null,
        checkInsSinceFirst: pg['checkInsSinceFirst'] as int? ?? 0,
      );
    }

    final wallet = <WalletItem>[];
    final walletRaw = json['wallet'];
    if (walletRaw is List) {
      for (final item in walletRaw) {
        if (item is! Map<String, dynamic>) continue;
        final gymId = item['gymId'] as String?;
        final gym = gymId == null ? null : repository.gymById(gymId);
        if (gym == null) continue;
        final typeName = item['type'] as String?;
        final type = PurchaseType.values.where((v) => v.name == typeName).firstOrNull;
        if (type == null) continue;
        final id = item['id'] as String? ?? 'legacy-${item['purchasedAt']}-${gym.id}';
        wallet.add(
          WalletItem(
            id: id,
            gym: gym,
            type: type,
            title: item['title'] as String? ?? 'Item',
            purchasedAt: DateTime.parse(item['purchasedAt'] as String),
            planName: item['planName'] as String?,
            validUntil: item['validUntil'] != null ? DateTime.parse(item['validUntil'] as String) : null,
            checkInCode: item['checkInCode'] as String?,
          ),
        );
      }
    }

    final savedCards = <SavedPaymentCard>[];
    final cardsRaw = json['savedCards'];
    if (cardsRaw is List) {
      for (final item in cardsRaw) {
        if (item is! Map<String, dynamic>) continue;
        savedCards.add(
          SavedPaymentCard(
            id: item['id'] as String,
            brand: item['brand'] as String,
            lastFour: item['lastFour'] as String,
            holderName: item['holderName'] as String,
            expiryLabel: item['expiryLabel'] as String,
            addedAt: DateTime.parse(item['addedAt'] as String),
            isDefault: item['isDefault'] as bool? ?? false,
          ),
        );
      }
    }

    final billingEntries = <BillingEntry>[];
    final billingRaw = json['billingEntries'];
    if (billingRaw is List) {
      for (final item in billingRaw) {
        if (item is! Map<String, dynamic>) continue;
        final kind = BillingEntryKind.values.where((v) => v.name == item['kind']).firstOrNull;
        final status = BillingEntryStatus.values.where((v) => v.name == item['status']).firstOrNull;
        if (kind == null || status == null) continue;
        billingEntries.add(
          BillingEntry(
            id: item['id'] as String,
            occurredAt: DateTime.parse(item['occurredAt'] as String),
            description: item['description'] as String,
            amount: (item['amount'] as num).toDouble(),
            kind: kind,
            status: status,
            cardLastFour: item['cardLastFour'] as String?,
          ),
        );
      }
    }

    return AppStateSnapshot(
      homeTabIndex: json['homeTabIndex'] as int? ?? 0,
      selectedConnectPlanId: json['selectedConnectPlanId'] as String?,
      enrollment: enrollment,
      activeConnect: activeConnect,
      activeGymSubscription: activeGymSubscription,
      primaryGym: primaryGym,
      wallet: wallet,
      savedCards: savedCards,
      billingEntries: billingEntries,
    );
  }
}
