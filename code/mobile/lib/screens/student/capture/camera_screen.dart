import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../services/geofence.dart';
import '../../../services/location_service.dart';
import '../../../state/app_state.dart';
import '../../../theme/tokens.dart';
import 'complaint_form_screen.dart';
import 'outside_campus_screen.dart';

/// Full-bleed in-app camera. Gallery access is deliberately absent — the
/// photo must be taken live, and GPS is captured at shutter-press.
///
/// [captureOnly]: skip all location logic and just pop with the taken
/// photo's [File] — used to add extra photos from the complaint form.
class CameraScreen extends StatefulWidget {
  final bool captureOnly;
  const CameraScreen({super.key, this.captureOnly = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  final _location = LocationService();
  String? _initError;
  bool _shooting = false;
  String _locationStatus = 'Locating…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    // Pre-warm GPS so shutter-press gets a fast, fresh fix.
    _location.warmUp().then((_) async {
      final res = await _location.capturePosition();
      if (!mounted) return;
      setState(() {
        _locationStatus = switch (res) {
          LocationOk(position: final p) =>
            zoneNameFor(p.latitude, p.longitude) ?? 'Outside campus',
          LocationInaccurate() => 'Weak GPS signal',
          LocationDisabled() => 'Location off',
          LocationDenied() => 'Location permission needed',
          LocationMocked() => 'Mock location detected',
        };
      });
    });

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      // medium (~720p) keeps uploads mobile-data friendly without a
      // compression dependency.
      final controller =
          CameraController(back, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on CameraException catch (e) {
      setState(() => _initError = e.code == 'CameraAccessDenied'
          ? 'Camera permission is needed to report a problem. Enable it in Settings.'
          : 'Could not start the camera (${e.code}).');
    } catch (e) {
      setState(() => _initError = 'Could not start the camera.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _init();
    }
  }

  Future<void> _shoot() async {
    final cam = _camera;
    if (cam == null || _shooting) return;
    setState(() => _shooting = true);
    HapticFeedback.mediumImpact();

    try {
      // Photo + GPS captured as one atomic moment.
      final shot = await cam.takePicture();
      if (widget.captureOnly) {
        if (mounted) Navigator.of(context).pop(File(shot.path));
        return;
      }
      final loc = await _location.capturePosition();
      if (!mounted) return;

      final demoTester =
          context.read<AppState>().profile?.demoTester ?? false;

      // Demo/test accounts skip every location gate: submit from anywhere,
      // with whatever fix (if any) we got.
      if (demoTester) {
        final p = loc is LocationOk ? loc.position : null;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ComplaintFormScreen(
            photo: File(shot.path),
            lat: p?.latitude ?? 0,
            lng: p?.longitude ?? 0,
            accuracy: p?.accuracy ?? 0,
            zoneName: p == null
                ? 'Campus'
                : (zoneNameFor(p.latitude, p.longitude) ?? 'Campus'),
            capturedAt: DateTime.now(),
            bypassGeofence: true,
          ),
        ));
        return;
      }

      switch (loc) {
        case LocationOk(position: final p):
          final zone = zoneNameFor(p.latitude, p.longitude);
          if (zone == null) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => const OutsideCampusScreen()));
            return;
          }
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => ComplaintFormScreen(
              photo: File(shot.path),
              lat: p.latitude,
              lng: p.longitude,
              accuracy: p.accuracy,
              zoneName: zone,
              capturedAt: DateTime.now(),
            ),
          ));
        case LocationInaccurate(accuracy: final a):
          _showIssue(
              'Couldn\'t get a precise location (±${a.toStringAsFixed(0)} m). '
              'Step outdoors or near a window and try again.');
        case LocationDisabled():
          _promptLocationSettings(
            'Location is off',
            'CampusCare needs your location to confirm the problem is on '
                'campus. Turn on Location (GPS) to continue.',
            openAppSettings: false,
          );
        case LocationDenied(forever: final forever):
          if (forever) {
            _promptLocationSettings(
              'Location permission needed',
              'Location permission is permanently denied. Allow it in app '
                  'settings to report a problem.',
              openAppSettings: true,
            );
          } else {
            _showIssue(
                'Location permission is needed so we know where the problem is.');
          }
        case LocationMocked():
          _showIssue(
              'A mock location app was detected. Real GPS is required.');
      }
    } catch (e) {
      _showIssue('Something went wrong taking the photo. Try again.');
    } finally {
      if (mounted) setState(() => _shooting = false);
    }
  }

  void _showIssue(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Dialog with a direct jump into the system settings screen that fixes
  /// the problem (location services, or this app's permission page).
  void _promptLocationSettings(String title, String message,
      {required bool openAppSettings}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings
                  ? Geolocator.openAppSettings()
                  : Geolocator.openLocationSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.select<AppState, bool>((s) => s.online);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_camera != null && _camera!.value.isInitialized)
            CameraPreview(_camera!)
          else if (_initError != null)
            _CameraError(message: _initError!)
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),

          // Top bar: close + live zone chip.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (!widget.captureOnly)
                    _ZoneStatusChip(status: _locationStatus),
                ],
              ),
            ),
          ),

          // Bottom: hint + shutter.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!online)
                      Container(
                        margin: const EdgeInsets.only(bottom: Space.md),
                        padding: const EdgeInsets.symmetric(
                            horizontal: Space.md, vertical: Space.xs + 2),
                        decoration: BoxDecoration(
                          color: BrandColors.warning,
                          borderRadius: BorderRadius.circular(Corners.pill),
                        ),
                        child: Text('Offline — complaint will queue and send later',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: Colors.white)),
                      ),
                    Text('Frame the problem and tap the shutter',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70)),
                    const SizedBox(height: Space.md),
                    GestureDetector(
                      onTap: _shoot,
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: AnimatedContainer(
                          duration: Motion.fast,
                          decoration: BoxDecoration(
                            color: _shooting
                                ? BrandColors.accent
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _shooting
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                    ).animate().scale(
                        duration: Motion.normal, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneStatusChip extends StatelessWidget {
  final String status;
  const _ZoneStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locating = status == 'Locating…';
    final problem = status == 'Outside campus' ||
        status.contains('GPS') ||
        status.contains('Location') ||
        status.contains('Mock');
    final color = locating
        ? Colors.black54
        : problem
            ? BrandColors.warning
            : BrandColors.success;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Space.md, vertical: Space.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(locating ? Icons.my_location_rounded : Icons.place_rounded,
              size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(status,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: Colors.white)),
        ],
      ),
    );
    if (locating) {
      chip = chip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.5, end: 1, duration: 700.ms);
    }
    return chip;
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  const _CameraError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white54, size: 56),
            const SizedBox(height: Space.md),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
