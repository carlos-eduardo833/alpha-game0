KM 42 - PARTE 1 (Godot 4.7 (renderizador Compatibilidade, funciona em PCs mais antigos))

COMO ABRIR
1. Descompacte este .zip em uma pasta.
2. Abra o Godot e clique em "Importar" (Import).
3. Selecione o arquivo project.godot desta pasta e clique em "Importar e editar".
4. Aperte F5 (ou o botao de play no canto superior direito) para jogar.

CONTROLES
W A S D andar | Mouse olhar | E interagir (segure E nas tarefas com barra) | Shift correr | Esc pausa

COMO GERAR UM .EXE (opcional)
1. No Godot: Editor > Gerenciar Templates de Exportacao > Baixar e Instalar.
2. Projeto > Exportar > Adicionar... > Windows Desktop.
3. Clique em "Exportar Projeto" e escolha onde salvar.

TUDO E CRIADO POR CODIGO
O cenario, as texturas e os sons sao gerados pelo arquivo main.gd. Nao ha imagens nem modelos externos.

SE DER ERRO
Copie a mensagem de erro (aba "Saida" ou "Depurador" no Godot) e me mande.

AJUSTES DE SOM (em main.gd, funcao _build_audio)
rain.volume_db = volume da chuva | radio.volume_db = volume do radio (mais negativo = mais baixo)

TEXTURAS E MODELOS REAIS
Leia assets/LEIA-ME.txt: voce pode colocar carro, galao, funil, bateria, multimetro (.glb) e texturas (.jpg) la dentro.

--- VERSAO 5 ---
- Fiat Uno (azul) sobre o elevador animado. Aperte E no painel ao lado do poste para subir/descer.
- Tarefas no carro so funcionam com o carro EMBAIXO.
- Elevador parado = vaga vazia ao lado. Radio, bateria e caixa de ferramentas novos.
- Chao de concreto rachado em toda a oficina; tijolos vermelhos nas paredes.
- Para mudar a cor do carro: CAR_TINT no inicio do main.gd (Color.WHITE = sem cor).

--- VERSAO 6 ---
- Carro agora e o Passat LS 1978 (o capo ainda nao abre; as tarefas do carro funcionam normalmente).
- Carro coberto no elevador parado; pilhas de pneus; armarios no lugar do oleo; mesas, sofa e luminarias novos.
- Estante no deposito com baterias e oleos 20W-50 (o do servico), 15W-40 e 5W-30.
- Janelas transparentes: floresta noturna ao fundo. O Larry espia pela janela dos fundos e some quando voce olha para ele.
- Se o jogo ficar pesado: apague assets/models/floresta.glb (o jogo roda sem ela).

--- VERSAO 7 ---
- Oficina menor: salao 14 x 17 m (antes 20 x 24) e comodos de 6 x 8 m (antes 10 x 12).
- Estantes com estoque (oleo e baterias) pelas paredes do salao, do deposito e da recepcao.
- Larry: so a cabeca aparece na janela, olhando para dentro da oficina.
- Teto de madeira (textura assets/textures/teto_color.jpg, opcional) e gabinete novo da recepcao
  (assets/models/gabinete.glb, opcional): se os arquivos nao existirem, o jogo usa versoes simples.

--- VERSAO 8 ---
- Teto com a textura de paineis de madeira (escurecida) e gabinete novo na recepcao.

--- VERSAO 9 ---
- Floresta mais perto e mais escura (noite), chuva do lado de fora, calcada/rua/poste na frente do portao.

--- VERSAO 10 ---
- Estantes so no deposito (esquerda). Chuva apenas fora do predio. Luz mais fraca e menos amarela.
- Musica do radio: coloque radio.mp3 ou radio.ogg em assets/audio (veja o LEIA-ME de la).

--- VERSAO 11 ---
- Passat maior (escala 1.0, antes 0.85).

