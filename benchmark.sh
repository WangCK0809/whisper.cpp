#!/bin/bash

datasets="ASR20_new_test"
data_root=/data1/joey.wang/speech/ASR/framework/wenet/code/decoder_wenet/benchmark/data

# 设置参数
model="./models/ggml-medium.bin"  # 模型文件路径
language="zh"  # 语种
output_file="output.srt"  # 输出文件路径

# 清空输出文件
> "$output_file"

for dataset in $datasets; do
    wav_dir=$data_root/$dataset/wav
    # 遍历ASR_auto_test目录下的所有wav文件
    for wav_file in $wav_dir/*.wav; do
        # 提取文件名（不包含路径和扩展名）
        filename=$(basename "$wav_file" .wav)
        
        # 执行解码命令并将输出追加到输出文件
        ./main -osrt -m "$model" -f "$wav_file" -l "$language" >> "$output_file"
        
        # 在输出文件中插入一个空行作为音频之间的分隔符
        echo "" >> "$output_file"
    done
done 


echo "解码测试完成。输出文件：$output_file"

