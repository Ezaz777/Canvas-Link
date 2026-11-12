import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'api_service.dart';
import '../utils/settings.dart';

class PurchaseService {
  static final PurchaseService instance = PurchaseService._internal();
  PurchaseService._internal();

  static const String proProductId = 'canvas_link_pro_lifetime';
  static const Set<String> _productIds = {proProductId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  ProductDetails? _proProduct;
  ProductDetails? get proProduct => _proProduct;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ApiService? _apiService;

  final ValueNotifier<bool> isProNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isProcessingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> purchaseErrorNotifier = ValueNotifier<String?>(null);

  /// Initialize In-App Purchase service, load local status, and listen to purchase updates.
  Future<void> initialize(ApiService? apiService) async {
    _apiService = apiService;
    isProNotifier.value = await Settings.isPro();

    // Check with backend if logged in
    _syncStatusWithBackend();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('[PurchaseService] InAppPurchase store unavailable on this device');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (error) {
        debugPrint('[PurchaseService] purchaseStream error: $error');
        isProcessingNotifier.value = false;
      },
    );

    await loadProducts();
  }

  Future<void> updateApiService(ApiService? apiService) async {
    _apiService = apiService;
    if (apiService == null) {
      await resetOnLogout();
      return;
    }
    await _syncStatusWithBackend();
  }

  /// Clear cached Pro state on logout so switching accounts never leaks Pro status.
  Future<void> resetOnLogout() async {
    _apiService = null;
    _errorMessage = null;
    purchaseErrorNotifier.value = null;
    isProcessingNotifier.value = false;
    await Settings.setPro(false);
    isProNotifier.value = false;
  }

  /// Update local and in-memory Pro status from a server response flag.
  Future<void> syncProStatusFromFlag(bool isPro) async {
    await Settings.setPro(isPro);
    isProNotifier.value = isPro;
  }

  Future<void> _syncStatusWithBackend() async {
    if (_apiService == null) return;
    try {
      final status = await _apiService!.getUserStatus();
      final isPro = status['is_pro'] == true;
      await Settings.setPro(isPro);
      isProNotifier.value = isPro;
    } catch (e) {
      debugPrint('[PurchaseService] Status sync error: $e');
    }
  }

  /// Load available products from Google Play
  Future<void> loadProducts() async {
    if (!_isAvailable) return;
    try {
      _isLoading = true;
      final response = await _iap.queryProductDetails(_productIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[PurchaseService] Products not found: ${response.notFoundIDs}');
      }
      if (response.productDetails.isNotEmpty) {
        _proProduct = response.productDetails.firstWhere(
          (p) => p.id == proProductId,
          orElse: () => response.productDetails.first,
        );
      }
    } catch (e) {
      debugPrint('[PurchaseService] Failed to load products: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  /// Launch purchase flow for Pinterest Auto Wallpaper Pro Lifetime
  Future<bool> buyPro() async {
    _errorMessage = null;
    purchaseErrorNotifier.value = null;

    if (!_isAvailable) {
      _errorMessage = 'Google Play Store is not available on this device';
      purchaseErrorNotifier.value = _errorMessage;
      return false;
    }

    if (_proProduct == null) {
      await loadProducts();
    }

    if (_proProduct == null) {
      _errorMessage = 'Product details not loaded from Google Play yet. Please try again.';
      purchaseErrorNotifier.value = _errorMessage;
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: _proProduct!);
    try {
      isProcessingNotifier.value = true;
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        isProcessingNotifier.value = false;
      }
      return started;
    } catch (e) {
      _errorMessage = e.toString();
      purchaseErrorNotifier.value = _errorMessage;
      isProcessingNotifier.value = false;
      debugPrint('[PurchaseService] buyNonConsumable error: $e');
      return false;
    }
  }

  /// Restore past purchases
  Future<void> restorePurchases() async {
    _errorMessage = null;
    purchaseErrorNotifier.value = null;

    if (!_isAvailable) {
      _errorMessage = 'Google Play Store is not available on this device';
      purchaseErrorNotifier.value = _errorMessage;
      return;
    }
    try {
      isProcessingNotifier.value = true;
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = e.toString();
      purchaseErrorNotifier.value = _errorMessage;
      debugPrint('[PurchaseService] restorePurchases error: $e');
    } finally {
      isProcessingNotifier.value = false;
    }
  }

  /// Handle incoming purchase stream updates from Google Play
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[PurchaseService] Purchase is pending...');
        isProcessingNotifier.value = true;
      } else {
        bool shouldComplete = true;

        if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('[PurchaseService] Purchase canceled by user');
          _errorMessage = null;
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('[PurchaseService] Purchase error: ${purchaseDetails.error}');
          _errorMessage = purchaseDetails.error?.message ?? 'Purchase failed.';
          purchaseErrorNotifier.value = _errorMessage;
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify with backend before activating locally or acknowledging
          shouldComplete = await _verifyAndActivate(purchaseDetails);
        }

        isProcessingNotifier.value = false;

        if (shouldComplete && purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyAndActivate(PurchaseDetails purchaseDetails) async {
    final token = purchaseDetails.verificationData.serverVerificationData;
    final productId = purchaseDetails.productID;
    final orderId = purchaseDetails.purchaseID;

    if (_apiService == null) {
      _errorMessage = 'Please log in before activating Pinterest Auto Wallpaper Pro.';
      purchaseErrorNotifier.value = _errorMessage;
      return false;
    }

    try {
      final res = await _apiService!.verifyPurchase(
        productId: productId,
        purchaseToken: token,
        orderId: orderId,
      );
      if (res['success'] == true) {
        await Settings.setPro(true);
        isProNotifier.value = true;
        debugPrint('[PurchaseService] Pinterest Auto Wallpaper Pro verified and activated!');
        return true;
      }
      _errorMessage = res['error']?.toString() ?? 'Could not verify purchase.';
      purchaseErrorNotifier.value = _errorMessage;
      return false;
    } catch (e) {
      debugPrint('[PurchaseService] Backend verifyPurchase failed: $e');
      _errorMessage = e.toString();
      purchaseErrorNotifier.value = _errorMessage;
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    isProNotifier.dispose();
    isProcessingNotifier.dispose();
    purchaseErrorNotifier.dispose();
  }
}

