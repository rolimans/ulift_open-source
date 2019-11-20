import 'package:flutter_driver/flutter_driver.dart';

import 'package:test/test.dart';

void main(){
  group('Counter App', () {
    final counterTextFinder = find.byValueKey('counter');
    final buttonFinder = find.byValueKey('button');

    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        driver.close();
      }
    });

    test('starts at 0', () async {
      expect(await driver.getText(counterTextFinder), "0");
    });

    test('increments the counter', () async {
      await driver.tap(buttonFinder);

      // Then, verify the counter text has been incremented by 1
      expect(await driver.getText(counterTextFinder), "1");
    });
  });
}