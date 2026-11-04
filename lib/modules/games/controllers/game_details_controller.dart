import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../repositories/games_repository.dart';
import '../../wallet/repositories/wallet_repository.dart';
import '../../wallet/datasources/wallet_remote_datasource.dart';
import '../../../data/models/game_model.dart';
import '../../../data/models/video_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../app/theme/app_colors.dart';
import '../../notifications/services/socket_notification_service.dart';

class GameDetailsController extends GetxController {
  final GamesRepository repository = Get.find<GamesRepository>();

  WalletRepository get _walletRepo {
    if (Get.isRegistered<WalletRepository>()) {
      return Get.find<WalletRepository>();
    } else {
      final dio = Get.find<DioClient>();
      final ds = WalletRemoteDataSource(dioClient: dio);
      return WalletRepository(remoteDataSource: ds);
    }
  }

  late Razorpay _razorpay;

  final Rxn<GameModel> game = Rxn<GameModel>();
  final RxList<GameRosterPlayerModel> teamARoster =
      <GameRosterPlayerModel>[].obs;
  final RxList<GameRosterPlayerModel> teamBRoster =
      <GameRosterPlayerModel>[].obs;
  final RxList<VideoModel> matchVideos = <VideoModel>[].obs;
  final Rxn<VideoModel> selectedVideo = Rxn<VideoModel>();

  final RxBool isLoading = false.obs;
  final RxBool isJoining = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxString paymentStatus = ''.obs;

  final RxString selectedPosition = 'ST'.obs;
  final RxString selectedJoinPaymentMethod = 'RAZORPAY'.obs;
  final RxDouble walletBalance = 0.0.obs;

  final RxnString currentPaymentOrderId = RxnString();
  final RxnString currentRazorpayOrderId = RxnString();

  String _gameId = '';

