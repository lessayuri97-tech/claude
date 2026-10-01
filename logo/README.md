# Logo — Vila Madalena Pizzarias

Recriação vetorial (SVG) do logo original. Os textos foram convertidos em
curvas (fonte Montserrat), por isso **não depende de nenhuma fonte instalada**.

| Ficheiro | Uso |
|---|---|
| `vila-madalena-logo.svg` | Logo com fundo preto (quadrado 330×330, escala sem perda) |
| `vila-madalena-logo-transparente.svg` | Sem fundo — para pôr sobre fundos escuros do site |
| `vila-madalena-logo.png` / `-transparente.png` | PNG 1200×1200 (redes sociais, favicon, etc.) |

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
