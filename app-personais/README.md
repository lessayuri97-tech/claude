# PT example · app para personal trainers

Webapp simples para personal trainers acompanharem alunos e planos de treino. Sem avatar, batalhas ou desafios.

- `index.html`: a app (abrir no navegador, não precisa de instalar nada).
- `apresentacao.html`: página de apresentação do produto, com link para a app.

## O que faz

- **Alunos**: objetivo, contacto, data de início, observações (lesões, restrições).
- **Biblioteca de exercícios**: cada exercício tem o link do YouTube (vídeo normal ou Shorts), com pré-visualização e vídeo dentro da app.
- **Plano de treino**: Treino A, B, C… com séries, reps, carga (kg), descanso e observação; reordenar e duplicar.
- **Registo de sessão**: peso (kg) e repetições de cada série, já preenchidos com o plano; mostra a carga da última vez; opção de atualizar as cargas do plano.
- **Evolução**: gráfico de peso corporal e de carga máxima por exercício, tabela de cargas (início, atual, evolução) e avaliações (peso, % gordura, cintura, quadril, braço).
- **Enviar plano ao aluno**: texto com cargas e links dos vídeos para colar no WhatsApp.
- **Backup**: copiar/colar ou baixar/abrir ficheiro JSON.

## Limitações desta versão

- Os dados ficam no navegador (localStorage) do aparelho; não há login nem servidor, por isso o aluno ainda não tem acesso próprio.
- Abre com dados de exemplo; o botão "Começar do zero" apaga-os (mantém a biblioteca de exercícios).
- Os exercícios de exemplo não têm vídeo: cole os links em "Exercícios".
