# Funções para gravar um fluxo com o agent-browser marcando o tempo de cada legenda.
# Uso: source rec-lib.sh (bash). Variáveis:
#   FV_DIR      pasta de trabalho, com legendas.json (obrigatória)
#   FV_SESSION  sessão do agent-browser (padrão: flow-video)
#   FV_FLOW     id do fluxo em gravação, usado pelo tap para registrar cliques (padrão: 1)
#   FV_CPS      caracteres por segundo de leitura (padrão: 22)
#   FV_MIN/FV_MAX  tempo mínimo/máximo de cada legenda, em segundos (padrão: 3 / 8.5)
# Depois de "agent-browser record start ...", rode: T0=$(now)

: "${FV_DIR:?defina FV_DIR}"
export AGENT_BROWSER_SESSION="${FV_SESSION:-flow-video}"
FV_CPS="${FV_CPS:-22}"; FV_MIN="${FV_MIN:-3}"; FV_MAX="${FV_MAX:-8.5}"

# ref PADRAO: ref (@eN) do primeiro elemento interativo cuja linha do snapshot casa com PADRAO
ref() { agent-browser snapshot -i -c | grep -m1 -- "$1" | sed 's/.*ref=\(e[0-9]*\).*/\1/'; }
# refall PADRAO: igual a ref, mas no snapshot completo (checkbox e botões que não aparecem no -i)
refall() { agent-browser snapshot -c | grep -m1 -- "$1" | sed 's/.*ref=\(e[0-9]*\).*/\1/'; }
# wref PADRAO [all]: espera até 6 s o elemento aparecer; evita clicar antes da tela renderizar
wref() {
  local r i
  for i in $(seq 1 15); do
    if [ "$2" = all ]; then r=$(refall "$1"); else r=$(ref "$1"); fi
    [ -n "$r" ] && { echo "$r"; return 0; }
    sleep 0.4
  done
  echo "NAO ACHOU: $1" >&2; return 1
}

# glide REF [ms]: leva o cursor até o centro do elemento numa curva suave (padrão 700 ms).
# O "hover" salta direto; com o glide o cursor percorre o caminho no vídeo.
# Use depois de scrollintoview, porque a posição é a da área visível.
glide() {
  local box cx cy
  box=$(agent-browser get box "@$1" --json) || return 1
  read -r cx cy < <(echo "$box" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(int(d['x']+d['width']/2), int(d['y']+d['height']/2))")
  agent-browser mouse move "$cx" "$cy" --human --duration "${2:-700}" >/dev/null
}

# tap REF: desliza até o elemento, desenha um anel que se expande no ponto do clique e clica.
# A onda do --cursor é discreta; o anel deixa o clique visível no vídeo.
tap() {
  local box cx cy
  glide "$1" "${2:-700}" || return 1
  box=$(agent-browser get box "@$1" --json) || return 1
  read -r cx cy < <(echo "$box" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(int(d['x']+d['width']/2), int(d['y']+d['height']/2))")
  # registra o clique (tempo x y) para o burn-captions.py tirar a legenda de cima dele
  awk -v t="$(now)" -v t0="$T0" -v x="$cx" -v y="$cy" 'BEGIN{printf "%.2f %d %d\n", t-t0, x, y}' >> "$FV_DIR/cliques-${FV_FLOW:-1}.txt"
  agent-browser eval "(()=>{const r=document.createElement('div');r.style.cssText='position:fixed;left:${cx}px;top:${cy}px;width:16px;height:16px;margin:-8px 0 0 -8px;border:3px solid rgba(255,140,0,.95);border-radius:50%;pointer-events:none;z-index:2147483647;transition:transform .55s ease-out,opacity .55s ease-out';document.body.appendChild(r);requestAnimationFrame(()=>{r.style.transform='scale(3.2)';r.style.opacity='0'});setTimeout(()=>r.remove(),700)})()" >/dev/null
  sleep 0.18
  agent-browser click "@$1" >/dev/null
}

# sscroll REF [ms]: rola a página com animação até o elemento ficar no meio da tela
# (o scrollintoview salta direto). Não faz nada se o elemento já estiver visível.
sscroll() {
  local box y vh
  box=$(agent-browser get box "@$1" --json) || return 1
  y=$(echo "$box" | python3 -c "import json,sys;d=json.load(sys.stdin)['data'];print(int(d['y']+d['height']/2))")
  vh=$(agent-browser eval "window.innerHeight" 2>/dev/null | tail -1 | tr -dc '0-9')
  vh=${vh:-800}
  if [ "$y" -lt 120 ] || [ "$y" -gt $((vh - 140)) ]; then
    agent-browser eval "window.scrollBy({top: $((y - vh / 2)), behavior: 'smooth'})" >/dev/null
    sleep "$(awk -v ms="${2:-900}" 'BEGIN{print ms/1000}')"
  fi
}

# key FLUXO TECLA [rótulo]: aperta a tecla e registra o horário em teclas-FLUXO.txt,
# para o burn-captions.py mostrar um selo com o nome da tecla no vídeo.
key() {
  awk -v l="${3:-$2}" -v t="$(now)" -v t0="$T0" 'BEGIN{printf "%.2f %s\n", t-t0, l}' >> "$FV_DIR/teclas-$1.txt"
  agent-browser press "$2" >/dev/null
}

now() { date +%s.%N; }

# mark FLUXO N: registra o início da legenda N (ou "fim") em $FV_DIR/marcas-FLUXO.txt
mark() { awk -v n="$2" -v t="$(now)" -v t0="$T0" 'BEGIN{printf "%s %.2f\n", n, t-t0}' >> "$FV_DIR/marcas-$1.txt"; }

# hold FLUXO N: espera até a legenda N completar o tempo de leitura calculado pelo tamanho do texto
hold() {
  local ini dur rest
  ini=$(awk -v n="$2" '$1==n{print $2}' "$FV_DIR/marcas-$1.txt")
  dur=$(python3 -c "import json,sys;t=json.load(open('$FV_DIR/legendas.json'))['$1'][$2-1];print(min($FV_MAX,max($FV_MIN,len(t)/$FV_CPS)))")
  rest=$(awk -v i="$ini" -v d="$dur" -v t="$(now)" -v t0="$T0" 'BEGIN{r=i+d-(t-t0); print (r>0?r:0)}')
  sleep "$rest"
}
