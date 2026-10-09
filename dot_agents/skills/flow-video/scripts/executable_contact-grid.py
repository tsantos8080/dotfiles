#!/usr/bin/env python3
"""Gera uma imagem com um quadro de cada legenda, para conferir o vídeo final.

Uso: contact-grid.py --video final.mp4 --marks FV_DIR/marcas-ID.txt --out grade.png [--offset 1.5]

Pega um quadro OFFSET segundos depois do início de cada legenda e monta uma
grade de duas colunas (640 px cada). Abra a imagem e confira se cada legenda
aparece no passo certo e se a caixa não cobre nada importante.
"""
import argparse
import os
import re
import subprocess
import tempfile


def frame_height(path: str) -> int:
    # ffprobe nem sempre está instalado; o "ffmpeg -i" mostra o tamanho no stderr
    info = subprocess.run(["ffmpeg", "-hide_banner", "-i", path], capture_output=True, text=True).stderr
    m = re.search(r"Video: .*?, (\d+)x(\d+)", info)
    return int(m.group(2)) if m else 400


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--video", required=True)
    p.add_argument("--marks", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--offset", type=float, default=1.5)
    a = p.parse_args()

    marks = [line.split() for line in open(a.marks) if line.strip() and not line.startswith("fim")]
    tmp = tempfile.mkdtemp(prefix="flow-video-")
    frames = []
    for k, t in marks:
        frame = os.path.join(tmp, f"{k}.png")
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", str(float(t) + a.offset), "-i", a.video,
                        "-frames:v", "1", "-vf", "scale=640:-2", frame], check=True)
        frames.append(frame)

    if len(frames) == 1:
        os.replace(frames[0], a.out)
    else:
        args = ["ffmpeg", "-loglevel", "error", "-y"]
        for f in frames:
            args += ["-i", f]
        h = frame_height(frames[0])
        layout = "|".join(f"{(j % 2) * 640}_{(j // 2) * h}" for j in range(len(frames)))
        args += ["-filter_complex", "".join(f"[{j}]" for j in range(len(frames)))
                 + f"xstack=inputs={len(frames)}:layout={layout}:fill=black", a.out]
        subprocess.run(args, check=True)
    print(a.out)


if __name__ == "__main__":
    main()