  String get gameId {
    if (_gameId.isNotEmpty) return _gameId;
    if (game.value?.id != null && game.value!.id.isNotEmpty) {
      _gameId = game.value!.id;
      return _gameId;
    }

    final paramId = Get.parameters['id'] ?? Get.parameters['gameId'];
    if (paramId != null && paramId.isNotEmpty) {
      _gameId = paramId;
      return _gameId;
    }

    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      _gameId = args;
      return _gameId;
    }
    if (args is Map) {
      if (args['gameId'] != null && args['gameId'].toString().isNotEmpty) {
        _gameId = args['gameId'].toString();
        return _gameId;
      }
      if (args['id'] != null && args['id'].toString().isNotEmpty) {
        _gameId = args['id'].toString();
        return _gameId;
      }
      if (args['game'] is GameModel) {
        _gameId = (args['game'] as GameModel).id;
        return _gameId;
      }
    }
    if (args is GameModel) {
      _gameId = args.id;
      return _gameId;
    }
    return '';
  }

  @override
  void onInit() {
    super.onInit();
    _initRazorpay();
    final args = Get.arguments;
    if (args is Map && args['game'] is GameModel) {
      game.value = args['game'] as GameModel;
    } else if (args is GameModel) {
      game.value = args;
    }
    _gameId = gameId;
    if (_gameId.isNotEmpty) {
      loadGameDetails();
    }
    fetchWalletBalance();
    _initSocketListeners();
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> fetchWalletBalance() async {
    if (Get.isRegistered<AuthService>() && !AuthService.to.isPlayer) {
      walletBalance.value = 0.0;
      return;
    }
    try {
      final w = await _walletRepo.getWallet();
      walletBalance.value = w.balance;
    } catch (_) {
      walletBalance.value = 0.0;
    }
  }

  Future<void> loadGameDetails() async {
    final targetId = gameId;
    if (targetId.isEmpty) return;
    isLoading.value = true;
    matchVideos.clear();
    selectedVideo.value = null;
    try {
      final g = await repository.getGameById(targetId);
      game.value = g;
      if (_gameId.isEmpty) _gameId = g.id;

      if (g.roster != null) {
        teamARoster.value = g.roster!.where((p) => p.isTeamA).toList();
        teamBRoster.value = g.roster!.where((p) => p.isTeamB).toList();
      }

      if (g.status == 'COMPLETED' || isUserInGame || isManagerOrAdmin) {
        try {
          final vids = await repository.getGameVideos(targetId);
          matchVideos.value = vids;
          if (vids.isNotEmpty) {
            selectedVideo.value = vids.first;
          } else {
            selectedVideo.value = null;
          }
        } catch (_) {
          matchVideos.clear();
          selectedVideo.value = null;
        }
      } else {
        matchVideos.clear();
        selectedVideo.value = null;
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isLoading.value = false;
    }
  }

  bool get isUserInGame {
    final uid = AuthService.to.currentUser.value?.id;
    if (uid == null || game.value?.roster == null) return false;
    return game.value!.roster!.any((p) => p.userId == uid);
  }

  String? get userTeam {
    final uid = AuthService.to.currentUser.value?.id;
    if (uid == null || game.value?.roster == null) return null;
    final match = game.value!.roster!.firstWhereOrNull((p) => p.userId == uid);
    return match?.team;
  }

  void selectCamera(VideoModel video) {
    selectedVideo.value = video;
  }

  bool get isManagerOrAdmin {
    final role = AuthService.to.currentUser.value?.roleId;
    return role == 1 || role == 2;
  }

  void requestJoinMatch(BuildContext context, VoidCallback showSheetCallback) {
    final fee = game.value?.perPlayerFee ?? 200.0;

    if (fee <= 0 || isManagerOrAdmin) {
      _executeJoinGameOnServer(position: selectedPosition.value);
    } else {
      showSheetCallback();
    }
  }

  Future<void> executeJoinPaymentAndJoinGame() async {
    final fee = game.value?.perPlayerFee ?? 200.0;

    if (selectedJoinPaymentMethod.value == 'WALLET') {
      try {
        final w = await _walletRepo.getWallet();
        if (!w.hasPin) {
          ErrorHandler.showErrorSnackBar(
            'PIN Setup Required',
            'Wallet 6-digit PIN setup is required before making payments. Please set up your PIN in Player Wallet.',
          );
          return;
        }
      } catch (_) {}

      if (walletBalance.value < fee) {
        ErrorHandler.showErrorSnackBar(
          'Insufficient Wallet Balance',
          'Your wallet balance is ₹${walletBalance.value.toStringAsFixed(0)}. Please choose Razorpay.',
        );
        return;
      }

      _promptPinAndAuthorizeWalletPayment(fee: fee);
      return;
    }

    isProcessingPayment.value = true;
    paymentStatus.value = 'Creating Order...';

    try {
      final targetGameId = gameId.isNotEmpty ? gameId : (game.value?.id ?? '');
      final order =
          await repository.createMatchOrder(fee, gameId: targetGameId);

      currentRazorpayOrderId.value = order.orderId;

      final user = AuthService.to.currentUser.value;
      final contact =
          (user != null && user.phone.isNotEmpty) ? user.phone : '9876543210';
      final email = (user != null && user.email.isNotEmpty)
          ? user.email
          : 'player@smashupindia.com';

      final key =
          order.keyId.isNotEmpty ? order.keyId : ApiConstants.razorpayKey;

      final options = {
        'key': key,
        'amount':
            order.amountPaisa > 0 ? order.amountPaisa : (fee * 100).toInt(),
        'name': 'SMASH UP INDIA',
        'description':
            'Player Entry Fee - ${game.value?.title ?? "Pickle Match"}',
        if (order.orderId.isNotEmpty &&
            !order.orderId.startsWith('rzp_order_mock_'))
          'order_id': order.orderId,
        'retry': {'enabled': true, 'max_count': 1},
        'prefill': {
          'contact': contact,
          'email': email,
        },
        'theme': {'color': '#2EA44F'},
      };

      paymentStatus.value = 'Waiting for Payment...';
      _razorpay.open(options);
    } catch (e) {
      isProcessingPayment.value = false;
      ErrorHandler.showErrorSnackBar('Payment Error', e);
    }
  }

  void _promptPinAndAuthorizeWalletPayment({required double fee}) {
    final pinController = TextEditingController();

    Get.dialog(
      Builder(
        builder: (context) {
          return AlertDialog(
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: context.borderColor),
            ),
            title: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Authorize Payment',
                    style: TextStyle(color: context.textPrimary, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your 6-digit Wallet PIN to authorize payment of ₹${fee.toStringAsFixed(0)}.',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(
                      color: context.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit PIN',
                    hintStyle:
                        TextStyle(color: context.textSecondary, fontSize: 13),
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: context.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel',
                    style: TextStyle(color: context.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.length != 6) {
                    ErrorHandler.showErrorSnackBar(
                        'Invalid PIN', 'Please enter a 6-digit PIN');
                    return;
                  }

                  try {
                    Get.back();
                    isProcessingPayment.value = true;
                    paymentStatus.value = 'Authorizing & Joining Match...';
                    await _executeJoinGameOnServer(
                      position: selectedPosition.value,
                      paymentMethod: 'WALLET',
                      walletPin: pin,
                    );
                  } catch (e) {
                    isProcessingPayment.value = false;
                    ErrorHandler.showErrorSnackBar('Authorization Failed', e);
                  }
                },
                child: const Text('Authorize & Pay',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> processTestModeJoinPayment() async {
    isProcessingPayment.value = true;
    paymentStatus.value = 'Opening Razorpay (Test Mode)...';
    await Future.delayed(const Duration(milliseconds: 600));

    paymentStatus.value = 'Verifying Payment...';
    await Future.delayed(const Duration(milliseconds: 600));

    paymentStatus.value = 'Finalizing Match Roster...';
    await Future.delayed(const Duration(milliseconds: 500));

    await _executeJoinGameOnServer(
      position: selectedPosition.value,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    paymentStatus.value = 'Payment Verified! Finalizing Roster...';

    try {
      final razorpayOrderIdToUse =
          (response.orderId != null && response.orderId!.isNotEmpty)
              ? response.orderId!
              : (currentRazorpayOrderId.value ?? '');

      await _executeJoinGameOnServer(
        position: selectedPosition.value,
        paymentMethod: 'RAZORPAY',
        razorpayOrderId: razorpayOrderIdToUse,
        razorpayPaymentId: response.paymentId,
        razorpaySignature: response.signature,
      );
    } catch (e) {
      isProcessingPayment.value = false;
      ErrorHandler.showErrorSnackBar('Join Payment Failed', e);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessingPayment.value = false;
    AppLogger.error(
        '❌ Razorpay Payment Error: ${response.code} - ${response.message}');
    ErrorHandler.showErrorSnackBar(
      'Payment Failed',
      response.message ?? 'Payment was cancelled or failed.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.info('External wallet selected: ${response.walletName}');
  }

  Future<void> _executeJoinGameOnServer({
    required String position,
    String? paymentMethod,
    String? walletPin,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final targetGameId = gameId.isNotEmpty ? gameId : (game.value?.id ?? '');
    if (targetGameId.isEmpty) {
      isProcessingPayment.value = false;
      ErrorHandler.showErrorSnackBar(
        'Match Error',
        'Unable to determine match ID. Please refresh and try again.',
      );
      return;
    }

    try {
      await repository.joinGame(
        targetGameId,
        position,
        paymentMethod: paymentMethod,
        walletPin: walletPin,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
      await loadGameDetails();
      await fetchWalletBalance();

      isProcessingPayment.value = false;
      if (Get.isBottomSheetOpen == true) Get.back();

      ErrorHandler.showSuccessSnackBar(
        'Match Joined!',
        'You have successfully joined in position $position!',
      );
    } catch (e) {
      isProcessingPayment.value = false;
      ErrorHandler.showErrorSnackBar('Join Error', e);
    }
  }

  Future<void> switchTeam() async {
    isJoining.value = true;
    try {
      await repository.switchTeam(gameId);
      await loadGameDetails();
      ErrorHandler.showSuccessSnackBar(
        'Team Switched',
        'You have successfully switched sides!',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Switch Error', e);
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> leaveMatch() async {
    isJoining.value = true;
    try {
      await repository.leaveGame(gameId);
      await loadGameDetails();
      await fetchWalletBalance();
      ErrorHandler.showSuccessSnackBar(
        'Left Match',
        'You have left the match roster.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Leave Error', e);
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> joinWaitlist() async {
    isJoining.value = true;
    try {
      final res = await repository.joinWaitlist(gameId, selectedPosition.value);
      await loadGameDetails();
      final pos = res['queuePosition'] ?? res['position'] ?? '1';
      ErrorHandler.showSuccessSnackBar(
        'Joined Waitlist',
        'You are currently #$pos on the reserve waitlist.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Waitlist Error', e);
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> leaveWaitlist() async {
    isJoining.value = true;
    try {
      await repository.leaveWaitlist(gameId);
      await loadGameDetails();
      ErrorHandler.showSuccessSnackBar(
        'Left Waitlist',
        'You have been removed from the reserve waitlist.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Error', e);
    } finally {
      isJoining.value = false;
    }
  }

  bool get isHost {
    final uid = AuthService.to.currentUser.value?.id;
    if (uid == null || game.value == null) return false;
    return game.value!.creatorId == uid;
  }

  bool get canHostCancel {
    final g = game.value;
    if (g == null || !isHost) return false;
    if (g.status == 'CANCELLED' ||
        g.status == 'COMPLETED' ||
        g.status == 'ONGOING' ||
        g.status == 'STARTED') {
      return false;
    }
    return AppDateUtils.isMatchInFuture(g.matchDate, g.startTime);
  }

  Future<void> cancelMatchByHost(String reason) async {
    isJoining.value = true;
    try {
      await repository.cancelPlayerGame(gameId, reason);
      await loadGameDetails();
      await fetchWalletBalance();
      ErrorHandler.showSuccessSnackBar(
        'Match Cancelled',
        'Your hosted match has been cancelled and entry fees refunded.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Cancellation Error', e);
    } finally {
      isJoining.value = false;
    }
  }

  final RxString activeRosterTab = 'TEAM_A'.obs;
  final RxList<Map<String, dynamic>> searchPlayerResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingPlayers = false.obs;
  final RxBool isRosterActionLoading = false.obs;

  void _initSocketListeners() {
    try {
      if (Get.isRegistered<SocketNotificationService>()) {
        SocketNotificationService.to.onEvent('match:live_feed', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Match live feed event in GameDetailsController');
          loadGameDetails();
        });
        SocketNotificationService.to.onEvent('notification', (data) {
          AppLogger.info(
              '⚡ [Socket.IO] Notification event in GameDetailsController');
          loadGameDetails();
        });
      }
    } catch (e) {
      AppLogger.warning(
          'Error setting up socket listeners in GameDetailsController: $e');
    }
  }

  bool get canHostManageRoster {
    final g = game.value;
    if (g == null || !isHost) return false;
    final statusUpper = g.status.toUpperCase();
    return statusUpper != 'COMPLETED' &&
        statusUpper != 'CANCELLED' &&
        statusUpper != 'ONGOING' &&
        statusUpper != 'STARTED';
  }

  Future<void> searchPlayersForHost(String query) async {
    final targetId = gameId;
    if (targetId.isEmpty) return;
    isSearchingPlayers.value = true;
    try {
      final list = await repository.searchPlayersForRoster(targetId, query);
      AppLogger.info(
          '🔍 [Roster Search] Found ${list.length} players for game $targetId: $list');
      searchPlayerResults.assignAll(list);
    } catch (e) {
      AppLogger.error('❌ [Roster Search] Error searching players: $e');
      searchPlayerResults.clear();
    } finally {
      isSearchingPlayers.value = false;
    }
  }

  Future<void> addPlayerToTeamByHost(
      String targetUserId, String team, String position) async {
    final targetId = gameId;
    if (targetId.isEmpty) return;
    isRosterActionLoading.value = true;
    try {
      await repository.addPlayerToRosterByHost(
          targetId, targetUserId, team, position);
      await loadGameDetails();
      ErrorHandler.showSuccessSnackBar(
        'Player Added!',
        'Player successfully added to ${team == 'TEAM_A' ? 'Team A' : 'Team B'}!',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Add Player Error', e);
    } finally {
      isRosterActionLoading.value = false;
    }
  }

  Future<void> removePlayerFromRosterByHost(String targetUserId) async {
    final targetId = gameId;
    if (targetId.isEmpty) return;
    isRosterActionLoading.value = true;
    try {
      await repository.removePlayerFromRosterByHost(targetId, targetUserId);
      await loadGameDetails();
      ErrorHandler.showSuccessSnackBar(
        'Player Removed',
        'Player successfully removed from match roster.',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar('Remove Player Error', e);
    } finally {
      isRosterActionLoading.value = false;
    }
  }
}