--- VERSAO 12 ---
- Cadillac Eldorado no lugar do Passat; pneus novos empilhados; tubos fluorescentes; latas de oleo novas.
- Galao e funil agora ficam no estoque do deposito.

--- VERSAO 13 ---
- Granulado de filme (estilo Fears to Fathom): ajuste GRAIN_FORCA e GRAIN_TAMANHO no inicio do main.gd.

--- VERSAO 14 ---
- Granulado mais fraco (GRAIN_FORCA 0.10) e desfoque leve da imagem (DESFOQUE 1.0; 0.0 desliga).

--- VERSAO 15 ---
- Visual VHS estilo Fears to Fathom: baixa resolucao (RESOLUCAO), imagem macia (MACIO), cores quentes, pretos levantados, linhas leves e granulado.

--- VERSAO 16 ---
- Cadillac mais comprido (so o miolo estica; rodas e pontas mantem o formato).
- Pneus: 4 rodas, o personagem agacha em cada uma (segure E). Passos mais lentos (andar 2.4, correr 4.0).

--- VERSAO 17 ---
- Granulado ainda mais fraco (GRAIN_FORCA 0.05).

--- VERSAO 18 ---
- Parede com a textura PSX Style Brick Wall.

--- VERSAO 19 ---
- Larry sem brilho, some na hora e so aparece ao pegar o multimetro (susto). Cantos internos das salas arredondados (raio 0.2 m no _fillet).

--- VERSAO 20 ---
- Prancheta e multimetro novos (modelos 3D).

--- VERSAO 21 ---
- Multimetro deitado na bancada; prancheta fica la ate o fim.

--- VERSAO 22 ---
- Janelas mais baixas, Larry mais perto (so a cabeca) e zoom no susto.
- Parede nova (tijolo ingles vermelho). Luz mais fraca.
- Removida prateleira que bloqueava a janela do deposito.
- Elevador: agora precisa apontar a mira para o motor do elevador (perto, ate 3,2 m) e apertar E.

--- VERSAO 24 ---
- Dia 1 maior: conferir etiqueta do oleo, pegar filtro, pegar calibrador e ronda das 4 janelas.
--- VERSAO 25 ---
- Corrigido: area de mira do motor do elevador estava enorme (aparecia "Descer o carro" na parede).
--- VERSAO 26 ---
- F11 alterna tela cheia.
--- VERSAO 27 ---
- Larry subiu: cabeca no meio do vidro da janela.
--- VERSAO 28 ---
- Parede nova: red_bricks_wall__tile_texture (tijolo vermelho que repete sem emenda).
--- VERSAO 29 ---
- Qualidade alta (PC bom): sombras em todas as lampadas, MSAA 2x, anisotropico, textura de parede 1024, VHS 432 linhas. Para notebook fraco: QUALIDADE_ALTA := false e RESOLUCAO 288 no topo do main.gd.
--- VERSAO 30 ---
- Quinas internas retas; so os batentes das portas (hall <-> salas) arredondados.
--- VERSAO 31 ---
- Removida a missao de ler as etiquetas do oleo.
--- VERSAO 32 ---
- Parede nova: distressed_painted_wall (reboco descascado, painel de 7,2 m espelhado). Tijolo guardado em assets/textures/parede_tijolo_reserva.jpg.
- Removida a missao do filtro de oleo.
- Larry: modelo cortado abaixo do queixo, so a cabeca aparece no vidro.
--- VERSAO 33 ---
- Bancada movida para x=-1.9 (libera a janela esquerda do fundo); prancheta e multimetro acompanham.
- Larry mais a direita e mais perto do vidro. Multimetro 1,8x maior. Folha borrada sobre a prancheta.
--- VERSAO 34 ---
- Removido o quadrado azul (tela antiga) da janela da recepcao. Radio 1,8x maior.
--- VERSAO 35 ---
- Compressor de ar embaixo do quadro de avisos (quadro movido para x=0,6). Botao do portao trocado pelo button_key.
