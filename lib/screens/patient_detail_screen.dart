import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../providers/api_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/pdf_service.dart';
import '../services/sync_service.dart';

part 'patient_detail_screen_state.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientName;
  final int? patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientName,
    this.patientId,
  });

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailState();
}
