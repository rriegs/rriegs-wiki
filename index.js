"use strict";

const fs = require("fs-extra");
const mime = require("mime");
const path = require("path");
const { send, buffer } = require("micro");
const { router, get, put, del } = require("microrouter");

const errToHttp = function (code) {
    switch (code) {
    case "EINVAL":
        return 400;
    case "EPERM":
    case "EACCES":
    case "ENAMETOOLONG":
        return 403;
    case "ENOENT":
        return 404;
    case "EEXIST":
    case "ENOTDIR":
    case "EISDIR":
    case "ENOTEMPTY":
        return 409;
    default:
        return 500;
    }
};

const errHandler = function (f) {
    return async function (req, res) {
        try {
            return await f(req, res);
        }
        catch (err) {
            send(res, errToHttp(err.code), err.message);
        }
    };
};

const getPath = async function (req, res) {
    let filePath = "www/" + (req.params._ || "index.html");
    let fileType = mime.getType(filePath) || "text/plain";
    res.setHeader("Content-Type", fileType);
    return await fs.readFile(filePath);
};

const putData = async function (req, res) {
    let dataPath = "www/data/" + req.params._;
    await fs.ensureDir(path.dirname(dataPath));
    await fs.writeFile(dataPath, await buffer(req));
    send(res, 200);
}

const delData = async function (req, res) {
    let dataPath = "www/data/" + req.params._;
    await fs.unlink(dataPath);
    send(res, 200);
}

module.exports = errHandler(router(
    get("/*", getPath),
    put("/data/*", putData),
    del("/data/*", delData),
    function (req, res) { send(res, 405); }
));
