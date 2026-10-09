// TODO: substituir pelo número real de WhatsApp da Growky antes de publicar.
export const WHATSAPP_NUMBER = '351900000000'; // PLACEHOLDER — não é um número real
export const WHATSAPP_MESSAGE = 'Olá! Vi o site da Growky e quero saber mais sobre os vossos serviços 🚀';
export const CONTACT_EMAIL = 'geral@growky.pt'; // TODO: confirmar email real

export function whatsappLink(message = WHATSAPP_MESSAGE) {
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`;
}
