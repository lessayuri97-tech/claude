# Logo — Vila Madalena Pizzarias

Recriação vetorial (SVG) do logo original. Os textos foram convertidos em
curvas (fonte Montserrat), por isso **não depende de nenhuma fonte instalada**.

| Ficheiro | Uso |
|---|---|
| `vila-madalena-logo.svg` | Logo com fundo preto (quadrado 330×330, escala sem perda) |
| `vila-madalena-logo-transparente.svg` | Sem fundo — para pôr sobre fundos escuros do site |
| `vila-madalena-logo.png` / `-transparente.png` | PNG 1200×1200 (redes sociais, favicon, etc.) |
| `vila-madalena-logo-animado.svg` | **Animado**, com fundo preto (~3 s, toca uma vez e fica parado) |
| `vila-madalena-logo-animado-transparente.svg` | **Animado**, sem fundo — ideal para o topo/hero do site |
| `vila-madalena-logo-animado-preview.gif` | Só pré-visualização da animação (não usar no site) |

## Como usar no site

Como imagem:

```html
<img src="logo/vila-madalena-logo-transparente.svg" alt="Vila Madalena Pizzarias" width="200">
```

Inline (permite mudar a cor por CSS — todo o desenho usa `currentColor`):

```html
<!-- cola o conteúdo do .svg e muda a cor no style do <svg> ou num CSS: -->
<style>.logo svg { color: #f4c542; width: 220px; height: auto; }</style>
```

Notas:
- Fundo do original: `#000`; traço/texto: `#fff`.
- Fontes de referência para o resto do site: **Montserrat ExtraLight (200)** para
  "MADALENA" e **Montserrat Bold/SemiBold (700/600)** para "VILA"/"PIZZARIAS".

## Logo animado

A animação está toda dentro do SVG (CSS embutido, sem JavaScript):
1. o arco e a fatia desenham-se como se fossem traçados à mão;
2. os três pepperonis aparecem com um pequeno "pop";
3. "VILA", "MADALENA" e "PIZZARIAS" surgem em sequência.

Usa-se como qualquer imagem — a animação arranca sozinha quando o SVG carrega:

```html
<img src="logo/vila-madalena-logo-animado-transparente.svg" alt="Vila Madalena Pizzarias" width="260">
```

- Para **repetir** a animação, recarrega a imagem (ex.: trocar o `src` por
  `...svg?` + `Date.now()`), ou cola o SVG inline e reinicia com JS.
- Quem tem "reduzir movimento" ativo no sistema vê o logo já completo, sem animação.
- Duração/atrasos ajustam-se nos `animation-delay` e `animation-duration` do `<style>` dentro do SVG.
