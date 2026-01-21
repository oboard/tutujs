#!/bin/bash
python convert_test262.py
moon build
node test262_runner.js