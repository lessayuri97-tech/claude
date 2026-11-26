// Guarda os dados da demo (um único documento JSON) no Vercel Blob, para o personal
// e a aluna verem a mesma informação em aparelhos diferentes.
// Só para demonstração: sem login no servidor e com dados fictícios.
import * as blobReal from '@vercel/blob';

const CAMINHO = 'pt-example/estado.json';
const LIMITE = 900 * 1024;

const TTL = 30 * 1000; // cada instância reutiliza a última leitura durante 30 s: poupa operações do Blob

export function criarHandler(blob, ambiente = process.env) {
  let cache = null, accessOk = null;
  async function ler(forcar) {
    if (!forcar && cache && Date.now() - cache.ts < TTL) return cache;
    let ultimo, semDocumento = null;
    for (const access of (accessOk ? [accessOk] : ['private', 'public'])) {
      try {
        const r = await blob.get(CAMINHO, { access, useCache: false });
        if (!r) { semDocumento = semDocumento || access; continue; }
        const texto = await new Response(r.stream).text();
        accessOk = access; cache = { doc: JSON.parse(texto), etag: r.blob && r.blob.etag, access, ts: Date.now() };
        return cache;
      } catch (e) { ultimo = e; }
    }
    if (semDocumento) { cache = { doc: null, etag: null, access: semDocumento, ts: Date.now() }; return cache; }
    throw ultimo || new Error('sem-acesso');
  }

  async function gravar(doc, etag, accessPreferido) {
    const ordem = accessPreferido ? [accessPreferido] : ['private', 'public'];
    let ultimo;
    for (const access of ordem) {
      try {
        const opcoes = { access, addRandomSuffix: false, allowOverwrite: true, contentType: 'application/json', cacheControlMaxAge: 60 };
        if (etag) opcoes.ifMatch = etag;
        const r = await blob.put(CAMINHO, JSON.stringify(doc), opcoes);
        accessOk = access; cache = r && r.etag ? { doc, etag: r.etag, access, ts: Date.now() } : null;
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
        if (doc && req.query && String(req.query.rev) === String(doc.rev)) return res.status(200).json({ rev: doc.rev, semAlteracoes: true });
        return res.status(200).json(doc || { rev: 0, data: null });
      }
      if (req.method === 'PUT') {
        let corpo = req.body;
        if (typeof corpo === 'string') corpo = JSON.parse(corpo);
        if (!corpo || !corpo.data || !Array.isArray(corpo.data.alunos) || !Array.isArray(corpo.data.exercicios)) return res.status(400).json({ erro: 'dados-invalidos' });
        if (JSON.stringify(corpo.data).length > LIMITE) return res.status(413).json({ erro: 'grande-demais' });
        const { doc, etag, access } = await ler();
        const revAtual = doc ? doc.rev || 0 : 0;
        if ((corpo.baseRev || 0) !== revAtual) { cache = null; return res.status(409).json((await ler(true)).doc || { rev: 0, data: null }); }
        const novo = { rev: revAtual + 1, atualizadoEm: new Date().toISOString(), data: corpo.data };
        try { await gravar(novo, etag, access); }
        catch (e) {
          if (blob.BlobPreconditionFailedError && e instanceof blob.BlobPreconditionFailedError) { cache = null; const atual = (await ler(true)).doc; return res.status(409).json(atual || { rev: 0, data: null }); }
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
