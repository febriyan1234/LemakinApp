import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/menu_item.dart';

class VariantSelector extends StatelessWidget {
  final MenuVariant variant;
  final VariantOption? selectedOption;
  final ValueChanged<VariantOption?> onOptionSelected;

  const VariantSelector({
    super.key,
    required this.variant,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
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
              if (variant.maxSelections > 1) ...[
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
              if (!variant.isRequired && variant.minSelections == 0 && selectedOption != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => onOptionSelected(null),
                  child: const Text(
                    'Clear Selection',
                    style: TextStyle(
                      color: AppColors.primary,
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

              return RadioListTile<String>(
                value: option.id,
                groupValue: selectedOption?.id,
                onChanged: (_) => onOptionSelected(option),
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
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
