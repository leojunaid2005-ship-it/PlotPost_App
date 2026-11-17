import 'package:flutter/material.dart';

import '../models/enquiry.dart';
import '../models/property_post.dart';
import '../theme/app_colors.dart';

class ShowInterestScreen extends StatefulWidget {
  const ShowInterestScreen({
    super.key,
    required this.post,
    required this.onSubmitted,
  });

  final PropertyPost post;
  final ValueChanged<Enquiry> onSubmitted;

  @override
  State<ShowInterestScreen> createState() => _ShowInterestScreenState();
}

class _ShowInterestScreenState extends State<ShowInterestScreen> {
  static const _methods = ['Phone call', 'WhatsApp', 'Email'];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  late final TextEditingController _message;

  String _method = _methods.first;
  bool _wantsVisit = false;
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(
      text:
          'Hi, I am interested in "${widget.post.title}". '
          'Please share more details.',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);

    // Frontend preview: a short delay stands in for the network request.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    widget.onSubmitted(
      Enquiry(
        postTitle: widget.post.title,
        seller: widget.post.seller,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        message: _message.text.trim(),
        contactMethod: _method,
        wantsVisit: _wantsVisit,
        sentAt: DateTime.now(),
      ),
    );
    setState(() {
      _sending = false;
      _sent = true;
    });
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
      );

  Widget _propertySummary(ColorScheme colors) {
    final post = widget.post;
    final price = post.price.trim().isEmpty
        ? 'Price on request'
        : post.price.trim();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.home_work_outlined, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$price · ${post.seller}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: plotPostTextAccent(context, colors.secondary),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(ColorScheme colors) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Text(
            'Contact the seller',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Share your details and ${widget.post.seller} can get back to you.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 18),
          _propertySummary(colors),
          const SizedBox(height: 22),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _input('Your name', icon: Icons.person_outline_rounded),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _input(
              'Phone number',
              hint: 'e.g. +91 98950 00000',
              icon: Icons.phone_outlined,
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isEmpty) return 'Enter your phone number';
              if (digits.length < 10 || digits.length > 13) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _input('Email (optional)', icon: Icons.email_outlined),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return null;
              final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value);
              return valid ? null : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Preferred way to be contacted',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _methods
                .map(
                  (method) => ChoiceChip(
                    label: Text(method),
                    selected: _method == method,
                    selectedColor: colors.primary.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _method = method),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _input('Message'),
            validator: (v) => v == null || v.trim().length < 10
                ? 'Write a short message (at least 10 characters)'
                : null,
          ),
          const SizedBox(height: 6),
          CheckboxListTile(
            value: _wantsVisit,
            onChanged: (value) => setState(() => _wantsVisit = value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: colors.primary,
            checkColor: colors.onPrimary,
            title: const Text(
              'I would like to schedule a visit',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_sending ? 'Sending…' : 'Send interest'),
          ),
          const SizedBox(height: 10),
          Text(
            'Frontend preview: your enquiry is kept on this device only. Sending it to the seller will be connected when the backend is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _success(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 44, color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Interest sent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.post.seller} will contact you by ${_method.toLowerCase()}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to property'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Show interest',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(child: _sent ? _success(colors) : _form(colors)),
    );
  }
}
