export const handler = (req, res) => {
    const requestUrl = req.url;
    const remoteAddress = req.socket.remoteAddress;

    const body = `Hello from '${requestUrl}'!`;

    res.statusCode = 200;
    res.setHeader("Content-Type", "text/plain");
    res.setHeader("X-Remote-Address", remoteAddress);
    res.end(body);
};
