# PT example · app para personal trainers

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
- **Enviar plano ao aluno**: texto com cargas e links dos vídeos para colar no WhatsApp.
- **Backup**: copiar/colar ou baixar/abrir ficheiro JSON.

## Limitações desta versão

- Os dados ficam no navegador (localStorage). Com a sincronização ativa (`api/dados.js` + Vercel Blob), o personal e a aluna veem os mesmos dados em aparelhos diferentes: o personal manda no plano, a aluna acrescenta sessões e medidas. Sem Blob configurado, a app funciona só neste aparelho. O login é só de demonstração (usuário `personal` / senha `personal`; aluna `Mariana Ribeiro` / senha `alunateste`), as senhas estão no código e a separação personal/aluno acontece só no navegador. Para uso real é preciso login e banco de dados.
- Abre com dados de exemplo; o botão "Começar do zero" apaga-os (mantém a biblioteca de exercícios).
- Os exercícios de exemplo não têm vídeo: cole os links em "Exercícios".

## Sincronização (Vercel Blob)

1. No painel da Vercel: projeto `pt-example` > Storage > Create > Blob e ligar ao projeto (cria `BLOB_READ_WRITE_TOKEN`).
2. Publicar de novo (`publicar.bat`).
3. Abrir primeiro como personal; a app envia os dados para a nuvem. Em Backup há botões para enviar ou receber à força.

Nota: os dados são fictícios e a rota `/api/dados` não tem autenticação (só demonstração).
