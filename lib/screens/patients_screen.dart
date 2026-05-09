import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'package:go_router/go_router.dart';
import '../models/patient.dart';
import '../core/theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/utils/search_utils.dart';
import '../providers/api_providers.dart';
part 'patients_screen_state.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => PatientsScreenState();
}
