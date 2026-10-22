# Philips TV Remote

[English](README.md) · **Português**

Controle remoto nativo em SwiftUI para iPhone, feito para TVs Philips NetTV mais antigas
(chassi TPM16.5L, ex.: **32PHG5201/78**). Ele conversa com a TV pela rede local através da
API JointSpace v1. Sem anúncios, sem conta, sem nuvem, sem rastreamento.

A interface usa Liquid Glass no iOS 26 ou superior, e um visual com material comum no
iOS 17–18. Está disponível em inglês (padrão) e português; dá para trocar nos Ajustes.

## Recursos

- Ligar / tela off, usando o modo ecológico "tela desativada" da TV (veja [Energia](#energia))
- Direcional + OK, Voltar, Início, Info, Opções, Multiview
- Volume + mudo, troca de canal
- Teclas coloridas, controles de reprodução, teclado numérico, legendas
- Ajustar, Buscar, Formato, Guia, Lista, Smart TV, TV/Sair
- Seletor de fontes com as entradas da TV (HDMI, TV, …)
- Status de conexão e volume em tempo real
- Vibração tátil a cada tecla
- Interface em inglês / português

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

## Descobrir o IP da TV

Use o jeito mais fácil para você:

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

O IP é atribuído pelo roteador (DHCP) e pode mudar. Reserve um IP fixo para a TV nas
configurações de DHCP do roteador para não precisar atualizar o app.

## Configurar o app

1. Abra o app. Na primeira vez a tela de Ajustes abre sozinha (ou toque na engrenagem).
2. Digite o IP da TV, ex.: `192.168.1.50`.
3. Toque em **Testar conexão**. "Conectada" significa que está funcionando.
4. Se quiser, troque o idioma em **Idioma**.
5. Toque em **OK**.

O IP e o idioma ficam salvos só no celular.

## Energia

Nesta geração de TV, o standby de verdade desliga o Wi-Fi, então nada na rede consegue
ligar a TV de volta, e o Wake-on-LAN não funciona na prática. Por isso o app usa o modo
ecológico **tela desativada** da TV:

- **Tela off** abre o menu Ajustar e seleciona *Configuração ecológica > Tela desativada*
  enviando `Ajustar, Direita, OK, Baixo, OK`. A tela apaga, mas a TV continua na rede.
- **Ligar** envia a seta para cima. Qualquer tecla acorda a tela.

Se o menu Ajustar da sua TV for diferente, altere a sequência em `TVClient.screenOff()`.

## Problemas comuns

- **"Sem resposta":** confira o IP, se o celular está no mesmo Wi-Fi da TV e se o acesso à
  Rede Local está permitido para o app.
- **Funcionava e parou:** a TV provavelmente pegou outro IP do roteador. Atualize nos
  Ajustes ou reserve um IP fixo.
- **Uma tecla não faz nada:** `Guide`, `List` e `Multiview` não têm nome de tecla
  documentado na v1 e podem ser ignoradas por algumas TVs.

## Notas do protocolo

O app usa JointSpace v1 em HTTP simples na porta 1925, sem autenticação nesta geração.

| Chamada | Para quê |
| --- | --- |
| `POST /1/input/key` com `{"key":"VolumeUp"}` | Enviar uma tecla (lista completa em `RemoteKey.swift`) |
| `GET/POST /1/audio/volume` | Ler ou definir volume e mudo |
| `GET /1/sources` | Listar entradas |
| `POST /1/sources/current` com `{"id":"hdmi1"}` | Trocar de entrada |
| `GET /1/system` | Modelo e versão de software |

`/1/applications`, `/1/menuitems` e a API v6 retornam **Forbidden** no TPM16.5L.

## Estrutura do projeto

| Arquivo | O que faz |
| --- | --- |
| `PhilipsTVRemoteApp.swift` | Ponto de entrada do app |
| `ContentView.swift` | Layout do controle, tela de ajustes, estilo glass |
| `SourceView.swift` | Seletor de fontes |
| `TVClient.swift` | Cliente HTTP JointSpace v1, lógica de energia |
| `RemoteKey.swift` | Nomes de teclas aceitos pela TV |
| `Language.swift` | Textos em inglês/português |

## Privacidade

O app não coleta nenhum dado. Ele só se comunica com o IP da TV que você informar, na sua
rede local. Nada é enviado para nenhum outro lugar.

## Licença

[MIT](LICENSE)

## Aviso

Sem vínculo nem endosso da Philips ou da TP Vision. "Philips" é marca registrada do seu
titular.
