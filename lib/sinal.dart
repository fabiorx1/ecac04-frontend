// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ModoSinal { ponto, linha, off }

class ECAC04Sinal {
  ECAC04Sinal({
    required this.name,
    this.color,
    this.f,
    this.ts,
    this.channel,
    this.modo = ModoSinal.linha,
    bool streaming = false,
  }) {
    if (streaming) stream = _stream();
  }
  final String name;
  final Color? color;
  int? ts;
  double? get fs => ts == null ? null : 1e3 / ts!;

  double? f;
  ModoSinal modo;

  WebSocketChannel? channel;
  Map<DateTime, double> buffer = {};
  late final t0 = DateTime.now().toLocal();
  DateTime? lastT;
  DateTime? lastButOneT;

  int get realTs => -((lastButOneT?.difference(lastT!))?.inMilliseconds ?? 0);
  double get realFs => realTs == 0 ? 0.0 : 1e3 / realTs;

  MapEntry<DateTime, double> add({DateTime? time, double? value}) {
    if (buffer.length >= 500) resetHalf();
    time ??= DateTime.now().toLocal();
    var t = time.difference(t0).inMilliseconds / 1e3;
    value ??= sin(2 * pi * (f ?? 1) * t);
    lastButOneT = lastT;
    lastT = time;
    buffer[time] = value;
    return MapEntry(time, value);
  }

  void reset() => buffer.clear();

  void resetHalf() {
    var half = buffer.length ~/ 2;
    var end = buffer.length - 1;
    buffer = {
      for (var entry in buffer.entries.toList().getRange(half, end))
        entry.key: entry.value
    };
  }

  void changeMode({ModoSinal? novoModo}) {
    if (novoModo != null) {
      modo = novoModo;
      return;
    }
    switch (modo) {
      case ModoSinal.ponto:
        modo = ModoSinal.linha;
        break;
      case ModoSinal.linha:
        modo = ModoSinal.off;
        break;
      case ModoSinal.off:
        modo = ModoSinal.ponto;
        break;
    }
  }

  late final Stream<MapEntry<DateTime, double>>? stream;

  Stream<MapEntry<DateTime, double>> _stream() async* {
    while (true) {
      var sample = add();
      if (channel != null) {
        channel!.sink
            .add(json.encode({sample.key.toIso8601String(): sample.value}));
      }
      yield sample;
      await Future.delayed(Duration(milliseconds: ts ?? 10));
    }
  }

  bool get visible => modo != ModoSinal.off && buffer.isNotEmpty;
  CartesianSeries<MapEntry<DateTime, double>, DateTime>? get series {
    switch (modo) {
      case ModoSinal.ponto:
        return ScatterSeries<MapEntry<DateTime, double>, DateTime>(
          name: name,
          color: color,
          dataSource: buffer.entries.toList(),
          xValueMapper: (e, _) => e.key,
          yValueMapper: (e, _) => e.value,
        );
      case ModoSinal.linha:
        return LineSeries<MapEntry<DateTime, double>, DateTime>(
          name: name,
          color: color,
          dataSource: buffer.entries.toList(),
          xValueMapper: (e, _) => e.key,
          yValueMapper: (e, _) => e.value,
        );
      case ModoSinal.off:
        return null;
    }
  }

  Widget get icon {
    switch (modo) {
      case ModoSinal.ponto:
        return Icon(Icons.circle, color: color);
      case ModoSinal.linha:
        return Icon(Icons.line_axis, color: color);
      case ModoSinal.off:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
  }

  Widget get tile => ListTile(
        leading: IconButton.outlined(onPressed: changeMode, icon: icon),
        title: Text(name),
        isThreeLine: true,
        subtitle: Text(
          'Amostragem Real: ${realFs.toStringAsFixed(2)} Hz | $realTs ms' +
              (ts != null
                  ? '\nAmostragem Alvo: ${fs!.toStringAsFixed(2)} Hz | $ts! ms'
                  : '') +
              (f != null
                  ? '\nFrequência do Sinal: ${f!.toStringAsFixed(2)} Hz'
                  : ''),
        ),
      );
}
