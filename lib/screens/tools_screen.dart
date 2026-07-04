// tools_screen.dart
//
// Stage 4 (stretch): Impact Tolerance Configurator + Nth-Party Dependency Mapper with
// concentration-risk detection. Entries persist locally and ground the Assistant's
// 'tolerance' and 'third-party' pillars (see ToolsState.groundingForPillar).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.dart';
import '../models/app_state.dart';
import '../models/tools.dart';
import '../models/tools_state.dart';
import '../theme/app_theme.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>().s;
    final tools = context.watch<ToolsState>();
    final risks = tools.concentrationRisks();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.toolsIntro, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 20),

            // ---- Impact Tolerance Configurator ----
            _SectionHeader(icon: Icons.timer_outlined, title: s.impactToleranceTitle),
            const SizedBox(height: 8),
            if (tools.tolerances.isEmpty)
              _EmptyHint(s.emptyTolerance)
            else
              ...tools.tolerances.asMap().entries.map(
                    (e) => _ToleranceCard(
                      entry: e.value,
                      onDelete: () => tools.removeTolerance(e.key),
                    ),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addTolerance(context, s),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.add),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // ---- Nth-Party Dependency Mapper ----
            _SectionHeader(icon: Icons.hub_outlined, title: s.nthPartyTitle),
            const SizedBox(height: 8),
            if (tools.vendors.isEmpty)
              _EmptyHint(s.emptyVendors)
            else
              ...tools.vendors.asMap().entries.map(
                    (e) => _VendorCard(
                      entry: e.value,
                      onDelete: () => tools.removeVendor(e.key),
                    ),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addVendor(context, s),
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.add),
              ),
            ),

            const SizedBox(height: 16),
            _ConcentrationPanel(risks: risks, strings: s),
          ],
        ),
      ),
    );
  }

  Future<void> _addTolerance(BuildContext context, AppStrings s) async {
    final entry = await showDialog<ToleranceEntry>(
      context: context,
      builder: (_) => _ToleranceDialog(strings: s),
    );
    if (entry != null && context.mounted) {
      context.read<ToolsState>().addTolerance(entry);
    }
  }

  Future<void> _addVendor(BuildContext context, AppStrings s) async {
    final entry = await showDialog<VendorEntry>(
      context: context,
      builder: (_) => _VendorDialog(strings: s),
    );
    if (entry != null && context.mounted) {
      context.read<ToolsState>().addVendor(entry);
    }
  }
}

// ───────────────────────── shared bits ─────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.color = AppColors.accent});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ToleranceCard extends StatelessWidget {
  const _ToleranceCard({required this.entry, required this.onDelete});
  final ToleranceEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.service,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (entry.objectives.isEmpty)
                    const Text('—', style: TextStyle(color: AppColors.textSecondary))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.objectives.map((o) => _Tag(o, color: AppColors.primary)).toList(),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.entry, required this.onDelete});
  final VendorEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.vendor,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (entry.service.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(entry.service,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  const SizedBox(height: 8),
                  if (entry.nthParties.isEmpty)
                    const Text('—', style: TextStyle(color: AppColors.textSecondary))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.nthParties.map((p) => _Tag(p)).toList(),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentrationPanel extends StatelessWidget {
  const _ConcentrationPanel({required this.risks, required this.strings});
  final List<ConcentrationRisk> risks;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final hasRisk = risks.isNotEmpty;
    final accent = hasRisk ? AppColors.warn : AppColors.good;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(hasRisk ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  strings.concentrationRisk,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!hasRisk)
              Text(strings.noConcentrationRisk,
                  style: const TextStyle(color: AppColors.textSecondary))
            else
              ...risks.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Tag(r.nthParty, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              strings.sharedByVendorsLabel(r.count),
                              style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.vendors.join(' · '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── dialogs ─────────────────────────

class _ToleranceDialog extends StatefulWidget {
  const _ToleranceDialog({required this.strings});
  final AppStrings strings;

  @override
  State<_ToleranceDialog> createState() => _ToleranceDialogState();
}

class _ToleranceDialogState extends State<_ToleranceDialog> {
  final _service = TextEditingController();
  final _rto = TextEditingController();
  final _rpo = TextEditingController();
  final _mtpd = TextEditingController();
  final _srto = TextEditingController();

  @override
  void dispose() {
    for (final c in [_service, _rto, _rpo, _mtpd, _srto]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final service = _service.text.trim();
    if (service.isEmpty) return;
    Navigator.of(context).pop(ToleranceEntry(
      service: service,
      rto: _rto.text.trim(),
      rpo: _rpo.text.trim(),
      mtpd: _mtpd.text.trim(),
      srto: _srto.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.impactToleranceTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_service, s.serviceName),
            _field(_rto, 'RTO'),
            _field(_rpo, 'RPO'),
            _field(_mtpd, 'MTPD'),
            _field(_srto, 'SRTO'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(s.add)),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _VendorDialog extends StatefulWidget {
  const _VendorDialog({required this.strings});
  final AppStrings strings;

  @override
  State<_VendorDialog> createState() => _VendorDialogState();
}

class _VendorDialogState extends State<_VendorDialog> {
  final _vendor = TextEditingController();
  final _service = TextEditingController();
  final _nthParties = TextEditingController();

  @override
  void dispose() {
    for (final c in [_vendor, _service, _nthParties]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final vendor = _vendor.text.trim();
    if (vendor.isEmpty) return;
    final parties = _nthParties.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    Navigator.of(context).pop(VendorEntry(
      vendor: vendor,
      service: _service.text.trim(),
      nthParties: parties,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.nthPartyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_vendor, s.vendorName),
            _field(_service, s.serviceProvided),
            _field(_nthParties, s.nthPartiesLabel),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(s.add)),
      ],
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
