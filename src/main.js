import { createServer } from "node:http";
import { handler } from "./handler.js";

const hostname = "0.0.0.0";
const port = 3000;

createServer(handler).listen(port, hostname, () => {
    console.log(`Server listening on http://${hostname}:${port}/`);
});
