#!/bin/bash

datasets="ASR20_new_test"
# datasets="ailab-test-600"
# datasets="test"
data_root=/data1/joey.wang/speech/ASR/framework/wenet/code/decoder_wenet/benchmark/data

# 设置参数
model_scale=small
model="./models/ggml-${model_scale}.bin"
language="zh"

stage=1
stop_stage=2

for dataset in $datasets; do
    if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
        echo "Start decoding dataset: $dataset"
        # output_file=./result/output_${dataset}.srt
        output_dir=./result/output_${dataset}
        mkdir -p $output_dir
        # 清空输出文件
        # > "$output_file"
        wav_dir=$data_root/$dataset/wav
        for wav_file in $wav_dir/*.wav; do
            filename=$(basename "$wav_file" .wav)
            rm $wav_dir/$filename.wav.txt
            ./main -otxt -m "$model" -f "$wav_file" -l "$language"
            # 在输出文件中插入一个空行作为音频之间的分隔符
            # echo "" >> "$output_file"
        done
        echo "End decoding dataset: $dataset"

        echo "merge result and compute RTF"
        python3 ./tools/compute_CER_RTF.py -wav_dir $wav_dir -output_dir $output_dir
    fi

    if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
        echo "222"
    fi    
done 

