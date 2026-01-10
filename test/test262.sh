#!/bin/bash
# 提取最后一行的前两个数字
dir=$(dirname "$0")
last_line=$(moon test --package oboard/tutujs/test --target wasm | tail -n 1)
first_two_numbers=$(echo "$last_line" | grep -o -E '[0-9]+' | head -n 2 | tr '\n' ' ')

# 输出提取的两个数字
echo "$first_two_numbers"

# 将提取的两个数字作为参数调用 Python 脚本生成进度 SVG
python $dir/generate_progress_svg.py $first_two_numbers $dir/test262_progress.svg