# Philips TV Remote

[English](README.md) · **Português**

Controle remoto nativo em SwiftUI para iPhone, feito para TVs Philips NetTV mais antigas
(chassi TPM16.5L, ex.: **32PHG5201/78**). Ele conversa com a TV pela rede local através da
API JointSpace v1. Sem anúncios, sem conta, sem nuvem, sem rastreamento.

A interface usa o Kiel UI, o design system dos meus apps: sempre escura, superfícies sólidas com
contorno fino (sem desfoque nem vidro), grade de 8 pontos e teclas em cápsula com toque elástico. O azul
só marca um estado ativo (mudo, a opção selecionada); verde quer dizer conectada. Cada toque dá uma vibração leve. Segue o idioma do celular: português do Brasil num iPhone em português, inglês nos demais.

## Recursos

- Ligar / tela off, usando o modo ecológico "tela desativada" da TV (veja [Energia](#energia))
- Direcional + OK, Voltar, Início, Info, Opções, Multiview
- Volume + mudo, troca de canal
- Teclas coloridas, controles de reprodução, teclado numérico, legendas
- Ajustar, Buscar, Formato, Guia, Lista, Smart TV, TV/Sair
- Encontra a TV no seu Wi-Fi sozinho, sem digitar IP
- Seletor de fontes com as entradas da TV (HDMI, TV, …)
- Status de conexão e volume em tempo real
- Vibração tátil a cada tecla
- Inglês e português do Brasil, seguindo o idioma do celular

## Requisitos

- iPhone com iOS 17 ou superior
- Um Mac com Xcode (para compilar e instalar o app)
- Celular e TV na mesma rede Wi-Fi/LAN
- TV Philips que responda à JointSpace v1 na porta 1925 (a maioria das Philips NetTV de
  2011 a 2016, aproximadamente)

## Compilar e instalar

1. Clone o repositório e rode `open PhilipsTVRemote.xcodeproj`.
2. Selecione o target **PhilipsTVRemote**, abra *Signing & Capabilities* e escolha o seu
   time (um Apple ID pessoal gratuito funciona). Se o Xcode reclamar do bundle ID, troque
   por algo único, ex.: `com.seunome.PhilipsTVRemote`.
3. Conecte o iPhone, selecione-o como destino e clique em Run.
4. Na primeira abertura o iOS pede acesso à **Rede Local**. Permita, senão o app não
   alcança a TV. (Dá para mudar depois em Ajustes do iOS > Privacidade e Segurança >
   Rede Local.)

Com Apple ID gratuito o app expira em 7 dias; rode de novo pelo Xcode para renovar.

Em um IPA assinado para desenvolvimento, o perfil de provisionamento precisa incluir
seu iPhone e estar dentro da validade. Para instalar sem assinar de novo, descompacte
o IPA e arraste `Payload/PhilipsTVRemote.app` para a janela Devices and Simulators do
Xcode, no iPhone conectado. Ao atualizar, mantenha o identificador do app e o time de
assinatura para preservar os dados. Contas gratuitas permitem até três apps instalados.

O erro `7252` do Sideloadly (certificado não encontrado no time) acontece na solicitação
de assinatura à Apple; mudar o identificador do IPA não corrige essa solicitação. Um
build já assinado pode ser instalado diretamente pelo Xcode.

## Descobrir o IP da TV

Só é preciso quando o app não encontra a TV sozinho. Use o jeito mais fácil para você:

- **Na TV:** aperte Início (Home) e vá em **Configuração > Configurações de rede >
  Visualizar configurações de rede** (os nomes mudam um pouco conforme modelo e firmware).
  O endereço IP aparece ali.
- **No roteador:** abra a página de administração e procure na lista de clientes DHCP /
  dispositivos conectados algo como "Philips" ou o modelo da TV.
- **De um computador na mesma rede:** confira se a API responde:

  ```sh
  curl http://<ip-da-tv>:1925/1/system
  ```

  Se vier um JSON, o IP está certo e a API está ativa.

O IP é atribuído pelo roteador (DHCP) e pode mudar. O app encontra a TV de novo sozinho;
um IP digitado à mão precisa ser atualizado, então reserve um IP fixo para a TV no roteador.

## Configurar o app

1. Ligue a TV e abra o app. Ele procura a TV no seu Wi-Fi (todos os endereços da sub-rede do
   celular, na porta 1925) e conecta quando encontra.
2. Se encontrar várias TVs, ou nenhuma, a tela de Ajustes abre: escolha sua TV em
   **TVs no seu Wi-Fi**, toque em **Procurar de novo** ou digite o IP em **Digitar o IP**.
3. Toque em **Concluído**.

Se a TV salva parar de responder (por exemplo, depois de pegar outro IP), o app procura de novo
na próxima abertura e troca para a TV quando encontra exatamente uma.

O IP fica salvo só no celular.

Na primeira vez que o app fala com a TV, o iOS pede acesso à rede local; permita. Esse aviso,
como o resto do app, segue o idioma do celular.

## Energia

Nesta geração de TV, o standby de verdade desliga o Wi-Fi, então nada na rede consegue
ligar a TV de volta, e o Wake-on-LAN não funciona na prática. Por isso o app usa o modo
ecológico **tela desativada** da TV:

- **Tela off** abre o menu Ajustar e seleciona *Configuração ecológica > Tela desativada*
  enviando `Ajustar, Direita, OK, Baixo, OK`. A tela apaga, mas a TV continua na rede.
- **Ligar** envia a seta para cima. Qualquer tecla acorda a tela.

Se o menu Ajustar da sua TV for diferente, altere a sequência em `TVClient.screenOff()`.

## Problemas comuns

- **"Sem resposta" ou nenhuma TV encontrada:** confira se a TV está ligada, se o celular está
  no mesmo Wi-Fi da TV e se o acesso à Rede Local está permitido para o app, e toque em
  **Procurar de novo** nos Ajustes. Logo depois de permitir a Rede Local, a primeira busca pode
  voltar vazia; procure de novo.
- **Funcionava e parou:** a TV provavelmente pegou outro IP do roteador. Abra o app de novo ou
  toque em **Procurar de novo**.
- **Uma tecla não faz nada:** `Guide`, `List` e `Multiview` não têm nome de tecla
  documentado na v1 e podem ser ignoradas por algumas TVs.

## Notas do protocolo

O app usa JointSpace v1 em HTTP simples na porta 1925, sem autenticação nesta geração.

| Chamada | Para quê |
| --- | --- |
| `POST /1/input/key` com `{"key":"VolumeUp"}` | Enviar uma tecla (lista completa em `TVKey.swift`) |
| `GET/POST /1/audio/volume` | Ler ou definir volume e mudo |
| `GET /1/sources` | Listar entradas |
| `POST /1/sources/current` com `{"id":"hdmi1"}` | Trocar de entrada |
| `GET /1/system` | Modelo e versão de software |

`/1/applications`, `/1/menuitems` e a API v6 retornam **Forbidden** no TPM16.5L.

## Estrutura do projeto

| Arquivo | O que faz |
| --- | --- |
| `PhilipsTVRemoteApp.swift` | Ponto de entrada do app |
| `ContentView.swift` | Layout do controle, tela de ajustes |
| `KielUI.swift` | Tokens e componentes do Kiel UI (copiado do design system Kiel UI) |
| `SourceView.swift` | Seletor de fontes |
| `TVClient.swift` | Cliente HTTP JointSpace v1, busca da TV no Wi-Fi, lógica de energia |
| `TVKey.swift` | Nomes de teclas aceitos pela TV |
| `Localizable.xcstrings` | Textos do app em inglês (as chaves) e português do Brasil |
| `InfoPlist.xcstrings` | Aviso de rede local em inglês e português |

## Privacidade

O app não coleta nenhum dado. Ele só se comunica com aparelhos da sua rede local: a busca pergunta
a cada endereço da sub-rede do seu Wi-Fi pela API da TV, e depois o app fala com a TV encontrada
ou com o IP que você digitar. Nada é enviado para nenhum outro lugar.

## Licença

[MIT](LICENSE)

## Aviso

Sem vínculo nem endosso da Philips ou da TP Vision. "Philips" é marca registrada do seu
titular.
