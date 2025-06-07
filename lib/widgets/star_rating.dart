import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool allowHalfRating;
  final ValueChanged<double>? onRatingChanged;
  final int maxStars;
  final MainAxisAlignment alignment;
  final EdgeInsets padding;

  const StarRating({
    Key? key,
    required this.rating,
    this.size = 24.0,
    this.color,
    this.allowHalfRating = true,
    this.onRatingChanged,
    this.maxStars = 5,
    this.alignment = MainAxisAlignment.start,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.primary;
    final isInteractive = onRatingChanged != null;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignment,
        children: List.generate(maxStars, (index) {
          // Calculate the star value (full, half, or empty)
          final starValue = index + 1;
          final isFullStar = rating >= starValue;
          final isHalfStar =
              allowHalfRating && rating > index && rating < starValue;

          // Determine which icon to use
          IconData starIcon;
          if (isFullStar) {
            starIcon = Icons.star;
          } else if (isHalfStar) {
            starIcon = Icons.star_half;
          } else {
            starIcon = Icons.star_border;
          }

          return GestureDetector(
            onTap: isInteractive
                ? () => onRatingChanged!(starValue.toDouble())
                : null,
            onHorizontalDragUpdate: isInteractive
                ? (details) {
                    // Get the RenderBox of the widget
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition =
                        box.globalToLocal(details.globalPosition);

                    // Calculate the width of each star
                    final starWidth = box.size.width / maxStars;

                    // Calculate which star we're on
                    final starPosition = localPosition.dx / starWidth;

                    // Clamp between 0 and maxStars
                    final rating = starPosition.clamp(0.0, maxStars.toDouble());

                    // Round to nearest half or whole number based on allowHalfRating
                    double newRating;
                    if (allowHalfRating) {
                      newRating = (rating * 2).round() / 2;
                    } else {
                      newRating = rating.round().toDouble();
                    }

                    // Update the rating
                    onRatingChanged!(newRating);
                  }
                : null,
            child: Icon(
              starIcon,
              color: starIcon == Icons.star_border
                  ? starColor.withOpacity(0.3)
                  : starColor,
              size: size,
            ),
          );
        }),
      ),
    );
  }
}

// Preview the rating with text
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double starSize;
  final bool showCount;
  final TextStyle? textStyle;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.totalRatings = 0,
    this.starSize = 16.0,
    this.showCount = true,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(
          rating: rating,
          size: starSize,
          padding: const EdgeInsets.only(right: 4),
        ),
        Text(
          rating.toStringAsFixed(1),
          style: textStyle ?? defaultTextStyle,
        ),
        if (showCount && totalRatings > 0)
          Text(
            ' (${totalRatings})',
            style: textStyle ?? defaultTextStyle,
          ),
      ],
    );
  }
}
