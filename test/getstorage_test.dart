import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/src/storage_impl.dart';
import 'package:get_storage/src/read_write_value.dart';

import 'utils/list_equality.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  GetStorage g;

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  void setUpMockChannels(MethodChannel channel) {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.';
      }
    });
  }

  setUpAll(() async {
    setUpMockChannels(channel);
  });

  setUp(() async {
    await GetStorage.init();
    g = GetStorage();
    await g.erase();
  });

  test('write, read listen, e removeListen', () async {
    String valueListen = "";
    g.write('test', 'a');

    final removeListen = g.listen(() {
      valueListen = g.read('test');
    });

    expect('a', g.read('test'));

    await g.write('test', 'b');
    expect('b', g.read<String>('test'));
    expect('b', valueListen);

    removeListen();

    await g.write('test', 'c');

    expect('c', g.read<String>('test'));
    expect('b', valueListen);
    await g.write('test', 'd');

    expect('d', g.read<String>('test'));
  });

  test('Write and read', () {
    var list = new List<int>.generate(50, (i) {
      int count = i + 1;
      g.write('write', count);
      return count;
    });

    expect(list.last, g.read('write'));
  });

  test('Write and read using delegate', () {
    final data = 0.val('write');
    var list = new List<int>.generate(50, (i) {
      int count = i + 1;
      data.val = count;
      return count;
    });

    expect(list.last, data.val);
  });

  test('Write, read, remove and exists', () {
    expect(null, g.read('write'));

    var list = new List<int>.generate(50, (i) {
      int count = i + 1;
      g.write('write', count);
      return count;
    });
    expect(list.last, g.read('write'));
    g.remove('write');
    expect(null, g.read('write'));
  });

  test('newContainer', () async {
    final container1 = await GetStorage.init('container1');
    await GetStorage.init('newContainer');
    final newContainer = GetStorage('newContainer');

    /// Attempting to start a Container that has already started must return the container already created.
    var container2 = await GetStorage.init();
    expect(container1 == container2, true);

    newContainer.write('test', '1234');
    g.write('test', 'a');
    expect(g.read('test') == newContainer.read('test'), false);
  });

  group('get keys/values', () {
    Function(Iterable, List) eq =
        (i, l) => const ListEquality().equals(i.toList(), l);

    test('should return their stored dynamic values', () {
      expect(eq(g.getKeys().toList(), []), true);
      expect(eq(g.getValues().toList(), []), true);

      g.write('key1', 1);
      expect(eq(g.getKeys(), ['key1']), true);
      expect(eq(g.getValues(), [1]), true);

      g.write('key2', 'a');
      expect(eq(g.getKeys(), ['key1', 'key2']), true);
      expect(eq(g.getValues(), [1, 'a']), true);

      g.write('key3', 3.0);
      expect(eq(g.getKeys(), ['key1', 'key2', 'key3']), true);
      expect(eq(g.getValues(), [1, 'a', 3.0]), true);
    });
  });
}
