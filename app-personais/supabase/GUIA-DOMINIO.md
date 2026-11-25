# Ligar o domínio vemprosquad.com.br à app

Demora uns 10 minutos, mais o tempo da internet "aprender" o endereço (de minutos até algumas horas). O endereço `pt-example.vercel.app` continua a funcionar como alternativa.

## 1. No Vercel
1. Abra o projeto **squad** → **Settings** → **Domains**.
2. Em **Add Domain**, escreva `vemprosquad.com.br` e toque em **Add**.
3. Escolha a opção que **também** liga o `www.vemprosquad.com.br` (recomendado). O Vercel mostra então os **registos DNS** que precisa. Normalmente são estes dois:

| Tipo | Nome (Host) | Valor |
|---|---|---|
| A | `@` (ou vazio) | `76.76.21.21` |
| CNAME | `www` | `cname.vercel-dns.com` |

Se o Vercel mostrar valores diferentes, **use os do Vercel** (são os certos para o seu projeto).

## 2. No Registro.br (opção A, a mais simples: registos A e CNAME)
1. Entre em **registro.br** com o seu login e toque em `vemprosquad.com.br`.
2. Na secção **DNS**, toque em **Editar zona** (ou **Configurar zona DNS**). Se pedir, escolha usar os servidores DNS do Registro.br.
3. **Nova entrada**: tipo **A**, nome **em branco**, dados `76.76.21.21` → **Salvar**.
4. **Nova entrada**: tipo **CNAME**, nome `www`, dados `cname.vercel-dns.com.` (com o ponto no fim, se o Registro.br pedir) → **Salvar**.
5. Se já existirem entradas A ou CNAME antigas com o mesmo nome, apague-as antes.
6. Toque em **Salvar alterações** no fim da página.

**Opção B (alternativa): usar os servidores do Vercel.** Em **DNS** toque em **Alterar servidores DNS**, escolha **Usar outros servidores** e escreva `ns1.vercel-dns.com` e `ns2.vercel-dns.com`. Só use esta opção se o Vercel lhe pedir isso em Domains; a opção A é a normal.

O Registro.br pode demorar de alguns minutos até 24 horas a propagar.

## 3. Confirmar
Volte a **Settings → Domains** no Vercel. Quando aparecer **Valid Configuration** (visto verde), o site já abre em https://www.vemprosquad.com.br (o endereço sem www redireciona para ele). O certificado (cadeado) é automático.

## 4. Depois de funcionar
- No Supabase: **Authentication → URL Configuration → Site URL** = `https://vemprosquad.com.br`.
- Os links de convite passam a usar este endereço sozinhos.
