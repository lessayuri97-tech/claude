// Configuração do Supabase (só valores PÚBLICOS).
// Preencha com o "Project URL" e a chave "anon public" do seu projeto Supabase.
// NUNCA coloque aqui a chave "service_role" / "secret".
// Enquanto estiver vazio, a app funciona só em modo demonstração (dados no próprio aparelho).
// whatsapp: número do personal com indicativo, só números (ex.: '351912345678'). Recebe as mensagens do diagnóstico.
// leadsPara: o id da conta do personal no Supabase (o Claude preenche) para guardar os diagnósticos.
window.PT_SUPABASE = { url: '', anonKey: '', whatsapp: '', leadsPara: '' };
