// Guarda os dados da demo (um único documento JSON) no Vercel Blob, para o personal
// e a aluna verem a mesma informação em aparelhos diferentes.
// Só para demonstração: sem login no servidor e com dados fictícios.
import * as blobReal from '@vercel/blob';

const CAMINHO = 'pt-example/estado.json';
const LIMITE = 900 * 1024;

export function criarHandler(blob, ambiente = process.env) {
  async function ler() {
    let ultimo, semDocumento = null;
    for (const access of ['private', 'public']) {
      try {
        const r = await blob.get(CAMINHO, { access, useCache: false });
        if (!r) { semDocumento = semDocumento || access; continue; }
        const texto = await new Response(r.stream).text();
        return { doc: JSON.parse(texto), etag: r.blob && r.blob.etag, access };
      } catch (e) { ultimo = e; }
    }
    if (semDocumento) return { doc: null, etag: null, access: semDocumento };
    throw ultimo || new Error('sem-acesso');
  }

  async function gravar(doc, etag, accessPreferido) {
    const ordem = accessPreferido ? [accessPreferido] : ['private', 'public'];
    let ultimo;
    for (const access of ordem) {
      try {
        const opcoes = { access, addRandomSuffix: false, allowOverwrite: true, contentType: 'application/json', cacheControlMaxAge: 60 };
        if (etag) opcoes.ifMatch = etag;
        await blob.put(CAMINHO, JSON.stringify(doc), opcoes);
        return;
      } catch (e) {
        if (blob.BlobPreconditionFailedError && e instanceof blob.BlobPreconditionFailedError) throw e;
        ultimo = e;
      }
    }
    throw ultimo;
  }

  return async function handler(req, res) {
    res.setHeader('Cache-Control', 'no-store');
    if (!ambiente.BLOB_READ_WRITE_TOKEN) return res.status(503).json({ erro: 'sem-armazenamento' });
    try {
      if (req.method === 'GET') {
        const { doc } = await ler();
        return res.status(200).json(doc || { rev: 0, data: null });
      }
      if (req.method === 'PUT') {
        let corpo = req.body;
        if (typeof corpo === 'string') corpo = JSON.parse(corpo);
        if (!corpo || !corpo.data || !Array.isArray(corpo.data.alunos) || !Array.isArray(corpo.data.exercicios)) return res.status(400).json({ erro: 'dados-invalidos' });
        if (JSON.stringify(corpo.data).length > LIMITE) return res.status(413).json({ erro: 'grande-demais' });
        const { doc, etag, access } = await ler();
        const revAtual = doc ? doc.rev || 0 : 0;
        if ((corpo.baseRev || 0) !== revAtual) return res.status(409).json(doc || { rev: 0, data: null });
        const novo = { rev: revAtual + 1, atualizadoEm: new Date().toISOString(), data: corpo.data };
        try { await gravar(novo, etag, access); }
        catch (e) {
          if (blob.BlobPreconditionFailedError && e instanceof blob.BlobPreconditionFailedError) { const atual = (await ler()).doc; return res.status(409).json(atual || { rev: 0, data: null }); }
          throw e;
        }
        return res.status(200).json({ rev: novo.rev });
      }
      res.setHeader('Allow', 'GET, PUT');
      return res.status(405).json({ erro: 'metodo' });
    } catch (e) {
      return res.status(500).json({ erro: 'falha' });
    }
  };
}

export default criarHandler(blobReal);
