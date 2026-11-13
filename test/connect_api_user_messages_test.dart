import 'package:flutter_test/flutter_test.dart';

import 'package:acaf/services/connect_api.dart';

void main() {
  test('traduz erro de plano inativo para linguagem do associado', () {
    expect(
      ConnectApi.userFacingMessage('Não há assinatura Connect ativa para este titular.'),
      contains('Não encontramos um plano ativo'),
    );
    expect(
      ConnectApi.userFacingMessage(
        'Não encontramos um plano app ativo para este cadastro. Assine um plano ou confira se o benefício da empresa já foi liberado.',
      ),
      contains('Minha conta'),
    );
  });

  test('preserva mensagens não mapeadas', () {
    const custom = 'Cartão recusado pelo emissor.';
    expect(ConnectApi.userFacingMessage(custom), custom);
  });
}
