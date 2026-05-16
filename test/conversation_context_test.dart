import 'package:elegantfaso/models/messages/conversation_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationContext', () {
    test('normalise an unknown type to general', () {
      final context = ConversationContext.fromMap({
        'type': 'unknown',
        'title': 'Discussion test',
      });

      expect(context.type, ConversationContextTypes.general);
      expect(context.title, 'Discussion test');
    });

    test('detects meaningful business context', () {
      const context = ConversationContext(
        type: ConversationContextTypes.product,
        id: 'product-1',
        title: 'Robe cérémonie',
      );

      expect(context.hasContent, isTrue);
      expect(context.toMap()['type'], ConversationContextTypes.product);
    });

    test('empty context stays lightweight', () {
      const context = ConversationContext();

      expect(context.hasContent, isFalse);
      expect(context.toMap()['type'], ConversationContextTypes.general);
    });
  });
}
