import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../models/patient.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_decorations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../widgets/premium_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state_view.dart';
import '../core/utils/search_utils.dart';
import '../providers/api_providers.dart';

part 'doctor_panel_screen_state.dart';

class DoctorPanelScreen extends ConsumerStatefulWidget {
  const DoctorPanelScreen({super.key});

  @override
  ConsumerState<DoctorPanelScreen> createState() => DoctorPanelScreenState();
}
