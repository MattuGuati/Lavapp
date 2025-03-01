import { createBot, createProvider, createFlow, addKeyword } from '@builderbot/bot';
import { MemoryDB as Database } from '@builderbot/bot';
import { BaileysProvider as Provider } from '@builderbot/provider-baileys';

const PORT = 3008;

const welcomeFlow = addKeyword(['hi', 'hello', 'hola'])
    .addAnswer(`🙌 Hello welcome to *LavApp Bot*`);

const main = async () => {
    const adapterFlow = createFlow([welcomeFlow]);
    const adapterProvider = createProvider(Provider);
    const adapterDB = new Database();

    const { handleCtx, httpServer } = await createBot({
        flow: adapterFlow,
        provider: adapterProvider,
        database: adapterDB,
    });

    adapterProvider.server.post(
        '/v1/messages',
        handleCtx(async (bot, req, res) => {
            const { number, message } = req.body;
            try {
                const recipient = number.includes('@s.whatsapp.net') ? number : `${number}@s.whatsapp.net`;
                await bot.sendMessage(recipient, message, {});
                res.writeHead(200, { 'Content-Type': 'text/plain' });
                res.end('Mensaje enviado');
            } catch (error) {
                console.error('Error enviando mensaje:', error);
                res.writeHead(500, { 'Content-Type': 'text/plain' });
                res.end('Error al enviar el mensaje');
            }
        })
    );

    httpServer(PORT);
}

main();