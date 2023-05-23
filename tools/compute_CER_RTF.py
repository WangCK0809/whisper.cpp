

import argparse
import glob
from pathlib import Path


def get_params():
    parser = argparse.ArgumentParser()
    parser.add_argument('-wav_dir', type=str, required=True, help='dataset dir')
    parser.add_argument('-output_dir', type=str, required=True, help='dataset dir')
    return parser


def main():
    parser = get_params()
    args = parser.parse_args()

    root_path = Path(args.wav_dir)
    output_path = Path(args.output_dir)    # # text | RTF | CER

    total_decode_time_s = 0.0
    total_wav_time_s = 0.0

    with open(output_path.joinpath("text"), 'w', encoding="utf-8") as fout:
        for txt_path in root_path.glob("*.txt"):
            wav_name = str(txt_path.stem)
            with open(txt_path, 'r', encoding="utf-8") as fin:
                for line in fin.readlines():
                    if line.startswith("text"):
                        out_line = line.lstrip("text: ").rstrip("\r\t\n ")
                        fout.writelines(wav_name + " " + out_line)
                    elif line.startswith("decode_time_s"):
                        decode_time_s = float(line.lstrip("decode_time_s: ").rstrip("\r\t\n "))
                        total_decode_time_s += decode_time_s
                    elif line.startswith("wav_time_s"):
                        wav_time_s = float(line.lstrip("wav_time_s: ").rstrip("\r\t\n "))
                        total_wav_time_s += wav_time_s
                    else:
                        continue

    with open(output_path.joinpath("RTF"), 'w', encoding="utf-8") as fout:
        RTF = float(total_decode_time_s / total_wav_time_s)
        fout.writelines(f"total_decode_time_s = {total_decode_time_s}")
        fout.writelines(f"total_wav_time_s = {total_wav_time_s}")
        fout.writelines(f"RTF = {RTF}")


if __name__ == '__main__':
    main()
