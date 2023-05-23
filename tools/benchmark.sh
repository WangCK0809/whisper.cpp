#!/bin/bash

datasets="ASR20_new_test ailab-test-600 ailab-test-20170421 ailab-test-20170615 command-20170607 huiting-test-1000"
datasets="test1 test2"
data_root=/data1/joey.wang/speech/ASR/framework/wenet/code/decoder_wenet/benchmark/data

# 设置参数
model_scales="small medium large"
# model="./models/ggml-${model_scale}.bin"
language="zh"

for model_scale in $model_scales; do
    model="./models/ggml-${model_scale}.bin"

    for dataset in $datasets; do
        echo "Start decoding dataset: $dataset"
        # output_file=./result/output_${dataset}.srt
        output_dir=./result/output_${model_scale}_${dataset}
        mkdir -p $output_dir
        # 清空输出文件
        # > "$output_file"
        wav_dir=$data_root/$dataset/wav
        for wav_file in $wav_dir/*.wav; do
            filename=$(basename "$wav_file" .wav)
            # rm $wav_dir/$filename.wav.txt
            ./main -otxt -m "$model" -f "$wav_file" -l "$language"
            # 在输出文件中插入一个空行作为音频之间的分隔符
            # echo "" >> "$output_file"
        done
        tmp_dir=$wav_dir/output_${model_scale}_${dataset}
        mkdir -p $tmp_dir
        mv $wav_dir/*.wav.txt $tmp_dir/
        echo "End decoding dataset: $dataset"

        echo "merge result and compute RTF"
        python3 ./tools/compute_CER_RTF.py -wav_dir $wav_dir -output_dir $output_dir
    done
done




