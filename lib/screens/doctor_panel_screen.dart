import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/patient.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/page_container.dart';
part 'doctor_panel_screen_state.dart';

class DoctorPanelScreen extends StatefulWidget {
  const DoctorPanelScreen({super.key});

  @override
  State<DoctorPanelScreen> createState() => DoctorPanelScreenState();
}
