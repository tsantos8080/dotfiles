#!/usr/bin/env python3
"""Grava as legendas no vídeo bruto.

Uso: burn-captions.py --dir FV_DIR --flow ID --raw bruto.mp4 --out final.mp4

Lê FV_DIR/legendas.json ({"ID": ["legenda 1", ...]}) e FV_DIR/marcas-ID.txt
(linhas "N segundos", terminando em "fim segundos"). Cada legenda fica na tela
do seu início até o início da próxima. Estilo: texto branco em caixa única
preta a 60%, centralizada embaixo, linhas de tamanho parecido.
"""
import argparse
import json
import math
import os
import re
import subprocess
import textwrap


def wrap(text: str, max_width: int = 66) -> str:
    lines = math.ceil(len(text) / max_width)
    if lines <= 1:
        return text
    return "\n".join(textwrap.wrap(text, math.ceil(len(text) / lines) + 6))


def video_height(path: str) -> int:
    info = subprocess.run(["ffmpeg", "-hide_banner", "-i", path], capture_output=True, text=True).stderr
    m = re.search(r"Video: .*?, (\d+)x(\d+)", info)
    return int(m.group(2)) if m else 800


def font_file() -> str:
    out = subprocess.run(["fc-match", "DejaVu Sans", "-f", "%{file}"], capture_output=True, text=True)
    return out.stdout.strip()


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--dir", required=True)
    p.add_argument("--flow", required=True)
    p.add_argument("--raw", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--fontsize", type=int, default=26)
    a = p.parse_args()

    captions = json.load(open(os.path.join(a.dir, "legendas.json")))[a.flow]
    marks = [line.split() for line in open(os.path.join(a.dir, f"marcas-{a.flow}.txt")) if line.strip()]
    keys = [k for k, _ in marks]
    start = {k: float(v) for k, v in marks}
    if keys[-1] != "fim":
        raise SystemExit("marcas sem a linha final 'fim'")

    # Cliques registrados pelo tap (tempo x y). Se algum clique de uma legenda cair na
    # faixa de baixo da tela, essa legenda vai para o topo para não esconder o clique.
    clicks = []
    clicks_file = os.path.join(a.dir, f"cliques-{a.flow}.txt")
    if os.path.exists(clicks_file):
        clicks = [tuple(map(float, line.split())) for line in open(clicks_file) if line.strip()]
    height = video_height(a.raw)

    text_dir = os.path.join(a.dir, f"textos-{a.flow}")
    os.makedirs(text_dir, exist_ok=True)
    font = font_file()
    filters = []
    for i, k in enumerate(keys[:-1]):
        begin, end = start[k], start[keys[i + 1]] - 0.05
        path = os.path.join(text_dir, f"{k}.txt")
        with open(path, "w") as f:
            f.write(wrap(captions[int(k) - 1]))
        on_top = any(begin <= t <= end and y > height - 220 for t, _, y in clicks)
        y_expr = "150" if on_top else "h-text_h-44"
        filters.append(
            f"drawtext=fontfile={font}:textfile={path}:fontsize={a.fontsize}:fontcolor=white"
            f":line_spacing=8:text_align=C:box=1:boxcolor=black@0.6:boxborderw=14"
            f":x=(w-text_w)/2:y={y_expr}:enable='between(t,{begin:.2f},{end:.2f})'"
        )

    # Selo de tecla (gravado pela função key do rec-lib.sh): canto superior direito, 1,2 s
    keys_file = os.path.join(a.dir, f"teclas-{a.flow}.txt")
    if os.path.exists(keys_file):
        for n, line in enumerate(open(keys_file)):
            if not line.strip():
                continue
            t, label = line.split(maxsplit=1)
            path = os.path.join(text_dir, f"tecla-{n}.txt")
            with open(path, "w") as f:
                label = label.strip()
                f.write(f"Tecla: {label}" + (" ⏎" if label.lower() == "enter" else ""))
            filters.append(
                f"drawtext=fontfile={font}:textfile={path}:fontsize=28:fontcolor=white"
                f":box=1:boxcolor=black@0.7:boxborderw=12"
                f":x=w-text_w-40:y=90:enable='between(t,{float(t):.2f},{float(t) + 1.2:.2f})'"
            )

    script = os.path.join(a.dir, f"filtro-{a.flow}.txt")
    with open(script, "w") as f:
        f.write(",\n".join(filters))
    subprocess.run(
        ["ffmpeg", "-loglevel", "error", "-y", "-i", a.raw, "-filter_complex_script", script,
         "-c:v", "libx264", "-crf", "23", "-preset", "medium", "-pix_fmt", "yuv420p",
         "-movflags", "+faststart", a.out],
        check=True,
    )
    print(f"{a.out}: {len(filters)} textos (legendas e teclas), {os.path.getsize(a.out)} bytes")


if __name__ == "__main__":
    main()
