import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

enum AuthViewport { mobile, tablet, desktop }

class AuthFeature {
  const AuthFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.viewport,
    required this.eyebrow,
    required this.heroTitle,
    required this.panelTitle,
    required this.form,
    this.backLabel,
    this.onBack,
    this.features = const <AuthFeature>[],
  });

  final AuthViewport viewport;
  final String eyebrow;
  final String heroTitle;
  final String panelTitle;
  final String? backLabel;
  final VoidCallback? onBack;
  final Widget form;
  final List<AuthFeature> features;

  @override
  Widget build(BuildContext context) {
    final isMobile = viewport == AuthViewport.mobile;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppTheme.clayBg),
        child: SafeArea(
          child: isMobile ? _buildMobile(context) : _buildDesktop(context),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.claySurface,
              border: Border.all(color: AppTheme.clayBorder2, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(backLabel ?? 'Back'),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  panelTitle,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                form,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      heroTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Farm management built for simplicity and scale.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    for (final feature in features) ...[
                      _FeatureItem(feature: feature),
                      const SizedBox(height: 16),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.claySurface,
                    border: Border.all(color: AppTheme.clayBorder2, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (onBack != null) ...<Widget>[
                        TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(backLabel ?? 'Back'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        panelTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      form,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.feature});

  final AuthFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          feature.icon,
          color: AppTheme.terra400,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                feature.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
