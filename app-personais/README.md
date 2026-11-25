# Squad · app para personal trainers

Webapp simples para personal trainers acompanharem alunos e planos de treino. Sem avatar, batalhas ou desafios.

- `index.html`: página de apresentação do produto (em `/`).
- `app.html`: a app, pensada para telemóvel (em `/app`). Pode ser instalada no ecrã inicial (manifest + ícones).
- `vercel.json`: site estático na Vercel, sem build. Publicar com `npx vercel --prod` dentro desta pasta.

## O que faz

- **Alunos**: objetivo, contacto, data de início, observações (lesões, restrições).
- **Biblioteca de exercícios**: cada exercício tem o link do YouTube (vídeo normal ou Shorts), com pré-visualização e vídeo dentro da app.
- **Plano de treino**: Treino A, B, C… com séries, reps, carga (kg), descanso e observação; reordenar e duplicar.
- **Registo de sessão**: peso (kg) e repetições de cada série, já preenchidos com o plano; mostra a carga da última vez; opção de atualizar as cargas do plano.
- **Evolução**: gráfico de peso corporal e de carga máxima por exercício, tabela de cargas (início, atual, evolução) e avaliações (peso, % gordura, cintura, quadril, braço).
- **Área do aluno** ("Ver como aluno" ou login como aluna): treino do dia, vídeo, peso/reps por série, descanso, evolução e perfil.
- **Comentários da aluna**: por exercício (durante o treino), no fim do treino e livres (Início/Perfil). O personal vê o painel "Comentários do aluno" na ficha, as notas dentro das sessões e um aviso de novos na lista de alunos.
- **Descanso cronometrado**: ao marcar uma série, começa a contagem com o descanso do plano; pausar, ±15s, pular, aviso no fim (vibração, som, visual) e ecrã mantido ligado durante o treino.
- **Técnicas avançadas**: por exercício, o personal escolhe drop set, cluster, rest-pause, bi-set, super-set, isometria, negativa ou cadência, com campos próprios. A aluna vê a etiqueta e uma explicação curta; o texto do WhatsApp também leva a técnica. Duplicar e reordenar exercícios; o ecrã do personal usa a largura do computador.
- **Copiar e modelos**: copiar um treino ou toda a programação para outro aluno (acrescentar ou substituir); guardar treinos ou programações como modelos e aplicá-los a qualquer aluno. Cada exercício tem a "Nota para o aluno", que aparece na área dele.
- **Biblioteca**: lista compacta com ~175 exercícios genéricos de ginásio (grupo e equipamento), filtros por grupo, equipamento, com/sem vídeo e uso nos planos, busca sem acentos, e edição direta na linha (nome, grupo, equipamento, link do YouTube). Os exercícios novos são acrescentados à biblioteca do personal uma vez.
- **Rever (personal)**: painel com os treinos feitos pelos alunos, mais recentes primeiro, com séries, técnica, esforço, comentários e variação de carga; estado Por rever / Revisto (sincroniza), filtros por aluno, estado e período, e contador no menu.
- **Central de clientes (personal)**: página inicial com quem treinou hoje, parados há N dias, quem nunca treinou e quem pode precisar de nova revisão do plano (carga ou reps a subir nas últimas sessões seguidas, ou esforço baixo). Limites ajustáveis em "Limites"; "Plano revisto" reinicia a verificação.
- **Enviar plano ao aluno**: texto com cargas e links dos vídeos para colar no WhatsApp.
- **Backup**: copiar/colar ou baixar/abrir ficheiro JSON.
- **Nutrição**: por aluno, metas diárias (kcal, proteína, hidratos, gordura, água) com sugestão automática, refeições com alimentos (~60 de base, macros automáticos por gramas) e nota. A aluna vê a aba "Comida", marca as refeições feitas, conta copos de água e comenta. A Central mostra quem não regista comida há N dias.
- **Marca e convites**: em "Definições" o personal escolhe nome, logótipo, cor, WhatsApp e boas-vindas. Na ficha do aluno, "Convidar para a app" gera a mensagem para WhatsApp.
- **Primeiros passos** na Central (4 passos), busca de alunos e dica de instalar a app no telemóvel.

## Dois modos

- **Demonstração** (`config.js` vazio): dados só no aparelho; logins de teste `personal`/`personal` e `Mariana Ribeiro`/`alunateste`. Se `api/dados.js` + Vercel Blob existirem, a demo sincroniza entre aparelhos (sem segurança; só para mostrar).
- **Real com Supabase**: preencher `config.js` (URL e chave anon, nunca a service_role). Cada personal cria conta com e-mail/senha, convida alunos por link, e as regras de segurança (RLS) em `supabase/schema.sql` garantem que cada personal só vê os seus alunos e cada aluno só o seu registo. Passo a passo: `supabase/GUIA-SUPABASE.md`. Com Supabase configurado a demo fica só local e o Blob deixa de ser usado.

## Limitações

- Abre com dados de exemplo na demo; "Começar do zero" apaga-os (mantém a biblioteca).
- Conflitos: se personal e aluno editarem ao mesmo tempo, o plano é do personal e a aluna acrescenta sessões, medidas, comentários, refeições e água (união por id).
- Ainda não há: pagamentos/assinaturas, termos e privacidade (dados de saúde = RGPD), domínio próprio, e-mails com a marca, cópias de segurança automáticas.

## Uso do Blob (demo)

A app consulta no máximo 1 vez por minuto com o ecrã aberto, só pergunta se mudou algo (`?rev=`), o servidor guarda em cache 30 s e as gravações são agrupadas (8 s).
