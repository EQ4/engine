// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:typed_data';

ui.Color color;

ui.Picture paint(ui.Rect paintBounds) {
  ui.PictureRecorder recorder = new ui.PictureRecorder();
  ui.Canvas canvas = new ui.Canvas(recorder, paintBounds);
  ui.Size size = paintBounds.size;

  double radius = size.shortestSide * 0.45;
  ui.Paint paint = new ui.Paint()
    ..color = color;
  canvas.drawCircle(size.center(ui.Point.origin), radius, paint);

  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.view.devicePixelRatio;
  ui.Rect sceneBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width * devicePixelRatio, ui.view.height * devicePixelRatio);
  Float64List deviceTransform = new Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  ui.SceneBuilder sceneBuilder = new ui.SceneBuilder(sceneBounds)
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture, paintBounds)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(double timeStamp) {
  ui.Rect paintBounds = new ui.Rect.fromLTWH(0.0, 0.0, ui.view.width, ui.view.height);
  ui.Picture picture = paint(paintBounds);
  ui.Scene scene = composite(picture, paintBounds);
  ui.view.scene = scene;
}

bool handleEvent(ui.Event event) {
  if (event.type == 'pointerdown') {
    color = new ui.Color.fromARGB(255, 0, 0, 255);
    ui.view.scheduleFrame();
    return true;
  }

  if (event.type == 'pointerup') {
    color = new ui.Color.fromARGB(255, 0, 255, 0);
    ui.view.scheduleFrame();
    return true;
  }

  if (event.type == 'back') {
    print('Pressed back button.');
    return true;
  }

  return false;
}

void main() {
  print('Hello, world');
  color = new ui.Color.fromARGB(255, 0, 255, 0);
  ui.view.setFrameCallback(beginFrame);
  ui.view.setEventCallback(handleEvent);
  ui.view.scheduleFrame();
}
