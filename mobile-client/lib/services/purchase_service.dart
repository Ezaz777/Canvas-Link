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

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        debugPrint('[PurchaseService] purchaseStream error: $error');
      },
    );

    await loadProducts();
  }

  void updateApiService(ApiService? apiService) {
    _apiService = apiService;
    _syncStatusWithBackend();
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

  /// Launch purchase flow for Canvas Link Pro Lifetime
  Future<bool> buyPro() async {
    if (!_isAvailable) {
      _errorMessage = 'Google Play Store is not available on this device';
      return false;
    }

    if (_proProduct == null) {
      await loadProducts();
    }

    if (_proProduct == null) {
      _errorMessage = 'Product details not loaded from Google Play yet. Please try again.';
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: _proProduct!);
    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[PurchaseService] buyNonConsumable error: $e');
      return false;
    }
  }

  /// Restore past purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('[PurchaseService] restorePurchases error: $e');
    }
  }

  /// Handle incoming purchase stream updates from Google Play
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[PurchaseService] Purchase is pending...');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('[PurchaseService] Purchase error: ${purchaseDetails.error}');
          _errorMessage = purchaseDetails.error?.message;
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify with backend
          await _verifyAndActivate(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchaseDetails) async {
    final token = purchaseDetails.verificationData.serverVerificationData;
    final productId = purchaseDetails.productID;
    final orderId = purchaseDetails.purchaseID;

    bool backendSuccess = false;
    if (_apiService != null) {
      try {
        final res = await _apiService!.verifyPurchase(
          productId: productId,
          purchaseToken: token,
          orderId: orderId,
        );
        backendSuccess = res['success'] == true;
      } catch (e) {
        debugPrint('[PurchaseService] Backend verifyPurchase failed: $e');
      }
    }

    // Always grant locally if Google Play confirmed purchase
    await Settings.setPro(true);
    isProNotifier.value = true;
    debugPrint('[PurchaseService] Canvas Link Pro successfully activated! (Backend confirmed: $backendSuccess)');
  }

  void dispose() {
    _subscription?.cancel();
  }
}

