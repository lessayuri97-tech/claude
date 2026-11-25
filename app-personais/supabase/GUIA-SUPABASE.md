# Ligar a app ao Supabase — passo a passo simples

Demora uns 10 minutos. É grátis. Faz isto uma vez só.

## 1. Criar a conta e o projeto
1. Abra **supabase.com** e toque em **Start your project**. Entre com o Google ou GitHub.
2. Toque em **New project**.
3. **Name**: escreva `squad`.
4. **Database Password**: toque em **Generate a password** e guarde-a num sítio seu (não precisa de a enviar a ninguém).
5. **Region**: escolha a mais perto (ex.: *West EU (Ireland)* ou *South America (São Paulo)*).
6. Toque em **Create new project** e espere 1–2 minutos.

## 2. Criar as tabelas
1. No menu da esquerda, toque em **SQL Editor** e depois em **New query**.
2. Abra o ficheiro `supabase\schema.sql` (está na pasta do projeto), copie **tudo** e cole na caixa.
3. Toque em **Run**. Deve aparecer "Success. No rows returned".

## 3. Deixar as pessoas entrarem sem confirmar o e-mail
1. Menu da esquerda: **Authentication** → **Sign In / Providers** (ou **Providers**) → **Email**.
2. Desligue **Confirm email** e toque em **Save**.
   (Se deixar ligado, cada pessoa tem de abrir um e-mail antes de entrar. Funciona, mas dá mais passos aos alunos.)
3. Em **Authentication** → **URL Configuration**, em **Site URL** escreva `https://www.vemprosquad.com.br` e guarde. Em **Redirect URLs** acrescente estas três (uma por linha): `https://www.vemprosquad.com.br/**`, `https://vemprosquad.com.br/**` e `https://pt-example.vercel.app/**`. (Serve para o link de "esqueci a senha".)

## 4. Copiar só duas coisas
1. Menu da esquerda: **Project Settings** (a roda dentada) → **API** (ou **API Keys**).
2. Copie o **Project URL** (algo como `https://abcdxyz.supabase.co`).
3. Copie a chave **anon** / **public** (uma linha comprida que começa por `eyJ…`).
4. Envie estas **duas** coisas ao Claude.

> ⚠️ **Nunca envie a chave `service_role` / `secret`.** Essa dá acesso a tudo e não é preciso para nada. A chave `anon` pode ser vista por qualquer pessoa — é normal, a segurança está nas regras da base de dados (já incluídas no `schema.sql`).

## 5. Publicar
O Claude coloca o URL e a chave no ficheiro `config.js`. Depois faça duplo clique no **publicar.bat** como de costume.

## Como fica a usar
- **Personal**: abre a app, toca em **Sou personal e quero criar a minha conta**, escreve e-mail e senha.
- **Aluno**: o personal toca em **Convidar para a app** na ficha do aluno e envia a mensagem por WhatsApp. O aluno abre o link, escolhe e-mail e senha, e já está dentro.
- Cada personal só vê os seus alunos. Cada aluno só vê o seu próprio plano.

## Supervisão: dar o mesmo acesso a outra pessoa da equipe
1. No Supabase: **SQL Editor** → **New query** → cole o conteúdo de `supabase/supervisao.sql` → **Run**. (Só uma vez. É seguro repetir.)
2. Na app, entre como dono: **Definições → Equipe e supervisão → Gerar convite de supervisor**. Envie o link por WhatsApp só à pessoa certa. O link vale 7 dias e só funciona uma vez.
3. A pessoa abre o link, escolhe o próprio e-mail e senha e entra. Daí em diante entra em `www.vemprosquad.com.br/app` com esse e-mail e senha.

**O que o supervisor pode:** ver e editar as mesmas alunas, leads, treinos, nutrição, modelos e a Central. Os dados são os mesmos que os seus, não uma cópia.
**O que não pode:** gerar convites para outros supervisores. As alunas continuam a ver só o seu próprio registo.

**Remover o acesso:** em **Definições → Equipe e supervisão**, toque em **Remover acesso** ao lado do e-mail. O acesso termina logo. (Opcional: apagar também a conta em Supabase → Authentication → Users.)
