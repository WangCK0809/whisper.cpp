#!/bin/bash

# datasets="ASR20_new_test"
# datasets="ailab-test-600"
datasets="test"
data_root=/data1/joey.wang/speech/ASR/framework/wenet/code/decoder_wenet/benchmark/data

# 设置参数
model="./models/ggml-large.bin"
language="zh"

stage=1
stop_stage=2

for dataset in $datasets; do
    if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
        echo "Start decoding dataset: $dataset"
        output_file=./result/output_${dataset}.srt
        # 清空输出文件
        > "$output_file"
        wav_dir=$data_root/$dataset/wav
        for wav_file in $wav_dir/*.wav; do
            filename=$(basename "$wav_file" .wav)
            ./main -otxt -m "$model" -f "$wav_file" -l "$language" >> "$output_file"
            # 在输出文件中插入一个空行作为音频之间的分隔符
            echo "" >> "$output_file"
        done
        echo "End decoding dataset: $dataset"
    fi

    if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then

    fi    
done 

