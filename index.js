"use strict";

const fs = require("fs-extra");
const mime = require("mime");
const { send, buffer } = require("micro");
const { router, get, put, del } = require("microrouter");

const getPath = async function (req, res) {
    let filePath = "www/" + (req.params._ || "index.html");
    let fileType = mime.getType(filePath) || "text/plain";
    res.setHeader("Content-Type", fileType);
    return await fs.readFile(filePath);
};

const putData = async function (req, res) {
    await fs.ensureDir("www/data");
    let dataPath = "www/data/" + req.params.file;
    await fs.writeFile(dataPath, await buffer(req));
    send(res, 200);
}

const delData = async function (req, res) {
    let dataPath = "www/data/" + req.params.file;
    await fs.unlink(dataPath);
    send(res, 200);
}

module.exports = router(
    get("/*", getPath),
    put("/data/:file", putData),
    del("/data/:file", delData)
);
