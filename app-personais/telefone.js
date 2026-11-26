// Campo de telefone/WhatsApp com bandeira do país e máscara (usado no diagnóstico e na app).
// PTTel.criar(contentor, { valor: '+5511987654321' }) devolve { get(), raw(), valido(), definir(v) }.
// get() devolve sempre o número internacional completo (ex.: +5511987654321), ou '' se estiver incompleto.
(function () {
  const PAISES = [['br', 'Brasil', '55'], ['pt', 'Portugal', '351'], ['us', 'Estados Unidos', '1'], ['gb', 'Reino Unido', '44'], ['es', 'Espanha', '34'], ['fr', 'França', '33'], ['de', 'Alemanha', '49'], ['it', 'Itália', '39'], ['ao', 'Angola', '244'], ['mz', 'Moçambique', '258'], ['cv', 'Cabo Verde', '238'], ['gw', 'Guiné-Bissau', '245'], ['st', 'São Tomé e Príncipe', '239'], ['tl', 'Timor-Leste', '670'], ['ch', 'Suíça', '41'], ['lu', 'Luxemburgo', '352'], ['be', 'Bélgica', '32'], ['nl', 'Países Baixos', '31'], ['ie', 'Irlanda', '353'], ['ca', 'Canadá', '1'], ['ar', 'Argentina', '54'], ['uy', 'Uruguai', '598'], ['py', 'Paraguai', '595'], ['cl', 'Chile', '56'], ['co', 'Colômbia', '57'], ['mx', 'México', '52'], ['pe', 'Peru', '51'], ['ve', 'Venezuela', '58'], ['au', 'Austrália', '61'], ['jp', 'Japão', '81'], ['ae', 'Emirados Árabes Unidos', '971'], ['za', 'África do Sul', '27']];
  const dig = s => String(s || '').replace(/\D/g, '');
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const flag = c => `<img src="https://flagcdn.com/w40/${c}.png" srcset="https://flagcdn.com/w80/${c}.png 2x" alt="" width="28" height="21" loading="lazy">`;
  const nm = v => String(v).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
  const MAX = { br: 11, pt: 9, us: 10, ca: 10 };
  const maxDe = c => MAX[c] || 12;

  function mascara(c, d) {
    d = d.slice(0, maxDe(c));
    if (c === 'br') {
      if (d.length <= 2) return d ? '(' + d : '';
      if (d.length <= 6) return `(${d.slice(0, 2)}) ${d.slice(2)}`;
      return d.length === 11 ? `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}` : `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`;
    }
    if (c === 'pt') return d.replace(/(\d{3})(?=\d)/g, '$1 ').trim();
    if (c === 'us' || c === 'ca') {
      if (d.length <= 3) return d ? '(' + d : '';
      if (d.length <= 6) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
      return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
    }
    return d.replace(/(\d{3})(?=\d)/g, '$1 ').trim();
  }
  function valido(c, d) {
    if (c === 'br') return (d.length === 10 || d.length === 11) && /^[1-9][1-9]/.test(d) && (d.length === 10 || d[2] === '9');
    if (c === 'pt') return d.length === 9;
    if (c === 'us' || c === 'ca') return d.length === 10;
    return d.length >= 6 && d.length <= 12;
  }
  // país pelo prefixo (o mais longo ganha)
  function porPrefixo(d) {
    let m = null;
    PAISES.forEach(p => { if (d.startsWith(p[2]) && (!m || p[2].length > m[2].length)) m = p; });
    return m;
  }
  // Link do WhatsApp a partir de qualquer formato guardado (sem + e 10/11 dígitos = Brasil)
  function wa(t) {
    t = String(t || ''); let d = dig(t);
    if (!t.trim().startsWith('+') && (d.length === 10 || d.length === 11)) d = '55' + d.replace(/^0+/, '');
    return d;
  }

  const css = `.pttel{display:flex;gap:8px;margin-top:6px;position:relative}.pttel input{margin-top:0!important;flex:1;min-width:0}
.pttel .ptpais{display:flex;align-items:center;gap:8px;background:var(--card,#fff);color:var(--fg,#1F2033);border:1.5px solid var(--line,#ddd);border-radius:12px;padding:0 12px;font:600 1.05rem Barlow,sans-serif;cursor:pointer;min-height:48px}
.pttel .ptpais img,.pttel .ptlp img{width:28px;height:21px;object-fit:cover;border-radius:3px;flex:none;box-shadow:0 0 0 1px rgba(0,0,0,.12)}
.ptlista{position:absolute;z-index:80;top:56px;left:0;right:0;background:var(--card,#fff);border:1.5px solid var(--line,#ddd);border-radius:12px;max-height:300px;overflow:auto;box-shadow:0 12px 30px rgba(0,0,0,.18)}
.ptlista input{margin:8px!important;width:calc(100% - 16px)!important;flex:none!important}
.ptlp{display:flex;align-items:center;gap:10px;width:100%;padding:12px;background:none;border:0;color:var(--fg,#1F2033);font:500 1rem Barlow,sans-serif;text-align:left;cursor:pointer}
.ptlp:hover,.ptlp:active{background:rgba(0,0,0,.06)}.ptlp span:last-child{margin-left:auto;opacity:.6}`;
  function injeta() { if (document.getElementById('pt-tel-css')) return; const s = document.createElement('style'); s.id = 'pt-tel-css'; s.textContent = css; document.head.appendChild(s); }

  function criar(host, o) {
    o = o || {}; injeta();
    let pais = o.pais || 'br';
    host.classList.add('pttel');
    host.innerHTML = `<button type="button" class="ptpais" aria-label="Escolher país"></button><input type="tel" inputmode="tel" autocomplete="tel-national" placeholder="${esc(o.placeholder || '(11) 98765-4321')}"${o.required ? ' required' : ''}>`;
    const btn = host.querySelector('.ptpais'), inp = host.querySelector('input');
    const dial = () => PAISES.find(p => p[0] === pais)[2];
    const desenha = () => { btn.innerHTML = `${flag(pais)}<span>+${dial()}</span><span aria-hidden="true">▾</span>`; inp.placeholder = pais === 'br' ? '(11) 98765-4321' : pais === 'pt' ? '912 345 678' : (pais === 'us' || pais === 'ca') ? '(555) 123-4567' : 'Número'; };
    // limpa o que foi digitado/colado: aceita +prefixo e "0" do tronco nacional
    function normaliza(raw) {
      let d = dig(raw);
      if (String(raw).trim().startsWith('+')) { const p = porPrefixo(d); if (p) { pais = p[0]; d = d.slice(p[2].length); desenha(); } }
      else if (d.length > maxDe(pais) && d.startsWith(dial())) d = d.slice(dial().length);
      if (pais === 'br' || pais === 'pt') d = d.replace(/^0+/, '');
      return d.slice(0, maxDe(pais));
    }
    const refaz = () => { const d = normaliza(inp.value); inp.value = mascara(pais, d); };
    inp.addEventListener('input', refaz);
    btn.addEventListener('click', () => {
      const ex = host.querySelector('.ptlista'); if (ex) { ex.remove(); return; }
      const box = document.createElement('div'); box.className = 'ptlista';
      box.innerHTML = '<input type="text" placeholder="Procurar país…" autocomplete="off"><div></div>';
      host.appendChild(box);
      const q = box.querySelector('input'), pl = box.querySelector('div');
      const lista = t => { pl.innerHTML = PAISES.filter(x => !t || nm(x[1]).includes(nm(t)) || x[2].startsWith(t.replace('+', ''))).map(x => `<button type="button" class="ptlp" data-c="${x[0]}">${flag(x[0])}<span>${x[1]}</span><span>+${x[2]}</span></button>`).join('') || '<div class="ptlp">Nenhum país encontrado</div>'; };
      lista(''); q.focus(); q.oninput = () => lista(q.value);
      pl.onclick = e => { const b = e.target.closest('.ptlp[data-c]'); if (!b) return; pais = b.dataset.c; box.remove(); desenha(); refaz(); inp.focus(); };
    });
    document.addEventListener('click', e => { const l = host.querySelector('.ptlista'); if (l && !host.contains(e.target)) l.remove(); });
    function definir(v) {
      v = String(v || '').trim(); if (!v) { inp.value = ''; return; }
      let d = dig(v);
      if (v.startsWith('+')) { const p = porPrefixo(d); if (p) { pais = p[0]; d = d.slice(p[2].length); } }
      else if (d.length === 10 || d.length === 11) pais = 'br';
      desenha(); inp.value = mascara(pais, d.replace(/^0+/, ''));
    }
    desenha(); if (o.valor) definir(o.valor);
    return {
      pais: () => pais,
      raw: () => { const d = dig(inp.value); return d ? '+' + dial() + d : ''; },
      valido: () => valido(pais, dig(inp.value)),
      get: () => { const d = dig(inp.value); return valido(pais, d) ? '+' + dial() + d : ''; },
      definir, focar: () => inp.focus()
    };
  }
  window.PTTel = { PAISES, criar, wa, mascara, valido };
})();
