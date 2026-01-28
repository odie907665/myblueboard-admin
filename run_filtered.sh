#!/bin/bash
flutter run -d macos 2>&1 | grep -v "FlutterQuillEmbeds" | grep -v "QuillRawEditor" | grep -v "quill_native_bridge" | grep -v "^\[        \]" | grep -v "warning:" | grep -v "Run script build phase"
