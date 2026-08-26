import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/menu_item.dart';

class VariantSelector extends StatelessWidget {
  final MenuVariant variant;
  final List<VariantOption> selectedOptions;
  final ValueChanged<VariantOption?> onSingleOptionSelected;
  final void Function(VariantOption option, bool isSelected) onToggleOption;
  final VoidCallback onClearSelection;
  final bool isClosed;

  const VariantSelector({
    super.key,
    required this.variant,
    required this.selectedOptions,
    required this.onSingleOptionSelected,
    required this.onToggleOption,
    required this.onClearSelection,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMulti = variant.maxSelections > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'Choose ${variant.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (variant.isRequired || variant.minSelections > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '* Required (Min: ${variant.minSelections})',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                const Text(
                  '(Optional)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
              if (isMulti) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Max: ${variant.maxSelections}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (!variant.isRequired &&
                  variant.minSelections == 0 &&
                  selectedOptions.isNotEmpty) ...[
                const Spacer(),
                GestureDetector(
                  onTap: isClosed ? null : onClearSelection,
                  child: Text(
                    'Clear Selection',
                    style: TextStyle(
                      color: isClosed ? Colors.grey : AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variant.options.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: AppColors.border,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final option = variant.options[index];
              final isSelected = selectedOptions.any((o) => o.id == option.id);

              if (isMulti) {
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: isClosed ? null : (checked) => onToggleOption(option, checked ?? false),
                  title: Text(
                    option.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  secondary: option.additionalPrice > 0
                      ? Text(
                          '+ ${CurrencyFormatter.format(option.additionalPrice)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                );
              } else {
                return RadioListTile<String>(
                  value: option.id,
                  groupValue: selectedOptions.isNotEmpty ? selectedOptions.first.id : null,
                  onChanged: isClosed ? null : (_) => onSingleOptionSelected(option),
                  title: Text(
                    option.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  secondary: option.additionalPrice > 0
                      ? Text(
                          '+ ${CurrencyFormatter.format(option.additionalPrice)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
