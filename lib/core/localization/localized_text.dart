import 'package:flutter/material.dart' as material;

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Drop-in localized text for legacy presentation files.
///
/// This keeps proper names and user/backend content intact while translating
/// registered product copy. New code should use `context.tr` for non-Text
/// labels such as tooltips, input decorations, and semantic labels.
class Text extends material.StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    material.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final material.InlineSpan? textSpan;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    final translatedSemantics =
        semanticsLabel == null ? null : context.tr(semanticsLabel!);
    if (textSpan case final span?) {
      return material.Text.rich(
        _translateSpan(context, span),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: translatedSemantics,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return material.Text(
      context.tr(data!),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: translatedSemantics,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  material.InlineSpan _translateSpan(
    material.BuildContext context,
    material.InlineSpan span,
  ) {
    if (span is! material.TextSpan) return span;
    return material.TextSpan(
      text: span.text == null ? null : context.tr(span.text!),
      children: span.children
          ?.map((child) => _translateSpan(context, child))
          .toList(growable: false),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel:
          span.semanticsLabel == null ? null : context.tr(span.semanticsLabel!),
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}
