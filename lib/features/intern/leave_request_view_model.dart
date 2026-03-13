import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/api_client_base.dart';
import '../../core/services/session_store.dart';

class LeaveRequestViewModel extends ChangeNotifier {
  LeaveRequestViewModel({required this.apiClient, required this.session});

  final ApiClient apiClient;
  final SessionStore session;

  bool loading = false;
  String? error;
  bool success = false;
  // data lampiran
  XFile? attachment;
  String? attachmentName;

  void setAttachment(XFile? file) {
    attachment = file;
    attachmentName = file?.name;
    notifyListeners();
  }

  Future<void> submit({
    required String type, // IZIN/SAKIT
    required String dateFrom,
    required String dateTo,
    required String reason,
  }) async {
    if (!session.isAuthenticated) return;
    final normalizedFrom = dateFrom.trim();
    final normalizedTo = dateTo.trim();
    final normalizedReason = reason.trim();
    if (normalizedFrom.isEmpty || normalizedTo.isEmpty) {
      error = 'Tanggal izin/sakit wajib diisi.';
      notifyListeners();
      return;
    }
    final fromDate = DateTime.tryParse(normalizedFrom);
    final toDate = DateTime.tryParse(normalizedTo);
    if (fromDate == null || toDate == null) {
      error = 'Format tanggal harus YYYY-MM-DD.';
      notifyListeners();
      return;
    }
    if (fromDate.isAfter(toDate)) {
      error = 'Tanggal mulai tidak boleh lebih besar dari tanggal selesai.';
      notifyListeners();
      return;
    }
    if (normalizedReason.isEmpty) {
      error = 'Alasan izin/sakit wajib diisi.';
      notifyListeners();
      return;
    }
    if (type == 'SAKIT' && attachment == null) {
      error = 'Bukti sakit wajib diunggah.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    success = false;
    notifyListeners();
    try {
      String? base64;
      if (attachment != null) {
        final bytes = await attachment!.readAsBytes();
        base64 = base64Encode(bytes);
      }
      await apiClient.postJson(
        '/api/leave/request',
        bearerToken: session.token,
        body: {
          'type': type,
          'dateFrom': normalizedFrom,
          'dateTo': normalizedTo,
          'reason': normalizedReason,
          if (base64 != null) 'attachmentBase64': base64,
          if (attachmentName != null) 'attachmentName': attachmentName,
        },
      );
      success = true;
    } on ApiError catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
