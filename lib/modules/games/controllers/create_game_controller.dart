import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../repositories/games_repository.dart';
import '../../wallet/repositories/wallet_repository.dart';
import '../../wallet/datasources/wallet_remote_datasource.dart';
import '../../../data/models/court_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../core/constants/api_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class CreateGameController extends GetxController {
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

  final RxnString currentPaymentOrderId = RxnString();
  final RxnString currentRazorpayOrderId = RxnString();

  final formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();

  final availableClubs = <ClubModel>[].obs;
  final Rx<ClubModel> selectedClub = ClubModel(
    id: 'all_stars_arena_club',
    name: 'All Stars Turf Raipur',
    city: 'Raipur',
    address: 'VIP Road, Raipur',
  ).obs;

  final availableCourts = <CourtModel>[].obs;
  final Rxn<CourtModel> selectedCourt = Rxn<CourtModel>();
  final RxString selectedGameTitle = 'Football'.obs;

  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
  final Rxn<TimeOfDay> startTime = Rxn<TimeOfDay>();
  final Rxn<TimeOfDay> endTime = Rxn<TimeOfDay>();

  final isLoading = false.obs;
  final isProcessing = false.obs;
  final paymentStatus = ''.obs;
  final errorMessage = ''.obs;

  final occupiedCourtSlots = <CourtSlotModel>[].obs;
  final isFetchingSlots = false.obs;
  final slotConflictWarning = RxnString();
  final conflictingSlot = Rxn<CourtSlotModel>();

  final selectedPaymentMethod = 'RAZORPAY'.obs;
  final walletBalance = 0.0.obs;

  int get durationMinutes {
    if (startTime.value == null || endTime.value == null) return 90;
    final startM = startTime.value!.hour * 60 + startTime.value!.minute;
    final endM = endTime.value!.hour * 60 + endTime.value!.minute;
    var diff = endM - startM;
    if (diff <= 0) diff += 24 * 60;
    return diff;
  }

  double get pitchBookingAmount {
    final court = selectedCourt.value;
    final hourlyRate = court?.basePricePerHour ?? 1200.0;
    return (hourlyRate * (durationMinutes / 60.0)).roundToDouble();
  }

  @override
  void onInit() {
    super.onInit();
    _initRazorpay();
    _populateCourts();
    loadVenues();
    fetchWalletBalance();

    selectedGameTitle.value = 'Football';
    descriptionController.clear();
    selectedDate.value = null;
    startTime.value = null;
    endTime.value = null;

    if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args['courtId'] != null) {
        final target = args['courtId'].toString().toLowerCase();
        final match = availableCourts.firstWhereOrNull(
          (c) =>
              c.id.toLowerCase() == target ||
              c.name.toLowerCase().contains(target.contains('2') ? '2' : '1'),
        );
        if (match != null) {
          selectedCourt.value = match;
        }
      }
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    descriptionController.dispose();
    super.onClose();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> loadVenues() async {
    try {
      final fetchedClubs = await repository.getClubs();
      if (fetchedClubs.isNotEmpty) {
        availableClubs.assignAll(fetchedClubs);
        selectedClub.value = fetchedClubs.first;
      }
      final fetchedCourts =
          await repository.getCourts(clubId: selectedClub.value.id);
      _populateCourts(fetchedCourts);
    } catch (e) {
      AppLogger.warning('Error loading venues: $e');
      _populateCourts([]);
    }
  }

  Future<void> onClubChanged(ClubModel club) async {
    selectedClub.value = club;
    try {
      final fetchedCourts = await repository.getCourts(clubId: club.id);
      _populateCourts(fetchedCourts);
    } catch (e) {
      AppLogger.warning('Error loading courts: $e');
      _populateCourts([]);
    }
  }

  void _populateCourts([List<CourtModel>? fetchedCourts]) {
    if (fetchedCourts != null && fetchedCourts.isNotEmpty) {
      availableCourts.assignAll(fetchedCourts);
    } else if (availableCourts.isEmpty) {
      final clubId = selectedClub.value.id.isNotEmpty
          ? selectedClub.value.id
          : 'all_stars_arena_club';
      final clubName = selectedClub.value.name.isNotEmpty
          ? selectedClub.value.name
          : 'All Stars Turf Raipur';

      final court1 = CourtModel(
        id: 'court_1',
        clubId: clubId,
        clubName: clubName,
        name: 'Court 1',
        surfaceType: '3G Turf',
        basePricePerHour: 1200.0,
        status: 'AVAILABLE',
        city: 'Raipur',
        address: 'VIP Road, Raipur',
      );

      final court2 = CourtModel(
        id: 'court_2',
        clubId: clubId,
        clubName: clubName,
        name: 'Court 2',
        surfaceType: '3G Turf',
        basePricePerHour: 1200.0,
        status: 'AVAILABLE',
        city: 'Raipur',
        address: 'VIP Road, Raipur',
      );

      availableCourts.assignAll([court1, court2]);
    }

    if (availableCourts.isNotEmpty) {
      if (selectedCourt.value == null) {
        selectedCourt.value = availableCourts.first;
      } else {
        final match = availableCourts.firstWhereOrNull(
          (c) =>
              c.id == selectedCourt.value!.id ||
              c.name == selectedCourt.value!.name,
        );
        selectedCourt.value = match ?? availableCourts.first;
      }
      fetchCourtAvailability();
    }
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

  void selectCourt(CourtModel court) {
    selectedCourt.value = court;
    fetchCourtAvailability();
  }

  void switchToAlternateCourt() {
    final current = selectedCourt.value;
    final alt = availableCourts.firstWhereOrNull(
      (c) =>
          c.id != current?.id &&
          c.name.toLowerCase() != current?.name.toLowerCase(),
    );
    if (alt != null) {
      selectCourt(alt);
    }
  }

  Future<void> fetchCourtAvailability() async {
    final court = selectedCourt.value;
    final date = selectedDate.value;
    if (court == null || date == null) {
      occupiedCourtSlots.clear();
      slotConflictWarning.value = null;
      conflictingSlot.value = null;
      return;
    }

    final courtId = (court.name.toLowerCase().contains('2') ||
            court.id.toLowerCase().contains('2'))
        ? 'court_2'
        : 'court_1';
    final dateStr = AppDateUtils.formatIsoDate(date);

    isFetchingSlots.value = true;
    try {
      final slots = await repository.getCourtAvailability(courtId, dateStr);
      occupiedCourtSlots.assignAll(slots);
      recheckSlotCollision();
    } catch (e) {
      AppLogger.warning('Error fetching court slots: $e');
    } finally {
      isFetchingSlots.value = false;
    }
  }

  void recheckSlotCollision() {
    if (startTime.value == null ||
        endTime.value == null ||
        selectedDate.value == null) {
      slotConflictWarning.value = null;
      conflictingSlot.value = null;
      return;
    }

    final dateStr = AppDateUtils.formatIsoDate(selectedDate.value!);
    final startM = startTime.value!.hour * 60 + startTime.value!.minute;
    var endM = endTime.value!.hour * 60 + endTime.value!.minute;
    if (endM <= startM) {
      endM += 24 * 60;
    }

    CourtSlotModel? conflict;
    for (final slot in occupiedCourtSlots) {
      // Ignore slots from other dates or cancelled/rejected status
      if (slot.bookingDate.isNotEmpty && slot.bookingDate != dateStr) {
        continue;
      }
      final statusUpper = slot.status.toUpperCase();
      if (statusUpper == 'CANCELLED' ||
          statusUpper == 'REJECTED' ||
          statusUpper == 'EXPIRED') {
        continue;
      }

      final sStart = slot.startMinutes;
      final sEnd = slot.endMinutes;

      // Strict interval overlap test: start < sEnd && end > sStart
      // Back-to-back (start == sEnd or end == sStart) is allowed!
      if (startM < sEnd && endM > sStart) {
        conflict = slot;
        break;
      }
    }

    if (conflict != null) {
      conflictingSlot.value = conflict;
      final courtName = selectedCourt.value?.name ?? 'Court';
      final alt = availableCourts.firstWhereOrNull(
        (c) =>
            c.id != selectedCourt.value?.id &&
            c.name.toLowerCase() != selectedCourt.value?.name.toLowerCase(),
      );
      final altName = alt?.name ?? 'Court 2';

      slotConflictWarning.value =
          '$courtName is already booked (${conflict.startTime} - ${conflict.endTime}). '
          'Overlapping times cannot be booked on the same court. You can switch to $altName (separate court) or select a non-overlapping time slot (e.g. from ${conflict.endTime}).';
    } else {
      conflictingSlot.value = null;
      slotConflictWarning.value = null;
    }
  }

  bool get isSelectedTimeInPast {
    if (selectedDate.value == null || startTime.value == null) return false;
    final now = DateTime.now();
    final d = selectedDate.value!;
    final s = startTime.value!;
    final slotStart = DateTime(d.year, d.month, d.day, s.hour, s.minute);
    return slotStart.isBefore(now.subtract(const Duration(minutes: 1)));
  }

  void setToNextAvailableHour() {
    final now = DateTime.now();
    final nextStartHour = (now.hour + 1) % 24;
    startTime.value = TimeOfDay(hour: nextStartHour, minute: 0);
    final autoEndMinutes = (nextStartHour * 60 + 90) % (24 * 60);
    endTime.value =
        TimeOfDay(hour: autoEndMinutes ~/ 60, minute: autoEndMinutes % 60);
    recheckSlotCollision();
  }

  void updateDate(DateTime pickedDate) {
    selectedDate.value = pickedDate;
    final now = DateTime.now();

    final isToday = pickedDate.year == now.year &&
        pickedDate.month == now.month &&
        pickedDate.day == now.day;

    if (isToday) {
      final currentStart = startTime.value != null
          ? DateTime(now.year, now.month, now.day, startTime.value!.hour,
              startTime.value!.minute)
          : null;
      if (currentStart == null ||
          currentStart.isBefore(now.add(const Duration(minutes: 5)))) {
        final nextStartHour = (now.hour + 1) % 24;
        startTime.value = TimeOfDay(hour: nextStartHour, minute: 0);
        final autoEndMinutes = (nextStartHour * 60 + 90) % (24 * 60);
        endTime.value =
            TimeOfDay(hour: autoEndMinutes ~/ 60, minute: autoEndMinutes % 60);
      }
    }
    fetchCourtAvailability();
  }

  void updateStartTime(TimeOfDay newStart) {
    startTime.value = newStart;
    final startMinutes = newStart.hour * 60 + newStart.minute;
    final autoEndMinutes = (startMinutes + 90) % (24 * 60);
    endTime.value =
        TimeOfDay(hour: autoEndMinutes ~/ 60, minute: autoEndMinutes % 60);
    recheckSlotCollision();
  }

  void updateEndTime(TimeOfDay newEnd) {
    if (startTime.value == null) {
      endTime.value = newEnd;
      recheckSlotCollision();
      return;
    }

    final startMinutes = startTime.value!.hour * 60 + startTime.value!.minute;
    final endMinutes = newEnd.hour * 60 + newEnd.minute;

    if (endMinutes <= startMinutes && newEnd.hour >= startTime.value!.hour) {
      ErrorHandler.showErrorSnackBar(
        'Invalid End Time',
        'Pitch booking end time must be after start time (${AppDateUtils.formatTime(startTime.value!)})',
      );
      final autoEndMinutes = (startMinutes + 90) % (24 * 60);
      endTime.value =
          TimeOfDay(hour: autoEndMinutes ~/ 60, minute: autoEndMinutes % 60);
      recheckSlotCollision();
      return;
    }
    endTime.value = newEnd;
    recheckSlotCollision();
  }

  bool validateForm() {
    if (selectedGameTitle.value.trim().isEmpty) {
      ErrorHandler.showErrorSnackBar(
          'Validation Error', 'Please select a sport (Football or Basketball)');
      return false;
    }

    if (selectedCourt.value == null) {
      ErrorHandler.showErrorSnackBar(
          'Validation Error', 'Please select Court 1 or Court 2');
      return false;
    }

    if (selectedDate.value == null) {
      ErrorHandler.showErrorSnackBar(
          'Validation Error', 'Please select a booking date');
      return false;
    }

    if (startTime.value == null || endTime.value == null) {
      ErrorHandler.showErrorSnackBar(
          'Validation Error', 'Please select start and end times');
      return false;
    }

    final err = AppDateUtils.validateGameTimes(
      selectedDate.value!,
      startTime.value!,
      endTime.value!,
    );

    if (err != null) {
      ErrorHandler.showErrorSnackBar('Validation Error', err);
      return false;
    }

    if (isSelectedTimeInPast) {
      ErrorHandler.showErrorSnackBar(
        'Past Time Selected',
        'Cannot book a court slot in the past. Match date and start time must be in the future.',
      );
      return false;
    }

    recheckSlotCollision();
    if (slotConflictWarning.value != null) {
      ErrorHandler.showErrorSnackBar(
        'Court Slot Conflict',
        slotConflictWarning.value!,
      );
      return false;
    }

    return true;
  }

  Future<void> proceedToCheckout() async {
    isProcessing.value = true;
    try {
      await fetchCourtAvailability();
      if (!validateForm()) return;
      Get.toNamed('/games/checkout');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> executePaymentAndCreateGame() async {
    isProcessing.value = true;
    final userRole =
        AuthService.to.currentUser.value?.roleName?.toUpperCase() ?? '';
    final isManagerOrAdmin = userRole == 'MANAGER' || userRole == 'ADMIN';
    final fee = pitchBookingAmount;

    // Free booking or Manager/Admin
    if (fee <= 0 || isManagerOrAdmin) {
      paymentStatus.value = 'Confirming Pitch Booking...';
      await _createGameOnServer();
      return;
    }

    // Payment via Wallet
    if (selectedPaymentMethod.value == 'WALLET') {
      if (walletBalance.value < fee) {
        isProcessing.value = false;
        ErrorHandler.showErrorSnackBar(
          'Insufficient Wallet Balance',
          'Your wallet balance is ₹${walletBalance.value.toStringAsFixed(0)}. Please choose Razorpay to pay ₹${fee.toStringAsFixed(0)}.',
        );
        return;
      }
      isProcessing.value = false;
      _promptPinAndAuthorizeWalletPayment(fee: fee);
      return;
    }

    // Payment via Razorpay
    if (selectedPaymentMethod.value == 'RAZORPAY') {
      paymentStatus.value = 'Creating Razorpay Order...';

      try {
        final order = await repository.createMatchOrder(fee);

        currentRazorpayOrderId.value = order.orderId;

        final user = AuthService.to.currentUser.value;
        final contact =
            (user != null && user.phone.isNotEmpty) ? user.phone : '9876543210';
        final email = (user != null && user.email.isNotEmpty)
            ? user.email
            : 'player@allstarsarena.com';

        final key =
            order.keyId.isNotEmpty ? order.keyId : ApiConstants.razorpayKey;

        final courtTitle = selectedCourt.value?.name ?? 'Court';
        final sportTitle = selectedGameTitle.value.trim().isNotEmpty
            ? selectedGameTitle.value.trim()
            : 'Pitch Reservation';
        final options = {
          'key': key,
          'amount':
              order.amountPaisa > 0 ? order.amountPaisa : (fee * 100).toInt(),
          'name': 'ALL STARS ARENA',
          'description': '$sportTitle Booking - $courtTitle',
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

        paymentStatus.value = 'Opening Razorpay Gateway...';
        _razorpay.open(options);
      } catch (e) {
        isProcessing.value = false;
        ErrorHandler.showErrorSnackBar('Razorpay Order Failed', e);
      }
      return;
    }

    paymentStatus.value = 'Confirming Pitch Booking...';
    await _createGameOnServer();
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your 6-digit Wallet PIN to authorize pitch booking fee of ₹${fee.toStringAsFixed(0)}.',
                    style:
                        TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: true,
                    style: TextStyle(
                      color: context.textPrimary,
                      letterSpacing: 8,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '••••••',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: context.borderColor, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final pin = pinController.text.trim();
                  if (pin.length != 6) {
                    ErrorHandler.showErrorSnackBar('Invalid PIN',
                        'Please enter your complete 6-digit PIN');
                    return;
                  }
                  Get.back();
                  isProcessing.value = true;
                  paymentStatus.value = 'Debiting Wallet & Confirming...';
                  _createGameOnServer(walletPin: pin);
                },
                child: const Text('Confirm Pay',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> processTestModePayment() async {
    isProcessing.value = true;
    paymentStatus.value = 'Preparing Quick Pitch Booking...';
    await Future.delayed(const Duration(milliseconds: 300));

    paymentStatus.value = 'Opening Razorpay Gateway (Test Mode)...';
    await Future.delayed(const Duration(milliseconds: 500));

    paymentStatus.value = 'Verifying Payment...';
    await Future.delayed(const Duration(milliseconds: 400));

    paymentStatus.value = 'Finalizing Pitch Booking...';
    await Future.delayed(const Duration(milliseconds: 400));

    final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';
    final mockOrderId =
        'rzp_order_mock_${DateTime.now().millisecondsSinceEpoch}';

    await _createGameOnServer(
      paymentId: mockPaymentId,
      razorpayOrderId: mockOrderId,
      razorpaySignature: 'mock_signature',
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    paymentStatus.value = 'Payment Verified! Confirming Booking...';

    try {
      final razorpayOrderIdToUse =
          (response.orderId != null && response.orderId!.isNotEmpty)
              ? response.orderId!
              : (currentRazorpayOrderId.value ?? '');

      paymentStatus.value = 'Finalizing Pitch Booking...';
      await _createGameOnServer(
        paymentId: response.paymentId,
        razorpayOrderId: razorpayOrderIdToUse,
        razorpaySignature: response.signature,
      );
    } catch (e) {
      isProcessing.value = false;
      ErrorHandler.showErrorSnackBar('Booking Error', e);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isProcessing.value = false;
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

  Future<void> _createGameOnServer({
    String? paymentId,
    String? walletPin,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    final court = selectedCourt.value;
    final courtId = (court?.name.toLowerCase().contains('2') == true ||
            court?.id.toLowerCase().contains('2') == true)
        ? 'court_2'
        : 'court_1';
    final courtName = courtId == 'court_2' ? 'Court 2' : 'Court 1';

    final dateStr = selectedDate.value != null
        ? AppDateUtils.formatIsoDate(selectedDate.value!)
        : AppDateUtils.formatIsoDate(
            DateTime.now().add(const Duration(days: 1)));
    final startStr = startTime.value != null
        ? AppDateUtils.format24HourTime(startTime.value!)
        : '18:00';
    final endStr = endTime.value != null
        ? AppDateUtils.format24HourTime(endTime.value!)
        : '19:30';

    final fee = pitchBookingAmount;
    final sportTitle = selectedGameTitle.value.trim().isNotEmpty
        ? selectedGameTitle.value.trim()
        : 'Football';
    final formatKey =
        sportTitle.toLowerCase() == 'basketball' ? '5v5' : '11v11';

    try {
      final newGame = await repository.createGame({
        'title': sportTitle,
        'clubId': selectedClub.value.id.isNotEmpty
            ? selectedClub.value.id
            : 'all_stars_arena_club',
        'courtId': courtId,
        'courtName': courtName,
        'format': formatKey,
        'entryFee': fee,
        'matchDate': dateStr,
        'startTime': startStr,
        'endTime': endStr,
        'description': descriptionController.text.trim(),
        'paymentMethod': selectedPaymentMethod.value,
        if (walletPin != null && walletPin.isNotEmpty) 'walletPin': walletPin,
        if (paymentId != null) 'paymentReference': paymentId,
        if (paymentId != null) 'razorpayPaymentId': paymentId,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
      });

      await fetchWalletBalance();
      isProcessing.value = false;

      Get.offAllNamed(Routes.home);
      Get.toNamed('/payment/result', arguments: {
        'success': true,
        'amount': fee.toStringAsFixed(0),
        'gameTitle': newGame.title,
        'gameId': newGame.id,
      });
    } catch (e) {
      isProcessing.value = false;
      final msg = ErrorHandler.getErrorMessage(e);
      errorMessage.value = msg;
      if (msg.contains('already booked') ||
          msg.contains('Overlapping time slots') ||
          msg.contains('time slot')) {
        _showConflictDialogOnCheckout(msg);
      } else {
        ErrorHandler.showErrorSnackBar('Pitch Booking Error', e);
      }
    }
  }

  void _showConflictDialogOnCheckout(String errorMsg) {
    final courtName = selectedCourt.value?.name ?? 'Court';
    final alt = availableCourts.firstWhereOrNull(
      (c) =>
          c.id != selectedCourt.value?.id &&
          c.name.toLowerCase() != selectedCourt.value?.name.toLowerCase(),
    );
    final altName = alt?.name ?? 'Court 1';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pitch Already Booked',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          '$courtName is already booked for a match at your selected time slot.\n\nWould you like to switch to $altName or choose a different time?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              Get.back(); // Return to CreateGameView
            },
            child: const Text('Change Booking Time'),
          ),
          if (alt != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Get.back(); // Close dialog
                switchToAlternateCourt();
                await fetchCourtAvailability();
                Get.back(); // Return to CreateGameView
                ErrorHandler.showSuccessSnackBar(
                  'Court Updated to ${alt.name}',
                  'Switched to ${alt.name}. Please select an available time or proceed to checkout.',
                );
              },
              child: Text('Switch to ${alt.name}'),
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
