# Ligar o domínio vemprosquad.com.br à app

Demora uns 10 minutos, mais o tempo da internet "aprender" o endereço (de minutos até algumas horas). O endereço `squad.vercel.app` continua a funcionar como alternativa.

## 1. No Vercel
1. Abra o projeto **squad** → **Settings** → **Domains**.
2. Em **Add Domain**, escreva `vemprosquad.com.br` e toque em **Add**.
3. Escolha a opção que **também** liga o `www.vemprosquad.com.br` (recomendado). O Vercel mostra então os **registos DNS** que precisa. Normalmente são estes dois:

| Tipo | Nome (Host) | Valor |
|---|---|---|
| A | `@` (ou vazio) | `76.76.21.21` |
| CNAME | `www` | `cname.vercel-dns.com` |

Se o Vercel mostrar valores diferentes, **use os do Vercel** (são os certos para o seu projeto).

## 2. No Registro.br (se o domínio foi comprado lá)
1. Entre em registro.br → **Painel** → clique em `vemprosquad.com.br`.
2. Em **DNS**, confirme que usa os **servidores DNS do Registro.br**. Depois toque em **Configurar zona DNS** → **Modo avançado**.
3. **Nova entrada**: tipo **A**, nome vazio (ou `@`), dados `76.76.21.21` → Salvar.
4. **Nova entrada**: tipo **CNAME**, nome `www`, dados `cname.vercel-dns.com` → Salvar.
5. Se já existirem entradas A ou CNAME antigas para o mesmo nome, apague-as primeiro.

*Se comprou noutro sítio (GoDaddy, Hostinger, Cloudflare…), o passo é o mesmo: abra a gestão de **DNS** do domínio e crie os dois registos da tabela.*

## 3. Confirmar
Volte a **Settings → Domains** no Vercel. Quando aparecer **Valid Configuration** (visto verde), o site já abre em https://vemprosquad.com.br. O certificado (cadeado) é automático.

## 4. Depois de funcionar
- No Supabase: **Authentication → URL Configuration → Site URL** = `https://vemprosquad.com.br`.
- Os links de convite passam a usar este endereço sozinhos.
