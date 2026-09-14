import 'package:flutter/material.dart';

/// A reusable component for selecting a star rating from 1 to 5.
class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= rating;

        return Semantics(
          label: '$starValue star${starValue == 1 ? '' : 's'}',
          button: true,
          selected: isSelected,
          child: GestureDetector(
            onTap: onRatingChanged != null ? () => onRatingChanged!(starValue) : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: isSelected ? Colors.amber : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        );
      }),
    );
  }
}
