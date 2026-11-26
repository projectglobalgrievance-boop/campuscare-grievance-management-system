import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../config/campus_geo.dart';
import '../../../config/departments.dart';
import '../../../l10n/strings.dart';
import '../../../l10n/transliterate.dart';
import '../../../services/offline_queue.dart';
import '../../../state/app_state.dart';
import '../../../theme/tokens.dart';
import 'camera_screen.dart';
import 'success_screen.dart';

class ComplaintFormScreen extends StatefulWidget {
  final File photo;
  final double lat;
  final double lng;
  final double accuracy;
  final String zoneName;
  final DateTime capturedAt;
  final bool bypassGeofence; // demo/test accounts only

  const ComplaintFormScreen({
    super.key,
    required this.photo,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.zoneName,
    required this.capturedAt,
    this.bypassGeofence = false,
  });

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  static const _maxPerDay = 5;
  static const _maxPhotos = 4;
  static const _profanity = [
    'fuck', 'fucking', 'shit', 'bitch', 'asshole', 'bastard',
    'bkl', 'bsdk', 'chutiya',
  ];

  final _description = TextEditingController();
  final List<File> _extraPhotos = [];
  bool _busy = false;
  String _stage = '';
  late String _zone = widget.zoneName;

  /// Department the student says this is for. Required — it decides which
  /// department admin receives the complaint.
  String? _department;

  /// Script the description is typed in. Local to this form and always starts
  /// at English; the phone's keyboard stays English either way — Android gives
  /// apps no way to switch it — so Latin input is transliterated instead.
  String _lang = 'en';

  static const _typingHint = {
    'kn': 'English ಅಕ್ಷರಗಳಲ್ಲಿ ಟೈಪ್ ಮಾಡಿ — ಕನ್ನಡ ತಾನಾಗಿ ಬರುತ್ತದೆ',
    'hi': 'English अक्षरों में टाइप करें — हिन्दी अपने आप आएगी',
  };

