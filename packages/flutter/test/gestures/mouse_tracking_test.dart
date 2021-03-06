// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class TestGestureFlutterBinding extends BindingBase with ServicesBinding, SchedulerBinding, GestureBinding, SemanticsBinding, RendererBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null) {
      callback(event);
    }
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  final List<PointerEnterEvent> enter = <PointerEnterEvent>[];
  final List<PointerHoverEvent> move = <PointerHoverEvent>[];
  final List<PointerExitEvent> exit = <PointerExitEvent>[];
  final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
    onEnter: (PointerEnterEvent event) => enter.add(event),
    onHover: (PointerHoverEvent event) => move.add(event),
    onExit: (PointerExitEvent event) => exit.add(event),
  );
  // Only respond to some mouse events.
  final MouseTrackerAnnotation partialAnnotation = MouseTrackerAnnotation(
    onEnter: (PointerEnterEvent event) => enter.add(event),
    onHover: (PointerHoverEvent event) => move.add(event),
  );
  bool isInHitRegionOne;
  bool isInHitRegionTwo;

  void clear() {
    enter.clear();
    exit.clear();
    move.clear();
  }

  setUp(() {
    clear();
    isInHitRegionOne = true;
    isInHitRegionTwo = false;
    RendererBinding.instance.initMouseTracker(
      MouseTracker(
        GestureBinding.instance.pointerRouter,
        (Offset position) sync* {
          if (isInHitRegionOne)
            yield annotation;
          else if (isInHitRegionTwo) {
            yield partialAnnotation;
          }
        },
      ),
    );
    PointerEventConverter.clearPointers();
  });

  test('receives and processes mouse hover events', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover, // Will implicitly also add a PointerAdded event.
        physicalX: 0.0 * ui.window.devicePixelRatio,
        physicalY: 0.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet3 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.remove,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 201.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet4 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 301.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet5 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 401.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
        device: 1,
      ),
    ]);
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    RendererBinding.instance.mouseTracker.sendMouseNotifications(<int>{0});
    isInHitRegionOne = true;
    ui.window.onPointerDataPacket(packet1);
    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(0.0, 0.0)));
    expect(enter.first.device, equals(0));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(exit.length, equals(0), reason: 'exit contains $exit');
    expect(move.length, equals(1), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(0.0, 0.0)));
    expect(move.first.device, equals(0));
    expect(move.first.runtimeType, equals(PointerHoverEvent));
    clear();

    ui.window.onPointerDataPacket(packet2);
    expect(enter.length, equals(0), reason: 'enter contains $enter');
    expect(exit.length, equals(0), reason: 'exit contains $exit');
    expect(move.length, equals(1), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(1.0, 101.0)));
    expect(move.first.device, equals(0));
    expect(move.first.runtimeType, equals(PointerHoverEvent));
    clear();

    ui.window.onPointerDataPacket(packet3);
    expect(enter.length, equals(0), reason: 'enter contains $enter');
    expect(move.length, equals(1), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(1.0, 201.0)));
    expect(move.first.device, equals(0));
    expect(move.first.runtimeType, equals(PointerHoverEvent));
    expect(exit.length, equals(1), reason: 'exit contains $exit');
    expect(exit.first.position, equals(const Offset(1.0, 201.0)));
    expect(exit.first.device, equals(0));
    expect(exit.first.runtimeType, equals(PointerExitEvent));

    clear();
    ui.window.onPointerDataPacket(packet4);
    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(1.0, 301.0)));
    expect(enter.first.device, equals(0));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(exit.length, equals(0), reason: 'exit contains $exit');
    expect(move.length, equals(1), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(1.0, 301.0)));
    expect(move.first.device, equals(0));
    expect(move.first.runtimeType, equals(PointerHoverEvent));

    // add in a second mouse simultaneously.
    clear();
    ui.window.onPointerDataPacket(packet5);
    RendererBinding.instance.mouseTracker.sendMouseNotifications(<int>{1});
    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(1.0, 401.0)));
    expect(enter.first.device, equals(1));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(exit.length, equals(0), reason: 'exit contains $exit');
    expect(move.length, equals(2), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(1.0, 401.0)));
    expect(move.first.device, equals(1));
    expect(move.first.runtimeType, equals(PointerHoverEvent));
    expect(move.last.position, equals(const Offset(1.0, 401.0)));
    expect(move.last.device, equals(1));
    expect(move.last.runtimeType, equals(PointerHoverEvent));
  });

  test('detects exit when annotated layer no longer hit', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 0.0 * ui.window.devicePixelRatio,
        physicalY: 0.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 201.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    RendererBinding.instance.mouseTracker.sendMouseNotifications(<int>{0});

    ui.window.onPointerDataPacket(packet1);

    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(0.0, 0.0)));
    expect(enter.first.device, equals(0));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(move.length, equals(2), reason: 'move contains $move');
    expect(move.first.position, equals(const Offset(0.0, 0.0)));
    expect(move.first.device, equals(0));
    expect(move.first.runtimeType, equals(PointerHoverEvent));
    expect(move.last.position, equals(const Offset(1.0, 101.0)));
    expect(move.last.device, equals(0));
    expect(move.last.runtimeType, equals(PointerHoverEvent));
    expect(exit.length, equals(0), reason: 'exit contains $exit');
    // Simulate layer going away by detaching it.
    clear();
    isInHitRegionOne = false;

    ui.window.onPointerDataPacket(packet2);
    expect(enter.length, equals(0), reason: 'enter contains $enter');
    expect(move.length, equals(0), reason: 'enter contains $move');
    expect(exit.length, equals(1), reason: 'enter contains $exit');
    expect(exit.first.position, const Offset(1.0, 201.0));
    expect(exit.first.device, equals(0));
    expect(exit.first.runtimeType, equals(PointerExitEvent));

    // Actually detach annotation. Shouldn't receive hit.
    RendererBinding.instance.mouseTracker.detachAnnotation(annotation);
    clear();
    isInHitRegionOne = false;

    ui.window.onPointerDataPacket(packet2);
    expect(enter.length, equals(0), reason: 'enter contains $enter');
    expect(move.length, equals(0), reason: 'enter contains $move');
    expect(exit.length, equals(0), reason: 'enter contains $exit');
  });

  test("don't flip out if not all mouse events are listened to", () {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);

    isInHitRegionOne = false;
    isInHitRegionTwo = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(partialAnnotation);

    ui.window.onPointerDataPacket(packet);
    RendererBinding.instance.mouseTracker.detachAnnotation(partialAnnotation);
    isInHitRegionTwo = false;
  });

  test('detects exit when mouse goes away', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 0.0 * ui.window.devicePixelRatio,
        physicalY: 0.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.remove,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 201.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    RendererBinding.instance.mouseTracker.sendMouseNotifications(<int>{0});
    ui.window.onPointerDataPacket(packet1);
    ui.window.onPointerDataPacket(packet2);
    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(0.0, 0.0)));
    expect(enter.first.delta, equals(const Offset(0.0, 0.0)));
    expect(enter.first.device, equals(0));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(move.length, equals(3), reason: 'move contains $move');
    expect(move[0].position, equals(const Offset(0.0, 0.0)));
    expect(move[0].delta, equals(const Offset(0.0, 0.0)));
    expect(move[0].device, equals(0));
    expect(move[0].runtimeType, equals(PointerHoverEvent));
    expect(move[1].position, equals(const Offset(1.0, 101.0)));
    expect(move[1].delta, equals(const Offset(1.0, 101.0)));
    expect(move[1].device, equals(0));
    expect(move[1].runtimeType, equals(PointerHoverEvent));
    expect(move[2].position, equals(const Offset(1.0, 201.0)));
    expect(move[2].delta, equals(const Offset(0.0, 100.0)));
    expect(move[2].device, equals(0));
    expect(move[2].runtimeType, equals(PointerHoverEvent));
    expect(exit.length, equals(1), reason: 'exit contains $exit');
    expect(exit.first.position, equals(const Offset(1.0, 201.0)));
    expect(exit.first.delta, equals(const Offset(0.0, 0.0)));
    expect(exit.first.device, equals(0));
    expect(exit.first.runtimeType, equals(PointerExitEvent));
  });

  test('handles mouse down and move', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 0.0 * ui.window.devicePixelRatio,
        physicalY: 0.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
      ui.PointerData(
        change: ui.PointerChange.hover,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      ui.PointerData(
        change: ui.PointerChange.down,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 101.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
      ui.PointerData(
        change: ui.PointerChange.move,
        physicalX: 1.0 * ui.window.devicePixelRatio,
        physicalY: 201.0 * ui.window.devicePixelRatio,
        kind: PointerDeviceKind.mouse,
      ),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    RendererBinding.instance.mouseTracker.sendMouseNotifications(<int>{0});
    ui.window.onPointerDataPacket(packet1);
    ui.window.onPointerDataPacket(packet2);
    expect(enter.length, equals(1), reason: 'enter contains $enter');
    expect(enter.first.position, equals(const Offset(0.0, 0.0)));
    expect(enter.first.device, equals(0));
    expect(enter.first.runtimeType, equals(PointerEnterEvent));
    expect(move.length, equals(2), reason: 'move contains $move');
    expect(move[0].position, equals(const Offset(0.0, 0.0)));
    expect(move[0].device, equals(0));
    expect(move[0].runtimeType, equals(PointerHoverEvent));
    expect(move[1].position, equals(const Offset(1.0, 101.0)));
    expect(move[1].device, equals(0));
    expect(move[1].runtimeType, equals(PointerHoverEvent));
    expect(exit.length, equals(0), reason: 'exit contains $exit');
  });
}
