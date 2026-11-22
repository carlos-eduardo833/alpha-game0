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
--- VERSAO 36 ---
- Legendas aparecem digitando (TYPE_CPS no topo do main.gd controla a velocidade).
--- VERSAO 37 ---
- Corrigido erro de variavel duplicada (sm) criado pela folha da prancheta.
--- VERSAO 38 ---
- Bancada da garagem com proporcao menor (pernas menos esticadas), itens reposicionados.
- Mesa do radio movida para a parede leste, ao lado do gabinete (libera a janela da recepcao). Removidos objetos antigos (caixa preta e papel).
--- VERSAO 39 ---
- Bancada de volta embaixo da janela esquerda dos fundos, com prancheta e multimetro; ronda da janela feita de frente para a bancada.
--- VERSAO 40 ---
- Larry agora abaixa a cabeca (animacao de 0,35 s) e se esconde atras da parede quando o jogador o ve ou o tempo acaba.
--- VERSAO 41 ---
- Larry: nova animacao (vira o rosto e abaixa reto).
- Calibrador agora no compressor. Caixa de ferramentas sobre mesa (x=2,7) com quadro de ferramentas na parede.
--- VERSAO 42 ---
- Corrigido erro de variaveis duplicadas (dark/wood) no quadro de ferramentas.
--- VERSAO 43 ---
- Capo do Cadillac abre e fecha (pivo na base do para-brisa, 62 graus, com rangido). Compartimento do motor basico (bloco, bateria velha) visivel ao abrir. Parte interna do capo escura.
--- VERSAO 44 ---
- Corrigido: capo aparecia preto por fora (material interno dupla-face). Agora fora = cor do carro, dentro = escuro.
--- VERSAO 45 ---
- Bateria nova aparece no lugar da velha (BAT_SPOT no topo do main.gd). Compartimento do motor com luz propria ao abrir o capo e interior do capo mais claro.
--- VERSAO 46 ---
- Removido o vulto (sombra) do deposito.
- Pequenas anomalias aleatorias a cada 40-70 s: lampada falhando, passos na chuva, batidas no portao, porta rangendo, luz piscando.
--- VERSAO 47 ---
- Radio: sem musica. Chiado de estatica + noticiario lido com a voz do sistema (portugues) e legenda perto do radio. Noticias em RADIO_NEWS no main.gd. radio.mp3/ogg em assets/audio ainda substitui tudo.
--- VERSAO 48 ---
- Bateria atravessava o capo fechado: agora as baterias so aparecem com o capo aberto (menores). Bloco do motor mais baixo.
--- VERSAO 49 ---
- Radio: sem chiado e sem voz do sistema. Agora um murmurio de voz incompreensivel + legenda digitando perto do radio.
--- VERSAO 50 ---
- Chuva: som so de gotas batendo (sem chiado). Radio movido para perto dos pneus, em cima de uma mesa nova (3,7 / 7,0).
--- VERSAO 51 ---
- Radio mais baixo e mais direcional; noticia aparece como legenda digitando (a mesma legenda do jogo) ate 15 m do radio. Mais 5 noticias.
--- VERSAO 52 ---
- Chuva: som real (chuva.ogg, 46 s em loop sem emenda). Veja CREDITOS.txt.
--- VERSAO 53 ---
- Passos: 6 passos gravados (footstep.m4a cortado em passo1..6.ogg), sorteados a cada passada.
--- VERSAO 54 ---
- Corrida: passos mais rapidos, mais altos e mais agudos (secos), balanco da camera mais rapido.
--- VERSAO 55 ---
- Botao do portao trocado pelo interruptor (light_switch_and_bulb, so o interruptor). Clique ao fechar o portao.
- Curto-circuito quando as lampadas falham. Som ambiente de fundo (AMBIENTE_DB = -24).
--- VERSAO 56 ---
- Ferramentas reais no quadro (martelo, chave ajustavel, philips, 3 chaves de fenda, alicate de corte) e algumas soltas nas mesas.
- Morsa (bench vice) presa na quina da bancada; multimetro movido para x=-4,7.
- 6 tomadas (2 por comodo) e 3 interruptores de luz nas paredes; espingarda pendurada na parede da recepcao.
--- VERSAO 57 ---
- Multimetro trocado pelo retro_multimeter (texturas melhores), em pe sobre a bancada com os cabos na frente. Veja CREDITOS.txt.
--- VERSAO 58 ---
- Floresta mais densa e mais perto da garagem (duas copias extras). Som de curto-circuito tambem ao entrar no deposito e no susto do Larry.
--- VERSAO 59 ---
- Nova sequencia: ler ordem > subir o carro (ver embaixo) > descer > abrir capo > verificar nivel de oleo > funil e galao > completar oleo > multimetro (Larry na janela) > testar bateria > bateria nova > trocar > calibrador no compressor > 4 pneus > ronda > fechar capo.
- Bateria velha agora e o mesmo modelo, escurecido. Radio movido para x=2,2 (longe do interruptor do portao). Espingarda 40% maior.
--- VERSAO 60 ---
- Portao com a chapa ondulada (material_corrugated_sheet_metal), ondas na horizontal (assets/textures/portao_chapa.jpg).
--- VERSAO 61 ---
- Som do portao fechando (portao_fechando.ogg, silencio inicial cortado). O portao agora desce em 7 s para acompanhar o som.
--- VERSAO 62 ---
- Radio movido para a parede leste da garagem (x 6,45 / z -4,5), a parede vazia ao lado da porta da recepcao.
--- VERSAO 63 ---
- Caixa vermelha removida; lanterna 50% maior; prancheta vai para a mao ao ler a ordem de servico (volta para a bancada depois); curto-circuito toca sozinho (sem rangido/clack junto).
- (v64) renomeei uma variavel do portao para evitar conflito de nome.
--- VERSAO 65 ---
- Painel fixo na frente do trilho do portao (ele passa por tras). Elevador sobe mais (LIFT_SCALE_Y). Arvores proximas das janelas do deposito e da recepcao. Caixa vermelha da bancada removida de verdade. Lanterna na frente da mesa. Larry colado no vidro (z -8,47).
--- VERSAO 66 ---
- Caixa de ferramentas (modelo) devolvida a mesa de ferramentas (tinha sido removida por engano na v63).
--- VERSAO 67 ---
- Sons reais: capo abrindo/fechando, trava da janela (rondas), elevador subindo/descendo (trechos de 6 s). Sem esses arquivos o jogo volta aos sons gerados por codigo.
--- VERSAO 68 ---
- Arvores procedurais trocadas pelo modelo de pinheiro (tree_3d_model_fir_spruce_pine, ~1.600 triangulos cada): 16 pinheiros perto das janelas do deposito, recepcao e fundos.