  static bool _isLatinLetter(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122);
  }

  /// Converts every completed word, leaving the one still under the caret in
  /// Latin so the student can see what they are typing. Already-converted
  /// script contains no Latin letters, so re-running this is a no-op.
  void _onDescriptionChanged(String value) {
    if (_lang == 'en') return;
    final sel = _description.selection;
    if (!sel.isCollapsed || sel.baseOffset != value.length) return;
    var i = value.length;
    while (i > 0 && _isLatinLetter(value[i - 1])) {
      i--;
    }
    final head = value.substring(0, i);
    final converted = Transliterate.text(head, _lang);
    if (converted == head) return;
    final text = converted + value.substring(i);
    _description.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _setLang(String code) {
    setState(() {
      _lang = code;
      // Convert what is already in the box, so switching mid-sentence does
      // what it looks like it should.
      final text = Transliterate.text(_description.text, code);
      _description.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  bool get _isProfane {
    final text = ' ${_description.text.toLowerCase()} ';
    return _profanity.any((w) => text.contains(' $w '));
  }

  Future<void> _addPhoto() async {
    final shot = await Navigator.of(context).push<File>(MaterialPageRoute(
        builder: (_) => const CameraScreen(captureOnly: true)));
    if (shot != null && mounted) setState(() => _extraPhotos.add(shot));
  }

  Future<void> _submit() async {
    // The last word has no separator after it yet.
    if (_lang != 'en') {
      _description.text = Transliterate.text(_description.text, _lang);
    }
    final app = context.read<AppState>();
    final uid = app.auth.currentUser?.uid;
    if (uid == null) return;

    if (_department == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.t('pick_department'))));
      return;
    }

    if (_isProfane) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Please keep the description respectful — reword it and try again.')));
      return;
    }

    // Spam guard: demo accounts are exempt so demos can run freely.
    // FAILS OPEN — if the count query itself errors (missing index, offline
    // blip, rules change) we let the complaint through rather than silently
    // killing the Submit button. A spam guard is not worth losing a report.
    final demoTester = app.profile?.demoTester ?? false;
    if (!demoTester && app.online) {
      try {
        final today = await app.complaints.todaysComplaintCount(uid);
        if (today >= _maxPerDay) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Daily limit reached ($_maxPerDay complaints/day). Try again tomorrow.')));
          return;
        }
      } catch (_) {
        // ignore: avoid_print
        print('CampusCare: rate-limit check failed, allowing submit');
      }
    }
    if (!mounted) return;

    setState(() {
      _busy = true;
      _stage = 'Uploading photo…';
    });

    if (!app.online) {
      // Persist photo beyond the camera cache, queue with ORIGINAL capture
      // GPS/time, auto-sends when connectivity returns.
      final dir = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final saved =
          await widget.photo.copy('${dir.path}/queued_$stamp.jpg');
      final extras = [
        for (var i = 0; i < _extraPhotos.length; i++)
          (await _extraPhotos[i].copy('${dir.path}/queued_${stamp}_$i.jpg'))
              .path,
      ];
      await app.offlineQueue.enqueue(PendingComplaint(
        uid: uid,
        description: _description.text.trim(),
        department: _department,
        photoPath: saved.path,
        extraPhotoPaths: extras,
        lat: widget.lat,
        lng: widget.lng,
        accuracy: widget.accuracy,
        zoneName: _zone,
        capturedAt: widget.capturedAt,
        bypassGeofence: widget.bypassGeofence,
      ));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const SuccessScreen(queued: true)));
      return;
    }

    try {
      setState(() => _stage = 'Analyzing with AI…');
      final id = await app.complaints.submit(
        uid: uid,
        description: _description.text.trim(),
        department: _department,
        photo: widget.photo,
        extraPhotos: _extraPhotos,
        lat: widget.lat,
        lng: widget.lng,
        accuracy: widget.accuracy,
        zoneName: _zone,
        capturedAt: widget.capturedAt,
        bypassGeofence: widget.bypassGeofence,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SuccessScreen(complaintId: id)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _stage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Couldn\'t submit right now — check your connection and try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New complaint')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.md),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Corners.md),
              child: Image.file(widget.photo,
                  height: 220, width: double.infinity, fit: BoxFit.cover),
            ).animate().fadeIn(duration: Motion.normal),
            const SizedBox(height: Space.sm),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _extraPhotos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.sm),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Corners.sm),
                            child: Image.file(_extraPhotos[i],
                                width: 72, height: 72, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _busy
                                  ? null
                                  : () => setState(
                                      () => _extraPhotos.removeAt(i)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_extraPhotos.length < _maxPhotos - 1)
                    OutlinedButton(
                      onPressed: _busy ? null : _addPhoto,
                      style: OutlinedButton.styleFrom(
                        // theme minimumSize is full-width; pin it down so the
                        // tile survives the unbounded horizontal ListView.
                        minimumSize: const Size(72, 72),
                        maximumSize: const Size(72, 72),
                        fixedSize: const Size(72, 72),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Corners.sm)),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Auto-detected from GPS; the dropdown lets the
                          // student correct it (e.g. indoors, weak fix).
                          DropdownButton<String>(
                            value: _zone,
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            style: theme.textTheme.titleSmall,
                            items: {
                              _zone,
                              for (final z in CampusGeo.zones) z.name,
                            }
                                .map((n) => DropdownMenuItem(
                                    value: n, child: Text(n)))
                                .toList(),
                            onChanged: _busy
                                ? null
                                : (v) =>
                                    setState(() => _zone = v ?? _zone),
                          ),
                          Text(
                              'Location locked at capture · ±${widget.accuracy.toStringAsFixed(0)} m',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(
                        _zone == widget.zoneName
                            ? Icons.verified_rounded
                            : Icons.edit_location_alt_rounded,
                        color: BrandColors.success,
                        size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<String>(
              initialValue: _department,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: L10n.t('department'),
                prefixIcon: const Icon(Icons.apartment_rounded),
              ),
              hint: Text(L10n.t('pick_department')),
              // Closed field: just the name. Open menu: name + what it covers.
              selectedItemBuilder: (_) => [
                for (final d in Department.all)
                  Text(d.name, overflow: TextOverflow.ellipsis),
              ],
              items: [
                for (final d in Department.all)
                  DropdownMenuItem(
                    value: d.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.name, style: theme.textTheme.titleSmall),
                        Text(d.handles,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
              ],
              onChanged:
                  _busy ? null : (v) => setState(() => _department = v),
            ),
            const SizedBox(height: Space.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.translate_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: _lang,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  style: theme.textTheme.bodySmall,
                  items: [
                    for (final e in L10n.languages.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged:
                      _busy ? null : (v) => _setLang(v ?? 'en'),
                ),
              ],
            ),
            TextField(
              controller: _description,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _onDescriptionChanged,
              decoration: InputDecoration(
                hintText: _typingHint[_lang] ?? L10n.t('describe'),
              ),
            ),
            const SizedBox(height: Space.sm),
            Container(
              padding: const EdgeInsets.all(Space.sm + 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Corners.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Your complaint goes to the department you pick; AI sets '
                      'the priority. Your photo is the proof the admin sees — '
                      'your identity stays anonymous.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.send_rounded),
              label: Text(_busy ? _stage : L10n.t('submit')),
            ),
          ],
        ),
      ),
    );
  }
}
