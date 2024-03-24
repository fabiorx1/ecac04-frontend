import 'dart:convert';

import 'package:app/sinal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// const host = "ec2-3-85-104-254.compute-1.amazonaws.com";
const host = "ecac04.mywire.org";

class AmostradorPage extends StatefulWidget {
  const AmostradorPage(
      {super.key,
      required this.title,
      this.minTs = 300,
      this.maxTs = 3e3,
      this.minF = .1,
      this.maxF = 8});
  final String title;
  final double minTs;
  final double maxTs;
  final double minF;
  final double maxF;

  @override
  State<AmostradorPage> createState() => _AmostradorPageState();
}

class _AmostradorPageState extends State<AmostradorPage> {
  late final tooltipBehavior = TooltipBehavior(enable: true);

  late final analog = ECAC04Sinal(
    name: 'Sinal Real',
    color: Colors.lightBlue,
    f: widget.minF,
    streaming: true,
  );
  late final digital = ECAC04Sinal(
    name: 'Sinal Amostrado',
    color: Colors.deepPurple,
    channel: channel,
    f: widget.minF,
    ts: widget.minTs.toInt(),
    streaming: true,
  );
  final echo = ECAC04Sinal(
    name: 'Sinal Ecoado',
    color: Colors.red.shade800,
  );

  final channel = WebSocketChannel.connect(Uri.parse('wss://$host/ws/echo'));
  late final digitalTsCtrl = ValueNotifier<double>(widget.minTs);
  late final analogFCtrl = ValueNotifier<double>(widget.minF);

  @override
  void initState() {
    super.initState();

    analogFCtrl.addListener(
      () {
        analog.f = analogFCtrl.value;
        digital.f = analogFCtrl.value;
      },
    );
    digitalTsCtrl.addListener(
      () => digital.ts = digitalTsCtrl.value.toInt(),
    );
    digital.stream!.listen((event) {});
    channel.stream.listen(
      (event) {
        var map = json.decode(event);
        echo.add(time: DateTime.parse(map.keys.first), value: map.values.first);
      },
    );
  }

  @override
  void dispose() {
    digitalTsCtrl.dispose();
    analogFCtrl.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style:
                textTheme.titleMedium!.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: StreamBuilder<MapEntry<DateTime, double>>(
          stream: analog.stream,
          builder: (context, snapshot) {
            return ListView(
              children: [
                SizedBox(
                  height: 326,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SfCartesianChart(
                      title: ChartTitle(
                        text:
                            'Frequência do Dispositivo:\n${analog.realFs.toStringAsFixed(2)} Hz',
                        alignment: ChartAlignment.center,
                      ),
                      primaryXAxis: DateTimeAxis(dateFormat: DateFormat.Hms()),
                      primaryYAxis: const NumericAxis(name: 'Amplitude'),
                      tooltipBehavior: tooltipBehavior,
                      series: [
                        if (analog.visible) analog.series!,
                        if (digital.visible) digital.series!,
                        if (echo.visible) echo.series!
                      ],
                    ),
                  ),
                ),
                Center(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Resetar Buffers'),
                    onPressed: () {
                      analog.reset();
                      digital.reset();
                      echo.reset();
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  isThreeLine: true,
                  title: Text(
                      'Frequência do Sinal: ${analogFCtrl.value.toStringAsFixed(2)} Hz'),
                  subtitle: Slider(
                    thumbColor: analog.color,
                    activeColor: analog.color,
                    min: widget.minF,
                    max: widget.maxF,
                    value: analogFCtrl.value,
                    onChanged: (value) => analogFCtrl.value = value,
                  ),
                ),
                analog.tile,
                const Divider(),
                ListTile(
                  isThreeLine: true,
                  title: Text(
                      'Tempo de Amostragem: ${digitalTsCtrl.value.toInt()} ms'),
                  subtitle: Slider(
                    thumbColor: digital.color,
                    activeColor: digital.color,
                    min: widget.minTs,
                    max: widget.maxTs,
                    value: digitalTsCtrl.value,
                    onChanged: (value) => digitalTsCtrl.value = value,
                  ),
                ),
                digital.tile,
                const Divider(),
                echo.tile,
                const SizedBox(height: 12),
              ],
            );
          }),
    );
  }
}
